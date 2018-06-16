//
//  StoryUploadController.swift
//  See GO
//
//  Created by Hongyi Shen on 6/6/18.
//
// TO-DO: 0. Removes stored image when change image
// 3. Camera Picker (untested on simulator; unsure if there's better code)
// 4. might have (hopefully only rare) issue when changing image and current image is still being uploaded (see Note)

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
    var imageNameS: String = "" // for storage or stored image
    var imageNameD: String = "" // for deleting when change image is prompted (to avoid conflict)
    var imageURL: String = "" // download url for database
    var imageChosen: Bool = false

    // Location
    var location: String = ""
    var longitude: String = ""
    var latitude: String = ""
    var locationKey: String = ""
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hookText.delegate = self
        captionText.delegate = self
        
        // Location
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }

    // gets location to be used in database
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

    // after picking photo, gets photo details (for use when uploading to database and storage later)
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
        
        storetoStorage()
        
        imageChosen = true
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    func storetoStorage() {
        //MARK: Store Image to Firebase Storage
        
        // get file from local disk with path
        let localFile = URL(string: imagePath)!
        let storageRef = storage.reference()
        let storeRef = storageRef.child(imageNameS)
        
        let uploadTask = storeRef.putFile(from: localFile, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            
            storeRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                self.imageURL = downloadURL.absoluteString
                print(self.imageURL)
            }
        }
    }
    
    func addtoDatabase(){
        //MARK: Add Squawk to Firebase
        let storyItem = Story(caption: captionText.text!,
                              featured: false,
                              flagged: false,
                              location: self.location,
                              time: Int(NSDate().timeIntervalSince1970*1000),
                              uri: self.imageURL,
                              views: 0,
                              votes: 0,
                              keywords: hookText.text!)
        let storyItemRef = self.ref.childByAutoId()
        let childautoID = storyItemRef.key
        storyItemRef.setValue(storyItem.toAnyObject())
        
        // Create a location node
        
        self.locRef.child(self.locationKey).updateChildValues([childautoID : 0])
        
    }
    
    //MARK: Actions
    @IBAction func addSquawk(_ sender: UIBarButtonItem) {
        // When squawk button pressed, add to Database only after 1) fields completed and 2) storage is successful
        
        guard hookText.text != "", captionText.text != "", imageNameS != "" else {
            // if some fields are incomplete, UIAlertView pops out to alert
            let alert = UIAlertController(title: "Missing fields", message: "No image, hook or caption detected. Check again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        guard imageURL != "" else {
            let alert = UIAlertController(title: "Database error", message: "Try again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        print("can add to database")
        addtoDatabase()
        
        self.performSegue(withIdentifier: "squawkBackToMap", sender: self)
    }
    
    @IBAction func cancelSquawk(_ sender: UIBarButtonItem) {
        
        // alert to confirm
        let alert = UIAlertController(title: "Cancel squawk?", message: "If you come back again, all data will be lost.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            // deletes image from storage if it is uploaded
            if self.imageURL != "" {
                self.deleteStorageImage(imageNameHolder: self.imageNameS)
            } else {
                print("nothing to delete")
            }
            // unwind segue
            self.performSegue(withIdentifier: "squawkBackToMap", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        guard !imageChosen else {
            print("image chosen")
            
            let alert = UIAlertController(title: "Change Image?", message: "Changing image means current image will be lost.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                // Change image takes place where previous image is deleted from database
                self.imageNameD = self.imageNameS
                self.deleteStorageImage(imageNameHolder: self.imageNameD)
                // NOTE: still unsure how to deal with case where previous image is still being uploaded but is changed
                // currently the image just doesn't get deleted and stays in database.. hope this doesn't happen often? :/
                
                self.photoImageView.image = UIImage(named: "addImage")
                
                self.pickImage()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        pickImage()
    }
    
    func pickImage() {
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
    
    func deleteStorageImage(imageNameHolder: String){
        // tested that if imageNameHolder = "", nothing gets deleted
        let storageRef = self.storage.reference()
        let storeRef = storageRef.child(imageNameHolder)
        // Delete the file
        storeRef.delete { error in
            if let error = error {
                // Uh-oh, an error occurred!
            } else {
                // File deleted successfully
                print("deleted successfully")
            }
        }
    }

}
