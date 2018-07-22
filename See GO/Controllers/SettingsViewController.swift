//
//  SettingsViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 15/7/18.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?

    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func changePW(_ sender: Any) {
        //RAWR
    }
    
    @IBAction func contactUS(_ sender: Any) {
        //RAWR: cannot test unless on phone
        let email = "projectbored.inc@gmail.com"
        if let url = URL(string: "mailto:\(email)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func faqButton(_ sender: Any) {
        //RAWR
        if let url = URL(string: "https://projectboredinc.wordpress.com") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func logOut(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
            self.performSegue(withIdentifier: "LogOutToSignUp", sender: self)
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    

}
