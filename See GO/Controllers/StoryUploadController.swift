//
//  StoryUploadController.swift
//  See GO
//
//  Created by Hongyi Shen on 6/6/18.
//
// TO-DO: 0. Removes stored image when change image 1. Duplicate story at one location, one gets removed 2. Do dispatch queue A) for imagePicker (imageURL), and add to Firebase B) Cancel story only works after url?
// 3. Camera Picker (untested) 5. Prevent empty stories
// [6. Users 7. Comments 8. Hashtag and Hasthtag search]

import UIKit
import FirebaseDatabase
import Firebase
import CoreLocation
import FirebaseStorage
import os.log

class StoryUploadController: UIViewController, UITextFieldDelegate , UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {

    // MARK: Properties
    @IBOutlet weak var hookText: UITextField!
    @IBOutlet weak var captionText: UITextField!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var squawkButton: UIBarButtonItem!
    
    
    // Database
    let ref = Database.database().reference(withPath: "stories")
    let locRef = Database.database().reference(withPath: "locations")
    var items: [Story] = []
    
    // Storage
    let storage = Storage.storage()
    var imagePath: String = ""
    var imageNameS: String = ""
    var imageURL: String = "" // download url for database

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
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let imageUrl          = info[UIImagePickerControllerImageURL] as? NSURL
        let imageName         = imageUrl?.lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let photoURL          = NSURL(fileURLWithPath: documentDirectory)
        let localPath         = photoURL.appendingPathComponent(imageName!)
        
        if !FileManager.default.fileExists(atPath: localPath!.path) {
            do {
                try UIImageJPEGRepresentation(image, 1.0)?.write(to: localPath!)
                print("file saved")
            }catch {
                print("error saving file")
            }
        }
        else {
            print("file already exists")
        }
        
        imagePath = localPath!.absoluteString
        imageNameS = imageName!
        
        //MARK: Store Image to Firebase Storage
        
        // get file from local disk with path
        let localFile = URL(string: imagePath)!
        // Create a reference to the file you want to upload
        let storageRef = storage.reference()
        let storeRef = storageRef.child(imageNameS)
        let uploadTask = storeRef.putFile(from: localFile, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            
            // You can also access to download URL after upload.
            storeRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                
                self.imageURL = downloadURL.absoluteString
                print(self.imageURL)
            }
        }
        
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
            
            
            let storageRef = storage.reference()
            let storeRef = storageRef.child(imageNameS)
            // Delete the file
            storeRef.delete { error in
                if let error = error {
                    // Uh-oh, an error occurred!
                } else {
                    // File deleted successfully
                    print("deleted successfully")
                }
            }
            
            return
        }

        //MARK: Add Squawk to Firebase
        let storyItem = Story(caption: captionText.text!,
                              featured: false,
                              flagged: false,
                              location: self.location,
                              uri: self.imageURL,
                              views: 0,
                              votes: 0,
                              keywords: hookText.text!)
        let storyItemRef = self.ref.childByAutoId()
        let childautoID = storyItemRef.key
        storyItemRef.setValue(storyItem.toAnyObject())
        
        // Add time to another node
        storyItemRef.child("DateTime").setValue(["time": Int(NSDate().timeIntervalSince1970*1000)])
        
        // Create a location node
        self.locRef.child(self.locationKey).setValue([childautoID : 0])
        
        
    }
    
    //MARK: Actions
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func openCamera() {
        print("Camera")
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera;
            imagePickerController.allowsEditing = false
            present(imagePickerController, animated: true, completion: nil)
        } else {
            print("No camera on device")
        }
    }
    
    func openGallery() {
        print("Gallery")
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
