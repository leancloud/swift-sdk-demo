//
//  ChatRoomListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/25.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class ChatRoomListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var chatRooms: [IMChatRoom] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "ChatRoom List"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction)
        )
        
        if self.chatRooms.isEmpty {
            self.queryRecentChatRooms()
        }
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

// MARK: Navigation Action

extension ChatRoomListViewController {
    
    @objc func navigationRightButtonAction() {
        let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Create ChatRoom", style: .default, handler: { (_) in
            self.showCreateChatRoomAlert()
        }))
        alert.addAction(UIAlertAction(title: "Get Recent ChatRooms", style: .default, handler: { (_) in
            self.queryRecentChatRooms()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    func showCreateChatRoomAlert() {
        let alert = UIAlertController(title: "Input a Name", message: "for ChatRoom", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { $0.placeholder = "ChatRoom's Name" })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
            do {
                self.activityToggle()
                let name = alert.textFields?.first?.text ?? ""
                try Client.current.createChatRoom(name: name, completion: { [weak self] (result) in
                    Client.specificAssertion
                    guard let self = self else {
                        return
                    }
                    self.activityToggle()
                    switch result {
                    case .success(value: let chatRoom):
                        mainQueueExecuting {
                            self.chatRooms.insert(chatRoom, at: 0)
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
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func queryRecentChatRooms() {
        do {
            self.activityToggle()
            let query = Client.current.conversationQuery
            try query.where("tr", .equalTo(true))
            query.limit = 20
            try query.findConversations { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success(value: let conversations):
                    guard let conversations = conversations as? [IMChatRoom] else {
                        return
                    }
                    mainQueueExecuting {
                        self.chatRooms = conversations
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

extension ChatRoomListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "chat room"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.chatRooms[indexPath.row].name ?? "Chat-Room"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let chatRoom = self.chatRooms[indexPath.row]
        do {
            self.activityToggle()
            try chatRoom.join(completion: { [weak self] (result) in
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success:
                    mainQueueExecuting {
                        let vc = MessageListViewController()
                        vc.conversation = chatRoom
                        self.navigationController?.pushViewController(vc, animated: true)
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
