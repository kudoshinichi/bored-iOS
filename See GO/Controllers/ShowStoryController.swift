//
//  ShowStoryController.swift
//  See GO
//
//  Created by Hongyi Shen on 14/6/18.
//
// To-Do: 1. Date field 7. Comments (textEdit + tableview)

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseStorageUI

class ShowStoryController: UIViewController, UITextViewDelegate {

    //MARK: Properties
    var storyKey: String = ""
    var ref: DatabaseReference!
    let storage = Storage.storage()
    
    var keywords: String?
    var caption: String?
    var featured: Bool?
    var flagged: Bool?
    var dateTime: Int?
    var views: Int = 0
    var votes: Int = 0
    var URL: String?
    
    @IBOutlet weak var captionText: UITextView!
    @IBOutlet weak var voteText: UITextView!
    @IBOutlet weak var viewText: UITextView!
    @IBOutlet weak var storyImage: UIImageView!
    @IBOutlet weak var wing0: UIImageView!
    @IBOutlet weak var wing1: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        print("hi " + storyKey)
        
        getInfoFromDatabase{ (success) -> Void in
            if success {
                self.loadImage()
                self.loadInfoOntoUI()
            }
        }
        
        captionText.delegate = self
        voteText.delegate = self
        viewText.delegate = self
        
        wing0.alpha = 0
        wing1.alpha = 0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        self.storyImage.isUserInteractionEnabled = true
        self.storyImage.addGestureRecognizer(tap)
        
    }

    func getInfoFromDatabase(completion: @escaping (_ success: Bool) -> Void) {
        ref.child("stories").child(storyKey).observeSingleEvent(of: .value, with: { (snapshot) in
         self.caption = (snapshot.value as? NSDictionary)?["Caption"] as! String
         self.views = (snapshot.value as? NSDictionary)?["Views"] as! Int
         self.votes = (snapshot.value as? NSDictionary)?["Votes"] as! Int
         self.URL = (snapshot.value as? NSDictionary)?["URI"] as! String
         //self.featured = (snapshot.value as? NSDictionary)?["Featured"] as! Bool
         //self.flagged = (snapshot.value as? NSDictionary)?["Flagged"] as! Bool
         
            print(self.views)
            self.views += 1
            print(self.views)
            let childUpdates = ["/stories/\(self.storyKey)/Views": self.views]
            self.ref.updateChildValues(childUpdates)
            
        completion(true)
        })
        
    }
    
    func loadImage() {
        let reference = storage.reference(forURL: self.URL!)
        let placeholderImage = UIImage(named: "fetching.png")
        storyImage.sd_setImage(with: reference, placeholderImage: placeholderImage)
    }
    
    func loadInfoOntoUI() {
        captionText.text = self.caption
        print(self.caption)
        viewText.text = String(views) + " views"
        voteText.text = String(votes)
    }
    
    // MARK: Actions
    @IBAction func reportStory(_ sender: Any) {
        
        let alert = UIAlertController(title: "Flag squawk?", message: "This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            let childUpdates = ["/stories/\(self.storyKey)/Flagged": true]
            self.ref.updateChildValues(childUpdates)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
    }
    
    @IBAction func shareStory(_ sender: Any) {
        //Set the default sharing message.
        let message = "Omg cool squawk on See GO"
        //Set the link to share.
        if let link = NSURL(string: "http://projectboredinc.wordpress.com/story/" + storyKey)
        {
            let objectsToShare = [message,link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @objc func doubleTapped() {
        // do something here
        print("TapTap")
        wing0.alpha = 1
        wing1.alpha = 1
        votes = votes + 1
        print(String(votes))
        let childUpdates = ["/stories/\(storyKey)/Votes": self.votes]
        ref.updateChildValues(childUpdates)
        voteText.text = String(self.votes)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
