//
//  ShowStoryController.swift
//  See GO
//
//  Created by Hongyi Shen on 14/6/18.
//

import UIKit

class ShowStoryController: UIViewController {

    //MARK: Properties
    var storyKey: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("hi" + storyKey)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
