//
//  SignUpViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 8/7/18.
//

import UIKit
import Firebase
import GoogleSignIn

class SignUpViewController: UIViewController, UITextFieldDelegate, GIDSignInUIDelegate {
    
    // MARK: Properties
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!

    var handle: AuthStateDidChangeListenerHandle?
    
    // Database
    var userRef : DatabaseReference!
    var featuresRef: DatabaseReference!
    struct userItem {
        let admin: Bool
        let username: String
        let uid: String
        let flagothers: Int
        
        func toAnyObject() -> Any {
            return [
                "Admin": admin,
                "Username": username,
                "UID": uid,
                "FlagOthers": flagothers,
            ]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                print("User is signed in.")
            } else {
                print("User is signed out.")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        userRef = Database.database().reference(withPath: "users")
        featuresRef = Database.database().reference(withPath: "features")
        
        usernameText.delegate = self
        emailText.delegate = self
        passwordText.delegate = self
        
        // Google Sign In
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField{
        case usernameText:
            emailText.becomeFirstResponder()
        case emailText:
            passwordText.becomeFirstResponder()
        default: break
        }
        return true
    }
    
    // MARK: Actions
    @IBAction func unwindToSignIn(segue: UIStoryboardSegue) {
        print("Unwind segue to main screen triggered!")
    }
    
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
                        print("Create User Error: \(String(describing: error))")
                    }
                }
            } else {
                
                let userID = Auth.auth().currentUser!.uid
                
                // Add user to database
                let thisUser = userItem(admin: false, username: usernameTextD, uid: userID, flagothers: 0)
                self.userRef.child(userID).updateChildValues(thisUser.toAnyObject() as! [AnyHashable : Any])
                
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
        
        print("clicked")
        GIDSignIn.sharedInstance().signIn()
        print("clocked")
        
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
    
}
