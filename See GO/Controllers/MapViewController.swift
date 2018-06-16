//
//  MapViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 5/6/18.
//
// Subsequent TO-DO:
// 3. Multiple stories *
// [6. Users (reddit and stackoverflow, voting & read system)
// 2. Marker Aesthetic
// 8. Hashtag and Hasthtag search]

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
        
    }
    
    // Unwind segue
    @IBAction func unwindToMainScreen(segue: UIStoryboardSegue) {
        print("Unwind segue to main screen triggered!")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is ShowStoryController
        {
            let vc = segue.destination as? ShowStoryController
            vc?.storyKey = showStoryKey
        }
    }
    
}

// Delegate to handle events for Google Map View
extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("You tapped the infowindow! :o")
        // gets storyKey of this marker
        let data = marker.userData as! NSDictionary
        let key1 = data["key"]
        let near1 = data["near"] as! Bool
        if near1 {
            showStoryKey = key1 as! String
            self .performSegue(withIdentifier: "ShowStorySegue", sender: self)
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
                
                for grandchild in (child as AnyObject).children{
                    let valueD = grandchild as! DataSnapshot
                    self.storyKey = valueD.key
                    //print(self.storyKey)
                }
                
                // adding marker to map
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
                
                marker.userData = ["key": self.storyKey, "near": self.isNear]
                let data = marker.userData as! NSDictionary
                let key1 = data["key"]
                let near1 = data["near"]
                print(key1)
                print(near1)
                
                if !self.isNear {
                    marker.icon = GMSMarker.markerImage(with: .purple)
                    
                    self.ref.child("stories").child(self.storyKey).observe(.value, with: { snapshot in
                        let keywords = (snapshot.value as? NSDictionary)?["Keywords"] as? String
                        if keywords == nil {
                            marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk."
                        } else {
                            self.keywords = keywords!
                            marker.snippet = "In " + String(Int(distanceMetres)) + "m, \"" + self.keywords + "\"."
                        }
                    })
                    
                } else {
                    marker.icon = GMSMarker.markerImage(with: .green)
                    
                    self.ref.child("stories").child(self.storyKey).observe(.value, with: { snapshot in
                        let keywords = (snapshot.value as? NSDictionary)?["Keywords"] as? String
                        if keywords == nil {
                             marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk. Tap to open!"
                        } else {
                            self.keywords = keywords!
                            marker.snippet = "In " + String(Int(distanceMetres)) + "m, \"" + self.keywords + "\". Tap to open!"
                        }
                    })
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

