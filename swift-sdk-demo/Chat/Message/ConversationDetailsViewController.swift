//
//  ConversationDetailsViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/23.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class ConversationDetailsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var conversation: IMConversation!
    var isChatRoom: Bool {
        return type(of: self.conversation!) == IMChatRoom.self
    }
    var isServiceConversation: Bool {
        return type(of: self.conversation!) == IMServiceConversation.self
    }
    var isSubscribed: Bool?
    
    lazy var titleForHeaderInSection: [String] = {
        if self.isChatRoom {
            return ["conversation modify"]
        } else if self.isServiceConversation {
            return ["conversation subscription", "conversation mute"]
        } else {
            return ["conversation member", "conversation mute"]
        }
    }()
    
    lazy var textForRowInSection: [[String]] = {
        if self.isChatRoom {
            return [["Name Updating"]]
        } else if self.isServiceConversation {
            return [["Subscribed"], ["Muted"]]
        } else {
            return [["Member List", "Add member", "Remove member", "Leaving"], ["Muted"]]
        }
    }()
    
    var updatedCallback: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Details"
        
        if self.isServiceConversation {
            self.getServiceConversationSubscription()
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
    
    func getServiceConversationSubscription() {
        guard let serviceConversation = self.conversation as? IMServiceConversation else {
            return
        }
        self.activityToggle()
        serviceConversation.checkSubscription { [weak self] (result) in
            Client.specificAssertion
            self?.activityToggle()
            switch result {
            case .success(value: let isSubscribed):
                mainQueueExecuting {
                    self?.isSubscribed = isSubscribed
                    self?.tableView.reloadData()
                }
            case .failure(error: let error):
                UIAlertController.show(error: error, controller: self)
            }
        }
    }
    
}

