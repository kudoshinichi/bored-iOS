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
    
    func filterContentForSearchText(_ searchText: String, scope: String = "Unread") {
        
        var hashtagArray = [hashtagItem]()
        var storyKey: String = ""
        var hashtag: String = ""
        var latitude: String = ""
        var longitude: String = ""
        
        if searchBarIsEmpty() {
            if scope == "Today"{
                print("today")
                
                let timeInterval = NSDate().timeIntervalSince1970 * 1000
                print(timeInterval)
                mapView.clear()
                
                self.ref.child("stories").observe(.value, with: { snapshot in
                    for child in snapshot.children{
                        let snapshot1 = child as! DataSnapshot
                        let storytime = (snapshot1.value as? NSDictionary)?["Time"] as! Int
                        print("break")
                        let timediff = Int(timeInterval) - storytime
                        
                        // check if it's within 24h (i.e. 86 400 000 ms)
                        if timediff < 24 * 60 * 60 * 1000 {
                            let group = DispatchGroup()
                            group.enter()
                            DispatchQueue.main.async {
                                storyKey = snapshot1.key
                                print(storyKey)
                                let location = (snapshot1.value as? NSDictionary)?["Location"] as! String
                                let locationArray = location.split(separator:",")
                                latitude = String(locationArray[0])
                                longitude = String(locationArray[1])
                                group.leave()
                            }
                            group.notify(queue: .main) {
                                self.addMarker(latitude: latitude, longitude: longitude, storyKey: storyKey)
                            }
                        }
                    }
                })
                
            } else if scope == "Unread" {
                var location: String = ""
                
                // find read stories' location and see if it matches with markers' locations
                self.ref.child("users").child(self.uid).child("ReadStories").observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children{
                        let snapshot = child as! DataSnapshot
                        storyKey = snapshot.key as! String
                        
                        //location = snapshot.value as! String
                        //print(location)
                        
                        for marker in self.markerArray {
                            let data = marker.userData as! NSDictionary
                            let markerStoryKey = data["key"] as! String
                            if markerStoryKey == storyKey {
                                marker.map = nil
                                print(markerStoryKey)
                                print(storyKey)
                                print("single delete")
                            } else if markerStoryKey.contains(","){
                                print(markerStoryKey)
                                
                                let stories = markerStoryKey.split(separator: ",")
                                var boolsArray = [Bool]()
                                
                                // break into stories
                                // check if each story is read
                                // if all stories in the same location is read, delete the marker
                                
                                //TO-DO: RAWR HERE.. doesn't work :( cuz I check this for each storyKey.. unless i declare the marker first.. like a whole new function just to plough through multiple squawk markers...?
                                
                                /*
                                for oneStory in stories {
                                    if self.checkIfRead(untestedStoryKey: String(oneStory)){
                                        // story is read
                                        boolsArray.append(true)
                                    } else {
                                        // story is unread
                                        boolsArray.append(false)
                                    }
                                    /*
                                    if oneStory == storyKey {
                                        print(oneStory)
                                        print(storyKey)
                                        // story is read
                                        boolsArray.append(true)
                                    } else {
                                        boolsArray.append(false)
                                    }*/
                                }
                                print(boolsArray)
                                
                                if !boolsArray.contains(false){
                                    print("MULT")
                                    // all stories are read
                                    marker.map = nil
                                }*/
                            }
                            
                            
                            /*let markerLocation = data["location"] as! String
                            
                            if markerLocation == location {
                                print("is read")
                                print(markerLocation)
                                
                                marker.map = nil
                            } else {
                                print("break")
                            }*/
                        }
                        
                        // get userData to see if it contains multiple story (i.e. storyKey contains ",")
                        // if not just delete
                        // else split the string and check if read each of them if at least one is not read, just keep marker
                    }
                })
                
                print("unread")
                
            } else if scope == "My Squawks" {
                print("mine")
                
            }
        } else {
            if scope == "Hashtag" {
            
                // find hashtag info from database
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.main.async {
                    self.ref.child("hashtags").observe(.value, with: { snapshot in
                        // gets hashtag, relevant storyKeys and locations
                        for child in snapshot.children{
                            let hashtagSnap = child as! DataSnapshot
                            hashtag = hashtagSnap.key
                            for grandchild in (child as AnyObject).children{
                                let grandchild = grandchild as! DataSnapshot
                                let location = grandchild.value as! String
                                let locationArray = location.split(separator:",")
                                latitude = String(locationArray[0])
                                longitude = String(locationArray[1])
                                storyKey = grandchild.key
                            }
                            hashtagArray.append(hashtagItem(hashtag: hashtag, latitude: latitude, longitude: longitude, storyKey: storyKey))
                        }
                        group.leave()
                    })
                }
                
                group.notify(queue: .main) {
                    print("after database")
                    self.filteredSquawks = hashtagArray.filter({( hashtag : hashtagItem) -> Bool in
                        return hashtag.hashtag.lowercased().contains(searchText.lowercased())
                    })
                    print(self.filteredSquawks)
                    self.mapFilterSquawks()
                }
                
            } else {
                searchController.searchBar.text = nil
                searchController.searchBar.placeholder = "Please select Hashtag tab."
            }
        }
        
    }
    
    func filterStoriesByScope() -> [String: [StoryMeta]] {
        if currentScope != Scope.Hashtag {
            searchController.searchBar.text = nil
            searchController.searchBar.placeholder = "Use search bar in Hashtag tab."
            hashtagSearchText = ""
        }
        switch currentScope! {
            // TODO(???): Complete implementation
            case Scope.All:
                return storiesByLocation
            case Scope.Unread:
                let timeInterval = NSDate().timeIntervalSince1970 * 1000
                print(timeInterval)
                self.ref.child("stories").observe(.value, with: { snapshot in
                    return self.storiesByLocation
                })
                return storiesByLocation
            case Scope.Today:
                var a: [String: [StoryMeta]] = [:]
                return a
                //return storiesByLocation
            case Scope.Hashtag:
                return storiesByLocation
            case Scope.Mine:
                return storiesByLocation
        }
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
        print(String(distanceMetres))
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
        print(key1)
        print(near1)
        
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
            print(metas[0].longitude)
            print(metas[0].latitude)
            print(storyKey)
            self.addMarker(latitude: metas[0].latitude, longitude: metas[0].longitude, storyKey: storyKey)
        }
    }
    
    func shy() {
        //Read location coordinates from Firebase + add markers onto map
        mapView.clear()
        ref.child("locations").observe(.value, with: { snapshot in
            for child in snapshot.children{
                let valueD = child as! DataSnapshot
                let keyD = valueD.key // location with "d"
                let key = keyD.replacingOccurrences(of: "d", with: ".") // location with "."
                let locationArray = key.split(separator:",") // splits location into longitude and latitude
                let latitude: String = String(locationArray[0])
                let longitude: String = String(locationArray[1])
                let count = valueD.childrenCount // gets number of stories here
                //print(String(count) + " stories")
                
                var storyKeyArray: [String] = []
                var storyKey: String = ""
                
                // get storyKey(s)
                for grandchild in (child as AnyObject).children{
                    let valueD = grandchild as! DataSnapshot
                    
                    if count == 1 {
                        storyKey = valueD.key
                        
                    } else {
                        // join storykeys into more than one
                        
                        storyKeyArray.append(valueD.key)
                        let string = storyKeyArray.joined(separator: ",")
                        storyKey = string
                        
                    }
                }
                self.addMarker(latitude: latitude, longitude: longitude, storyKey: storyKey)
            }
        })
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
            print(self.storiesByLocation.count)
            self.drawSquawks(filteredStoriesByLocation: self.filterStoriesByScope())
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
        drawSquawks(filteredStoriesByLocation: filterStoriesByScope()) // Comment this and uncomment below to revert old behaviour
        //filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        mapView.clear()
        searchController.searchBar.placeholder = "Discover Squawks"
        // TO-DO: refresh map i guess?
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        currentScope = Scope(rawValue: searchBar.scopeButtonTitles![selectedScope])
        hashtagSearchText = searchBar.text!
        drawSquawks(filteredStoriesByLocation: filterStoriesByScope()) // Comment this and uncomment below to revert old behaviour
        //filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

