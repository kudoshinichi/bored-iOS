//
//  ShowStoryController.swift
//  See GO
//
//  Created by Hongyi Shen on 14/6/18.
//

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
        
    }

    func getInfoFromDatabase(completion: @escaping (_ success: Bool) -> Void) {
        ref.child("stories").child(storyKey).observe(.value, with: { snapshot in
         self.caption = (snapshot.value as? NSDictionary)?["Caption"] as! String
         self.views = (snapshot.value as? NSDictionary)?["Views"] as! Int
         self.votes = (snapshot.value as? NSDictionary)?["Votes"] as! Int
         self.URL = (snapshot.value as? NSDictionary)?["URI"] as! String
         //self.featured = (snapshot.value as? NSDictionary)?["Featured"] as! Bool
         //self.flagged = (snapshot.value as? NSDictionary)?["Flagged"] as! Bool
         
         print(self.views)
         print(self.votes)
         print(self.caption)
            
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
        viewText.text = String(views)
        voteText.text = String(votes)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
