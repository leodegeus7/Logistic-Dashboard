//
//  Truck.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 02/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit

class Truck: NSObject {
    var license = ""
    var actualJourney:Journey!
    
    init(license:String,actualJourney:Journey) {
        self.license = license
        self.actualJourney = actualJourney
    }
    
}
