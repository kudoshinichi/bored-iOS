//
//  SignInViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 8/7/18.
//

import UIKit
import Firebase
import FirebaseAuth




class SignInViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        /*
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
        }
        */

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameText.delegate = self
        emailText.delegate = self
        passwordText.delegate = self

        
    }
    
    // MARK: Actions
    @IBAction func createAccount(_ sender: Any) {
        
        guard emailText.text != "", passwordText.text != "", usernameText.text != "" else {
            
            // if some fields are incomplete, UIAlertView pops out to alert
            let alert = UIAlertController(title: "Missing fields", message: "No email, password, or username. Check again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        Auth.auth().createUser(withEmail: emailText.text!, password: passwordText.text!) { (authResult, error) in
            // ...
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
