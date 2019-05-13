//
//  ConversationListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class ConversationListViewController: UIViewController {
    
    let clientEventObserverKey = UUID().uuidString
    
    var contentView: ConversationListView {
        return (self.view as! ConversationListView)
    }
    
    var underlyingConversations: [IMConversation] = []
    var conversations: [IMConversation] = []
    
    var showDetailsCell: Bool = false
    var tableViewRowHeight: CGFloat {
        if self.showDetailsCell {
            return ConversationListDetailsCell.height
        } else {
            return self.view.frame.height / 10
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction(_:))
        )
        
        let tableView = (self.view as! ConversationListView).tableView!
        tableView.register(
            UINib(nibName: "\(ConversationListCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(ConversationListCell.self)"
        )
        tableView.register(
            UINib(nibName: "\(ConversationListDetailsCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(ConversationListDetailsCell.self)"
        )
        
        self.addEventObserverForClient()
        
        self.open()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        Client.default.removeObserver(key: self.clientEventObserverKey)
    }
    
    func addEventObserverForClient() {
        Client.default.addObserver(key: self.clientEventObserverKey) { [weak self] (client, conversation, event) in
            Client.default.specificAssertion
            switch event {
            case .joined(byClientID: _, at: _):
                self?.handleConversationEventJoined(conversation: conversation)
            case .left(byClientID: _, at: _):
                self?.handleConversationEventLeft(conversation: conversation, client: client)
            case let .membersJoined(members: members, byClientID: byClientID, at: at):
                self?.handleConversationEventMemberJoined(
                    conversation: conversation,
                    members: members,
                    byClientID: byClientID,
                    at: at
                )
            case let .membersLeft(members: members, byClientID: byClientID, at: at):
                self?.handleConversationEventMemberLeft(
                    conversation: conversation,
                    members: members,
                    byClientID: byClientID,
                    at: at
                )
            case .lastMessageUpdated(newMessage: let newMessage):
                self?.handleConversationEventLastMessageUpdated(conversation: conversation, isNewMessage: newMessage)
            case .unreadMessageCountUpdated:
                self?.handleConversationEventUnreadMessageCountUpdated(conversation: conversation)
            case let .dataUpdated(updatingData: updatingData, updatedData: updatedData, byClientID: byClientID, at: at):
                self?.handleConversationEventDataUpdated(
                    updatingData: updatingData,
                    updatedData: updatedData,
                    byClientID: byClientID,
                    at: at
                )
            default:
                break
            }
        }
    }
    
    func open() {
        if Client.default.imClient.options.contains(.usingLocalStorage) {
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
    
    func clientOpen() {
        self.activityToggle()
        Client.default.imClient.open(completion: { (result) in
            Client.default.specificAssertion
            self.activityToggle()
            var event: IMClientEvent
            switch result {
            case .success:
                event = .sessionDidOpen
            case .failure(error: let error):
                event = .sessionDidClose(error: error)
                self.showClientOpenFailedAlert()
            }
            Client.default.client(Client.default.imClient, event: event)
        })
    }
    
    func showClientOpenFailedAlert() {
        mainQueueExecuting {
            let alert = UIAlertController(
                title: "Open failed",
                message: "Rollback or Reopen ?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Rollback", style: .destructive, handler: { (_) in
                Client.default.imClient = nil
                UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: .main)
                    .instantiateViewController(withIdentifier: "ViewController")
            }))
            alert.addAction(UIAlertAction(title: "Reopen", style: .default, handler: { (_) in
                self.clientOpen()
            }))
            self.present(alert, animated: true)
        }
    }
    
    func loadLocalStorage(completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            try Client.default.imClient.prepareLocalStorage { (result) in
                Client.default.specificAssertion
                switch result {
                case .success:
                    do {
                        try Client.default.imClient.getAndLoadStoredConversations(completion: { (result) in
                            Client.default.specificAssertion
                            switch result {
                            case .success(value: let conversations):
                                self.underlyingConversations = conversations
                                mainQueueExecuting {
                                    self.conversations = conversations
                                    self.tableViewReloadData()
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
    
    func activityToggle() {
        mainQueueExecuting {
            if self.view.isUserInteractionEnabled {
                self.contentView.activityIndicatorView.startAnimating()
                self.view.isUserInteractionEnabled = false
            } else {
                self.contentView.activityIndicatorView.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func tableViewReloadData(indexPaths: [IndexPath]? = nil) {
        if let indexPaths = indexPaths {
            self.contentView.tableView.reloadRows(at: indexPaths, with: .automatic)
        } else {
            self.contentView.tableView.reloadData()
        }
    }
    
}

// MARK: Conversation Event

extension ConversationListViewController {
    
    func handleConversationEventJoined(conversation: IMConversation) {
        Client.default.specificAssertion
        self.moveConversationToTop(conversation: conversation)
    }
    
    func handleConversationEventLeft(conversation: IMConversation, client: IMClient) {
        Client.default.specificAssertion
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
            let newSortedConversations = self.underlyingConversations
            mainQueueExecuting {
                self.conversations = newSortedConversations
                self.tableViewReloadData()
            }
        }
    }
    
    func handleConversationEventMemberJoined(conversation: IMConversation, members: [String], byClientID: String?, at: Date?) {
        Client.default.specificAssertion
    }
    
    func handleConversationEventMemberLeft(conversation: IMConversation, members: [String], byClientID: String?, at: Date?) {
        Client.default.specificAssertion
    }
    
    func handleConversationEventLastMessageUpdated(conversation: IMConversation, isNewMessage: Bool) {
        Client.default.specificAssertion
        if isNewMessage {
            self.moveConversationToTop(conversation: conversation)
        } else {
            self.updateOrInsertConversation(conversation: conversation)
        }
    }
    
    func handleConversationEventUnreadMessageCountUpdated(conversation: IMConversation) {
        Client.default.specificAssertion
        self.updateOrInsertConversation(conversation: conversation)
    }
    
    func handleConversationEventDataUpdated(updatingData: [String: Any]?, updatedData: [String: Any]?, byClientID: String?, at: Date?) {
        Client.default.specificAssertion
    }
    
    func moveConversationToTop(conversation: IMConversation) {
        if let index = self.underlyingConversations.firstIndex(where: { $0.ID == conversation.ID }) {
            self.underlyingConversations.remove(at: index)
        }
        self.underlyingConversations.insert(conversation, at: 0)
        let newSortedConversations = self.underlyingConversations
        mainQueueExecuting {
            self.conversations = newSortedConversations
            self.tableViewReloadData()
        }
    }
    
    func updateOrInsertConversation(conversation: IMConversation) {
        if let index = self.underlyingConversations.firstIndex(where: { $0.ID == conversation.ID }) {
            mainQueueExecuting {
                let indexPath = IndexPath(row: index, section: 0)
                self.tableViewReloadData(indexPaths: [indexPath])
            }
        } else {
            self.underlyingConversations.insert(conversation, at: 0)
            let newSortedConversations = self.underlyingConversations
            mainQueueExecuting {
                self.conversations = newSortedConversations
                self.tableViewReloadData()
            }
        }
    }
    
}

// MARK: Action Sheet

extension ConversationListViewController {
    
    @objc func navigationRightButtonAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Actions", message: "-", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "\(Client.default.sessionStatusView.isHidden ? "Show" : "Hide") Session Status", style: .default, handler: { (_) in
            Client.default.sessionStatusView.isHidden.toggle()
        }))
        alert.addAction(UIAlertAction(title: "Show \(self.showDetailsCell ? "Info" : "Details")", style: .default, handler: { (_) in
            self.showDetailsCell.toggle()
            self.tableViewReloadData()
        }))
        alert.addAction(UIAlertAction(title: "Get Recent Conversations", style: .default, handler: { (_) in
            self.getRecentConversations()
        }))
        alert.addAction(UIAlertAction(title: "Create Conversation", style: .default, handler: { (_) in
            self.createConversation()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    func getRecentConversations() {
        let query = Client.default.imClient.conversationQuery
        do {
            self.activityToggle()
            query.options = [.containLastMessage]
            try query.findConversations { (result) in
                Client.default.specificAssertion
                switch result {
                case .success(value: let convs):
                    var conversationMap: [String: IMConversation] = [:]
                    for item in self.underlyingConversations {
                        conversationMap[item.ID] = item
                    }
                    for item in convs {
                        conversationMap[item.ID] = item
                    }
                    let sortedConversations = conversationMap.values.sorted(by: {
                        return ($0.lastMessage?.sentTimestamp ?? 0) > ($1.lastMessage?.sentTimestamp ?? 0)
                    })
                    self.underlyingConversations = sortedConversations
                    mainQueueExecuting {
                        self.activityToggle()
                        self.conversations = sortedConversations
                        self.tableViewReloadData()
                    }
                case .failure(error: let error):
                    self.activityToggle()
                    UIAlertController.show(error: error, controller: self)
                }
            }
        } catch {
            self.activityToggle()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
    func createConversation() {
        let inputName: (@escaping ([String]) -> Void) -> Void = { closure in
            let alert = UIAlertController(title: "Input other members", message: "use , to split multi-members.", preferredStyle: .alert)
            alert.addTextField()
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (_) in
                guard let text = alert.textFields?.first?.text, !text.isEmpty else {
                    return
                }
                let members: [String] = text.components(separatedBy: ",").map({ (item) -> String in
                    return item.trimmingCharacters(in: .whitespaces)
                })
                closure(members)
            }))
            self.present(alert, animated: true)
        }
        let alert = UIAlertController(title: "Create Conversation", message: "select type", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Normal Unique", style: .default, handler: { (_) in
            inputName() { members in
                do {
                    self.activityToggle()
                    try Client.default.imClient.createConversation(clientIDs: Set(members), completion: { (result) in
                        Client.default.specificAssertion
                        self.activityToggle()
                        if let error = result.error {
                            UIAlertController.show(error: error, controller: self)
                        }
                    })
                } catch {
                    self.activityToggle()
                    UIAlertController.show(error: error, controller: self)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Normal", style: .default, handler: { (_) in
            inputName() { members in
                do {
                    self.activityToggle()
                    try Client.default.imClient.createConversation(clientIDs: Set(members), isUnique: false, completion: { (result) in
                        Client.default.specificAssertion
                        self.activityToggle()
                        if let error = result.error {
                            UIAlertController.show(error: error, controller: self)
                        }
                    })
                } catch {
                    self.activityToggle()
                    UIAlertController.show(error: error, controller: self)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "ChatRoom", style: .default, handler: { (_) in
            do {
                self.activityToggle()
                try Client.default.imClient.createChatRoom(completion: { (result) in
                    Client.default.specificAssertion
                    self.activityToggle()
                    if let error = result.error {
                        UIAlertController.show(error: error, controller: self)
                    }
                })
            } catch {
                self.activityToggle()
                UIAlertController.show(error: error, controller: self)
            }
        }))
        alert.addAction(UIAlertAction(title: "Temporary", style: .default, handler: { (_) in
            inputName() { members in
                do {
                    self.activityToggle()
                    try Client.default.imClient.createTemporaryConversation(clientIDs: Set(members), timeToLive: 3600, completion: { (result) in
                        Client.default.specificAssertion
                        self.activityToggle()
                        if let error = result.error {
                            UIAlertController.show(error: error, controller: self)
                        }
                    })
                } catch {
                    self.activityToggle()
                    UIAlertController.show(error: error, controller: self)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ConversationListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableViewRowHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let conversation = self.conversations[indexPath.row]
        if self.showDetailsCell {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "\(ConversationListDetailsCell.self)")
                as! ConversationListDetailsCell
            cell.update(with: conversation)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "\(ConversationListCell.self)")
                as! ConversationListCell
            cell.update(with: conversation)
            return cell
        }
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
