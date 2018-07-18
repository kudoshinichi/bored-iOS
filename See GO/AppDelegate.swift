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
import FirebaseStorageUI
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyAGchByNHI_1ZdxX6fxju2Tdj3Y6iJPvwk")
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        let user = Auth.auth().currentUser;
        let userSignedIn: Bool = (user != nil)
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if userSignedIn{
            let mapScreen = storyBoard.instantiateViewController(withIdentifier: "MapViewNavControl")
            self.window?.rootViewController = mapScreen
            
        } else {
            let signupScreen = storyBoard.instantiateViewController(withIdentifier: "SignUpVC")
            self.window?.rootViewController = signupScreen
        }
        
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        
        return true
    }
    
    //Google Sign In
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            // ...
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // ...
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                // ...
                return
            }
            // User is signed in
            // ...
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }

}

