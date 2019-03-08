//
//  Truck.swift
//  SwanServerLogic
//
//  Created by Leonardo Geus on 07/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit

class Truck {
    var name:String
    var local:Warehouse
    var way:[Warehouse]
    
    init(name:String,local:Warehouse,way:[Warehouse]) {
        self.name = name
        self.local = local
        self.way = way
    }
    
    func printTruck() {
        var str = ""
        for wa in way {
            str += " \(wa.name)"
        }
        
        print("\(self.name)  -   \(self.local)    -\(str)")
    }
}
