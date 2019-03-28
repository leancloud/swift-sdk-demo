//
//  ConversationListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class ConversationListViewController: UIViewController {
    
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.hidesWhenStopped = true
        view.color = .black
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(type(of: self).navigationRightButtonAction(_:))
        )
        
        self.view.addSubview(self.activityIndicatorView)
        self.activityIndicatorView.center = self.view.center
        
        self.open()
    }
    
    func open() {
        self.activityToggle()
        Client.default.imClient?.open(completion: { (result) in
            self.activityToggle()
            
            guard let client = Client.default.imClient else {
                return
            }
            
            var event: IMClientEvent
            if let error = result.error {
                event = .sessionDidClose(error: error)
                mainQueueExecuting {
                    let alert = UIAlertController(
                        title: "Open failed",
                        message: "Rollback or Reopen ?",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Rollback", style: .destructive, handler: { (_) in
                        Client.default.imClient = nil
                        UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: .main)
                            .instantiateViewController(withIdentifier: "ViewController")
                    }))
                    alert.addAction(UIAlertAction(title: "Reopen", style: .default, handler: { (_) in
                        self.open()
                    }))
                    self.present(alert, animated: true)
                }
            } else {
                event = .sessionDidOpen
            }
            Client.default.client(client, event: event)
        })
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
    
    @objc func navigationRightButtonAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Session Status", style: .default, handler: { (_) in
            Client.default.sessionStatusView.isHidden.toggle()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
}
