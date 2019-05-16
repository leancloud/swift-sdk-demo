//
//  MessageListViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import LeanCloud

class MessageListViewController: UIViewController {
    
    let clientEventObserverKey = UUID().uuidString
    var audioPlayerItemDidPlayToEndObserver: NSObjectProtocol!
    var keyboardDidShowObserver: NSObjectProtocol!
    var keyboardWillHideObserver: NSObjectProtocol!
    
    let refreshControl = UIRefreshControl()
    var contentView: MessageListView {
        return self.view as! MessageListView
    }
    
    var conversation: IMConversation!
    var messages: [IMMessage] = []
    var firstRead: Bool = false
    
    var sendingMessage: IMMessage? {
        didSet {
            if let value = self.sendingMessage {
                switch value {
                case is IMImageMessage:
                    self.messageInputTextField(enabled: false, placeholder: "[Image]")
                case is IMAudioMessage:
                    self.messageInputTextField(enabled: false, placeholder: "[Audio]")
                case is IMVideoMessage:
                    self.messageInputTextField(enabled: false, placeholder: "[Video]")
                default:
                    self.messageInputTextField(enabled: true)
                }
            } else {
                self.messageInputTextField(enabled: true)
            }
        }
    }
    
    var audioPlayer: AVPlayer?
    
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
        self.contentView.tableView.register(
            UINib(nibName: "\(ImageMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(ImageMessageCell.self)"
        )
        self.contentView.tableView.register(
            UINib(nibName: "\(AudioMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(AudioMessageCell.self)"
        )
        self.contentView.tableView.register(
            UINib(nibName: "\(VideoMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(VideoMessageCell.self)"
        )
        self.contentView.tableView.rowHeight = UITableView.automaticDimension
        self.contentView.tableView.estimatedRowHeight = 100.0
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.audioPlayer?.pause()
        self.audioPlayer = nil
        self.contentView.mediaPlayingStatusView.isHidden = true
    }
    
    deinit {
        Client.default.removeObserver(key: self.clientEventObserverKey)
        if let observer = self.audioPlayerItemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        
        self.audioPlayerItemDidPlayToEndObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: .main, using: { [weak self] (_) in
            self?.audioPlayer = nil
            self?.contentView.mediaPlayingStatusView.isHidden = true
        })
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
    
    func activityToggle() {
        mainQueueExecuting {
            if self.view.isUserInteractionEnabled {
                self.contentView.activityIndicatorView.startAnimating()
                self.view.isUserInteractionEnabled = false
            } else {
                self.contentView.activityIndicatorView.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func messageInputTextField(enabled: Bool, placeholder: String? = nil) {
        mainQueueExecuting {
            self.contentView.messageInputViewTextField.isEnabled = enabled
            self.contentView.messageInputViewTextField.text = nil
            self.contentView.messageInputViewTextField.placeholder = placeholder
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
        if self.contentView.messageInputViewTextField.isFirstResponder {
           self.contentView.messageInputViewTextField.resignFirstResponder()
        }
        let alert = UIAlertController(title: "Attachment", message: "-", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Photo or Video", style: .default, handler: { (_) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Audio", style: .default, handler: { (_) in
            let audioRecordingViewController = AudioRecordingViewController()
            audioRecordingViewController.handlerForAudioFileURL = { fileURL in
                self.sendingMessage = IMAudioMessage(filePath: fileURL.path)
            }
            self.present(audioRecordingViewController, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: { (_) in
            self.sendingMessage = nil
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @IBAction func messageSendingAction(_ sender: UIButton) {
        let message: IMMessage
        if let sendingMessage = self.sendingMessage {
            message = sendingMessage
        } else {
            guard let text = self.contentView.messageInputViewTextField.text, !text.isEmpty else {
                return
            }
            message = IMTextMessage(text: text)
        }
        do {
            self.activityToggle()
            try self.conversation.send(message: message, completion: { [weak self] (result) in
                Client.default.specificAssertion
                guard let self = self else { return }
                self.activityToggle()
                switch result {
                case .success:
                    mainQueueExecuting {
                        self.sendingMessage = nil
                        self.messages.append(message)
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableViewReloadData()
                        self.tableViewScrollTo(
                            indexPath: indexPath,
                            scrollPosition: .bottom,
                            animated: true
                        )
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            })
        } catch {
            self.activityToggle()
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
        case is IMImageMessage:
            let imageCell = tableView.dequeueReusableCell(withIdentifier: "\(ImageMessageCell.self)") as! ImageMessageCell
            imageCell.update(with: message as! IMImageMessage)
            cell = imageCell
        case is IMAudioMessage:
            let audioCell = tableView.dequeueReusableCell(withIdentifier: "\(AudioMessageCell.self)") as! AudioMessageCell
            audioCell.update(with: message as! IMAudioMessage)
            audioCell.handlerForPlayer = { [weak self] url in
                guard let self = self else {
                    return
                }
                self.audioPlayer?.pause()
                self.audioPlayer = AVPlayer(url: url)
                self.audioPlayer?.play()
                self.contentView.mediaPlayingStatusView.isHidden = false
            }
            cell = audioCell
        case is IMVideoMessage:
            let videoCell = tableView.dequeueReusableCell(withIdentifier: "\(VideoMessageCell.self)") as! VideoMessageCell
            videoCell.update(with: message as! IMVideoMessage)
            videoCell.handlerForPlayer = { [weak self] url in
                guard let self = self else {
                    return
                }
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    player.play()
                }
            }
            cell = videoCell
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

extension MessageListViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var message: IMCategorizedMessage?
        if let image = info[.editedImage] as? UIImage {
            if let jpgData = image.jpeg() {
                message = IMImageMessage(data: jpgData, format: "jpg")
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            message = IMVideoMessage(filePath: videoURL.path)
        }
        picker.dismiss(animated: true) {
            self.sendingMessage = message
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
