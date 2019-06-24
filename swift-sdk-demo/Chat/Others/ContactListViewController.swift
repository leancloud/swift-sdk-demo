//
//  ContactListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/5.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class ContactListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var titleForSection: String?
    
    var isMultipleSelectionEnabled: Bool = false
    var clientIDSelectedClosure: ((Set<String>) -> Void)?
    var selectedSet: Set<String> = []
    
    var commonNames: [String] = [
        "James", "Mary",
        "John", "Patricia",
        "Robert", "Jennifer",
        "Michael", "Linda",
        "William", "Elizabeth",
        "David", "Barbara",
        "Richard", "Susan",
        "Joseph", "Jessica",
        "Thomas", "Sarah",
        "Charles", "Karen"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ID List"
        
        if self.isMultipleSelectionEnabled {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(type(of: self).done)
            )
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func done() {
        self.navigationController?.popViewController(animated: false)
        self.clientIDSelectedClosure?(self.selectedSet)
    }
    
}

extension ContactListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.commonNames.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.titleForSection
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = commonNames[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = name
        cell.accessoryType = (self.selectedSet.contains(name) ? .checkmark : .none)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let name = self.commonNames[indexPath.row]
        if self.selectedSet.contains(name) {
            self.selectedSet.remove(name)
        } else {
            self.selectedSet.insert(name)
        }
        tableView.reloadData()
        
        if !self.isMultipleSelectionEnabled {
            self.clientIDSelectedClosure?(self.selectedSet)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}
