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
    var uid: String = ""
    var email: String = ""
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.uid = user.uid
                self.email = user.email!
                
                print(self.uid)
                print(self.email)
                
                self.usernameText.text = self.uid
                self.emailText.text = self.email
            }
        }

    }
    

}
