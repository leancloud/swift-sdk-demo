//
//  SettingsViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/5.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.hidesWhenStopped = true
        view.color = .black
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.activityIndicatorView)
        self.activityIndicatorView.center = self.view.center
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

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell = UITableViewCell()
            cell.textLabel?.text = "IM Client Close"
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
        case (0, 0):
            self.activityToggle()
            Client.default.imClient?.close(completion: { (result) in
                self.activityToggle()
                switch result {
                case .success:
                    mainQueueExecuting {
                        UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ViewController")
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            })
        default:
            fatalError()
        }
    }
    
}
