//
//  Logic.swift
//  SwanServerLogic
//
//  Created by Leonardo Geus on 07/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit
import Firebase

class Logic: NSObject {
    var wareHouses = [Warehouse]()
    var trucks = [Truck]()
    
    var line = [Truck]()
    
    override init() {
        super.init()
    }
    
    func moveTruck(truck:Truck) -> Warehouse {
        
        if !trucks.contains(where: {$0.name == truck.name}) {
            trucks.append(truck)
        } else {
            trucks.removeAll(where: {$0.name == truck.name})
            trucks.append(truck)
        }
        
        let warehouse = getWarehouse(withName: truck.local.name)
        warehouse?.leavedOneTruck(truck: truck)
        if truck.way.count == 0 {
            sendTruckToFinal(truck: truck)
            return getWarehouse(withName: "Final")!
        } else {
            let betterPoint = getBetterPoint(truck: truck)
            if let betterPoint = betterPoint {
                if truck.local.name == "Line" {
                    let db = Firestore.firestore()
                    
                    var wares = [String]()
                    for wa in truck.way {
                        wares.append(wa.name)
                    }
                    
                    db.collection("truck").document(truck.name).updateData(["license":truck.name,
                                                                          "status":"InJourney",
                                                                          "lastWarehouse":"Line",
                                                                          "way":wares,
                                                                          "nextWarehouse":betterPoint.name,
                                                                     ])
                }
                betterPoint.rentLocal(truck: truck)
                truck.local = betterPoint

                return betterPoint
            } else {
                
                if truck.local.name != "Line" {
                    sendTruckToLine(truck: truck)
                }
                return getWarehouse(withName: "Line")!
            }
        }
    }
    

    func sendTruckToFinal(truck:Truck) {
        let final = getWarehouse(withName: "Final")!
        final.rentLocal(truck: truck)
        truck.local = final
    }
    
    func sendTruckToLine(truck:Truck) {
        let line = getWarehouse(withName: "Line")!
        line.rentLocal(truck: truck)
        truck.local = line
    }
    
    func oneTruckLeavedWarehouse() {
        for truck in getWarehouse(withName: "Line")!.trucks {
            moveTruck(truck: truck)
        }
    }
    
    
    func getWarehouse(withName:String) -> Warehouse? {
        for warehouse in wareHouses {
            if warehouse.name == withName {
                return warehouse
            }
        }
        return nil
    }
    
    func printWarehouses() {
        var str = ""
        for warehouse in wareHouses {
            str = str + " \(warehouse.name):\(warehouse.numberOfFutureAndPresentSpot)/\(warehouse.numberOfSpots) "
        }
        print(str)
    }
    
    func getBetterDistanceWarehouse(truck:Truck,warehouses:[Warehouse]) -> Warehouse? {
        var betterPoint:Warehouse!
        if truck.way.count > 0 {
            for point in warehouses {
                if point.name != truck.local.name {
                    if let _ = betterPoint {
                    } else {
                        betterPoint = point
                    }
                    if getDistanceBetween(point1: truck.local, point2: point) < getDistanceBetween(point1: truck.local, point2: betterPoint) {
                        betterPoint = point
                    }
                }
            }
            if let _ = betterPoint {
                return betterPoint
            } else {
                return nil
            }
            
        } else {
            return nil
        }
    }
    
    func getDistanceBetween(point1: Warehouse, point2: Warehouse) -> Double {
        let x1 = point1.position.latitude
        let y1 = point2.position.longitude
        
        let x2 = point2.position.latitude
        let y2 = point2.position.longitude
        
        return Double(sqrt(pow((x1-x2), 2.0) + pow((y1-y2), 2.0)))
    }
    
    func getFreeWarehouses() -> [Warehouse] {
        var points = [Warehouse]()
        for warehouse in wareHouses {
            if testIfThereIsFutureSpaceInWarehouse(wareHouse: warehouse) {
                points.append(warehouse)
            }
        }
        return points
    }
    
    func testIfThereIsFutureSpaceInWarehouse(wareHouse:Warehouse) -> Bool {
        if wareHouse.numberOfFutureAndPresentSpot < wareHouse.numberOfSpots {
            return true
        } else {
            return false
        }
    }
    
    func getBetterPoint(truck:Truck) -> Warehouse? {
        if truck.way.count > 0 {
            let way = truck.way
            var points = [Warehouse]()
            let freePoints = getFreeWarehouses()
            for point in way {
                if freePoints.contains(where: {$0.name == point.name}) {
                    points.append(point)
                }
            }
            if points.count > 0 {
                return getBetterDistanceWarehouse(truck: truck, warehouses: points)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func addTruck(truck:Truck) {
        if !trucks.contains(where: {$0.name == truck.name}) {
            trucks.append(truck)
        }
        getWarehouse(withName: "Initial")!.numberOfFutureAndPresentSpot = getWarehouse(withName: "Initial")!.numberOfFutureAndPresentSpot + 1
    }
    
}
