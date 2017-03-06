//
//  LocationManager.swift
//  DelegateClosureConversion
//
//  Created by Basem Emara on 3/2/17.
//  Copyright © 2017 Basem Emara. All rights reserved.
//

import CoreLocation

public class LocationManager: NSObject, CLLocationManagerDelegate {

    /// Internal Core Location manager
    fileprivate lazy var manager: CLLocationManager = {
        $0.delegate = self
        if let value = self.desiredAccuracy { $0.desiredAccuracy = value }
        if let value = self.distanceFilter { $0.distanceFilter = value }
        
        #if os(iOS)
            if let value = self.allowsBackgroundUpdates {
                $0.allowsBackgroundLocationUpdates = value
            }
        #endif
        
        return $0
    }(CLLocationManager())
    
    /// Default location manager options
    fileprivate let desiredAccuracy: CLLocationAccuracy?
    fileprivate let distanceFilter: Double?
    fileprivate let allowsBackgroundUpdates: Bool?
    
    public init(
        desiredAccuracy: CLLocationAccuracy? = nil,
        distanceFilter: Double? = nil,
        allowsBackgroundUpdates: Bool? = nil) {
            // Assign values to location manager options
            self.desiredAccuracy = desiredAccuracy
            self.distanceFilter = distanceFilter
            self.allowsBackgroundUpdates = allowsBackgroundUpdates
        
            super.init()
    }
    
    /// Subscribes to receive new location data when available.
    public var didUpdateLocations = SynchronizedArray<LocationHandler>()
    fileprivate var didUpdateLocationsSingle = SynchronizedArray<LocationHandler>()
    
    /// Subscribes to receive new authorization data when available.
    public var didChangeAuthorization = SynchronizedArray<AuthorizationHandler>()
    fileprivate var didChangeAuthorizationSingle = SynchronizedArray<AuthorizationHandler>()
}

// MARK: - Nested types
public extension LocationManager {

    /// Location handler queue type.
    typealias LocationHandler = (CLLocation) -> Void
    
    // Authorization handler queue type.
    typealias AuthorizationHandler = (Bool) -> Void
    
    /// Permission types to use location services.
    ///
    /// - whenInUse: While the app is in the foreground.
    /// - always: Whenever the app is running.
    enum AuthorizationType {
        case whenInUse, always
    }
}

// CLLocationManagerDelegate functions
public extension LocationManager {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Trigger and empty queues
        didUpdateLocations.forEach { $0(location) }
        didUpdateLocationsSingle.removeAll { $0.forEach { $0(location) } }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        
        // Trigger and empty queues
        didChangeAuthorization.forEach { $0(isAuthorized) }
        didChangeAuthorizationSingle.removeAll { $0.forEach { $0(self.isAuthorized) } }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: Injectable logger
        debugPrint(error)
    }
}

// MARK: - CLLocationManager wrappers
public extension LocationManager {

    /// A Boolean value indicating whether the app wants to receive location updates when suspended.
    var allowsBackgroundLocationUpdates: Bool {
        get { return manager.allowsBackgroundLocationUpdates }
        set { manager.allowsBackgroundLocationUpdates = newValue }
    }
    
    /// Determines if location services is enabled and authorized for always or when in use.
    var isAuthorized: Bool {
        return CLLocationManager.locationServicesEnabled()
            && [.authorizedAlways, .authorizedWhenInUse].contains(
                CLLocationManager.authorizationStatus())
    }
    
    /// Determines if location services is enabled and authorized for the specified authorization type.
    func isAuthorized(for type: AuthorizationType) -> Bool {
        guard CLLocationManager.locationServicesEnabled() else { return false }
        return (type == .whenInUse && CLLocationManager.authorizationStatus() == .authorizedWhenInUse)
            || (type == .always && CLLocationManager.authorizationStatus() == .authorizedAlways)
    }
    
    /// Starts the generation of updates that report the user’s current location.
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    /// Stops the generation of location updates.
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
}

// MARK: - Single requests
public extension LocationManager {
    
    /// Requests permission to use location services.
    ///
    /// - Parameters:
    ///   - type: Type of permission required, whether in the foreground (.whenInUse) or while running (.always).
    ///   - startUpdating: Starts the generation of updates that report the user’s current location.
    ///   - completion: True if the authorization succeeded for the authorization type, false otherwise.
    func requestAuthorization(for type: AuthorizationType = .whenInUse, startUpdating: Bool = false, completion: AuthorizationHandler? = nil) {
        // Handle authorized and exit
        guard !isAuthorized(for: type) else {
            if startUpdating { self.startUpdating() }
            completion?(true)
            return
        }
        
        // Request appropiate authorization before exit
        defer {
            switch type {
            case .whenInUse: manager.requestWhenInUseAuthorization()
            case .always: manager.requestAlwaysAuthorization()
            }
        }
        
        // Handle mismatched allowed and exit
        guard !isAuthorized else {
            if startUpdating { self.startUpdating() }
            
            // Process callback in case authorization dialog not launched by OS
            // since user will be notified first time only and inored subsequently
            completion?(false)
            return
        }
        
        if startUpdating {
            didChangeAuthorizationSingle += { _ in self.startUpdating() }
        }
        
        // Handle denied and exit
        guard CLLocationManager.authorizationStatus() == .notDetermined
            else { completion?(false); return }
        
        if let completion = completion {
            didChangeAuthorizationSingle += completion
        }
    }
    
    /// Request the one-time delivery of the user’s current location.
    ///
    /// - Parameter completion: The completion with the location object.
    func requestLocation(completion: @escaping LocationHandler) {
        didUpdateLocationsSingle += completion
        manager.requestLocation()
    }
}

#if os(iOS)
import UIKit

public extension LocationManager {

    /// Presents alert for notifying use to update location settings.
    ///
    /// - Parameters:
    ///   - controller: Controller to present from.
    ///   - title: Title of the alert.
    ///   - message: Message of the alert.
    ///   - buttonText: Settings button label text.
    ///   - cancelText: Cancel button label text.
    static func authorizationAlert(for controller: UIViewController?,
        title: String = "Allow access to your location while you use the app?",
        message: String = "Enable authorization from settings.",
        buttonText: String = "Settings",
        cancelText: String = "Cancel") {
            guard let controller = controller else { return }
        
            // Contruct alert and associated actions
            let alertController: UIAlertController = {
                $0.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: nil))
                $0.addAction(UIAlertAction(title: buttonText, style: .default) { _ in
                    guard let settings = URL(string: UIApplicationOpenSettingsURLString) else { return }
                    UIApplication.shared.open(settings)
                })
                return $0
            }(UIAlertController(title: title, message: message, preferredStyle: .alert))
        
            // Display alert to user
            controller.present(alertController, animated: true, completion: nil)
    }
}
#endif
