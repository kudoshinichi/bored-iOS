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
// 9. Discovery syste: √Hasthtag search, Today, Nearby (tbh a bit useless), My Squawks
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
    var keywords: String = ""
    var storyKey: String = ""
    var showStoryKey: String = ""
    var isNear: Bool = false
    var storyKeyArray: [String] = []
    
    //search
    let searchController = UISearchController(searchResultsController: nil)
    struct hashtagItem {
        let hashtag: String
        let latitude: String
        let longitude: String
        let storyKey: String
    }
    var filteredSquawks = [hashtagItem]()

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
        // Setup the Scope Bar/
        searchController.searchBar.scopeButtonTitles = ["Top", "Today", "Nearby", "My Squawks"]
        searchController.searchBar.delegate = self
        
    }
    
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
        }
    }
    
    //Search
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        
        // find hashtag info from database
        var hashtagArray = [hashtagItem]()
        var storyKey: String = ""
        var hashtag: String = ""
        var latitude: String = ""
        var longitude: String = ""
        
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
            // see if hashtag in search field exists in database
            print("after database")
            self.filteredSquawks = hashtagArray.filter({( hashtag : hashtagItem) -> Bool in
                return hashtag.hashtag.lowercased().contains(searchText.lowercased())
            })
            print(self.filteredSquawks)
            
            self.mapFilterSquawks()
            
            // there are various scopes
            
        }

        
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
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
        
        if distanceMetres <= 500.0 {
            self.isNear = true
        } else {
            self.isNear = false
        }
        
        // Loads into userData
        marker.userData = ["key": storyKey, "near": self.isNear]
        let data = marker.userData as! NSDictionary
        let key1 = data["key"]
        let near1 = data["near"]
        print(key1)
        print(near1)
        
        if !self.isNear {
            marker.icon = GMSMarker.markerImage(with: .purple)
            
            if !self.storyKey.contains(",") {
                self.ref.child("stories").child(storyKey).observe(.value, with: { snapshot in
                    let keywords = (snapshot.value as? NSDictionary)?["Keywords"] as? String
                    if keywords == nil {
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk."
                    } else {
                        self.keywords = keywords!
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, \"" + self.keywords + "\"."
                    }
                })
            } else {
                marker.snippet = "In " + String(Int(distanceMetres)) + "m, there are multiple squawks."
            }
            
        } else {
            marker.icon = GMSMarker.markerImage(with: .green)
            
            if !self.storyKey.contains(",") {
                self.ref.child("stories").child(storyKey).observe(.value, with: { snapshot in
                    let keywords = (snapshot.value as? NSDictionary)?["Keywords"] as? String
                    if keywords == nil {
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk. Tap to open!"
                    } else {
                        self.keywords = keywords!
                        marker.snippet = "In " + String(Int(distanceMetres)) + "m, \"" + self.keywords + "\". Tap to open!"
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
        if isFiltering(){
            // if hashtag exists in database, (clear map first) get location and story key so that can add marker
            mapView.clear()
            
            for hashtagItem in filteredSquawks{
                
                addMarker(latitude: hashtagItem.latitude, longitude: hashtagItem.longitude, storyKey: hashtagItem.storyKey)
            }
            
            // search footer
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
                let keyD = valueD.key
                let key = keyD.replacingOccurrences(of: "d", with: ".")
                let locationArray = key.split(separator:",")
                let latitude: String = String(locationArray[0])
                let longitude: String = String(locationArray[1])
                let count = valueD.childrenCount
                print(String(count) + " stories")
                
                self.storyKeyArray = []
                
                // get storyKey(s)
                for grandchild in (child as AnyObject).children{
                    let valueD = grandchild as! DataSnapshot
                    if count == 1 {
                        self.storyKey = valueD.key
                        //print(self.storyKey)
                    } else {
                        // join storykeys into more than one
                        
                        self.storyKeyArray.append(valueD.key)
                        let string = self.storyKeyArray.joined(separator: ",")
                        self.storyKey = string
                        // add indiv keys into srray
                        // add keys together with comma
                        //var array = [1,2,3]
                        //self.storyKey =
                    }
                }
                
                self.addMarker(latitude: latitude, longitude: longitude, storyKey: self.storyKey)
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

/*extension MapViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)

    }
}*/

extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        mapView.clear()
        // TO-DO: refresh map i guess?
    }
    
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

