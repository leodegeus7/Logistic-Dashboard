//
//  FirestoreDatabase.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 01/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import MapKit

class FirestoreDatabase: NSObject {
    
    static let shared = FirestoreDatabase()
    var wareHouses = [Warehouse]()
    
    func getWarehouses(completionHandler: @escaping ([Warehouse]?) -> Void) {
        let db = Firestore.firestore()
        db.collection("warehouse").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completionHandler(nil)
            } else {
                var warehouses = [Warehouse]()
                for document in querySnapshot!.documents {
                    var name = ""
                    var point2D:CLLocationCoordinate2D!
                    var numberOfSpots = 0
                    for dat in document.data() {
                        if dat.key == "name" {
                            name = dat.value as! String
                        }
                        if dat.key == "position" {
                            let point = dat.value as! GeoPoint
                            point2D = CLLocationCoordinate2D(latitude: (point.latitude), longitude: (point.longitude))
                        }
                        if dat.key == "numberOfSpots" {
                            numberOfSpots = (dat.value as? Int)!
                        }
                        
                    }
                    let warehouse = Warehouse(name: name, position: point2D, numberOfSpots: numberOfSpots)
                    warehouses.append(warehouse)
                }
                self.wareHouses = warehouses
                completionHandler(warehouses)
            }
        }
    }
    
    func updateCoord(truck:Truck,location:CLLocation) {
        let db = Firestore.firestore()
        db.collection("truck").document(truck.license).updateData(["lastLocation":GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),"lastUpdateLocation":location.timestamp])
    }
    
    
    func updateTruck(truck:Truck,completionHandler: @escaping (Journey?) -> Void) {
        let db = Firestore.firestore()
        var entries = [String]()
        for entry in truck.actualJourney.way {
            entries.append(entry.name)
            
        }
        let id = db.collection("entries").addDocument(data:
            ["truck":truck.license,"type":"arrivedInitial","way":entries]).documentID
        
        let journey = Journey(id: id, way: truck.actualJourney.way)
        completionHandler(journey)
        
    }
    
    func moveTruck(truck:Truck,actualLocal:Warehouse,completionHandler: @escaping (Journey) -> Void) {
        let db = Firestore.firestore()
        let journey = truck.actualJourney
        journey?.way.removeAll(where: {$0.name == actualLocal.name})
        let id = db.collection("entries").addDocument(data:
            ["truck":truck.license,"type":"arrivedWarehouse"]).documentID
        
        completionHandler(journey!)
        
    }
    
    func findWarehouse(withName:String) -> Warehouse? {
        return wareHouses.first(where: {$0.name == withName})
    }
    
    var listener:ListenerRegistration!
    
    func getNextPoint(truck:Truck,completionHandler: @escaping (String?,String?) -> Void) {
        let db = Firestore.firestore()
        
        listener = db.collection("truck").document(truck.license).addSnapshotListener { (snapshot, error) in
            var next = ""
            var last = ""
            if let data = snapshot?.data() {
                if let _ = data["nextWarehouse"] as? String {
                    for (key,value) in data {
                        
                        if key == "nextWarehouse" {
                            next = value as! String
                        }
                        if key == "lastWarehouse" {
                            last = value as! String
                        }
                    }
                    self.listener.remove()
                    completionHandler(last,next)
                }
                
            }
            
        }
    }
    
    
}
