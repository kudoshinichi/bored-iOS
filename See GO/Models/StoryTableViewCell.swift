//
//  StoryTableViewCell.swift
//  See GO
//
//  Created by Hongyi Shen on 17/6/18.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseUI

class StoryTableViewCell: UITableViewCell, UITextViewDelegate {
    var handle: AuthStateDidChangeListenerHandle?

    // MARK: Properties
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
    
    var uid: String = ""
    var location: String = ""
    var indexPath: IndexPath?
    var tableView: UITableView?
    var controller: StoryTableViewController?
    
    @IBOutlet weak var storyImage: UIImageView!
    @IBOutlet weak var captionText: UITextView!
    @IBOutlet weak var voteText: UITextView!
    @IBOutlet weak var viewText: UITextView!
    @IBOutlet weak var wing0: UIImageView!
    @IBOutlet weak var wing1: UIImageView!
    @IBOutlet weak var deleteSquawkButton: UIButton!
    
    func load(storyKey: String, uid: String, location: String, indexPath: IndexPath, tableView: UITableView, controller: StoryTableViewController) {
        
        self.storyKey = storyKey
        self.uid = uid
        self.location = location
        self.indexPath = indexPath
        self.tableView = tableView
        self.controller = controller
        print("transferred " + self.storyKey)
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // uid is handed over from TableViewController
        }
        
