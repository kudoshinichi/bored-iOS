//
//  StoryTableViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 17/6/18.
//
// imageView.image = nil use a placeholder image (don't I do this?!)
// prepare for ReUse to remove all data


import UIKit
import Firebase

class StoryTableViewController: UITableViewController {
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    //MARK: Properties
    var storyKey: String = ""
    var storyLocation: String = ""
    var story = [Substring]()
    var uid: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(storyKey)
        story = storyKey.split(separator: ",")
        print(story)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return 1
        return story.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "StoryTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? StoryTableViewCell  else {
            fatalError("The dequeued cell is not an instance of StoryTableViewCell.")
        }
        
        // Configure the cell...
        let oneStory = story[indexPath.row]
        cell.storyImage.image = nil
        cell.wing0.alpha = 0
        cell.wing1.alpha = 0
        cell.deleteSquawkButton.alpha = 0
        cell.load(storyKey: String(oneStory), uid: self.uid, location: self.storyLocation)

        return cell
    }
    
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let oneStory = story[indexPath.row]
        let ref = Database.database().reference()
        var isYours: Bool = false
        
        if editingStyle == .delete {
            
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                ref.child("users").child(self.uid).child("stories").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.hasChild(String(oneStory)) {
                        isYours = true
                        group.leave()
                    }
                })
            }
            
            group.notify(queue: .main){
                guard isYours else { return } // story is not yours
                
                let alert = UIAlertController(title: "Delete squawk?", message: "This action cannot be undone.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    print("imma delete this")
                    self.deleteFromEverywhere(delStoryKey: String(self.story[indexPath.row]))
                    self.story.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
            
        }
     }
    
    func deleteFromEverywhere(delStoryKey: String) {
        print("deleting " + delStoryKey)
        let ref = Database.database().reference()
        
        ref.child("stories").child(delStoryKey).observeSingleEvent(of: .value, with: { (snapshot) in
            let storyNode =  snapshot as! DataSnapshot
            for viewerChild in storyNode.childSnapshot(forPath: "Viewers").children {
                let user = viewerChild as! DataSnapshot
                let userKey = user.key
                ref.child("users").child(userKey).child("ReadStories").child(delStoryKey).removeValue() // delete from every user's ReadStories
            }
            
            for upvoterChild in storyNode.childSnapshot(forPath: "Upvoters").children {
                let user = upvoterChild as! DataSnapshot
                let userKey = user.key
                ref.child("users").child(userKey).child("UpvotedStories").child(delStoryKey).removeValue() // delete from every user's UpvotedStories
            }
            
            for flaggerChild in storyNode.childSnapshot(forPath: "Flaggers").children {
                let user = flaggerChild as! DataSnapshot
                let userKey = user.key
                ref.child("users").child(userKey).child("FlaggedStories").child(delStoryKey).removeValue() // delete from every user's FlaggedStories
                // NOTE* not deleted from badGuy's GotFlagged
            }
            
            for hashtagChild in storyNode.childSnapshot(forPath: "Hashtags").children {
                let hashtag = hashtagChild as! DataSnapshot
                let hashtagKey = hashtag.key
                ref.child("hashtags").child(hashtagKey).child(delStoryKey).removeValue() // delete from hashtags
            }
            
            // delete from owner's stories
            let userUID = storyNode.childSnapshot(forPath: "User").value as! String
            ref.child("users").child(userUID).child("stories").child(delStoryKey).removeValue()

            // delete from locations
            let location = storyNode.childSnapshot(forPath: "Location").value as! String
            let locationD = location.replacingOccurrences(of: ".", with: "d")
            ref.child("locations").child(locationD).child(delStoryKey).removeValue()
            
            // delete photo from storage
            let imageURI = storyNode.childSnapshot(forPath: "URI").value as! String
            let storage = Storage.storage()
            storage.reference(forURL: imageURI).delete(completion: nil)
            
            ref.child("stories").child(delStoryKey).removeValue()
        })
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
  
}
