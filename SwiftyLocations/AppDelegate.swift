//
//  AppDelegate.swift
//  SwiftyLocations
//
//  Created by Basem Emara on 3/6/17.
//  Copyright © 2017 Zamzam Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Global location manager
    static var locationManager: LocationManager = {
        return $0
    }(LocationManager())
    
}

