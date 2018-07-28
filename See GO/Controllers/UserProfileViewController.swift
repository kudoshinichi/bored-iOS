//
//  UserProfileViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 15/7/18.
//

import UIKit
import Firebase

class UserProfileViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var usernameText: UILabel!
    @IBOutlet weak var emailText: UILabel!
    @IBOutlet weak var peopleReachedText: UILabel!
    @IBOutlet weak var squawksFoundText: UILabel!
    @IBOutlet weak var squawksAddText: UILabel!
    @IBOutlet weak var wingsGivenText: UILabel!
    @IBOutlet weak var wingsReceivedText: UILabel!
    
    // Authentication values
    var handle: AuthStateDidChangeListenerHandle?
    var uid: String = ""
    var email: String = ""
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(self.handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.uid = user.uid
                self.email = user.email!
            }
        
            let ref = Database.database().reference()
            ref.child("users").child(self.uid).observe(.value, with: { userSnapshot in
                ref.child("stories").observe(.value, with: {storySnapshot in
                    self.usernameText.text = userSnapshot.childSnapshot(forPath: "Username").value as? String
                    self.emailText.text = self.email
                    self.squawksFoundText.text = String(userSnapshot.childSnapshot(forPath: "ReadStories").childrenCount)
                    self.squawksAddText.text = String(userSnapshot.childSnapshot(forPath: "stories").childrenCount)
                    
                    var reach = 0, flapsGiven = 0, flapsReceived = 0
                    var stories:[String:Story] = [:]
                    
                    // This can be greatly simplified if ReadStories and UpvotedStories are populated faithfully
                    for child in storySnapshot.children {
                        if let story = child as? DataSnapshot {
                            var viewers: Set<String> = Set<String>()
                            var voters: Set<String> = Set<String>()
                            for viewerChild in story.childSnapshot(forPath: "Viewers").children {
                                if let viewer = viewerChild as? DataSnapshot {
                                    viewers.insert(viewer.key)
                                }
                            }
                            for voterChild in story.childSnapshot(forPath: "Upvoters").children {
                                if let voter = voterChild as? DataSnapshot {
                                    voters.insert(voter.key)
                                }
                            }
                            stories[story.key] = Story(
                                id: story.key,
                                views: story.childSnapshot(forPath: "Views").value as? Int,
                                votes: story.childSnapshot(forPath: "Votes").value as? Int,
                                viewers: viewers,
                                voters: voters)
                        }
                    }
                    flapsGiven = Int(userSnapshot.childSnapshot(forPath: "UpvotedStories").childrenCount)
                    for child in userSnapshot.childSnapshot(forPath: "stories").children {
                        if let writtenStory = child as? DataSnapshot {
                            let story = stories[writtenStory.key]!
                            reach += story.views!
                            flapsReceived += story.votes!
                        }
                    }
                    self.peopleReachedText.text = "~ " + String(reach)
                    self.wingsGivenText.text = String(flapsGiven)
                    self.wingsReceivedText.text = String(flapsReceived)
                })
            })
        }
    }
    
    struct Story {
        var id: String?
        var views: Int?
        var votes: Int?
        var viewers: Set<String>
        var voters: Set<String>
    }
}
