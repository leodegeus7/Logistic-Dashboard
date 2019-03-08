//
//  Warehouse.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 01/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit
import MapKit


class Warehouse {
    var name:String
    var position:CLLocationCoordinate2D
    
    init(name:String,position:CLLocationCoordinate2D,numberOfSpots:Int) {
        self.name = name
        self.position = position
    }
}
