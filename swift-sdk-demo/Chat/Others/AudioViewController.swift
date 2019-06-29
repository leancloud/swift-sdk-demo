//
//  AudioViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/14.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class AudioViewController: UIViewController {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var audioButton: UIButton!
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVPlayer?
    var audioPlayerDidPlayToEndObserver: NSObjectProtocol?
    
    var fileURL: URL?
    var handlerForFileURL: ((URL) -> Void)?
    
    var timer: Timer?
    var seconds: Float = 0
    
    let buttonTitles: (start: String, stop: String, end: String, play: String, reset: String) = (
        start: "🔴",
        stop: "⬛️",
        end: "⚫️",
        play: "▶️",
        reset: "⏹"
    )
    
    deinit {
        self.audioRecorder?.stop()
        self.audioPlayer?.pause()
        if let observer = self.audioPlayerDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.timer?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Audio"
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            UIAlertController.show(error: error, controller: self)
        }
        
        if let _ = self.handlerForFileURL {
            self.timeLabel.text = "\(self.seconds)s"
            self.timeLabel.isHidden = false
            self.audioButton.setTitle(self.buttonTitles.start, for: .normal)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(type(of: self).done)
            )
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else if let url = self.fileURL {
            self.timeLabel.isHidden = true
            self.audioButton.setTitle(self.buttonTitles.play, for: .normal)
            self.audioPlayer = AVPlayer(url: url)
            self.audioPlayerDidPlayToEndObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name.AVPlayerItemDidPlayToEndTime,
                object: nil,
                queue: .main)
            { [weak self] (_) in
                guard let self = self else {
                    return
                }
                self.audioButton.setTitle(self.buttonTitles.play, for: .normal)
                self.audioPlayer?.seek(to: .zero)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let notGranted: () -> Void = {
            UIAlertController.show(error: "Microphone Permission not Granted", controller: self)
        }
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                if !granted {
                    notGranted()
                }
                mainQueueExecuting {
                    self.audioButton.isEnabled = granted
                }
            }
        case .denied:
            notGranted()
            mainQueueExecuting {
                self.audioButton.isEnabled = false
            }
        default:
            break
        }
    }
    
    @IBAction func audioAction(_ sender: UIButton) {
        let title = self.audioButton.titleLabel?.text
        
        if title == self.buttonTitles.start {
            self.audioButton.setTitle(self.buttonTitles.stop, for: .normal)
            
            let tempfileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            self.fileURL = tempfileURL
            
            do {
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 12000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                self.audioRecorder = try AVAudioRecorder(url: tempfileURL, settings: settings)
                self.audioRecorder?.delegate = self
                self.audioRecorder?.record()
                
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (_) in
                    guard let self = self else {
                        return
                    }
                    self.seconds += 1
                    self.timeLabel.text = "\(self.seconds)s"
                })
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        } else if title == self.buttonTitles.stop {
            self.audioButton.setTitle(self.buttonTitles.end, for: .normal)
            self.audioRecorder?.stop()
            self.audioRecorder = nil
            self.timer?.invalidate()
            self.timer = nil
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else if title == self.buttonTitles.play {
            self.audioButton.setTitle(self.buttonTitles.reset, for: .normal)
            self.audioPlayer?.play()
        } else if title == self.buttonTitles.reset {
            self.audioButton.setTitle(self.buttonTitles.play, for: .normal)
            self.audioPlayer?.pause()
            self.audioPlayer?.seek(to: .zero)
        }
    }
    
    @objc func done() {
        if let fileURL = self.fileURL {
            self.handlerForFileURL?(fileURL)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension AudioViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            UIAlertController.show(error: "recorder not success", controller: self)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        UIAlertController.show(error: "recorder not success", controller: self)
    }
    
}
