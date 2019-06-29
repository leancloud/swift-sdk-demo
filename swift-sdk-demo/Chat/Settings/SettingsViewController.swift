//
//  SettingsViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/5.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let uuid = UUID().uuidString
    
    let titleForHeaderInSection: [String] = [
        "current client",
        "session status",
        "client operation"
    ]
    
    deinit {
        Client.removeSessionObserver(key: self.uuid)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Settings"
        
        Client.addSessionObserver(key: self.uuid) { [weak self] client, event in
            mainQueueExecuting {
                self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
            }
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
    
    func clientClose() {
        let clientID: String = Client.current.ID
        self.activityToggle()
        Client.current.close(completion: { [weak self] (result) in
            self?.activityToggle()
            switch result {
            case .success:
                mainQueueExecuting {
                    Client.current = nil
                    Configuration.UserOption.isAutoOpenEnabled.set(value: false)
                    UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: LaunchViewController())
                }
                Client.installationOperatingQueue.async {
                    do {
                        let installation = LCApplication.default.currentInstallation
                        try installation.remove("channels", element: clientID)
                        if let _ = installation.deviceToken {
                            if let error = installation.save().error {
                                print(error)
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            case .failure(error: let error):
                UIAlertController.show(error: error, controller: self)
            }
        })
    }
    
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if let _ = Client.current.tag {
                return 4
            } else {
                return 3
            }
        case 1:
            return 1
        case 2:
            return 1
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.titleForHeaderInSection[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell = UITableViewCell()
            cell.textLabel?.text = "ID: \(Client.current.ID)"
            cell.accessoryType = .none
        case (0, 1):
            cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Unread Message Count"
            cell.detailTextLabel?.text = Client.current.options.contains(.receiveUnreadMessageCountAfterSessionDidOpen) ? "ON" : "OFF"
            cell.accessoryType = .none
        case (0, 2):
            cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Local Storage"
            cell.detailTextLabel?.text = Client.current.options.contains(.usingLocalStorage) ? "ON" : "OFF"
            cell.accessoryType = .none
        case (0, 3):
            cell = UITableViewCell()
            cell.textLabel?.text = "Tag: \(Client.current.tag ?? "")"
            cell.accessoryType = .none
        case (1, 0):
            cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Session Status"
            cell.detailTextLabel?.text = "\(Client.current.sessionState)"
            cell.accessoryType = .none
        case (2, 0):
            cell = UITableViewCell()
            cell.textLabel?.text = "Close"
            cell.accessoryType = .disclosureIndicator
        default:
            fatalError()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        switch (indexPath.section, indexPath.row) {
        case (2, 0):
            self.clientClose()
        default:
            break
        }
    }
    
}
