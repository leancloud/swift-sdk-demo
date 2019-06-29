//
//  NormalConversationListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import UserNotifications
import LeanCloud

class NormalConversationListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let uuid = UUID().uuidString
    
    var conversations: [IMConversation] = []
    
    deinit {
        Client.removeEventObserver(key: self.uuid)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Conversation List"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction)
        )
        
        self.tableView.register(
            UINib(nibName: "\(NormalConversationListCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(NormalConversationListCell.self)"
        )
        self.tableView.rowHeight = 63
        
        self.addObserverForClient()
        
        if let conversations = Client.storedConversations {
            self.conversations = conversations
            Client.storedConversations = nil
        }
        
        self.addClientIDToInstallationChannels()
        self.requestPushNotificationAuthorization()
        LocationManager.current.requestWhenInUseAuthorization()
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

// MARK: Authorization

extension NormalConversationListViewController {
    
    func addClientIDToInstallationChannels() {
        let clientID: String = Client.current.ID
        Client.installationOperatingQueue.async {
            let installation = LCApplication.default.currentInstallation
            do {
                try installation.append("channels", element: clientID, unique: true)
                if let _ = installation.deviceToken {
                    if let error = installation.save().error {
                        print(error)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func requestPushNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                mainQueueExecuting {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                    if granted {
                        mainQueueExecuting {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else if let error = error {
                        UIAlertController.show(error: error, controller: self)
                    }
                }
            default:
                break
            }
        }
    }
    
}

// MARK: IM Event

extension NormalConversationListViewController {
    
    func addObserverForClient() {
        Client.addEventObserver(key: self.uuid) { [weak self] (client, conversation, event) in
            Client.specificAssertion
            guard type(of: conversation) == IMConversation.self, let self = self else {
                return
            }
            switch event {
            case .left(byClientID: _, at: _):
                self.handleConversationEventLeft(conversation: conversation, client: client)
            case .lastMessageUpdated(newMessage: let isNewMessage):
                self.handleConversationEventLastMessageUpdated(conversation: conversation, isNewMessage: isNewMessage)
            case .unreadMessageCountUpdated:
                self.handleConversationEventUnreadMessageCountUpdated(conversation: conversation)
            default:
                break
            }
        }
    }
    
    func handleConversationEventLeft(conversation: IMConversation, client: IMClient) {
        Client.specificAssertion
        client.removeCachedConversation(IDs: [conversation.ID]) { (result) in
            if let error = result.error {
                UIAlertController.show(error: error, controller: self)
            }
        }
        if client.options.contains(.usingLocalStorage) {
            do {
                try client.deleteStoredConversationAndMessages(IDs: [conversation.ID]) { (result) in
                    if let error = result.error {
                        UIAlertController.show(error: error, controller: self)
                    }
                }
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }
        mainQueueExecuting {
            if let index = self.conversations.firstIndex(where: { $0.ID == conversation.ID }) {
                self.conversations.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
    }
    
    func handleConversationEventLastMessageUpdated(conversation: IMConversation, isNewMessage: Bool) {
        self.tryUpsertCell(conversation: conversation, hasNewMessage: isNewMessage)
    }
    
    func handleConversationEventUnreadMessageCountUpdated(conversation: IMConversation) {
        self.tryUpsertCell(conversation: conversation)
    }
    
    func tryUpsertCell(conversation: IMConversation, hasNewMessage: Bool = false) {
        Client.specificAssertion
        mainQueueExecuting {
            if let index = self.conversations.firstIndex(where: { $0.ID == conversation.ID }) {
                if hasNewMessage, index != 0 {
                    self.conversations.remove(at: index)
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.conversations.insert(conversation, at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                } else {
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            } else if let sentTimestamp = conversation.lastMessage?.sentTimestamp {
                var index: Int = 0
                for (i, conv) in self.conversations.enumerated() {
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
                self.conversations.insert(conversation, at: index)
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
    }
    
}

// MARK: Navigation Action

extension NormalConversationListViewController {
    
    @objc func navigationRightButtonAction() {
        let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Create Normal Conversation", style: .default, handler: { (_) in
            let vc = ContactListViewController()
            vc.titleForSection = "choose a set of id for conversation"
            vc.isMultipleSelectionEnabled = true
            vc.commonNames = {
                var names = vc.commonNames
                if let index = names.firstIndex(of: Client.current.ID) {
                    names.remove(at: index)
                }
                return names
            }()
            vc.clientIDSelectedClosure = { [weak self] IDSet in
                self?.createNormalConversation(with: IDSet)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Get Recent Normal Conversations", style: .default, handler: { (_) in
            self.queryRecentNormalConversations()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    func createNormalConversation(with IDSet: Set<String>) {
        var memberSet: Set<String> = IDSet
        memberSet.insert(Client.current.ID)
        guard memberSet.count > 1 else {
            return
        }
        let name: String = {
            let sortedNames: [String] = memberSet.sorted(by: { $0 < $1 })
            let name: String
            if sortedNames.count > 3 {
                name = [sortedNames[0], sortedNames[1], sortedNames[2], "..."].joined(separator: " & ")
            } else {
                name = sortedNames.joined(separator: " & ")
            }
            return name
        }()
        self.activityToggle()
        do {
            try Client.current.createConversation(clientIDs: memberSet, name: name, completion: { (result) in
                self.activityToggle()
                switch result {
                case .success(value: let conversation):
                    mainQueueExecuting {
                        let messageListVC = MessageListViewController()
                        messageListVC.conversation = conversation
                        self.navigationController?.pushViewController(messageListVC, animated: true)
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
    
    func queryRecentNormalConversations() {
        do {
            self.activityToggle()
            
            let transientKey: String = "tr"
            let transientFalseQuery = Client.current.conversationQuery
            try transientFalseQuery.where(transientKey, .equalTo(false))
            let transientNotExistQuery = Client.current.conversationQuery
            try transientNotExistQuery.where(transientKey, .notExisted)
            
            let systemKey: String = "sys"
            let systemFalseQuery = Client.current.conversationQuery
            try systemFalseQuery.where(systemKey, .equalTo(false))
            let systemNotExistQuery = Client.current.conversationQuery
            try systemNotExistQuery.where(systemKey, .notExisted)
            
            guard
                let notTransientQuery = try transientFalseQuery.or(transientNotExistQuery),
                let notSystemQuery = try systemFalseQuery.or(systemNotExistQuery),
                let query = try notTransientQuery.and(notSystemQuery) else
            {
                fatalError()
            }
            
            try query.where("m", .containedIn([Client.current.ID]))
            query.options = [.containLastMessage]
            query.limit = 20
            
            try query.findConversations { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success(value: let conversations):
                    mainQueueExecuting {
                        self.conversations = conversations
                        self.tableView.reloadData()
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            }
        } catch {
            self.activityToggle()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
}

// MARK: Table View

extension NormalConversationListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "normal conversation"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let conversation = self.conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(NormalConversationListCell.self)") as! NormalConversationListCell
        cell.update(with: conversation)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let conversation = self.conversations[indexPath.row]
        let vc = MessageListViewController()
        vc.conversation = conversation
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
