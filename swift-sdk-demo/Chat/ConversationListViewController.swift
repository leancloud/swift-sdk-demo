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
    
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.hidesWhenStopped = true
        view.color = .black
        return view
    }()
    
    var underlyingConversationMap: [String: IMConversation] = [:]
    var underlyingConversations: [IMConversation] = []
    var conversations: [IMConversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction(_:))
        )
        
        let tableView = (self.view as! ConversationListView).tableView!
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: "ConversationListCell", bundle: .main),
            forCellReuseIdentifier: "ConversationListCell"
        )
        tableView.rowHeight = (self.view.frame.height / 10)
        
        self.view.addSubview(self.activityIndicatorView)
        self.activityIndicatorView.center = self.view.center
        
        self.open()
        
        Client.default.addObserver(key: "ConversationListViewController") { (client, conversation, event) in
            switch event {
            case .joined(byClientID: _):
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
            case .left(byClientID: _):
                if let index = self.underlyingConversations.firstIndex(where: { return $0.ID == conversation.ID }) {
                    self.underlyingConversations.remove(at: index)
                }
                self.underlyingConversationMap.removeValue(forKey: conversation.ID)
                let newSortedConversations = self.underlyingConversations
                mainQueueExecuting {
                    self.conversations = newSortedConversations
                    self.tableViewReloadData()
                }
            default:
                break
            }
        }
    }
    
    func open() {
        self.activityToggle()
        Client.default.imClient?.open(completion: { (result) in
            self.activityToggle()
            
            guard let client = Client.default.imClient else {
                return
            }
            
            var event: IMClientEvent
            if let error = result.error {
                event = .sessionDidClose(error: error)
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
                        self.open()
                    }))
                    self.present(alert, animated: true)
                }
            } else {
                event = .sessionDidOpen
            }
            Client.default.client(client, event: event)
        })
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

// MARK: - Action Sheet

extension ConversationListViewController {
    
    @objc func navigationRightButtonAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Actions", message: "-", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Session Status", style: .default, handler: { (_) in
            Client.default.sessionStatusView.isHidden.toggle()
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
        guard let query = Client.default.imClient?.conversationQuery else {
            return
        }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationListCell") as! ConversationListCell
        let conversation = self.conversations[indexPath.row]
        cell.nameLabel.text = {
            var title: String = ""
            if conversation is IMChatRoom {
                title += "Transient: \(conversation.name ?? "Chat Room")"
            } else if conversation is IMServiceConversation {
                title += "System: \(conversation.name ?? "Service Conversation")"
            } else {
                if conversation is IMTemporaryConversation {
                    title += "Temporary: "
                } else if conversation.isUnique {
                    title += "Unique: "
                } else {
                    title += "Normal: "
                }
                if let members = conversation.members, !members.isEmpty {
                    if let clientID = Client.default.imClient?.ID, members.contains(clientID) {
                        if members.count == 2 {
                            for member in members {
                                if clientID != member {
                                    title += member
                                }
                            }
                            return title
                        } else if members.count > 2 {
                            title += (conversation.name ?? "Group")
                            return title
                        }
                    }
                }
                title += (conversation.name ?? "Conversation")
            }
            return title
        }()
        let lastMessage = conversation.lastMessage
        cell.dateLabel.text = {
            if let date = lastMessage?.sentDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return dateFormatter.string(from: date)
            } else {
                return ""
            }
        }()
        cell.contentLabel.text = {
            if lastMessage is IMCategorizedMessage {
                return (lastMessage as? IMCategorizedMessage)?.text ?? ""
            } else {
                return lastMessage?.content?.string ?? ""
            }
        }()
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
