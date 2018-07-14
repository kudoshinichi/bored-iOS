//
//  SignUpViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 8/7/18.
//

import UIKit
import Firebase

var handle: AuthStateDidChangeListenerHandle?

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    @IBOutlet weak var usernameText: UITextField!
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
        
        usernameText.delegate = self
        emailText.delegate = self
        passwordText.delegate = self
        
    }
    
    // MARK: Actions
    @IBAction func createAccount(_ sender: Any) {
        
        //check if email exists alr
        
        guard emailText.text != "", passwordText.text != "", usernameText.text != "" else {
            let alert = UIAlertController(title: "Missing fields", message: "No email, password, or username. Check again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        guard isValidEmail(testStr: emailText.text!) else {
            let alert = UIAlertController(title: "Invalid Email", message: "Try again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        guard isValidPassword(testStr: passwordText.text!) else {
            let alert = UIAlertController(title: "Invalid Password", message: "Please create passwords with at least 8 characters, one letter and one number.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        let emailTextD = self.emailText.text!
        let passwordTextD = self.passwordText.text
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            Auth.auth().createUser(withEmail: emailTextD, password: passwordTextD!) { (authResult, error) in
                // ...
            }
            
            Auth.auth().signIn(withEmail: emailTextD, password: passwordTextD!) { (user, error) in
                // ...
            }
            group.leave()
        }
        
        group.notify(queue: .main){
            self.performSegue(withIdentifier: "SignUpToMap", sender: nil)
        }
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func isValidPassword(testStr:String?) -> Bool {
        guard testStr != nil else { return false }
        
        // at least one digit
        // at least one lowercase
        // 8 characters total
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "(?=.*[0-9])(?=.*[a-z]).{8,}")
        return passwordTest.evaluate(with: testStr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
