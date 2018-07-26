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
                    self.deleteFromEverywhere(storyKey: String(self.story[indexPath.row]))
                    self.story.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
            
        }
     }
    
    func deleteFromEverywhere(storyKey: String) {
        print("deleting " + storyKey)
        // delete from every user's UpvotedStories
        // delete from every user's ReadStories
        // delete from every user's flaggedStories
        // delete from hashtags
        // delete from locations
        // delete from stories
        
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
  
}
