//
//  ViewController.swift
//  VoIP
//
//  Created by zapcannon87 on 2019/11/26.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import UIKit
import PushKit
import CallKit
import LeanCloud

class ViewController: UIViewController {
    
    var voipRegistry: PKPushRegistry?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerForVoIPPushes()
    }
    
    func registerForVoIPPushes() {
        self.voipRegistry = PKPushRegistry(queue: nil)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]
    }
}

extension ViewController: CXProviderDelegate {
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin")
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset")
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }
}

extension ViewController: PKPushRegistryDelegate {
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        AppDelegate.installationQueue.async {
            let voipInstallation = LCInstallation()
            if let apnsTopic = voipInstallation.apnsTopic?.value {
                voipInstallation.apnsTopic = LCString("\(apnsTopic).voip")
                voipInstallation.set(
                    deviceToken: pushCredentials.token,
                    apnsTeamId: "7J5XFNL99Q")
                let result = voipInstallation.save()
                if let error = result.error {
                    print(error)
                }
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("didInvalidatePushTokenFor: \(type)")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if type == .voIP {
            let config = CXProviderConfiguration(localizedName: "VoIP")
            config.includesCallsInRecents = false;
            config.supportsVideo = true;
            let provider = CXProvider(configuration: config)
            provider.setDelegate(self, queue: nil)
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(
                type: .generic,
                value: ((payload.dictionaryPayload["aps"] as? [String: Any])?["alert"] as? String)
                    ?? "hello world")
            update.hasVideo = true
            provider.reportNewIncomingCall(
                with: UUID(),
                update: update,
                completion: { error in
                    if let error = error {
                        print(error)
                    }
            })
        }
    }
}
