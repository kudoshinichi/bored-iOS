//
//  MapViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 5/6/18.
//
// Subsequent TO-DO: 1. Marker Snippet 2. Marker Colours and Aesthetic

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
    var stoRef: DatabaseReference!
    var locRef: DatabaseReference!
    
    // Others
    var userLocation: CLLocation?
    var keywords: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        stoRef = Database.database().reference(withPath: "stories")
        locRef = Database.database().reference(withPath: "locations")
        
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
    
}

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("TapTapTap")
        // marker.title = "You selected me!"
        // marker.snippet = "Erm ok..."
        // true means that the default behaviour will not happen. false means that the default
        // behaviour still gets executed. In this case the default behaviour is to show the
        // marker info window. If you click on the tap info window your line below will print.
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("You tapped the infowindow! :o")
        self .performSegue(withIdentifier: "ShowStorySegue", sender: self)
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
                
                //let value1 = valueD.value
                //print(value1)
                // This gives -L-H4On_Yd5cMmlI3Qv1" = 0
                
                // HOW TO READ STORY KEY
                
                
                //let keywords = (snapshot.value as? NSDictionary)?[keyD] as? String ?? ""
                //print(keywords)
                
                //NEW THING GET STORY KEY
                /*self.ref.child(keyD).observe(.value, with: { snapshot in
                    for child in snapshot.children{
                        let value = child as! DataSnapshot
                        let storyKey = value.key
                        print (storyKey)
                    }
                })*/
                // apparently there are no "children"
                
                // adding marker to map
                let marker = GMSMarker()
                let storyLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
                marker.position = CLLocationCoordinate2D(latitude: Double(latitude)!, longitude: Double(longitude)!)
                marker.map = self.mapView
                
                let distanceMetres = (self.userLocation?.distance(from: storyLocation))!
                print(String(distanceMetres))
                
                if distanceMetres > 500.0 {
                    marker.icon = GMSMarker.markerImage(with: .purple)
                    marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk."
                    
                } else {
                    marker.icon = GMSMarker.markerImage(with: .green)
                    
                    // if have keywords
                    /* self.stoRef.observe(.value, with: { snapshot in
                        let value = snapshot.key as? String //= "Optional("stories")"
                        print(value)
                        //let username = value?["Keywords"] as? String
                        //print(username)
                        
                        //let keywords = (snapshot.value as? NSDictionary)?["Caption"] as? String
                        //print(keywords)
                        //print(self.keywords)
                    }) */
                    
                    marker.snippet = "In " + String(Int(distanceMetres)) + "m, there is a squawk. Tap me to open!"
                    
                }
                
                //if it is near
                //  make it green
                //  tap me to open
                //  if it
                
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

