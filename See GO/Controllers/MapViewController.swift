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
// MARK: Properties
    
    // Google Maps
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var zoomLevel: Float = 19.0
    
    // Firebase
    var ref: DatabaseReference!
    
    // Others
    var userLocation: CLLocation?
    var showStoryKey: String = ""
    
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
    

    //MARK: View
    override func viewWillAppear(_ animated: Bool) {
        loadUserInfoGroup.enter()
        DispatchQueue.main.async {
            handle = Auth.auth().addStateDidChangeListener { (auth, user) in
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
        searchController.searchBar.scopeButtonTitles = ["Unread", "Today", "Hashtag", "My Squawks"]
        searchController.searchBar.delegate = self
        
    }

    func checkIfRead (untestedStoryKey: String) -> Bool {
        var isRead: Bool = false
        self.ref.child("users").child(self.uid).child("ReadStories").observeSingleEvent(of: .value, with: { (snapshot) in
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
                        if timediff<86400000 {
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
                
                // remove markers for read ones
                
                /*
                 self.loadUserInfoGroup.notify(queue: .main){
                 if !self.checkIfRead(untestedStoryKey: untestedStoryKey){
                 // story is unread
                 storyKey = untestedStoryKey
                 self.addMarker(latitude: latitude, longitude: longitude, storyKey: storyKey)
                 } else {
                 print("story is read")
                 print("incase i break too early")
                 }
                 }*/
                
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
    
}

// MARK: Map Delegate to handle events for Google Map View
extension MapViewController: GMSMapViewDelegate {
    
    func addMarker(latitude: String, longitude: String, storyKey: String){
        let marker = GMSMarker()
        let storyLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
        marker.position = CLLocationCoordinate2D(latitude: Double(latitude)!, longitude: Double(longitude)!)
        marker.map = self.mapView
        
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
        marker.userData = ["key": storyKey, "near": isNear]
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
        if near1 {
            showStoryKey = key1 as! String
            self .performSegue(withIdentifier: "ShowStoryTableSegue", sender: self)
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
        
        mapView.clear()
        
        //Read location coordinates from Firebase + add markers onto map
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
                //var untestedStoryKey: String = "" // originally for checking unread immediately
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
                        self.addMarker(latitude: latitude, longitude: longitude, storyKey: storyKey)
                        
                        
                    }
                }
            }
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
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        mapView.clear()
        searchController.searchBar.placeholder = "Discover Squawks"
        // TO-DO: refresh map i guess?
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

