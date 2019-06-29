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
    
    static let current = CLLocationManager()
    
    static var requestLocationCompletions: [((Result<CLLocation, Error>) -> Void)] = []
    
    static let delegator: LocationManager = LocationManager()
    
    private override init() {
        super.init()
        LocationManager.current.delegate = self
        LocationManager.current.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    static func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        mainQueueExecuting {
            self.requestLocationCompletions.append(completion)
            self.current.requestLocation()
        }
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mainQueueExecuting {
            if let location = locations.first {
                LocationManager.requestLocationCompletions.forEach({ (completion) in
                    completion(.success(location))
                })
            }
            LocationManager.requestLocationCompletions.removeAll()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LocationManager.requestLocationCompletions.forEach({ (completion) in
            completion(.failure(error))
        })
        LocationManager.requestLocationCompletions.removeAll()
    }
    
}
