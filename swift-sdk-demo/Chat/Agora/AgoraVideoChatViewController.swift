//
//  AgoraVideoChatViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/9/16.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import AgoraRtcEngineKit

class AgoraVideoChatViewController: UIViewController {
    
    @IBOutlet weak var remoteVideoView: UIView!
    @IBOutlet weak var remoteVideoPlaceholderImageView: UIImageView!
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var localVideoPlaceholderImageView: UIImageView!
    @IBOutlet weak var endVideoChatButton: UIButton!
    @IBOutlet weak var microphoneToggleButton: UIButton!
    @IBOutlet weak var cameraSwitchButton: UIButton!
    
    var channelID: String!
    var agoraKit: AgoraRtcEngineKit!
    
    @IBAction func endVideoChat(_ sender: UIButton) {
        self.agoraKit.leaveChannel { (_) in
            mainQueueExecuting {
                self.dismiss(animated: true, completion: nil)
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
    
    @IBAction func microphoneToggle(_ sender: UIButton) {
        sender.isSelected.toggle()
        self.agoraKit.muteLocalAudioStream(sender.isSelected)
    }
    
    @IBAction func cameraSwitch(_ sender: UIButton) {
        self.agoraKit.switchCamera()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(
            withAppId: "8fb5a6f39ef94136a03d766de9da6a89",
            delegate: self)
        
        self.agoraKit.enableVideo()
        self.agoraKit.setVideoEncoderConfiguration(
            AgoraVideoEncoderConfiguration(
                size: AgoraVideoDimension640x360,
                frameRate: .fps15,
                bitrate: AgoraVideoBitrateStandard,
                orientationMode: .adaptative))
        
        self.agoraKit.setupLocalVideo({
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = 0
            videoCanvas.view = self.localVideoView
            videoCanvas.renderMode = .hidden
            return videoCanvas
            }())
        
        self.agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        self.agoraKit.joinChannel(byToken: nil, channelId: self.channelID, info: nil, uid: 0) { (_, _, _) in
            mainQueueExecuting {
                self.localVideoPlaceholderImageView.isHidden = true
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
    }
    
}

extension AgoraVideoChatViewController: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        self.remoteVideoPlaceholderImageView.isHidden = true
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = self.remoteVideoView
        videoCanvas.renderMode = .hidden
        self.agoraKit.setupRemoteVideo(videoCanvas)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("\(type(of: self)): uid \(uid) did offline for reason code \(reason)")
        self.remoteVideoPlaceholderImageView.isHidden = false
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        print("\(type(of: self)): warning code \(warningCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("\(type(of: self)): error code \(errorCode)")
        self.endVideoChat(self.endVideoChatButton)
    }
    
}