        // Update cell UI as you wish
        getInfoFromDatabase{ (success) -> Void in
            if success {
                self.loadImage()
                self.loadInfoOntoUI()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        print(storyKey)
        ref = Database.database().reference()
        
        captionText.delegate = self
        voteText.delegate = self
        viewText.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        self.storyImage.isUserInteractionEnabled = true
        self.storyImage.addGestureRecognizer(tap)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        

        
        
        // Configure the view for the selected state
    }
    
    func getInfoFromDatabase(completion: @escaping (_ success: Bool) -> Void) {
        ref.child("stories").child(self.storyKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.caption = (snapshot.value as? NSDictionary)?["Caption"] as? String
            self.views = (snapshot.value as? NSDictionary)?["Views"] as! Int
            self.votes = (snapshot.value as? NSDictionary)?["Votes"] as! Int
            self.URL = (snapshot.value as? NSDictionary)?["URI"] as? String
            //self.featured = (snapshot.value as? NSDictionary)?["Featured"] as! Bool
            //self.flagged = (snapshot.value as? NSDictionary)?["Flagged"] as! Bool
            
            print(self.views)
            self.views += 1 // user read it
            print(self.views)
            let storyViewsUpdates = ["/stories/\(self.storyKey)/Views": self.views]
            self.ref.updateChildValues(storyViewsUpdates)
            let storyViewersUpdates = ["/stories/\(self.storyKey)/Viewers/\(self.uid)": self.uid]
            self.ref.updateChildValues(storyViewersUpdates)
            
            let userReadUpdates = ["/users/\(self.uid)/ReadStories/\(self.storyKey)": self.location]
            self.ref.updateChildValues(userReadUpdates)
            
            completion(true)
        })
        
        // likes and wings
        self.ref.child("users").child(self.uid).child("UpvotedStories").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(self.storyKey) {
                self.wing0.alpha = 1
                self.wing1.alpha = 1
            }
        })
        
        // is this story yours
        self.ref.child("users").child(self.uid).child("stories").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(self.storyKey) {
                self.deleteSquawkButton.alpha = 1
            }
        })
    }
    
    func loadImage() {
        let reference = storage.reference(forURL: self.URL!)
        let placeholderImage = UIImage(named: "fetching.png")
        storyImage.sd_setImage(with: reference, placeholderImage: placeholderImage)
    }
    
    func loadInfoOntoUI() {
        captionText.text = self.caption
        captionText.resolveTags()
        print(self.caption!)
        viewText.text = String(views) + " views"
        voteText.text = String(votes)
    }
    
    // MARK: Actions
    
    @IBAction func reportStory(_ sender: UIButton) {
        let alert = UIAlertController(title: "Flag this squawk?", message: "This action cannot be undone. This squawk will be hidden from you, and potentially deleted.", preferredStyle: .alert) // TO-DO: give brief reason
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Please give brief reason(s)."
        })
        alert.addAction(UIAlertAction(title: "Flag", style: .default, handler: { action in
            let reasonField = alert.textFields![0]
            
            // 1) Update flagged STORY
            let childUpdates = ["/stories/\(self.storyKey)/Flagged": true]
            self.ref.updateChildValues(childUpdates)
            self.ref.child("stories").child(self.storyKey).child("Flaggers").updateChildValues([self.uid: reasonField.text!])
            
            // 2) Update FLAGGER's User
            self.ref.child("users").child(self.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let flagInt = (snapshot.value as? NSDictionary)?["FlagOthers"] as? Int {
                    self.ref.child("users").child(self.uid).updateChildValues(["FlagOthers": flagInt+1])
                } else {
                    self.ref.child("users").child(self.uid).updateChildValues(["FlagOthers": 1])
                }
            })
            self.ref.child("users").child(self.uid).child("FlaggedStories").updateChildValues([self.storyKey: self.location])
                // TO-DO delete cell row
            
            // 3) Update BADGUY's User
            self.ref.child("stories").child(self.storyKey).observeSingleEvent(of: .value, with: { (snapshot) in
                if let badGuy = (snapshot.value as? NSDictionary)?["User"] as? String {
                    // add GotFlagged story node
                    self.ref.child("users").child(badGuy).child("GotFlagged").updateChildValues([self.storyKey:0])
                    // make disabled
                    self.ref.child("users").child(badGuy).updateChildValues(["Disabled":1])
                    
                    self.ref.child("users").child(self.uid).observeSingleEvent(of: .value, with: { (bgSnapshot) in
                        // add GotFlaggedCount
                        if let gotflagInt = (bgSnapshot.value as? NSDictionary)?["GotFlaggedCount"] as? Int {
                            self.ref.child("users").child(self.uid).updateChildValues(["GotFlaggedCount": gotflagInt+1])
                        } else {
                            self.ref.child("users").child(self.uid).updateChildValues(["GotFlaggedCount": 1])
                        }
                    })
                }
            })
            
            // 4) Update flaggedstories MEGANODE
            self.ref.child("flaggedstories").updateChildValues([self.storyKey: self.location]) // for Admin app to parse easily
            
            // 5) Remove flagged story from display
            self.controller!.flagStory(tableView: self.tableView!, indexPath: self.indexPath!)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }
    
    @IBAction func deleteSquawk(_ sender: UIButton) {
        let alert = UIAlertController(title: "Delete squawk?", message: "This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            
            //Delete story from everywhere
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }
    
    @objc func doubleTapped() {
        print("TapTap")
        
        self.ref.child("users").child(self.uid).child("UpvotedStories").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(self.storyKey) {
                self.wing0.alpha = 0
                self.wing1.alpha = 0
                
                self.votes = self.votes - 1
                print(String(self.votes))
                self.voteText.text = String(self.votes)
                
                // minus votes to stories
                let childUpdates = ["/stories/\(self.storyKey)/Votes": self.votes]
                self.ref.updateChildValues(childUpdates)
                
                // remove story from upvotedstories
                self.ref.child("users").child(self.uid).child("UpvotedStories").child(self.storyKey).removeValue()
                
                self.ref.child("stories").child(self.storyKey).child("Upvoters").child(self.uid).removeValue()
                
            } else {
                self.wing0.alpha = 1
                self.wing1.alpha = 1
                
                self.votes = self.votes + 1
                print(String(self.votes))
                self.voteText.text = String(self.votes)
                
                // add votes and voters to stories
                let childUpdates = ["/stories/\(self.storyKey)/Votes": self.votes]
                let upvotedStoryUpdates = ["/stories/\(self.storyKey)/Upvoters/\(self.uid)": self.uid]
                self.ref.updateChildValues(childUpdates)
                self.ref.updateChildValues(upvotedStoryUpdates)
                
                // add story to users' upvotedstories
                let upvotedUpdates = ["/users/\(self.uid)/UpvotedStories/\(self.storyKey)": self.location]
                self.ref.updateChildValues(upvotedUpdates)
            }
        })
        voteText.text = String(self.votes)
    }
    
}
