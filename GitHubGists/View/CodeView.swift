//
//  CodeLabel.swift
//  GitHubGists
//
//  Created by Eugene Ar on 27/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import UIKit

class CodeView: UIView {
    
    override func awakeFromNib() {
        self.layer.borderWidth = 1.0
        self.layer.borderColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        self.layer.cornerRadius = 5.0
    }
    
}