extension ConversationDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.titleForHeaderInSection.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.titleForHeaderInSection[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.textForRowInSection[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = self.textForRowInSection[indexPath.section][indexPath.row]
        switch indexPath.section {
        case 0:
            if self.isChatRoom {
                cell.detailTextLabel?.text = self.conversation.name ?? ""
            } else if self.isServiceConversation {
                cell.detailTextLabel?.text = (self.isSubscribed != nil) ? (self.isSubscribed! ? "ON" : "OFF") : "-"
            } else {
                cell.detailTextLabel?.text = ""
            }
        case 1:
            cell.detailTextLabel?.text = self.conversation.isMuted ? "ON" : "OFF"
        default:
            fatalError()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        switch indexPath.section {
        case 0:
            if self.isChatRoom {
                self.showUpdatingNameAlert(indexPath: indexPath)
            } else if self.isServiceConversation {
                self.showSubscriptionOption(indexPath: indexPath)
            } else {
                switch indexPath.row {
                case 0:
                    self.showMemberList()
                case 1:
                    self.addMember()
                case 2:
                    self.removeMember()
                case 3:
                    self.leaving()
                default:
                    fatalError()
                }
            }
        case 1:
            self.showMuteOption(indexPath: indexPath)
        default:
            fatalError()
        }
    }
    
}

extension ConversationDetailsViewController {
    
    func showMemberList() {
        let vc = ConversationMemberListTableViewController(style: .grouped)
        vc.memberList = self.conversation.members ?? []
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func addMember()  {
        let vc = ContactListViewController()
        vc.titleForSection = "add members"
        vc.isMultipleSelectionEnabled = true
        vc.commonNames = {
            var names = vc.commonNames
            for item in (self.conversation.members ?? []) {
                if let index = names.firstIndex(of: item) {
                    names.remove(at: index)
                }
            }
            return names
        }()
        vc.clientIDSelectedClosure = { [weak self] IDSet in
            guard let self = self, !IDSet.isEmpty else {
                return
            }
            do {
                self.activityToggle()
                try self.conversation.add(members: IDSet, completion: { [weak self] (result) in
                    Client.specificAssertion
                    self?.activityToggle()
                    switch result {
                    case .allSucceeded:
                        break
                    case .failure(error: let error):
                        UIAlertController.show(error: error, controller: self)
                    case let .slicing(success: successIDs, failure: failures):
                        UIAlertController.show(error: "success: \(successIDs ?? []), failure: \(failures)", controller: self)
                    }
                })
            } catch {
                self.activityToggle()
                UIAlertController.show(error: error, controller: self)
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func removeMember() {
        let vc = ContactListViewController()
        vc.titleForSection = "remove members"
        vc.isMultipleSelectionEnabled = true
        vc.commonNames = {
            var members = self.conversation.members ?? []
            if let index = members.firstIndex(of: Client.current.ID) {
                members.remove(at: index)
            }
            return members
        }()
        vc.clientIDSelectedClosure = { [weak self] IDSet in
            guard let self = self, !IDSet.isEmpty else {
                return
            }
            do {
                self.activityToggle()
                try self.conversation.remove(members: IDSet, completion: { [weak self] (result) in
                    Client.specificAssertion
                    self?.activityToggle()
                    switch result {
                    case .allSucceeded:
                        break
                    case .failure(error: let error):
                        UIAlertController.show(error: error, controller: self)
                    case let .slicing(success: successIDs, failure: failures):
                        UIAlertController.show(error: "success: \(successIDs ?? []), failure: \(failures)", controller: self)
                    }
                })
            } catch {
                self.activityToggle()
                UIAlertController.show(error: error, controller: self)
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func leaving() {
        let alert = UIAlertController(title: "Leaving from this conversation", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { (_) in
            do {
                self.activityToggle()
                try self.conversation.leave(completion: { [weak self] (result) in
                    Client.specificAssertion
                    self?.activityToggle()
                    switch result {
                    case .success:
                        mainQueueExecuting {
                            self?.navigationController?.popToRootViewController(animated: true)
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
    
    func showMuteOption(indexPath: IndexPath) {
        let vc = ConversationOptionTableViewController(style: .grouped)
        vc.navigationTitle = "Mute"
        vc.titleForHeader = "if muted then will not receive notification from this conversation"
        vc.selectedRow = self.conversation.isMuted ? 1 : 0
        vc.didSelectRowAtClosure = { [weak self] shouldMuted in
            guard let self = self else {
                return
            }
            let isMuted = self.conversation.isMuted
            guard isMuted != shouldMuted else {
                return
            }
            let completion: (LCBooleanResult) -> Void = { (result) in
                Client.specificAssertion
                switch result {
                case .success:
                    mainQueueExecuting {
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            }
            if shouldMuted {
                self.conversation.mute(completion: completion)
            } else {
                self.conversation.unmute(completion: completion)
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showUpdatingNameAlert(indexPath: IndexPath) {
        let alert = UIAlertController(title: "Input a New Name", message: "for the Chat-Room", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { $0.placeholder = "Name" })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Change", style: .default, handler: { (_) in
            guard let name = alert.textFields?.first?.text else {
                return
            }
            do {
                self.activityToggle()
                try self.conversation.update(attribution: ["name": name], completion: { [weak self] (result) in
                    self?.activityToggle()
                    switch result {
                    case .success:
                        mainQueueExecuting {
                            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                            self?.updatedCallback?()
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
    
    func showSubscriptionOption(indexPath: IndexPath) {
        let vc = ConversationOptionTableViewController(style: .grouped)
        vc.navigationTitle = "Subscribe"
        vc.titleForHeader = "if subscribed then can receive subscribing message"
        vc.selectedRow = (self.isSubscribed != nil) ? (self.isSubscribed! ? 1 : 0) : -1
        vc.didSelectRowAtClosure = { [weak self] isSubscribing in
            guard
                let self = self,
                let serviceConversation = self.conversation as? IMServiceConversation,
                self.isSubscribed != isSubscribing else
            {
                return
            }
            let completion: (LCBooleanResult) -> Void = { [weak self] result in
                Client.specificAssertion
                switch result {
                case .success:
                    mainQueueExecuting {
                        self?.isSubscribed = isSubscribing
                        self?.tableView.reloadData()
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            }
            do {
                if isSubscribing {
                    try serviceConversation.subscribe(completion: completion)
                } else {
                    try serviceConversation.unsubscribe(completion: completion)
                }
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

class ConversationMemberListTableViewController: UITableViewController {
    
    var memberList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Member List"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.memberList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.memberList[indexPath.row]
        return cell
    }
    
}

class ConversationOptionTableViewController: UITableViewController {
    
    var navigationTitle: String?
    var titleForHeader: String?
    var selectedRow: Int = 0
    var didSelectRowAtClosure: ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.navigationTitle
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.titleForHeader
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = (indexPath.row == 0 ? "OFF" : "ON")
        cell.accessoryType = (self.selectedRow == indexPath.row ? .checkmark : .none)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectRowAtClosure?(indexPath.row == 1)
        self.navigationController?.popViewController(animated: true)
    }
    
}
