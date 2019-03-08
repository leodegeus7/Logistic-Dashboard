//
//  Journey.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 02/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit

class Journey: NSObject {
    var way = [Warehouse]()
    var id = ""
    
    init(id:String,way:[Warehouse]) {
        self.id = id
        self.way = way
    }
    
    init(way:[Warehouse]) {
        self.way = way
    }
}
