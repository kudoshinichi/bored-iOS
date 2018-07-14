//
//  LoginViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 13/7/18.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    
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
        
        emailText.delegate = self
        passwordText.delegate = self
        
    }
    
    //MARK: Actions
    @IBAction func LoginAccount(_ sender: Any) {
        
        let email = emailText.text
        let password = passwordText.text
        
        print(email)
        print(password)
        
        guard emailText.text != "", passwordText.text != "" else {
            // if some fields are incomplete, UIAlertView pops out to alert
            let alert = UIAlertController(title: "Missing fields", message: "No email, password, or username. Check again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            Auth.auth().signIn(withEmail: email!, password: password!) { (user, error) in
                // ...
            }
            group.leave()
        }
        
        group.notify(queue: .main){
            self.performSegue(withIdentifier: "LoginToMap", sender: nil)
        }
        
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
