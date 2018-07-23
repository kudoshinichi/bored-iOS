//
//  LikesTableViewCell.swift
//  See GO
//
//  Created by Hongyi Shen on 15/7/18.
//

import UIKit
import Firebase
import FirebaseUI

class LikesTableViewCell: UITableViewCell {

    //MARK: Properties
    @IBOutlet weak var storyImage: UIImageView!
    @IBOutlet weak var viewText: UILabel!
    @IBOutlet weak var voteText: UILabel!
    @IBOutlet weak var hookText: UITextView!
    
    var storyKey: String = ""
    
    
    func load(storyKey:String){
        print(storyKey)
        self.storyKey = storyKey
        print(self.storyKey)
        
        getInfoFromDatabase{ (success) -> Void in
            if success {
                self.loadImage()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func getInfoFromDatabase(completion: @escaping (_ success: Bool) -> Void) {
        let ref = Database.database().reference()
        ref.child("stories").child(self.storyKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let hookText = (snapshot.value as? NSDictionary)?["Keywords"] as! String
            let viewText = (snapshot.value as? NSDictionary)?["Views"] as! Int
            let voteText = (snapshot.value as? NSDictionary)?["Votes"] as! Int
            
            completion(true)
            
            self.hookText.text = hookText
            self.viewText.text = String(viewText)
            self.voteText.text = String(voteText)
        })
    }
    
    func loadImage() {
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
