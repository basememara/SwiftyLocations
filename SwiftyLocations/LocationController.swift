//
//  ViewController.swift
//  DelegateClosureConversion
//
//  Created by Basem Emara on 3/1/17.
//  Copyright © 2017 Basem Emara. All rights reserved.
//

import UIKit
import CoreLocation

class LocationController: UIViewController {
    
    @IBOutlet weak var authorizationSegmentedControl: UISegmentedControl!
    @IBOutlet weak var resultLabel: UILabel!
    
    var locationManager: LocationManager {
        return AppDelegate.locationManager
    }
    
    var authorizationType: LocationManager.AuthorizationType {
        return authorizationSegmentedControl.selectedSegmentIndex == 0
            ? .whenInUse : .always
    }
    
    lazy var locationsObserver: LocationManager.LocationObservable = Observable { [weak self] in
        self?.resultLabel.text = "subscribe location from observer property: \($0)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.didUpdateLocations += locationsObserver
    }
    
    deinit {
        locationManager.didUpdateLocations -= locationsObserver
    }
    
    @IBAction func requestAuthorizationAndUpdateTapped(_ sender: Any) {
        locationManager.requestAuthorization(for: authorizationType, startUpdating: true) { [weak self] in
            self?.resultLabel.text = "request authorization and update: \($0)"
            
            guard !$0 else { return }
            LocationManager.authorizationAlert(for: self)
        }
    }
    
    @IBAction func requestAuthorizationTapped(_ sender: Any) {
        locationManager.requestAuthorization(for: authorizationType) { [weak self] in
            self?.resultLabel.text = "request authorization: \($0)"
            
            guard !$0 else { return }
            LocationManager.authorizationAlert(for: self)
        }
    }
    
    @IBAction func requestLocationTapped(_ sender: Any) {
        locationManager.requestLocation { [weak self] in
            self?.resultLabel.text = "request location: \($0)"
        }
    }
    
    @IBAction func subscribeAuthorizationTapped(_ sender: Any) {
        locationManager.didChangeAuthorization += Observable { [weak self] in
            self?.resultLabel.text = "subscribe authorization: \($0)"
        }
    }
    
    @IBAction func subscribeLocationTapped(_ sender: Any) {
        guard !locationManager.didUpdateLocations.contains(locationsObserver) else { return }
        locationManager.didUpdateLocations += locationsObserver
    }
    
    @IBAction func unsubscribeMonitorTapped(_ sender: Any) {
        locationManager.didChangeAuthorization.removeAll()
        locationManager.didUpdateLocations -= locationsObserver
        resultLabel.text = "Unsubscribed all"
    }
    
    @IBAction func startLocationTapped(_ sender: Any) {
        locationManager.startUpdating()
        resultLabel.text = "start updating"
    }
    
    @IBAction func stopLocationTapped(_ sender: Any) {
        locationManager.stopUpdating()
        resultLabel.text = "stop updating"
    }
}
