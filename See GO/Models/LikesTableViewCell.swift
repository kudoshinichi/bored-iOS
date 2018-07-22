//
//  LikesTableViewCell.swift
//  See GO
//
//  Created by Hongyi Shen on 15/7/18.
//

import UIKit

class LikesTableViewCell: UITableViewCell {

    //MARK: Properties
    @IBOutlet weak var storyImage: UIImageView!
    @IBOutlet weak var hookText: UILabel!
    @IBOutlet weak var viewText: UILabel!
    @IBOutlet weak var voteText: UILabel!
    
    
    func load(storyKey:String){
        print(storyKey)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
