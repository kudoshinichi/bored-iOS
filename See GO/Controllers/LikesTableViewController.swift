//
//  LikesTableViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 15/7/18.
//

import UIKit
import Firebase

class LikesTableViewController: UITableViewController {
    var handle: AuthStateDidChangeListenerHandle?
    
    //MARK: Properties
    // Authentication values
    var uid: String = ""
    var email: String = ""
    var group = DispatchGroup()
    
    // Database
    var storyKeyArray = [String]()

    override func viewWillAppear(_ animated: Bool) {
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            self.handle = Auth.auth().addStateDidChangeListener { (auth, user) in
                if let user = user {
                    self.uid = user.uid
                    self.email = user.email!
                }
                
                let ref = Database.database().reference()
                ref.child("users").child(self.uid).child("UpvotedStories").observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children{
                        let story = child as! DataSnapshot
                        let storyKey = story.key
                        self.storyKeyArray.append(storyKey)
                        
                        print(storyKey)
                    }
                    group.leave()
                })
            }
        }
        
        group.notify(queue:. main){
            self.tableView.reloadData()
            print("hope it works")
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.storyKeyArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "LikedSquawksTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LikesTableViewCell else {
            fatalError("The dequeued cell is not an instance of LikesTableViewCell.")
        }
        
        // Configure the cell...
        for oneStory in storyKeyArray {
            print(oneStory)
            cell.load(storyKey: oneStory)
        }
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
