//
//  ViewController.swift
//  SwanServerLogic
//
//  Created by Leonardo Geus on 07/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import MapKit

class ViewController: UIViewController,UITextFieldDelegate {
    
    var logic = Logic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        getInfoOfWarehouses { (warehouses) in
            self.logic.wareHouses = warehouses
            
            self.receiveDataFromEntries { (entries) in
                for entry in entries {
                    self.resolveEntryLogs(entry: entry)
                }
            }
        }
        
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        textField.center = self.view.center
        self.view.addSubview(textField)
        textField.delegate = self
        textField.backgroundColor = UIColor.blue
        
        
        
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let db = Firestore.firestore()
        if textField.text != "" {
            var string = textField.text!
            let firstLetter = string.first!
            
            
            if firstLetter == "G" {
                
                //                let truck = Int(String(string[string.index(string.startIndex, offsetBy: 1)]))!
                //
                //                let warehouse = logic.wareHouses[Int(String(string[string.index(string.startIndex, offsetBy: 1)]))!]
                //                logic.moveTruck(truck: truck)
                
            }
            if firstLetter == "A" {
                let placa = String(string.prefix(8))
                db.collection("entries").addDocument(data:
                    ["truck":placa,"type":"arrivedInitial","way":["01C","02MA","05A"]])
            }
            if firstLetter == "L" {
                let start = string.index(string.startIndex, offsetBy: 1)
                let end = string.index(string.startIndex, offsetBy: 9)
                let range = start..<end
                
                let license = string[range]
                
                
                db.collection("entries").addDocument(data:
                    ["truck":license,"type":"finishLoading"])
            }
            logic.printWarehouses()
        }
        return true
    }
    
