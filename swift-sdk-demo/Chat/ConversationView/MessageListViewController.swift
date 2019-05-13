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
    
    let clientEventObserverKey = UUID().uuidString
    var keyboardDidShowObserver: NSObjectProtocol!
    var keyboardWillHideObserver: NSObjectProtocol!
    
    let refreshControl = UIRefreshControl()
    var contentView: MessageListView {
        return self.view as! MessageListView
    }
    
    var conversation: IMConversation!
    var messages: [IMMessage] = []
    var firstRead: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.addTarget(
            self,
            action: #selector(type(of: self).pullToRefresh),
            for: .valueChanged
        )
        
        self.contentView.tableView.register(
            UINib(nibName: "\(TextMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(TextMessageCell.self)"
        )
        self.contentView.tableView.rowHeight = UITableView.automaticDimension
        self.contentView.tableView.estimatedRowHeight = 60.0
        self.contentView.tableView.refreshControl = self.refreshControl
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: self.contentView.messageInputViewHeightConstraint.constant, right: 0)
        self.contentView.tableView.contentInset = insets
        self.contentView.tableView.scrollIndicatorInsets = insets
        
        self.refreshControl.beginRefreshing()
        self.pullToRefresh()
        
        self.addEventObserverForClient()
        self.addObserverForKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    deinit {
        Client.default.removeObserver(key: self.clientEventObserverKey)
    }
    
    func addEventObserverForClient() {
        Client.default.addObserver(key: self.clientEventObserverKey) { [weak self] (client, conversation, event) in
            Client.default.specificAssertion
            guard
                let self = self,
                self.conversation.ID == conversation.ID
                else
            { return }
            switch event {
            case let .message(event: messageEvent):
                switch messageEvent {
                case let .received(message: message):
                    self.conversation.read(message: message)
                    mainQueueExecuting {
                        self.messages.append(message)
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableViewReloadData(indexPaths: [indexPath])
                    }
                default:
                    break
                }
            default:
                break
            }
        }
    }
    
    func addObserverForKeyboard() {
        self.keyboardDidShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main)
        { [weak self] (notification) in
            guard
                let self = self,
                let info = notification.userInfo,
                let kbFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else
            {
                return
            }
            let kbSize = kbFrame.size
            let insets = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: kbSize.height + self.contentView.messageInputViewHeightConstraint.constant,
                right: 0
            )
            
            self.contentView.tableView.contentInset = insets
            self.contentView.tableView.scrollIndicatorInsets = insets
            self.contentView.messageInputViewBottomConstraint.constant = -kbSize.height
            self.contentView.messageInputView.layoutIfNeeded()
        }
        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main)
        { [weak self] (notification) in
            guard let self = self else { return }
            
            let insets = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: self.contentView.messageInputViewHeightConstraint.constant,
                right: 0
            )
            
            self.contentView.tableView.contentInset = insets
            self.contentView.tableView.scrollIndicatorInsets = insets
            self.contentView.messageInputViewBottomConstraint.constant = 0
            self.contentView.layoutIfNeeded()
        }
    }
    
    func tableViewReloadData(indexPaths: [IndexPath]? = nil) {
        assert(Thread.isMainThread)
        if let indexPaths = indexPaths {
            self.contentView.tableView.reloadRows(at: indexPaths, with: .automatic)
        } else {
            self.contentView.tableView.reloadData()
        }
    }
    
    func tableViewScrollTo(
        indexPath: IndexPath,
        scrollPosition: UITableView.ScrollPosition,
        animated: Bool)
    {
        assert(Thread.isMainThread)
        if !self.messages.isEmpty {
            self.contentView.tableView.scrollToRow(
                at: indexPath,
                at: scrollPosition,
                animated: animated
            )
        }
    }
    
    @objc func pullToRefresh() {
        var start: IMConversation.MessageQueryEndpoint? = nil
        if let oldMessage = self.messages.first {
            start = IMConversation.MessageQueryEndpoint(
                messageID: oldMessage.ID,
                sentTimestamp: oldMessage.sentTimestamp,
                isClosed: true
            )
        }
        do {
            try conversation.queryMessage(
                start: start,
                direction: .newToOld,
                policy: .cacheThenNetwork)
            { [weak self] (result) in
                Client.default.specificAssertion
                guard let self = self else { return }
                switch result {
                case .success(value: let messageResults):
                    if !self.firstRead {
                        self.firstRead = true
                        self.conversation.read()
                    }
                    mainQueueExecuting {
                        let isOriginMessageEmpty = self.messages.isEmpty
                        self.refreshControl.endRefreshing()
                        if
                            let first = self.messages.first,
                            let last = messageResults.last,
                            let firstTimestamp = first.sentTimestamp,
                            let lastTimestamp = last.sentTimestamp,
                            firstTimestamp == lastTimestamp,
                            let firstMessageID = first.ID,
                            let lastMessageID = last.ID,
                            firstMessageID == lastMessageID
                        {
                            self.messages.removeFirst()
                        }
                        self.messages.insert(contentsOf: messageResults, at: 0)
                        self.tableViewReloadData()
                        self.tableViewScrollTo(
                            indexPath: IndexPath(row: messageResults.count - 1, section: 0),
                            scrollPosition: isOriginMessageEmpty ? .bottom : .top,
                            animated: false
                        )
                    }
                case .failure(error: let error):
                    self.refreshControl.endRefreshing()
                    UIAlertController.show(error: error, controller: self)
                }
            }
        } catch {
            self.refreshControl.endRefreshing()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
    @IBAction func messageAttachingAction(_ sender: UIButton) {
        
    }
    
    @IBAction func messageSendingAction(_ sender: UIButton) {
        guard let text = self.contentView.messageInputViewTextField.text, !text.isEmpty else {
            return
        }
        let message = IMTextMessage(text: text)
        self.contentView.messageInputViewTextField.text = nil
        do {
            try self.conversation.send(message: message, completion: { [weak self] (result) in
                Client.default.specificAssertion
                guard let self = self else { return }
                switch result {
                case .success:
                    mainQueueExecuting {
                        mainQueueExecuting {
                            self.messages.append(message)
                            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                            self.tableViewReloadData()
                            self.tableViewScrollTo(
                                indexPath: indexPath,
                                scrollPosition: .bottom,
                                animated: true
                            )
                        }
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            })
        } catch {
            UIAlertController.show(error: error, controller: self)
        }
    }
    
}

extension MessageListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let message = self.messages[indexPath.row]
        switch message {
        case is IMTextMessage:
            let textCell = tableView.dequeueReusableCell(withIdentifier: "\(TextMessageCell.self)") as! TextMessageCell
            textCell.update(with: message as! IMTextMessage)
            cell = textCell
        default:
            fatalError()
        }
        cell.contentView.backgroundColor = (message.ioType == .out)
            ? UIColor(red: 194.0 / 255.0, green: 224.0 / 255.0, blue: 198.0 / 255.0, alpha: 1.0)
            : UIColor.white
        return cell
    }
    
}

extension MessageListViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
