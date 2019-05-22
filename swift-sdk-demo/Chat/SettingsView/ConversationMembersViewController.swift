//
//  ConversationMembersViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/22.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class ConversationMembersViewController: UIViewController {
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var reservedMemberID: String?
    var members: [String] = []
    var completion: (([String]) -> Void)?
    
    var canCellEdit: Bool = true
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addAction(_ sender: UIButton) {
        let alert = UIAlertController(title: "Input Member ID", message: "use alphanumeric and not start with number", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (_) in
            guard
                let text = alert.textFields?.first?.text,
                !text.isEmpty,
                !self.members.contains(text)
                else
            {
                return
            }
            if let reservedMemberID = self.reservedMemberID {
                guard reservedMemberID != text else {
                    return
                }
            }
            self.members.append(text)
            self.tableView.reloadData()
        }))
        self.present(alert, animated: true)
    }
    
    @IBAction func doneAction(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.completion?(self.members)
        }
    }
    
}

extension ConversationMembersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.members[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.canCellEdit
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.members.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        return [delete]
    }
    
}
