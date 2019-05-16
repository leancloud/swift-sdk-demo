//
//  LocationManager.swift
//  Chat
//
//  Created by ZapCannon87 on 2019/5/16.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject {
    
    static let shared: LocationManager = LocationManager()
    
    let manager = CLLocationManager()
    
    var requestLocationCompletions: [((Result<CLLocation, Error>) -> Void)] = []
    
    private override init() {
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        mainQueueExecuting {
            self.requestLocationCompletions.append(completion)
            self.manager.requestLocation()
        }
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mainQueueExecuting {
            if let location = locations.first {
                self.requestLocationCompletions.forEach({ (completion) in
                    completion(.success(location))
                })
                self.requestLocationCompletions.removeAll()
            } else {
                self.requestLocationCompletions.removeAll()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.requestLocationCompletions.forEach({ (completion) in
            completion(.failure(error))
        })
        self.requestLocationCompletions.removeAll()
    }
    
}
