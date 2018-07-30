//
//  StoryUploadController.swift
//  See GO
//
//  Created by Hongyi Shen on 6/6/18.
//
// TO-DO:
// 3. Camera Picker (untested on simulator; unsure if there's better code)
// 4. might have (hopefully only rare) issue when changing image and current image is still being uploaded (see Note)
// 5. Hashtags get into database

import UIKit
import FirebaseDatabase
import Firebase
import CoreLocation
import FirebaseStorage
import os.log
import Photos

class StoryUploadController: UIViewController, UITextFieldDelegate , UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    var handle: AuthStateDidChangeListenerHandle?

    // MARK: Properties
    @IBOutlet weak var hookText: UITextField!
    @IBOutlet weak var captionTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!
    
    var placeholderText = "Insert caption #and #hashtags."
    var hashtags: [String] = []
    
    // Database
    let ref = Database.database().reference()
    let stoRef = Database.database().reference(withPath: "stories")
    let locRef = Database.database().reference(withPath: "locations")
    let userRef = Database.database().reference(withPath: "users")
    var items: [Story] = []
    
    // Storage
    let storage = Storage.storage()
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
    
    //User
    var uid: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.uid = user.uid
                
                print(self.uid)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        hookText.delegate = self
        captionTextView.delegate = self
        
        captionTextView.text = placeholderText
        captionTextView.textColor = UIColor.lightGray
        
        // Location
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        pickImage()
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
            captionTextView.becomeFirstResponder()
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
        
        if picker.sourceType == .camera {
            let originalImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            // get the documents directory url
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            let image = originalImage.resizeWithWidth(width: 500)!
            
            // choose a name for your image
            let date :NSDate = NSDate()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'_'HH_mm_ss"
            dateFormatter.timeZone = NSTimeZone(name: "GMT") as! TimeZone
            
            let fileName = "/\(dateFormatter.string(from: date as Date)).jpg"
            
            // create the destination file url to save your image
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            // get your UIImage jpeg data representation and check if the destination file url already exists
            if let data = UIImageJPEGRepresentation(image, 1.0),
                !FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    // writes the image data to disk
                    try data.write(to: fileURL)
                    print("file saved")
                } catch {
                    print("error saving file:", error)
                }
            }
            
            imageNameS = fileName
            
            storetoStorage(localPath: fileURL.absoluteString, imageName: imageNameS)
           
        } else if picker.sourceType == .photoLibrary {
            let originalImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let image = originalImage.resizeWithWidth(width: 500)!
            let imageUrl          = info[UIImagePickerControllerImageURL] as? NSURL
            let imageName         = imageUrl?.lastPathComponent
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let photoURL          = NSURL(fileURLWithPath: documentDirectory)
            let localPath         = photoURL.appendingPathComponent(imageName!)
            
            if !FileManager.default.fileExists(atPath: localPath!.path) {
                do {
                    try UIImageJPEGRepresentation(image, 1.0)?.write(to: localPath!)
                    print("file saved")
                    print("blop")
                }catch {
                    print("error saving file")
                    print("blop")
                }
            }
            else {
                print("file already exists")
                print("blop")
            }
            
            imageNameS = imageName!
            
            storetoStorage(localPath: localPath!.absoluteString, imageName: imageNameS)
        }
        
        imageChosen = true

        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    func addAsset(image: UIImage, to album: PHAssetCollection) {
        PHPhotoLibrary.shared().performChanges({
            // Request creating an asset from the image.
            let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            // Request editing the album.
            guard let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                else { return }
            // Get a placeholder for the new asset and add it to the album editing request.
            addAssetRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
        }, completionHandler: { success, error in
            if !success { NSLog("error creating asset: \(error)") }
        })
    }
    
    
    //MARK: Store Things to Firebase
    func storetoStorage(localPath: String, imageName: String) {
        
        // get file from local disk with path
        let localFile = URL(string: localPath)!
        let storageRef = storage.reference()
        let storeRef = storageRef.child(imageName)
        
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
    
    func addtoDatabase(hashtags: [String]){
        // Add to stories node
        let storyItem = Story(caption: captionTextView.text!,
                              featured: false,
                              flagged: false,
                              location: self.location,
                              time: Int(NSDate().timeIntervalSince1970*1000),
                              uri: self.imageURL,
                              views: 0,
                              votes: 0,
                              keywords: hookText.text!,
                              user: self.uid)
        let storyItemRef = self.stoRef.childByAutoId()
        let childautoID = storyItemRef.key
        storyItemRef.setValue(storyItem.toAnyObject())
        
        // Add to location node
        self.locRef.child(self.locationKey).updateChildValues([childautoID : 0])
        
        // Add story to user node
        self.userRef.child(self.uid).child("stories").updateChildValues([childautoID: self.location])
        
        // Add hashtags to hashtag node & story node
        for hashtag in hashtags {
            let tagonly = hashtag.dropFirst()
            self.ref.child("hashtags").child(String(tagonly)).updateChildValues([childautoID: self.location]) // add to hashtag node
            self.stoRef.child(childautoID).child("Hashtags").updateChildValues([tagonly:tagonly])
        }
    }
    
    //MARK: Actions
    @IBAction func addSquawk(_ sender: UIBarButtonItem) {
        // When squawk button pressed, add to Database only after 1) fields completed and 2) storage is successful
        
        guard hookText.text != "", captionTextView.text != "", imageNameS != "" else {
            // if some fields are incomplete, UIAlertView pops out to alert
            let alert = UIAlertController(title: "Missing fields", message: "No image, hook or caption detected. Check again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        guard imageURL != "" else {
            let alert = UIAlertController(title: "Database error", message: "Image is still being uploaded. Try again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        hashtags = captionTextView.text!.findMentionText()
        print(hashtags)
        print("can add to database")
        addtoDatabase(hashtags: hashtags)
        
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
    
    //MARK: Image Matters
    
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
            if error != nil {
                // Uh-oh, an error occurred!
            } else {
                // File deleted successfully
                print("deleted successfully")
            }
        }
    }
    
    //MARK: Text Matters
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 40
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = UIColor.lightGray
        } else {
            captionTextView.resolveTags()
        }
    }
}

extension String {
    func findMentionText() -> [String] {
        var arr_hasStrings:[String] = []
        let regex = try? NSRegularExpression(pattern: "(#[a-zA-Z0-9_\\p{Arabic}\\p{N}]*)", options: [])
        if let matches = regex?.matches(in: self, options:[], range:NSMakeRange(0, self.count)) {
            for match in matches {
                arr_hasStrings.append(NSString(string: self).substring(with: NSRange(location:match.range.location, length: match.range.length )))
            }
        }
        return arr_hasStrings
    }
}

extension UITextView {
    func resolveTags(){
        let text = self.text
        let hashtags = text!.findMentionText()
        self.attributedText = convert(hashtags, string: text!)
    }

    func convert(_ hashElements:[String], string: String) -> NSAttributedString {
        let hasAttr = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0), NSAttributedStringKey.foregroundColor: UIColor.orange]
        let normalAttr = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0), NSAttributedStringKey.foregroundColor: UIColor.black]
        let mainAttributedString = NSMutableAttributedString(string: string, attributes: normalAttr)
        let txtViewReviewText = string as NSString
        hashElements.forEach { if string.contains($0) {
            mainAttributedString.addAttributes(hasAttr, range: txtViewReviewText.range(of: $0))
            }
        }
        return mainAttributedString
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
}

extension UIImage {
    func resizeWithWidth(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
}
}
