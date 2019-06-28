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
    
    var temporaryConversations: [IMTemporaryConversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Temporary Conversation"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction)
        )
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

// MARK: Navigation Right Action Sheet

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
