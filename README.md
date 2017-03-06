# SwiftyLocations
A closure-based wrapper for CLLocationManager to provide observable locations, instead of using delegates: https://basememara.com/swifty-locations-observables

## Usage

### Location updates
Instead of delegates to listen to location or authorization updates, subscribe to events:
```
class ViewController: UIViewController {
    
    lazy var locationManager: LocationManager = {
        return $0
    }(LocationManager())
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        locationManager.requestAuthorization {
            print("request authorization: \($0)")
        }
 
        locationManager.requestLocation {
            print("request location: \($0)")
        }
        
        locationManager.didUpdateLocations += {
            print("subscribe location from viewDidLoad: \($0)")
        }
    }
}
```

### Request authorization
After adding the necessary `Info.plist` privacy entries, call `requestAuthorization` with a closure:
```
locationManager.requestAuthorization(for: .whenInUse, startUpdating: true) {
    // Presents OS dialog to user if applicable
    // Then start location updates when authorized
 
    guard !$0 else { return }
    // Present alert to route user to app settings if needed
}
```
A few things come into play with this extended `requestAuthorization` function:

* The permission type needed is handled by an enum parameter: `requestAuthorization(for: .whenInUse)`. This way, calling `requestWhenInUseAuthorization` or `requestAlwaysAuthorization` is abstracted away.
* The `startUpdating` boolean parameter automatically starts the location update services after authorization is offered to the user. It is queued up in the `didChangeAuthorization` when needed to ensure it is called after authorization has been given.
* If the required authorization is already given, everything is ignored and start updates occur if specified.
* If the authorization is already given, but is not the authorization requested, it will start updates immediately since this can still occur, but will return false in the callback to specify the requested authorization is not given.
* If the authorization is denied, it will queue up start updates for later execution.

### Singleton manager
Many times, a single `CoreLocation` manager is needed for your entire app. This helps in conserving power and simplifying data flow. For this reason, the following pattern was created. In the `AppDelegate`, we add the lazy / static location manager:
```
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Global location manager
    static var locationManager: LocationManager = {
        return $0
    }(LocationManager())
    
}
```
With this global location manager in place and lazily loaded, view controllers can reference the location manager like this:
```
class LocationController: UIViewController {
    
    var locationManager: LocationManager {
        return AppDelegate.locationManager
    }

    ...
}
```
## Author

Zamzam Inc., contact@zamzam.io

## License

SwiftyLocations is available under the MIT license. See the LICENSE file for more info.