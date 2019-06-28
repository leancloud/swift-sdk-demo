//
//  ServiceConversationListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class ServiceConversationListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var serviceConversations: [IMServiceConversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Service-Conversation List"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction)
        )
        
        if self.serviceConversations.isEmpty {
            self.queryRecentServiceConversations()
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

extension ServiceConversationListViewController {
    
    @objc func navigationRightButtonAction() {
        let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Get Recent Service-Conversations", style: .default, handler: { (_) in
            self.queryRecentServiceConversations()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    func queryRecentServiceConversations() {
        do {
            self.activityToggle()
            let query = Client.current.conversationQuery
            try query.where("sys", .equalTo(true))
            query.limit = 20
            try query.findConversations { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success(value: let conversations):
                    guard let conversations = conversations as? [IMServiceConversation] else {
                        return
                    }
                    mainQueueExecuting {
                        self.serviceConversations = conversations
                        self.tableView.reloadData()
                    }
                case .failure(error: let error):
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

extension ServiceConversationListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.serviceConversations.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "service conversation"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.serviceConversations[indexPath.row].name ?? "Service-Conversation"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let serviceConversation = self.serviceConversations[indexPath.row]
        let vc = MessageListViewController()
        vc.conversation = serviceConversation
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
