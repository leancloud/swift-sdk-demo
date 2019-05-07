//
//  MessageListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class MessageListViewController: UIViewController {
    
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.hidesWhenStopped = true
        view.color = .black
        return view
    }()
    let refreshControl = UIRefreshControl()
    var tableView: UITableView {
        return (self.view as! MessageListView).tableView
    }
    
    var conversation: IMConversation!
    
    var underlyingMessages: [IMMessage] = []
    var messages: [IMMessage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction(_:))
        )
        
        let tableView = (self.view as! MessageListView).tableView!
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: "MessageListLeftCell", bundle: .main),
            forCellReuseIdentifier: "MessageListLeftCell"
        )
        tableView.register(
            UINib(nibName: "MessageListRightCell", bundle: .main),
            forCellReuseIdentifier: "MessageListRightCell"
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60.0
        
        self.refreshControl.addTarget(
            self,
            action: #selector(type(of: self).pullToRefresh),
            for: .valueChanged
        )
        tableView.refreshControl = self.refreshControl
        
        self.view.addSubview(self.activityIndicatorView)
        self.activityIndicatorView.center = self.view.center
        
        Client.default.addObserver(key: "MessageListViewController\(self.conversation.ID)") { [weak self] (client, conv, event) in
            guard let self = self, conv.ID == self.conversation.ID else {
                return
            }
            switch event {
            case .message(event: let messageEvent):
                switch messageEvent {
                case .received(message: let message):
                    self.underlyingMessages.append(message)
                    let newMessages = self.underlyingMessages
                    mainQueueExecuting {
                        self.messages = newMessages
                        self.tableView.reloadData()
                    }
                default:
                    break
                }
            default:
                break
            }
        }
        
        self.refreshControl.beginRefreshing()
        self.pullToRefresh()
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
    
    @objc func pullToRefresh() {
        do {
            var start: IMConversation.MessageQueryEndpoint?
            if let oldMessage = self.messages.first {
                start = IMConversation.MessageQueryEndpoint(
                    messageID: oldMessage.ID,
                    sentTimestamp: oldMessage.sentTimestamp,
                    isClosed: false
                )
            }
            try conversation.queryMessage(start: start, direction: .newToOld, limit: 10, completion: { (result) in
                switch result {
                case .success(value: let msgs):
                    self.underlyingMessages = msgs + self.underlyingMessages
                    let newMessages = self.underlyingMessages
                    mainQueueExecuting {
                        self.refreshControl.endRefreshing()
                        self.messages = newMessages
                        self.tableView.reloadData()
                    }
                case .failure(error: let error):
                    self.refreshControl.endRefreshing()
                    UIAlertController.show(error: error, controller: self)
                }
            })
        } catch {
            self.refreshControl.endRefreshing()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
    @objc func navigationRightButtonAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Send Text Message", message: "-", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (_) in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else {
                return
            }
            do {
                let message = IMTextMessage()
                message.text = text
                self.activityToggle()
                try self.conversation.send(message: message, completion: { (result) in
                    switch result {
                    case .success:
                        self.underlyingMessages.append(message)
                        let newMessages = self.underlyingMessages
                        mainQueueExecuting {
                            self.activityToggle()
                            self.messages = newMessages
                            self.tableView.reloadData()
                            self.tableView.scrollToRow(
                                at: IndexPath(row: newMessages.count - 1, section: 0),
                                at: .bottom,
                                animated: true
                            )
                        }
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
        self.present(alert, animated: true)
    }
    
}

extension MessageListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = self.messages[indexPath.row]
        if message.ioType == .in {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageListLeftCell") as! MessageListLeftCell
            cell.contentLabel.text = (message as? IMCategorizedMessage)?.text
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageListRightCell") as! MessageListRightCell
            cell.contentLabel.text = (message as? IMCategorizedMessage)?.text
            return cell
        }
    }
    
}
