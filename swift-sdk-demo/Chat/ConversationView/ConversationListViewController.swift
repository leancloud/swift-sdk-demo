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
    
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.hidesWhenStopped = true
        view.color = .black
        return view
    }()
    
    var underlyingConversationMap: [String: IMConversation] = [:]
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
        
        self.view.addSubview(self.activityIndicatorView)
        self.activityIndicatorView.center = self.view.center
        
        self.addEventObserverForClient()
        
        self.open()
    }
    
    deinit {
        Client.default.removeObserver(key: self.clientEventObserverKey)
    }
    
    func addEventObserverForClient() {
        Client.default.addObserver(key: self.clientEventObserverKey) { [weak self] (client, conversation, event) in
            switch event {
            case .joined(byClientID: _, at: _):
                self?.handleConversationEventJoined(conversation: conversation)
            case .left(byClientID: _, at: _):
                self?.handleConversationEventLeft(conversation: conversation, client: client)
            case .lastMessageUpdated:
                self?.handleConversationLastMessageUpdated(conversation: conversation)
            case .unreadMessageCountUpdated:
                self?.handleConversationUnreadMessageCountUpdated(conversation: conversation)
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
                switch result {
                case .success:
                    do {
                        try Client.default.imClient.getAndLoadStoredConversations(completion: { (result) in
                            switch result {
                            case .success(value: let conversations):
                                self.underlyingConversations = conversations
                                for conv in conversations {
                                    self.underlyingConversationMap[conv.ID] = conv
                                }
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
                self.activityIndicatorView.startAnimating()
                self.view.isUserInteractionEnabled = false
            } else {
                self.activityIndicatorView.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func tableViewReloadData() {
        (self.view as! ConversationListView).tableView.reloadData()
    }
    
}

// MARK: Conversation Event

extension ConversationListViewController {
    
    func handleConversationEventJoined(conversation: IMConversation) {
        self.updateConversationList(conversation: conversation)
    }
    
    func handleConversationEventLeft(conversation: IMConversation, client: IMClient) {
        if let index = self.underlyingConversations.firstIndex(where: { return $0.ID == conversation.ID }) {
            self.underlyingConversations.remove(at: index)
        }
        self.underlyingConversationMap.removeValue(forKey: conversation.ID)
        let newSortedConversations = self.underlyingConversations
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
            self.conversations = newSortedConversations
            self.tableViewReloadData()
        }
    }
    
    func handleConversationLastMessageUpdated(conversation: IMConversation) {
        self.updateConversationList(conversation: conversation)
    }
    
    func handleConversationUnreadMessageCountUpdated(conversation: IMConversation) {
        self.updateConversationList(conversation: conversation)
    }
    
    func updateConversationList(conversation: IMConversation) {
        if let _ = self.underlyingConversationMap[conversation.ID],
            let index = self.underlyingConversations.firstIndex(where: { return $0.ID == conversation.ID }) {
            self.underlyingConversations.remove(at: index)
        }
        self.underlyingConversations.insert(conversation, at: 0)
        self.underlyingConversationMap[conversation.ID] = conversation
        let newSortedConversations = self.underlyingConversations
        mainQueueExecuting {
            self.conversations = newSortedConversations
            self.tableViewReloadData()
        }
    }
    
}

// MARK: Action Sheet

extension ConversationListViewController {
    
    @objc func navigationRightButtonAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Actions", message: "-", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Session Status", style: .default, handler: { (_) in
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
                switch result {
                case .success(value: let convs):
                    for conv in convs {
                        self.underlyingConversationMap[conv.ID] = conv
                    }
                    let sortedConversations = self.underlyingConversationMap.values.sorted(by: {
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
        guard let client = Client.default.imClient else {
            return
        }
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
        let handleConversation: (IMConversation) -> Void = { conv in
            if let _ = self.underlyingConversationMap[conv.ID],
                let index = self.underlyingConversations.firstIndex(where: { return $0.ID == conv.ID }) {
                self.underlyingConversations.remove(at: index)
            }
            self.underlyingConversations.insert(conv, at: 0)
            self.underlyingConversationMap[conv.ID] = conv
            let newSortedConversations = self.underlyingConversations
            mainQueueExecuting {
                self.activityToggle()
                self.conversations = newSortedConversations
                self.tableViewReloadData()
            }
        }
        let alert = UIAlertController(title: "Create Conversation", message: "select type", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Normal Unique", style: .default, handler: { (_) in
            inputName() { members in
                do {
                    self.activityToggle()
                    try client.createConversation(clientIDs: Set(members), completion: { (result) in
                        switch result {
                        case .success(value: let conversation):
                            handleConversation(conversation)
                        case .failure(error: let error):
                            self.activityToggle()
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
                    try client.createConversation(clientIDs: Set(members), isUnique: false, completion: { (result) in
                        switch result {
                        case .success(value: let conversation):
                            handleConversation(conversation)
                        case .failure(error: let error):
                            self.activityToggle()
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
                try client.createChatRoom(completion: { (result) in
                    switch result {
                    case .success(value: let conversation):
                        handleConversation(conversation)
                    case .failure(error: let error):
                        self.activityToggle()
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
                    try client.createTemporaryConversation(clientIDs: Set(members), timeToLive: 3600, completion: { (result) in
                        switch result {
                        case .success(value: let conversation):
                            handleConversation(conversation)
                        case .failure(error: let error):
                            self.activityToggle()
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
