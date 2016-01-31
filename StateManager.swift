//
//  StateManager.swift
//  VSTSV2
//
//  Created by Fidel Esteban Morales Cifuentes on 1/31/16.
//  Copyright (c) 2016 Fidel Esteban Morales Cifuentes. All rights reserved.
//

import Foundation

class StateManager {
    
    //Singleton
    static let SharedInstance = StateManager()

    //Properties
    var team : TeamProject = TeamProject()
    var changed: Bool = false
}