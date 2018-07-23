//
//  MapViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 5/6/18.
//
// Subsequent TO-DO:
// 3. Multiple stories * (uhm keywords don't get seeen)
// [6. Users (reddit and stackoverflow, voting & read system)
// 2. Marker Aesthetic
// 8. Hashtag from story upload
// 9. Discovery syste: √Hasthtag search, √Today, My Squawks
// 9.1 Search footer (tbc)
// 10. Search bar idk overall theme hmm

import UIKit
import GoogleMaps
import Firebase
import FirebaseDatabase

class MapViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?
// MARK: Properties
    
    // Google Maps
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var zoomLevel: Float = 19.0
    var markerArray = [GMSMarker]()
    
    // Firebase
    var ref: DatabaseReference!
    
    // Others
    var userLocation: CLLocation?
    
    // To pass variables to showStory
    var showStoryKey: String = ""
    var showStoryLocation: String = ""
    
    //search
    let searchController = UISearchController(searchResultsController: nil)
    struct hashtagItem {
        let hashtag: String
        let latitude: String
        let longitude: String
        let storyKey: String
    }
    var filteredSquawks = [hashtagItem]()
    
    //user info
    var loadUserInfoGroup = DispatchGroup()
    var uid: String = ""
    
    enum Scope :String {
        case All
        case Unread
        case Today
        case Hashtag
        case Mine
    }
    let ALL_SCOPES = [Scope.All.rawValue, Scope.Unread.rawValue, Scope.Today.rawValue, Scope.Hashtag.rawValue, Scope.Mine.rawValue]
    var currentScope: Scope!
    var hashtagSearchText: String!
    
    let MIN_LOCATION_UPDATE_DELAY_MILLIS = 5000
    var lastLocationUpdate: Int = 0
    
    struct StoryMeta {
        var longitude: String
        var latitude: String
        var id: String
    }
    var storiesByLocation: [String: [StoryMeta]] = [:]
    
    //MARK: View
    override func viewWillAppear(_ animated: Bool) {
        loadUserInfoGroup.enter()
        DispatchQueue.main.async {
            self.handle = Auth.auth().addStateDidChangeListener { (auth, user) in
                if let user = user {
                    // The user's ID, unique to the Firebase project.
                    // Do NOT use this value to authenticate with your backend server,
                    // if you have one. Use getTokenWithCompletion:completion: instead.
                    self.uid = user.uid
                    let email = user.email
                    
                    self.loadUserInfoGroup.leave()
                    print(self.uid)
                    print(email)
                } else {
                    print("user is signed out")
                }
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.bringSubview(toFront: SearchFooter()) // RAWR TO-DO, how to bring it above GMSMapView
        
        ref = Database.database().reference()
        
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        // A default location to use when location permission is not granted.
        let defaultLocation = CLLocation(latitude: 1.346313, longitude: 103.841332)
        
        self.view .layoutIfNeeded()
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.delegate = self
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true
        
        //searchController
        //searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Discover Squawks"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        // Setup the Scope Bar
        searchController.searchBar.scopeButtonTitles = ALL_SCOPES
        currentScope = Scope.All
        hashtagSearchText = ""
        searchController.searchBar.delegate = self
    }

    func checkIfRead (untestedStoryKey: String) -> Bool {
        var isRead: Bool = false
        self.ref.child("users").child(self.uid).child("ReadStories").observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            if !snapshot.hasChild(untestedStoryKey) {
                // story is unread
                isRead = false
            } else {
                print(untestedStoryKey)
                isRead = true
            }
        })
        return isRead
    }
    
    //MARK: Navigation
    // Unwind segue
    @IBAction func unwindToMainScreen(segue: UIStoryboardSegue) {
        print("Unwind segue to main screen triggered!")
    }

    // Before segue to showStory, set showStory storyKey variable
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        //if segue.destination is ShowStoryController
        if segue.destination is StoryTableViewController
        {
            //let vc = segue.destination as? ShowStoryController
            let vc = segue.destination as? StoryTableViewController
            vc?.storyKey = showStoryKey
            vc?.storyLocation = showStoryLocation
            vc?.uid = self.uid
        }
    }
    
    //MARK: Search
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterStoriesByScope() {
        if currentScope != Scope.Hashtag {
            searchController.searchBar.text = nil
            searchController.searchBar.placeholder = "Use search bar in Hashtag tab."
            hashtagSearchText = ""
        }
        switch currentScope! {
            case Scope.All:
               drawSquawks(filteredStoriesByLocation: storiesByLocation)
            case Scope.Unread:
                self.ref.child("users").child(self.uid).child("ReadStories").observe(.value, with: { snapshot in
                    var readStories: Set<String> = Set()
                    for child in snapshot.children {
                        let story = child as! DataSnapshot
                        readStories.insert(story.key)
                    }
                    self.drawSquawks(filteredStoriesByLocation: self.filterStoriesBy(
                        filter: { (meta: StoryMeta) -> Bool in
                            return !readStories.contains(meta.id)
                        }))
                })
            case Scope.Today:
                let earliestTime = Int(NSDate().timeIntervalSince1970 - 24 * 60 * 60) * 1000
                self.ref.child("stories").observe(.value, with: { snapshot in
                    self.drawSquawks(filteredStoriesByLocation: self.filterStoriesBy(
                        filter: { (meta: StoryMeta) -> Bool in
                            let story = snapshot.childSnapshot(forPath: meta.id) as! DataSnapshot
                            let storyTime = (story.value as? NSDictionary)?["Time"] as! Int
                            return storyTime >= earliestTime
                        }))
                })
            case Scope.Hashtag:
                if hashtagSearchText == "" {
                    drawSquawks(filteredStoriesByLocation: storiesByLocation)
                } else if hashtagSearchText.contains(".") ||
                          hashtagSearchText.contains("#") ||
                          hashtagSearchText.contains("$") ||
                          hashtagSearchText.contains("[") ||
                          hashtagSearchText.contains("]")  {
                    drawSquawks(filteredStoriesByLocation: [:])
                } else {
                    self.ref.child("hashtags").child(hashtagSearchText).observe(.value, with: { snapshot in
                        var hashtagStories: Set<String> = Set()
                        for child in snapshot.children {
                            let story = child as! DataSnapshot
                            hashtagStories.insert(story.key)
                        }
                        self.drawSquawks(filteredStoriesByLocation: self.filterStoriesBy(
                            filter: { (meta: StoryMeta) -> Bool in
                                return hashtagStories.contains(meta.id)
                            }))
                    })
                }
            case Scope.Mine:
                self.ref.child("users").child(self.uid).child("stories").observe(.value, with: { snapshot in
                    var writtenStories: Set<String> = Set()
                    for child in snapshot.children {
                        let story = child as! DataSnapshot
                        writtenStories.insert(story.key)
                    }
                    self.drawSquawks(filteredStoriesByLocation: self.filterStoriesBy(
                        filter: { (meta: StoryMeta) -> Bool in
                            return writtenStories.contains(meta.id)
                        }))
                })
        }
    }
    
    func filterStoriesBy(filter: (StoryMeta) -> Bool) -> [String:[StoryMeta]] {
        var filteredStoriesByLocation: [String:[StoryMeta]] = [:]
        for (loc, metas) in self.storiesByLocation {
            let filteredMetas: [StoryMeta] = metas.filter(filter)
            if filteredMetas.count > 0 {
                filteredStoriesByLocation[loc] = filteredMetas
            }
        }
        return filteredStoriesByLocation
    }
}

