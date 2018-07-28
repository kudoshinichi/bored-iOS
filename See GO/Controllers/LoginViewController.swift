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
    var handle: AuthStateDidChangeListenerHandle?
    
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
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        emailText.delegate = self
        passwordText.delegate = self
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField{
        case emailText:
            passwordText.becomeFirstResponder()
        default: break
        }
        return true
    }
    
    //MARK: Actions
    @IBAction func LoginAction(_ sender: Any) {
        let emailOrUsername = emailText.text
        let password = passwordText.text
        
        print(emailOrUsername!)
        print(password!)
        
        // Guard missing fields
        guard emailText.text != "", passwordText.text != "" else {
            let alert = UIAlertController(title: "Missing fields", message: "No email/username or password. Check again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        // Log in by username if not valid email
        guard isValidEmail(testStr: emailText.text!) else {
            
            let emailfromUsername = UserDefaults.standard.string(forKey: emailOrUsername!) ?? ""
            print(emailfromUsername)
            
            // if no stored email
            if emailfromUsername == "" {
                let alert = UIAlertController(title: "First Time Login", message: "This is the first time you are logging in with this username on this device. Please input your corresponding email.", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = "Username"
                })
                alert.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = "Email"
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler:{(action:UIAlertAction!) in
                    let usernameField = alert.textFields![0]
                    let emailField = alert.textFields![1]
                    print(usernameField.text!)
                    print(emailField.text!)
                    
                    UserDefaults.standard.set(emailField.text!, forKey: usernameField.text!)
                    
                    self.actuallyLogIn(email: emailField.text!)
                }))
                self.present(alert, animated: true)
                
                
            } else {
                actuallyLogIn(email: emailfromUsername)
            }
            
            return
        }
        
        actuallyLogIn(email: emailOrUsername!)
       
    }
    
    @IBAction func forgetPassword(_ sender: Any) {
        //RAWR
    }
    
    func actuallyLogIn(email: String) {
        
        Auth.auth().signIn(withEmail: email, password: passwordText.text!) { (user, error) in
            if (error != nil) {
                
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    
                    switch errCode {
                        
                    case AuthErrorCode.invalidEmail:
                        let alert = UIAlertController(title: "Invalid Email", message: "Invalid email format. Try again?", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        
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
                        print("Create User Error: \(String(describing: error))")
                    }
                    
                }
                
            } else {
                self.performSegue(withIdentifier: "LoginToMap", sender: nil)
                print ("cool")
            }
        }
        
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
