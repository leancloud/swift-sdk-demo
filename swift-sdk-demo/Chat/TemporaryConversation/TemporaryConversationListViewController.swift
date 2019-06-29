//
//  TemporaryConversationListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/28.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class TemporaryConversationListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let uuid = UUID().uuidString
    
    var temporaryConversations: [IMTemporaryConversation] = []
    
    deinit {
        Client.removeEventObserver(key: self.uuid)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Temporary Conversation"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction)
        )
        
        self.addObserverForClient()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func activityToggle() {
        mainQueueExecuting {
            if self.view.isUserInteractionEnabled {
                self.activityIndicatorView.startAnimating()
                self.view.isUserInteractionEnabled = false
            } else {
                self.activityIndicatorView.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
}

// MARK: IM Event

extension TemporaryConversationListViewController {
    
    func addObserverForClient() {
        Client.addEventObserver(key: self.uuid) { [weak self] (client, conversation, event) in
            Client.specificAssertion
            guard let temporaryConversation = conversation as? IMTemporaryConversation, let self = self else {
                return
            }
            switch event {
            case .lastMessageUpdated(newMessage: let isNewMessage):
                self.handleConversationEventLastMessageUpdated(
                    temporaryConversation: temporaryConversation,
                    isNewMessage: isNewMessage
                )
            case .unreadMessageCountUpdated:
                self.handleConversationEventUnreadMessageCountUpdated(
                    temporaryConversation: temporaryConversation
                )
            default:
                break
            }
        }
    }
    
    func handleConversationEventLastMessageUpdated(temporaryConversation: IMTemporaryConversation, isNewMessage: Bool) {
        self.tryUpsertCell(temporaryConversation: temporaryConversation, hasNewMessage: isNewMessage)
    }
    
    func handleConversationEventUnreadMessageCountUpdated(temporaryConversation: IMTemporaryConversation) {
        self.tryUpsertCell(temporaryConversation: temporaryConversation)
    }
    
    func tryUpsertCell(temporaryConversation: IMTemporaryConversation, hasNewMessage: Bool = false) {
        Client.specificAssertion
        mainQueueExecuting {
            if let index = self.temporaryConversations.firstIndex(where: { $0.ID == temporaryConversation.ID }) {
                if hasNewMessage, index != 0 {
                    self.temporaryConversations.remove(at: index)
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.temporaryConversations.insert(temporaryConversation, at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                } else {
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            } else if let sentTimestamp = temporaryConversation.lastMessage?.sentTimestamp {
                var index: Int = 0
                for (i, conv) in self.temporaryConversations.enumerated() {
                    index = i
                    if let st = conv.lastMessage?.sentTimestamp {
                        if sentTimestamp >= st {
                            break
                        } else {
                            continue
                        }
                    } else {
                        break
                    }
                }
                self.temporaryConversations.insert(temporaryConversation, at: index)
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
    }
    
}

// MARK: Navigation Action

extension TemporaryConversationListViewController {
    
    @objc func navigationRightButtonAction() {
        let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Create Temporary-Conversation", style: .default, handler: { (_) in
            let vc = ContactListViewController()
            vc.titleForSection = "choose a set of id for temporary conversation"
            vc.isMultipleSelectionEnabled = true
            vc.commonNames = {
                var names = vc.commonNames
                if let index = names.firstIndex(of: Client.current.ID) {
                    names.remove(at: index)
                }
                return names
            }()
            vc.clientIDSelectedClosure = { [weak self] IDSet in
                self?.createTemporaryConversation(with: IDSet)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    func createTemporaryConversation(with members: Set<String>) {
        guard !members.isEmpty, !(members.count == 1 && members.contains(Client.current.ID)) else {
            return
        }
        do {
            self.activityToggle()
            try Client.current.createTemporaryConversation(clientIDs: members, timeToLive: 3600, completion: { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success(value: let tempConv):
                    mainQueueExecuting {
                        self.temporaryConversations.insert(tempConv, at: 0)
                        self.tableView.reloadData()
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            })
        } catch {
            self.activityToggle()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
}

// MARK: Table View

extension TemporaryConversationListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.temporaryConversations.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "temporary conversation"
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.temporaryConversations[indexPath.row].members?.joined(separator: " & ")
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let temporaryConversation = self.temporaryConversations[indexPath.row]
        let vc = MessageListViewController()
        vc.conversation = temporaryConversation
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