// MARK: Map Delegate to handle events for Google Map View
extension MapViewController: GMSMapViewDelegate {
    func addMarker(latitude: String, longitude: String, storyKey: String){
        let marker = GMSMarker()
        let storyLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
        marker.position = CLLocationCoordinate2D(latitude: Double(latitude)!, longitude: Double(longitude)!)
        marker.map = self.mapView
        markerArray.append(marker) //RAWR
        
        let distanceMetres = (self.userLocation?.distance(from: storyLocation))!
        var isNear: Bool
        var snipkeywords: String = ""
        
        if distanceMetres <= 500.0 {
            isNear = true
        } else {
            isNear = false
        }
        
        // Loads into userData
        marker.userData = ["key": storyKey, "near": isNear, "location": latitude + "," + longitude]
        let data = marker.userData as! NSDictionary
        let key1 = data["key"]
        let near1 = data["near"]
        
        if !isNear {
            marker.icon = GMSMarker.markerImage(with: .purple)
            
            if !storyKey.contains(",") {
                self.ref.child("stories").child(storyKey).observe(.value, with: { snapshot in
                    let keywords = (snapshot.value as? NSDictionary)?["Keywords"] as? String
                    if keywords == nil {
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk."
                    } else {
                        snipkeywords = keywords!
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, \"" + snipkeywords + "\"."
                    }
                })
            } else {
                marker.snippet = "In " + String(Int(distanceMetres)) + "m, there are multiple squawks."
            }
            
        } else {
            marker.icon = GMSMarker.markerImage(with: .green)
            
            if !storyKey.contains(",") {
                self.ref.child("stories").child(storyKey).observe(.value, with: { snapshot in
                    let keywords = (snapshot.value as? NSDictionary)?["Keywords"] as? String
                    if keywords == nil {
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk. Tap to open!"
                    } else {
                        snipkeywords = keywords!
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, \"" + snipkeywords + "\". Tap to open!"
                    }
                })
            } else {
                marker.snippet = "In " + String(Int(distanceMetres)) + "m, there are multiple squawks."
            }
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("You tapped the infowindow! :o")
        // gets storyKey of this marker
        let data = marker.userData as! NSDictionary
        let key1 = data["key"]
        let near1 = data["near"] as! Bool
        let location1 = data["location"]
        if near1 {
            showStoryKey = key1 as! String
            showStoryLocation = location1 as! String
            self.performSegue(withIdentifier: "ShowStoryTableSegue", sender: self)
        }
    }
    
    func mapFilterSquawks(){
        mapView.clear()
        for hashtagItem in filteredSquawks{
            addMarker(latitude: hashtagItem.latitude, longitude: hashtagItem.longitude, storyKey: hashtagItem.storyKey)
        }
    }
}

// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate {
    func drawSquawks(filteredStoriesByLocation: [String: [StoryMeta]]) {
        mapView.clear()
        for (key, metas) in filteredStoriesByLocation {
            var storyKeys: [String] = []
            for meta in metas {
                storyKeys.append(meta.id)
            }
            let storyKey = storyKeys.joined(separator: ",")
            self.addMarker(latitude: metas[0].latitude, longitude: metas[0].longitude, storyKey: storyKey)
        }
    }
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        userLocation = locations.last!
        
