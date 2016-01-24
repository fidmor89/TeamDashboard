//
//  PickProjectViewController.swift
//  VSTSV2
//
//  Created by Giorgio Balconi on 1/23/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import UIKit

class PickProjectViewController: UIViewController {
    @IBOutlet weak var btnPickProject: UIButton!
    
    
    @IBAction func dismissModal(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}