//    func getTrucks(warehouses:Warehouse,completion: @escaping (Bool) -> Void) {
//        let db = Firestore.firestore()
//
//        db.collection("truck").getDocuments { (snapshot, error) in
//            let snap = snapshot?.documents
//            var trucks = [Truck]()
//            for sn in snap! {
//                var name = ""
//                var local:Warehouse!
//                var way = [Warehouse]()
//                for (key, value) in sn.data() {
//                    if key == "name" {
//                        name = value as! String
//                    } else if key == "nextWarehouse" {
//                        if let value = value as? String {
//                            local = self.logic.getWarehouse(withName: value)
//                        }
//                    } else if key == "way" {
//                        let ways = value as! [String]
//                        for w in ways {
//                            let ware = self.logic.getWarehouse(withName: w)!
//                            way.append(ware)
//                        }
//                    }
//                }
//                let truck = Truck(name: name, local: local, way: <#T##[Warehouse]#>)
//                ware.logic = self.logic
//                warehouses.append(ware)
//            }
//            completion(warehouses)
//        }
//    }
    
    func getTruck(truck:String,completionFinal: @escaping (Truck) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("truck").document(truck).getDocument { (snapshot, error) in
            var license = truck
            var actualJourney = ""
            var status = ""
            var lastWarehouse:Warehouse!
            var way = [Warehouse]()
            for (key,value) in snapshot!.data()! {
                if key == "actualJourney" {
                    actualJourney = value as! String
                }
                if key == "status" {
                    status = value as! String
                }
                if key == "lastWarehouse" {
                    let lastWarehouseString = value as! String
                    lastWarehouse = self.logic.getWarehouse(withName: lastWarehouseString)
                }
                if key == "license" {
                    license = value as! String
                }
                if key == "way" {
                    let ways = value as! [String]
                    for w in ways {
                        let ware = self.logic.getWarehouse(withName: w)!
                        way.append(ware)
                    }
                }
            }
            let truck = Truck(name: license, local: lastWarehouse, way: way)
            completionFinal(truck)
        }
    }
    
    struct EntryLog {
        var id = ""
        var truck = ""
        var type = ""
        var way:[String]!
    }
    
    func receiveDataFromEntries(completion: @escaping ([EntryLog]) -> Void) {
        let db = Firestore.firestore()
        db.collection("entries").addSnapshotListener { (snapshot, error) in
            let documents = snapshot?.documentChanges
            var entries = [EntryLog]()
            for doc in documents! {
                let newDocument = doc.document
                let data = newDocument.data()
                var truck = ""
                var type = ""
                var warehouse = ""
                var id = newDocument.documentID
                var way = [String]()
                for (key,value) in data {
                    if key == "truck" {
                        truck = value as! String
                    }
                    if key == "type" {
                        type = value as! String
                    }
                    if key == "way" {
                        let ways = value as! [String]
                        for w in ways {
                            way.append(w)
                        }
                    }
                }
                entries.append(EntryLog(id:id,truck: truck, type: type,way:way))
            }
            completion(entries)
        }
        
    }
    
    var ids = [String]()
    
    func resolveEntryLogs(entry:EntryLog) {
        if !ids.contains(entry.id) {
            ids.append(entry.id)
            switch entry.type {
            case "arrivedInitial":
                let db = Firestore.firestore()
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                let dateString = dateFormatter.string(from: date)
                for ware in logic.wareHouses {
                    if ware.name == "Initial" {
                        ware.numberOfFutureAndPresentSpot =  ware.numberOfFutureAndPresentSpot + 1
                    }
                }
                var warehouses = [Warehouse]()
                for ware in entry.way {
                    if let warehouse = logic.getWarehouse(withName: ware) {
                        warehouses.append(warehouse)
                    }
                }
                
                if warehouses.count > 0 {
                    let truck = Truck(name: entry.truck, local: logic.getWarehouse(withName: "Initial")!, way: warehouses)
                    
                    let docID = db.collection("truck").document(entry.truck).collection("journeys").addDocument(data: ["startTime":dateString,"way":entry.way]).documentID
                    let nextPoint = logic.moveTruck(truck: truck)
                    
                    db.collection("truck").document(entry.truck).setData(["license":entry.truck,
                                                                          "status":"InJourney",
                                                                          "lastWarehouse":"Initial",
                                                                          "way":entry.way,
                                                                          "nextWarehouse":nextPoint.name,
                                                                          "actualJourney":docID])
                    
                } else {
                    print("Didn't find any warehouse in way, \(entry.truck) will be deleted on entries.")
                }
                db.collection("entries").document(entry.id).delete()

            case "finishLoading":
                let db = Firestore.firestore()
                
                db.collection("truck").document(entry.truck).getDocument { (snapshot, error) in
                    
                    if let _ = snapshot?.data() {
                        var lastLastWarehouse = ""
                        var way = [String]()
                        var nextWarehouse = ""
                        
                        for (key,value) in snapshot!.data()! {
                            if key == "way" {
                                let value = value as! [String]
                                way = value
                            }
                            if key == "lastWarehouse" {
                                let value = value as! String
                                lastLastWarehouse = value
                            }
                            if key == "nextWarehouse" {
                                let value = value as! String
                                nextWarehouse = value
                            }
                        }
                        
                        var warehouses = [Warehouse]()
                        for ware in way {
                            if ware != nextWarehouse {
                                warehouses.append(self.logic.getWarehouse(withName: ware)!)
                            }
                        }
                        
                        let truck = Truck(name: entry.truck, local: self.logic.getWarehouse(withName: nextWarehouse)!, way: warehouses)
                        let lastWarehouse = nextWarehouse
                        let nextPoint = self.logic.moveTruck(truck: truck)
                        
                        
                        var wares = [String]()
                        for wa in truck.way {
                            wares.append(wa.name)
                        }
                        
                        db.collection("truck").document(entry.truck)
                            .updateData(["lastWarehouse":lastWarehouse,"nextWarehouse":nextPoint.name,"way":wares])
                        db.collection("entries").document(entry.id).delete()
                        
                        

                    } else {
                        print("Impossible to find")
                    }
                }
            default:
                break
            }
        }
    }
    
    
    func updateNextLocal(truck:Truck,warehouse:Warehouse,completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("truck").document(truck.name).updateData(["nextLocal":warehouse.name]) { (error) in
            if let _ = error {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func getInfoOfWarehouses(completion: @escaping ([Warehouse]) -> Void) {
        
        let db = Firestore.firestore()
        db.collection("warehouse").getDocuments { (snapshot, error) in
            let snap = snapshot?.documents
            var warehouses = [Warehouse]()
            for sn in snap! {
                var name = ""
                var numberOfSpots = 0
                var numberOfSpotsFull = 0
                var position: GeoPoint!
                for (key, value) in sn.data() {
                    if key == "name" {
                        name = value as! String
                    } else if key == "numberOfSpots" {
                        if let value = value as? Int {
                            numberOfSpots = value
                        }
                        
                    } else if key == "numberOfSpotsFull" {
                        if let value = value as? Int {
                            numberOfSpotsFull = value
                        }
                    } else if key == "position" {
                        if let value = value as? GeoPoint {
                            position = value
                        }
                    }
                }
                let ware = Warehouse(name: name, position: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude), numberOfSpots: numberOfSpots,numberOfSpotsFull:numberOfSpotsFull)
                ware.logic = self.logic
                warehouses.append(ware)
            }
            completion(warehouses)
        }
    }
    
}

