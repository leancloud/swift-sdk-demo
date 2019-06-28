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
import CoreLocation
import LeanCloud

class MessageListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputViewContainer: UIView!
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewTextField: UITextField!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let refreshControl = UIRefreshControl()
    var maskView: UIView?
    
    let uuid = UUID().uuidString
    var keyboardDidShowObserver: NSObjectProtocol!
    var keyboardWillHideObserver: NSObjectProtocol!
    var isKeyboardObserverActive: Bool = false
    
    var conversation: IMConversation!
    var isChatRoom: Bool {
        return type(of: self.conversation!) == IMChatRoom.self
    }
    var isTemporaryConversation: Bool {
        return type(of: self.conversation!) == IMTemporaryConversation.self
    }
    var timerForGetOnlineMembersCount: Timer?
    var messages: [IMMessage] = []
    
    deinit {
        Client.removeEventObserver(key: self.uuid)
        Client.removeSessionObserver(key: self.uuid)
        NotificationCenter.default.removeObserver(self.keyboardDidShowObserver!)
        NotificationCenter.default.removeObserver(self.keyboardWillHideObserver!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isChatRoom {
            self.navigationItem.title = "\(self.conversation.name ?? "")(0)"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Leaving",
                style: .plain,
                target: self,
                action: #selector(type(of: self).leave)
            )
            self.setupTimerForGetOnlineMembersCount()
        } else if self.isTemporaryConversation {
            self.navigationItem.title = "Temporary"
        } else {
            self.navigationItem.title = self.conversation.name
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "∙∙∙",
                style: .plain,
                target: self,
                action: #selector(type(of: self).moreInfo)
            )
        }
        
        self.setupTableView()
        
        self.addObserverForClient()
        self.addObserverForKeyboard()
        
        self.refreshControl.beginRefreshing()
        self.pullToRefresh(NSNumber(value: true))
        
        if self.conversation.isOutdated {
            self.refreshConversationData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isKeyboardObserverActive = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isKeyboardObserverActive = false
    }
    
    func setupTableView() {
        self.tableView.register(
            UINib(nibName: "\(TextMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(TextMessageCell.self)"
        )
        self.tableView.register(
            UINib(nibName: "\(ImageMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(ImageMessageCell.self)"
        )
        self.tableView.register(
            UINib(nibName: "\(MediaMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(MediaMessageCell.self)"
        )
        self.tableView.register(
            UINib(nibName: "\(RecalledMessageCell.self)", bundle: .main),
            forCellReuseIdentifier: "\(RecalledMessageCell.self)"
        )
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 100.0
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: self.inputViewHeightConstraint.constant, right: 0)
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
        self.tableView.separatorColor = UIColor.clear
        
        self.refreshControl.addTarget(
            self,
            action: #selector(type(of: self).pullToRefresh(_:)),
            for: .valueChanged
        )
        self.tableView.refreshControl = self.refreshControl
    }
    
    @objc func pullToRefresh(_ isFirst: NSNumber?) {
        self.queryMessageHistory(isFirst: (isFirst != nil)) { (_) in
            mainQueueExecuting {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func activityToggle() {
        mainQueueExecuting {
            if self.activityIndicatorView.isAnimating {
                self.activityIndicatorView.stopAnimating()
                self.maskView?.removeFromSuperview()
                self.maskView = nil
            } else {
                self.activityIndicatorView.startAnimating()
                let maskView = UIView(frame: self.view.bounds)
                maskView.isUserInteractionEnabled = false
                maskView.backgroundColor = .clear
                self.view.addSubview(maskView)
                self.maskView = maskView
            }
        }
    }
    
    @objc func leave() {
        do {
            self.activityToggle()
            try self.conversation.leave(completion: { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success:
                    mainQueueExecuting {
                        self.timerForGetOnlineMembersCount?.invalidate()
                        self.timerForGetOnlineMembersCount = nil
                        self.navigationController?.popViewController(animated: true)
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
    
    @objc func moreInfo() {
        let vc = ConversationDetailsViewController()
        vc.conversation = self.conversation
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func setupTimerForGetOnlineMembersCount() {
        self.timerForGetOnlineMembersCount = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { [weak self] (_) in
            (self?.conversation as? IMChatRoom)?.getOnlineMembersCount(completion: { (result) in
                guard let self = self, result.error == nil else {
                    return
                }
                mainQueueExecuting {
                    self.navigationItem.title = "\(self.conversation.name ?? "")(\(result.intValue))"
                }
            })
        })
        self.timerForGetOnlineMembersCount?.fire()
    }
    
}

// MARK: IM Event

extension MessageListViewController {
    
    func addObserverForClient() {
        Client.addEventObserver(key: self.uuid) { [weak self] (client, conversation, event) in
            Client.specificAssertion
            guard let self = self, self.conversation.ID == conversation.ID else {
                return
            }
            switch event {
            case .message(event: let messageEvent):
                switch messageEvent {
                case let .received(message: message):
                    self.handleMessageReceived(message: message)
                case let .updated(updatedMessage: updatedMessage, reason: _):
                    self.handleMessageUpdated(updatedMessage: updatedMessage)
                default:
                    break
                }
            default:
                break
            }
            if conversation.isOutdated {
                self.refreshConversationData()
            }
        }
        
        Client.addSessionObserver(key: self.uuid) { [weak self] (client, event) in
            Client.specificAssertion
            guard let self = self else {
                return
            }
            switch event {
            case .sessionDidOpen:
                if self.isChatRoom {
                    self.joiningChatRoom()
                } else {
                    self.refreshMessageList()
                }
            default:
                break
            }
        }
    }
    
    func handleMessageReceived(message: IMMessage) {
        self.conversation.read(message: message)
        mainQueueExecuting {
            var originBottomIndexPath: IndexPath?
            if !self.messages.isEmpty {
                originBottomIndexPath = IndexPath(row: self.messages.count - 1, section: 0)
            }
            self.messages.append(message)
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            if
                let bottomIndexPath = originBottomIndexPath,
                let bottomCell = self.tableView.cellForRow(at: bottomIndexPath),
                self.tableView.visibleCells.contains(bottomCell)
            {
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    func handleMessageUpdated(updatedMessage: IMMessage) {
        mainQueueExecuting {
            var indexPath: IndexPath?
            for (index, item) in self.messages.enumerated() {
                if item.ID == updatedMessage.ID, item.sentTimestamp == updatedMessage.sentTimestamp {
                    indexPath = IndexPath(row: index, section: 0)
                    self.messages[index] = updatedMessage
                    break
                }
            }
            if let indexPath = indexPath {
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    func joiningChatRoom() {
        do {
            self.activityToggle()
            try self.conversation.join(completion: { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success:
                    self.refreshMessageList()
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            })
        } catch {
            self.activityToggle()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
    func refreshConversationData() {
        do {
            try conversation.refresh(completion: { (result) in
                Client.specificAssertion
                switch result {
                case .success:
                    break
                case .failure(error: let error):
                    print(error)
                }
            })
        } catch {
            print(error)
        }
    }
    
}

// MARK: Keyboard

extension MessageListViewController {
    
    func addObserverForKeyboard() {
        self.keyboardDidShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main)
        { [weak self] (notification) in
            self?.keyboardDidShow(notification: notification)
        }
        
        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main)
        { [weak self] (notification) in
            self?.keyboardWillHide(notification: notification)
        }
    }
    
    func keyboardDidShow(notification: Notification) {
        guard
            self.isKeyboardObserverActive,
            let info = notification.userInfo,
            let kbFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else
        {
            return
        }
        
        let kbSize = kbFrame.size
        let insets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: kbSize.height + self.inputViewHeightConstraint.constant,
            right: 0
        )
        
        let bottomSafeAreaSize: CGFloat
        if #available(iOS 11.0, *) {
            bottomSafeAreaSize = self.view.safeAreaInsets.bottom
        } else {
            bottomSafeAreaSize = self.bottomLayoutGuide.length
        }
        
        self.tableView.contentInset = insets
        self.inputViewBottomConstraint.constant = kbSize.height - bottomSafeAreaSize
        self.inputViewContainer.layoutIfNeeded()
        
        if !self.messages.isEmpty {
            self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    func keyboardWillHide(notification: Notification) {
        guard self.isKeyboardObserverActive else {
            return
        }
        
        let insets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: self.inputViewHeightConstraint.constant,
            right: 0
        )
        
        self.tableView.contentInset = insets
        self.inputViewBottomConstraint.constant = 0
        self.inputViewContainer.layoutIfNeeded()
    }
    
}

// MARK: Input View

extension MessageListViewController {
    
    func send(message: IMMessage) {
        do {
            self.activityToggle()
            try self.conversation.send(message: message, completion: { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success:
                    mainQueueExecuting {
                        self.messages.append(message)
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.insertRows(at: [indexPath], with: .bottom)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
    
    @IBAction func toggleInputViewActionSheet(_ sender: UIButton) {
        if self.inputViewTextField.isFirstResponder {
            self.inputViewTextField.resignFirstResponder()
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(self.sendPhotoOrVideoAlertAction)
        alert.addAction(self.sendAudioAlertAction)
        alert.addAction(self.sendLocationAlertAction)
        alert.addAction(self.sendFileAlertAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    var sendPhotoOrVideoAlertAction: UIAlertAction {
        return UIAlertAction(title: "Send Photo or Video", style: .default, handler: { (_) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true)
        })
    }
    
    var sendAudioAlertAction: UIAlertAction {
        return UIAlertAction(title: "Send Audio", style: .default, handler: { (_) in
            let vc = AudioViewController()
            vc.handlerForFileURL = { fileURL in
                self.send(message: IMAudioMessage(filePath: fileURL.path, format: "m4a"))
            }
            self.navigationController?.pushViewController(vc, animated: true)
        })
    }
    
    var sendLocationAlertAction: UIAlertAction {
        return UIAlertAction(title: "Send Location", style: .default, handler: { (_) in
            self.activityToggle()
            LocationManager.requestLocation(completion: { [weak self] (result) in
                self?.activityToggle()
                switch result {
                case .success(let location):
                    let message = IMLocationMessage(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    self?.send(message: message)
                case .failure(let error):
                    UIAlertController.show(error: error, controller: self)
                }
            })
        })
    }
    
    var sendFileAlertAction: UIAlertAction {
        return UIAlertAction(title: "Send File", style: .default, handler: { (_) in
            let vc = FileViewController()
            vc.handlerForData = { [weak self] data in
                self?.send(message: IMFileMessage(data: data, format: "txt"))
            }
            self.navigationController?.pushViewController(vc, animated: true)
        })
    }
    
}

// MARK: Message Query

extension MessageListViewController {
    
    func queryMessageHistory(isFirst: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
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
                policy: isFirst ? .onlyNetwork : .default)
            { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                switch result {
                case .success(value: let messageResults):
                    if isFirst {
                        self.conversation.read()
                        if messageResults.isEmpty {
                            self.send(message: IMTextMessage(text: "Hello."))
                        }
                    }
                    if !messageResults.isEmpty {
                        mainQueueExecuting {
                            let isOriginMessageEmpty = self.messages.isEmpty
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
                            self.tableView.reloadData()
                            self.tableView.scrollToRow(
                                at: IndexPath(row: messageResults.count - 1, section: 0),
                                at: isOriginMessageEmpty ? .bottom : .top,
                                animated: false
                            )
                        }
                    }
                    completion(.success(true))
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                    completion(.failure(error))
                }
            }
        } catch {
            UIAlertController.show(error: error, controller: self)
            completion(.failure(error))
        }
    }
    
    func refreshMessageList() {
        do {
            self.activityToggle()
            try self.conversation.queryMessage(policy: .onlyNetwork) { [weak self] (result) in
                Client.specificAssertion
                guard let self = self else {
                    return
                }
                self.activityToggle()
                switch result {
                case .success(value: let messages):
                    guard !messages.isEmpty else {
                        return
                    }
                    self.conversation.read()
                    mainQueueExecuting {
                        self.messages = messages
                        self.tableView.reloadData()
                        self.tableView.scrollToRow(
                            at: IndexPath(row: self.messages.count - 1, section: 0),
                            at: .bottom,
                            animated: true
                        )
                    }
                case .failure(error: let error):
                    UIAlertController.show(error: error, controller: self)
                }
            }
        } catch {
            self.activityToggle()
            UIAlertController.show(error: error, controller: self)
        }
    }
    
}

// MARK: Table View Delegate

extension MessageListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let message = self.messages[indexPath.row]
        switch message {
        case let textMessage as IMTextMessage:
            let textCell = tableView.dequeueReusableCell(withIdentifier: "\(TextMessageCell.self)") as! TextMessageCell
            textCell.update(with: textMessage)
            cell = textCell
        case let imageMessage as IMImageMessage:
            let imageCell = tableView.dequeueReusableCell(withIdentifier: "\(ImageMessageCell.self)") as! ImageMessageCell
            imageCell.update(with: imageMessage)
            cell = imageCell
        case let audioMessage as IMAudioMessage:
            let audioCell = tableView.dequeueReusableCell(withIdentifier: "\(MediaMessageCell.self)") as! MediaMessageCell
            audioCell.update(with: audioMessage)
            audioCell.handlerForURL = { [weak self] url in
                let vc = AudioViewController()
                vc.fileURL = url
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            cell = audioCell
        case let videoMessage as IMVideoMessage:
            let videoCell = tableView.dequeueReusableCell(withIdentifier: "\(MediaMessageCell.self)") as! MediaMessageCell
            videoCell.update(with: videoMessage)
            videoCell.handlerForURL = { [weak self] url in
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self?.present(playerViewController, animated: true) {
                    player.play()
                }
            }
            cell = videoCell
        case let fileMessage as IMFileMessage:
            let fileCell = tableView.dequeueReusableCell(withIdentifier: "\(MediaMessageCell.self)") as! MediaMessageCell
            fileCell.update(with: fileMessage)
            fileCell.handlerForURL = { [weak self] url in
                let vc = FileViewController()
                vc.url = url
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            cell = fileCell
        case let locationMessage as IMLocationMessage:
            let locationCell = tableView.dequeueReusableCell(withIdentifier: "\(TextMessageCell.self)") as! TextMessageCell
            locationCell.update(with: locationMessage)
            cell = locationCell
        case is IMRecalledMessage:
            let recalledCell = tableView.dequeueReusableCell(withIdentifier: "\(RecalledMessageCell.self)") as! RecalledMessageCell
            recalledCell.update(with: message as! IMRecalledMessage)
            cell = recalledCell
        default:
            fatalError()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let recall = UITableViewRowAction(style: .destructive, title: "Recall") { (action, indexPath) in
            let recallingMessage = self.messages[indexPath.row]
            do {
                self.activityToggle()
                try self.conversation.recall(message: recallingMessage, completion: { [weak self] (result) in
                    Client.specificAssertion
                    guard let self = self else {
                        return
                    }
                    self.activityToggle()
                    switch result {
                    case .success(value: let recalledMessage):
                        mainQueueExecuting {
                            self.messages[indexPath.row] = recalledMessage
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    case .failure(error: let error):
                        UIAlertController.show(error: error, controller: self)
                    }
                })
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
            let message = self.messages[indexPath.row]
            guard let updatingMessage = message as? IMTextMessage else {
                UIAlertController.show(error: "only text can be edited", controller: self)
                return
            }
            let vc = TextEditViewController()
            vc.text = updatingMessage.text
            vc.handlerForEditedText = { editedText in
                do {
                    self.activityToggle()
                    let updatedMessage = IMTextMessage(text: editedText)
                    try self.conversation.update(oldMessage: updatingMessage, to: updatedMessage, completion: { [weak self] (result) in
                        Client.specificAssertion
                        guard let self = self else {
                            return
                        }
                        self.activityToggle()
                        switch result {
                        case .success:
                            mainQueueExecuting {
                                self.messages[indexPath.row] = updatedMessage
                                tableView.reloadRows(at: [indexPath], with: .automatic)
                            }
                        case .failure(error: let error):
                            UIAlertController.show(error: error, controller: self)
                        }
                    })
                } catch {
                    UIAlertController.show(error: error, controller: self)
                }
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        return [recall, edit]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let message = self.messages[indexPath.row]
        return (message.ioType == .out) && (type(of: message) != IMRecalledMessage.self)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.inputViewTextField.resignFirstResponder()
    }
    
}

// MARK: Text Field Delegate

extension MessageListViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .send {
            if let text = textField.text, !text.isEmpty {
                self.send(message: IMTextMessage(text: text))
                textField.text = nil
            }
            return true
        }
        return false
    }
    
}

// MARK: Image Picker Controller Delegate

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
            if let message = message {
                self.send(message: message)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
