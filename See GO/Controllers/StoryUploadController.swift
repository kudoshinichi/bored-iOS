//
//  StoryUploadController.swift
//  See GO
//
//  Created by Hongyi Shen on 6/6/18.
//
// TO-DO: *technically solved under 2* 0. Removes stored image when change image
// 2. *TEST TMR* Do dispatch queue A) for imagePicker (imageURL), and add to Firebase B) Cancel story only works after url?
// Test and see if it's slow hmmm (can ask lik hern how the uploads thingum work?)
// Test first, but actually need not hmmmm... if i can just if success, no can't
// 3. Camera Picker (untested)
// 5. *TMR* Prevent empty stories

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
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let button = sender as? UIBarButtonItem, button == squawkButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            /*
            Code to remove image from storage.. technically not necessary if i only store image much later?
             
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
            } */
            return
        }
        
        // When squawk button pressed, add to Database only after storage is successful
        storetoStorage{ (success) -> Void in
            if success {
                self.addtoDatabase()
            }
        }
    }
    
    func storetoStorage(completion: @escaping (_ success: Bool) -> Void) {
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
                completion(true)
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

}
