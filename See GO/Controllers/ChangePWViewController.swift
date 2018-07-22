//
//  ChangePWViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 22/7/18.
//

import UIKit
import Firebase

class ChangePWViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var oldPW: UITextField!
    @IBOutlet weak var newPW: UITextField!
    
    // Authentication
    var oldPassword : String = ""
    var newPassword: String = ""
    var email: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.email = user.email!
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
        
        oldPW.delegate = self
        newPW.delegate = self
    }
    
    //MARK: Actions
    @IBAction func changePW(_ sender: Any) {
        //oldPassword = oldPW.text!
        //newPassword = newPW.text!
        
        guard oldPW.text! == "", newPW.text! == "" else {
            let alert = UIAlertController(title: "Missing fields", message: "Check again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        guard isValidPassword(testStr: newPW.text!) else {
            print(newPW.text!)
            let alert = UIAlertController(title: "Invalid Password", message: "Please create passwords with at least 8 characters, one letter and one number.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        Auth.auth().currentUser?.updatePassword(to: newPW.text!) { (error) in
            if (error != nil){
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    if errCode == AuthErrorCode.requiresRecentLogin{
                        //reauthenticate
                        let user = Auth.auth().currentUser
                        var credential: AuthCredential
                        
                        credential = EmailAuthProvider.credential(withEmail: self.email, password: self.oldPW.text!)
                        user?.reauthenticateAndRetrieveData(with: credential)
                    }
                }
            } else {
                let alert = UIAlertController(title: "Password Change Success", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Thanks", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func isValidPassword(testStr:String?) -> Bool {
        guard testStr != nil else { return false }
        // at least one digit && at least one lowercase && 8 characters total
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "(?=.*[0-9])(?=.*[a-z]).{8,}")
        return passwordTest.evaluate(with: testStr)
    }
    

    

}
