//
//  gistTableViewCell.swift
//  GitHubGists
//
//  Created by Eugene Ar on 24/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import UIKit

class GistTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var gistDescriptionLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
