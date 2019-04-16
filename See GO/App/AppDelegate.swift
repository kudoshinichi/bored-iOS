//
//  AppDelegate.swift
//  See GO
//
//  Created by Hongyi Shen on 5/6/18.
//

import UIKit
import GoogleMaps
import Firebase
import FirebaseDatabase
import FirebaseUI
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    var handle: AuthStateDidChangeListenerHandle?

    var window: UIWindow?
    
    //Google Sign In + Database
    var uid: String = ""
    var email: String = ""
    var userRef : DatabaseReference!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        GMSServices.provideAPIKey(Constants.APIkey)
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        
        return true
    }
    
    //Google Sign In
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
            
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            print(error)
            
            return
        }
        
        guard let authentication = user.authentication else { return }
        
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // ...
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                print(authResult!)
                print(error)
                return
            }
            
            let googleSignInBefore = UserDefaults.standard.bool(forKey: "googleSignInBefore")
            
            if (!googleSignInBefore){
                self.handle = Auth.auth().addStateDidChangeListener { (auth, user) in
                    // User is signed in
                    if let user = user {
                        self.uid = user.uid
                        self.email = user.email!
                        
                        print(self.uid)
                        print(self.email)
                    }
                    
                    let thisUser = userItem(admin: false, username: "name", uid: self.uid, flagothers: 0)
                    self.userRef = Database.database().reference(withPath: "users")
                    self.userRef.child(self.uid).updateChildValues(thisUser.toAnyObject() as! [AnyHashable : Any])
                    
                    UserDefaults.standard.set(true, forKey: "googleSignInBefore")
                }
            }
            
            // Opens up map
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let mapScreen = storyBoard.instantiateViewController(withIdentifier: "MapViewNavControl")
            self.window?.rootViewController = mapScreen
        }
        
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }

}

