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
    
    var underlyingConversations: [IMConversation] = []
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
        
        self.open()
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

// MARK: Open

extension NormalConversationListViewController {
    
    func open() {
        if Client.current.options.contains(.usingLocalStorage) {
            self.activityToggle()
            self.loadLocalStorage { (result) in
                self.activityToggle()
                switch result {
                case .success:
                    self.clientOpen()
                case .failure(let error):
                    UIAlertController.show(error: error, controller: self)
                }
            }
        } else {
            self.clientOpen()
        }
    }
    
    func loadLocalStorage(completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            try Client.current.prepareLocalStorage { (result) in
                Client.specificAssertion
                switch result {
                case .success:
                    do {
                        try Client.current.getAndLoadStoredConversations(completion: { (result) in
                            Client.specificAssertion
                            switch result {
                            case .success(value: let conversations):
                                self.underlyingConversations = conversations
                                mainQueueExecuting {
                                    self.conversations = conversations
                                    self.tableView.reloadData()
                                }
                                completion(.success(true))
                            case .failure(error: let error):
                                completion(.failure(error))
                            }
                        })
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(error: let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func clientOpen() {
        self.activityToggle()
        let options: IMClient.SessionOpenOptions
        if let _ = Client.current.tag {
            options = Configuration.UserOption.isAutoOpenEnabled.boolValue ? [] : [.forced]
        } else {
            options = .default
        }
        Client.current.open(options: options, completion: { [weak self] (result) in
            Client.specificAssertion
            guard let self = self else {
                return
            }
            self.activityToggle()
            var event: IMClientEvent
            switch result {
            case .success:
                event = .sessionDidOpen
                
                self.addClientIDToInstallationChannels()
                self.requestPushNotificationAuthorization()
                LocationManager.current.requestWhenInUseAuthorization()
                
                mainQueueExecuting {
                    if self.conversations.isEmpty {
                        self.queryRecentNormalConversations()
                    }
                }
            case .failure(error: let error):
                event = .sessionDidClose(error: error)
                if error.code != 4111 {
                    self.showClientOpenFailedAlert(error: error)
                }
            }
            if let client = Client.current {
                Client.delegator.client(client, event: event)
            }
        })
    }
    
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
    
    func showClientOpenFailedAlert(error: LCError) {
        mainQueueExecuting {
            let alert = UIAlertController(
                title: "Open failed, Rollback or Reopen ?",
                message: "Error: \(error)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Rollback", style: .destructive, handler: { (_) in
                Client.current = nil
                UIApplication.shared.keyWindow?.rootViewController = UINavigationController(
                    rootViewController: LaunchViewController()
                )
            }))
            alert.addAction(UIAlertAction(title: "Reopen", style: .default, handler: { (_) in
                self.clientOpen()
            }))
            self.present(alert, animated: true)
        }
    }

    
}

// MARK: IM Event

extension NormalConversationListViewController {
    
    func addObserverForClient() {
        Client.addEventObserver(key: self.uuid) { [weak self] (client, conversation, event) in
            Client.specificAssertion
            guard let self = self, type(of: conversation) == IMConversation.self else {
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
        if let index = self.underlyingConversations.firstIndex(where: { return $0.ID == conversation.ID }) {
            self.underlyingConversations.remove(at: index)
            let underlyingConversationsCopy = self.underlyingConversations
            mainQueueExecuting {
                self.conversations = underlyingConversationsCopy
                self.tableView.reloadData()
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
        
        let resort: (Int64) -> Void = { sentTimestamp in
            var index: Int = 0
            for (i, conv) in self.underlyingConversations.enumerated() {
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
            self.underlyingConversations.insert(conversation, at: index)
            let underlyingConversationsCopy = self.underlyingConversations
            mainQueueExecuting {
                self.conversations = underlyingConversationsCopy
                self.tableView.reloadData()
            }
        }
        
        if let index = self.underlyingConversations.firstIndex(where: { $0.ID == conversation.ID }) {
            if hasNewMessage {
                if let sentTimestamp = conversation.lastMessage?.sentTimestamp {
                    self.underlyingConversations.remove(at: index)
                    resort(sentTimestamp)
                }
            } else {
                mainQueueExecuting {
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        } else if let sentTimestamp = conversation.lastMessage?.sentTimestamp {
            resort(sentTimestamp)
        }
    }
    
}

// MARK: Navigation Right Action Sheet

extension NormalConversationListViewController {
    
    @objc func navigationRightButtonAction() {
        let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Create Normal Conversation", style: .default, handler: { (_) in
            let vc = ContactListViewController()
            vc.titleForSection = "choose a set of id for conversation"
            vc.isMultipleSelectionEnabled = true
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
        self.activityToggle()
        do {
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
                switch result {
                case .success(value: let conversations):
                    var conversationMap: [String: IMConversation] = [:]
                    self.underlyingConversations.forEach({ (item) in
                        conversationMap[item.ID] = item
                    })
                    conversations.forEach({ (item) in
                        conversationMap[item.ID] = item
                    })
                    let sortedConversations = conversationMap.values.sorted(by: {
                        ($0.lastMessage?.sentTimestamp ?? 0) > ($1.lastMessage?.sentTimestamp ?? 0)
                    })
                    self.underlyingConversations = sortedConversations
                    mainQueueExecuting {
                        self.activityToggle()
                        self.conversations = sortedConversations
                        self.tableView.reloadData()
                    }
                case .failure(error: let error):
                    self.activityToggle()
                    if error.code != 9100 {                    
                        UIAlertController.show(error: error, controller: self)
                    }
                }
            }
        } catch {
            self.activityToggle()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
}

// MARK: Table View Delegate

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
