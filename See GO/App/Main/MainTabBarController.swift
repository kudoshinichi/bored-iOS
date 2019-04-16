//
//  MainTabBarController.swift
//  See GO
//
//  Created by Bhargav Singapuri on 28/3/19.
//

import UIKit
import Firebase
import GoogleSignIn

class MainTabBarController: UITabBarController {
    
    var handle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user = Auth.auth().currentUser;
        let userSignedIn: Bool = (user != nil)
        
        if !userSignedIn{
            performSegue(withIdentifier: "ShowLogin", sender: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener {[weak self] (auth, user) in
            if user != nil {
                print("User is signed in.")
            } else {
                print("User is signed out.")
                self?.performSegue(withIdentifier: "ShowLogin", sender: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
}
