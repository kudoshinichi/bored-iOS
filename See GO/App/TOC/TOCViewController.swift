//
//  TOCViewController.swift
//  See GO
//
//  Created by Hongyi Shen on 24/7/18.
//
// Save to database?

import UIKit

class TOCViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func acceptTOC(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "acceptedTOC")
    }
    
}
