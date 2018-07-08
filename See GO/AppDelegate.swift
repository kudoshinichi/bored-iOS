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
//import FirebaseAuthUI
//import FirebaseGoogleAuthUI
import FirebaseStorageUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyAGchByNHI_1ZdxX6fxju2Tdj3Y6iJPvwk")
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        return true
    }

}