        let curTime = Int(NSDate().timeIntervalSince1970 * 1000)
        if curTime - lastLocationUpdate <= MIN_LOCATION_UPDATE_DELAY_MILLIS {
            return
        }
        
        lastLocationUpdate = curTime
        storiesByLocation = [:]
        ref.child("locations").observe(.value, with: { snapshot in
            for child in snapshot.children  {
                let valueD = child as! DataSnapshot
                let keyD = valueD.key // location with "d"
                let key = keyD.replacingOccurrences(of: "d", with: ".") // location with "."
                let locationArray = key.split(separator:",") // splits location into longitude and latitude
                let latitude: String = String(locationArray[0])
                let longitude: String = String(locationArray[1])
                self.storiesByLocation[key] = []
                for grandchild in (child as AnyObject).children {
                    let valueD = grandchild as! DataSnapshot
                    self.storiesByLocation[key]!.append(StoryMeta(longitude: longitude, latitude: latitude, id: valueD.key))
                }
            }
            self.filterStoriesByScope()
        })
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

// MARK: - UISearchBar Delegate
extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        currentScope = Scope(rawValue: searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex])
        hashtagSearchText = searchController.searchBar.text!
        filterStoriesByScope()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.placeholder = "Discover Squawks"
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        currentScope = Scope(rawValue: searchBar.scopeButtonTitles![selectedScope])
        hashtagSearchText = searchBar.text!
        filterStoriesByScope()
    }
}
