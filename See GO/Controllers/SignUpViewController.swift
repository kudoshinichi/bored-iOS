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
    
    // Database
    var userRef : DatabaseReference!
    var featuresRef: DatabaseReference!
    struct userItem {
        let admin: Bool
        let username: String
        let uid: String
        
        func toAnyObject() -> Any {
            return [
                "Admin": admin,
                "Username": username,
            ]
        }
    }
    
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
        
        userRef = Database.database().reference(withPath: "users")
        featuresRef = Database.database().reference(withPath: "features")
        
        usernameText.delegate = self
        emailText.delegate = self
        passwordText.delegate = self
        
    }
    
    // MARK: Actions
    @IBAction func createAccount(_ sender: Any) {
        
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
        let usernameTextD = self.usernameText.text!
        
        Auth.auth().createUser(withEmail: emailTextD, password: passwordTextD!) { (authResult, error) in
            
            if (error != nil){
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    
                    print(errCode)
                    
                    switch errCode {
                        
                    case AuthErrorCode.emailAlreadyInUse:
                        print("in use")
                        let alert = UIAlertController(title: "Email Already In Use", message: "A user already exists under this email. Try logging in?", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        
                    default:
                        print("Create User Error: \(error)")
                    }
                }
            } else {
                
                let userID = Auth.auth().currentUser!.uid
                
                // Add to database
                let thisUser = userItem(admin: false, username: usernameTextD, uid: userID)
                self.userRef.child(usernameTextD).updateChildValues(thisUser.toAnyObject() as! [AnyHashable : Any])
                
                // Add Username & Email to User Defaults
                UserDefaults.standard.set(emailTextD, forKey: usernameTextD)
                
                // Login
                Auth.auth().signIn(withEmail: emailTextD, password: passwordTextD!) { (user, error) in
                    //...
                }
                
                // Open Map
                self.performSegue(withIdentifier: "SignUpToMap", sender: nil)
                
            }
        }
         
    }
    
    @IBAction func googleSignUp(_ sender: Any) {
        
        let alert = UIAlertController(title: "You discovered a dummy feature!", message: "This feature is still in development. Let our developers know you want it developed by clicking 'I want this!' below. Otherwise, please 'Cancel' ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I want this!", style: .default, handler: {(action:UIAlertAction!) in
            
            /*
            self.featuresRef.child("iOS").child("GoogleSignIn").observeSingleEvent(of: .value, with: { (snapshot) in
                
                
                self.featuresRef.child("iOS").child("GoogleSignIn").updateChildValues(<#T##values: [AnyHashable : Any]##[AnyHashable : Any]#>)
                
            })*/
            
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
        //RAWR
    }
    
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func isValidPassword(testStr:String?) -> Bool {
        guard testStr != nil else { return false }
        // at least one digit && at least one lowercase && 8 characters total
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "(?=.*[0-9])(?=.*[a-z]).{8,}")
        return passwordTest.evaluate(with: testStr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
