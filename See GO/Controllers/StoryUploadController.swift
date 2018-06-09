//
//  StoryUploadController.swift
//  See GO
//
//  Created by Hongyi Shen on 6/6/18.
//

// Subsequent TO-DO: 2. Image storage + URI 3. Camera Picker 5. Prevent empty stories 6. Users [ 7. Comments 8. Hashtag and Hasthtag search ]

import UIKit
import FirebaseDatabase
import Firebase
import CoreLocation
import os.log

class StoryUploadController: UIViewController, UITextFieldDelegate , UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {

    // MARK: Properties
    @IBOutlet weak var hookText: UITextField!
    @IBOutlet weak var captionText: UITextField!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var squawkButton: UIBarButtonItem!
    
    
    // Firebase
    let ref = Database.database().reference(withPath: "stories")
    let locRef = Database.database().reference(withPath: "locations")
    var items: [Story] = []
    // Get a reference to the storage service using the default Firebase App
    let storage = Storage.storage()
    
    
    // Location
    var location: String = ""
    var longitude: String = ""
    var latitude: String = ""
    var locationKey: String = ""
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle the text field’s user input through delegate callbacks.
        hookText.delegate = self
        captionText.delegate = self
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        // Location variable
        location = "\(locValue.latitude),\(locValue.longitude)"
        longitude = "\(locValue.longitude)"
        latitude = "\(locValue.latitude)"
        locationKey = latitude.replacingOccurrences(of: ".", with: "d") + "," + longitude.replacingOccurrences(of: ".", with: "d")
        print(locationKey)
        print(location)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField{
        case hookText:
            captionText.becomeFirstResponder()
        case captionText:
            captionText.resignFirstResponder()
        default: break
        }
        return true
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        // Set photoImageView to display the selected image.
        photoImageView.image = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Navigation
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === squawkButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let storyItem = Story(caption: captionText.text!,
                              featured: false,
                              flagged: false,
                              location: self.location,
                              uri: "test.uri",
                              views: 0,
                              votes: 0,
                              keywords: hookText.text!)
        
        // 3
        let storyItemRef = self.ref.childByAutoId()
        let childautoID = storyItemRef.key
        
        // 4
        storyItemRef.setValue(storyItem.toAnyObject())
        
        // 5 Add time to another node
        storyItemRef.child("DateTime").setValue(["time": Int(NSDate().timeIntervalSince1970*1000)])
        
        //6 create a location node
        self.locRef.child(self.locationKey).setValue([childautoID : 0])
        
    }
    
    //MARK: Actions
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
