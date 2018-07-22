//
//  ForgetPWViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 22/7/18.
//

import UIKit
import Firebase

class ForgetPWViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var emailText: UITextField!
    var email: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailText.delegate = self
        email = emailText.text!

        // Do any additional setup after loading the view.
    }
    
    // MARK: Actions
    @IBAction func sendForgetPWemail(_ sender: Any) {
        guard isValidEmail(testStr: emailText.text!) else {
            let alert = UIAlertController(title: "Invalid Email", message: "Try again?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if error == nil {
                let alert = UIAlertController(title: "Email Sent", message: "You might need to check your spam inbox.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else {
                print("error")
            }
        }
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    
}
