//
//  LaunchViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/6.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class LaunchViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let tupleForSections: [(Int, String)] = [
        (3, "options"),
        (1, "client id"),
        (1, "action")
    ]
    let tupleForFirstSection: [(String, Configuration.UserOption)] = [
        ("Single Device Online", .isTagEnabled),
        ("Local Storage Enabled", .isLocalStorageEnabled),
        ("Auto Open Enabled", .isAutoOpenEnabled),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Launch View"
        
        if Configuration.UserOption.isAutoOpenEnabled.boolValue {
            self.clientOpen()
        }
    }
    
    func clientOpen() {
        do {
            let clientID: String = Configuration.UserOption.clientID.stringValue ?? ""
            let tag: String? = (Configuration.UserOption.isTagEnabled.boolValue ? "mobile" : nil)
            let options: IMClient.Options = Configuration.UserOption.isLocalStorageEnabled.boolValue
                ? .default
                : { var dOptions = IMClient.Options.default; dOptions.remove(.usingLocalStorage); return dOptions }()
            
            Client.current = try IMClient(
                ID: clientID,
                tag: tag,
                options: options,
                delegate: Client.delegator,
                eventQueue: Client.queue
            )
            
            UIApplication.shared.keyWindow?.rootViewController = TabBarController()
        } catch {
            UIAlertController.show(error: error, controller: self)
        }
    }
    
}

extension LaunchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tupleForSections[section].0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.tupleForSections[section].1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        switch indexPath.section {
        case 0:
            let tuple = self.tupleForFirstSection[indexPath.row]
            cell.textLabel?.text = tuple.0
            cell.detailTextLabel?.text = tuple.1.boolValue ? "ON" : "OFF"
        case 1:
            cell.textLabel?.text = "Client ID"
            cell.detailTextLabel?.text = Configuration.UserOption.clientID.stringValue ?? ""
        case 2:
            cell.textLabel?.text = "Open"
            cell.detailTextLabel?.text = ""
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
            let vc = LaunchOptionTableViewController(style: .grouped)
            vc.userOption = self.tupleForFirstSection[indexPath.row].1
            vc.didSelectRowAtClosure = {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = ContactListViewController()
            vc.titleForSection = "choose one id for client"
            vc.clientIDSelectedClosure = { set in
                guard let clientID = set.first else {
                    return
                }
                Configuration.UserOption.clientID.set(value: clientID)
                tableView.reloadData()
            }
            self.navigationController?.pushViewController(vc, animated: true)
        case 2:
            self.clientOpen()
        default:
            fatalError()
        }
    }
    
}

class LaunchOptionTableViewController: UITableViewController {
    
    var userOption: Configuration.UserOption!
    var didSelectRowAtClosure: (() -> Void)?
    
    let titleForHeaderInSection: [String: String] = [
        Configuration.UserOption.isTagEnabled.key: "whether use tag to keep single device online",
        Configuration.UserOption.isLocalStorageEnabled.key: "whether use local storage to cache conversations and messages",
        Configuration.UserOption.isAutoOpenEnabled.key: "whether auto open after launch"
    ]
    
    private var selectedRow: Int {
        get {
            return self.userOption.boolValue ? 1 : 0
        }
        set {
            self.userOption.set(value: (newValue == 1))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Option"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.titleForHeaderInSection[self.userOption.key]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = (indexPath.row == 0 ? "Off" : "On")
        cell.accessoryType = (self.selectedRow == indexPath.row ? .checkmark : .none)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedRow = indexPath.row
        self.didSelectRowAtClosure?()
        self.navigationController?.popViewController(animated: true)
    }
    
}
