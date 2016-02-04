//
//  WorkItemCell.swift
//  VSTSV2
//
//  Created by Giorgio Balconi on 1/24/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import Foundation
import UIKit

class WorkItemCell : UITableViewCell {
    
    @IBOutlet weak var titleText: UILabel!
    
    @IBOutlet weak var detailText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}