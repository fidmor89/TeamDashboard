//
//  Utils.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 3/10/16.
//  Copyright © 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import Foundation

extension String
{
    func trim() -> String
    {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}