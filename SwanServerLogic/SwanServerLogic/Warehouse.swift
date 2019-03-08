//
//  Warehouse.swift
//  SwanServerLogic
//
//  Created by Leonardo Geus on 07/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class Warehouse {
    var logic:Logic!
    var name:String
    var position:CLLocationCoordinate2D
    var numberOfSpots = 0
    var numberOfFutureAndPresentSpot = 0
    var spotsTotal = 0
    var trucks = [Truck]()
    
    init(name:String,position:CLLocationCoordinate2D,numberOfSpots:Int,numberOfSpotsFull:Int) {
        self.name = name
        self.position = position
        self.numberOfSpots = numberOfSpots
        self.numberOfFutureAndPresentSpot = numberOfSpotsFull
    }

    func rentLocal(truck:Truck) {
        numberOfFutureAndPresentSpot = numberOfFutureAndPresentSpot + 1
        let db = Firestore.firestore()
        db.collection("warehouse").document(name).updateData(["numberOfSpotsFull":numberOfFutureAndPresentSpot])
        trucks.append(truck)
        print("Truck \(truck.name) rent \(name)")
    }
    
    func arrivedOneTruck() {
        
    }
    
    func leavedOneTruck(truck:Truck) {
        print("Truck \(truck.name) leaved in \(name)")
        truck.way.removeAll(where: {$0.name == truck.local.name})
        numberOfFutureAndPresentSpot = numberOfFutureAndPresentSpot - 1
        if trucks.contains(where: {$0.name == truck.name}) {
           trucks.removeAll(where: {$0.name == truck.name})
        }
        logic.oneTruckLeavedWarehouse()
        let db = Firestore.firestore()
        db.collection("warehouse").document(name).updateData(["numberOfSpotsFull":numberOfFutureAndPresentSpot])
    }
}

