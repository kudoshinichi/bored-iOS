//
//  LoginViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 13/7/18.
//
// TODO: make password hidden

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
    @IBAction func LoginAction(_ sender: Any) {
        let email = emailText.text
        let password = passwordText.text
        
        print(email)
        print(password)
        
        // TODO: allow login by username
        
        guard emailText.text != "", passwordText.text != "" else {
            // if some fields are incomplete, UIAlertView pops out to alert
            let alert = UIAlertController(title: "Missing fields", message: "No email/username or password. Check again?", preferredStyle: .alert)
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
       
        Auth.auth().signIn(withEmail: email!, password: password!) { (user, error) in
            if (error != nil) {
                
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    
                    switch errCode {
                        
                    case AuthErrorCode.userNotFound:
                        let alert = UIAlertController(title: "User Not Found", message: "User does not exist or may have been deleted. Try signing up?", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        
                    case AuthErrorCode.userDisabled:
                        let alert = UIAlertController(title: "User Disabled", message: "Contact us with this error.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        
                    case AuthErrorCode.wrongPassword:
                        let alert = UIAlertController(title: "Wrong Password", message: "Try again? Or try 'Forgot Your Password'?", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        
                    default:
                        print("Create User Error: \(error)")
                    }
                    
                }
                
            } else {
                self.performSegue(withIdentifier: "LoginToMap", sender: nil)
                print ("cool")
            }
        }
    }
    
    @IBAction func forgetPassword(_ sender: Any) {
        //RAWR
    }
    
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
