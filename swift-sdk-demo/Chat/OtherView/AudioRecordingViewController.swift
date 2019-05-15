//
//  AudioRecordingViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/14.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class AudioRecordingViewController: UIViewController {
    
    var handlerForAudioFileURL: ((URL) -> Void)?
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    @IBOutlet weak var audioDurationLabel: UILabel!
    @IBOutlet weak var audioRecordingButton: UIButton!
    @IBOutlet weak var audioRecordClearButton: UIButton!
    @IBOutlet weak var audioPlayingButton: UIButton!
    @IBOutlet weak var audioClearButton: UIButton!
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.audioRecorder?.stop()
        self.audioPlayer?.stop()
        self.dismiss(animated: true)
    }
    
    @IBAction func doneAction(_ sender: UIButton) {
        guard let audioFileURL = self.audioRecorder?.url else {
            let alert = UIAlertController(
                title: "Error",
                message: "Not get audio file URL",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
            return
        }
        self.audioRecorder?.stop()
        self.audioPlayer?.stop()
        self.handlerForAudioFileURL?(audioFileURL)
        self.dismiss(animated: true)
    }
    
    @IBAction func recordingAction(_ sender: UIButton) {
        if let recorder = self.audioRecorder {
            let interval = recorder.currentTime
            recorder.stop()
            
            self.audioDurationLabel.text = "\(interval)s"
            self.audioRecordingButton.setTitle("Recording Done", for: .disabled)
            self.audioRecordingButton.isEnabled = false
            self.audioPlayingButton.setTitle("Play Record", for: .normal)
            self.audioPlayingButton.isEnabled = true
        } else {
            let audioFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
            do {
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 8000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
                ]
                let recorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
                recorder.delegate = self
                self.audioRecorder = recorder
                recorder.record()
            
                self.audioDurationLabel.text = "In Recording"
                self.audioRecordingButton.setTitle("Stop Recording", for: .normal)
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }
    }
    
    @IBAction func playingAction(_ sender: UIButton) {
        if let player = self.audioPlayer {
            player.stop()
            self.audioPlayer = nil
            
            self.audioPlayingButton.setTitle("Play Record", for: .normal)
        } else {
            do {
                let player = try AVAudioPlayer(contentsOf: self.audioRecorder!.url)
                player.delegate = self
                self.audioPlayer = player
                player.play()
                
                self.audioPlayingButton.setTitle("Stop Playing", for: .normal)
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }
    }
    
    @IBAction func clearRecordAction(_ sender: UIButton) {
        self.audioRecorder?.stop()
        self.audioRecorder = nil
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        
        self.audioDurationLabel.text = "-"
        self.audioRecordingButton.setTitle("Start Recording", for: .normal)
        self.audioRecordingButton.isEnabled = true
        self.audioPlayingButton.setTitle("Play Record", for: .disabled)
        self.audioPlayingButton.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            fatalError("\(error)")
        }
        
        self.view.isUserInteractionEnabled = false
        self.clearRecordAction(self.audioClearButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                mainQueueExecuting {
                    self.view.isUserInteractionEnabled = true
                    guard granted else {
                        self.showPermissionNotGrantedAlert()
                        return
                    }
                }
            }
        case .denied:
            self.showPermissionNotGrantedAlert()
        default:
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func showPermissionNotGrantedAlert() {
        let alert = UIAlertController(
            title: "Microphone Permission not Granted",
            message: "this View Controller will be dismiss",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true)
    }
    
}

extension AudioRecordingViewController: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            mainQueueExecuting {
                self.clearRecordAction(self.audioClearButton)
                UIAlertController.show(error: error, controller: self)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag, self.audioPlayingButton.isEnabled {
           self.audioPlayingButton.setTitle("Play Record", for: .normal)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            mainQueueExecuting {
                self.clearRecordAction(self.audioClearButton)
                UIAlertController.show(error: error, controller: self)
            }
        }
    }
    
}
