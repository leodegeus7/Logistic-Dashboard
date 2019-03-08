//
//  MainViewController.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 01/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftyJSON
import CoreLocation

class MainViewController: UIViewController,GMSMapViewDelegate{
    
    @IBOutlet weak var mapViewBack: UIView!
    @IBOutlet weak var nextWarehouseLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timePastLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var warehouseStatusLabel: UILabel!
    
    var locationManager:CLLocationManager!
    var totalSeconds = 5400.0
    var nextWarehouse:Warehouse!
    var lastWarehouse:Warehouse!
    var mapView:GMSMapView!
    var actualJourney:Journey!
    var truck:Truck!
    var totalJourney = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.startUpdatingLocation()
        }
        
        startTimer()
        self.speedLabel.text = "- km/h"
        self.distanceLabel.text = "- m"
        totalJourney = actualJourney.way.count
        self.warehouseStatusLabel.text = "0/\(actualJourney.way.count)"
    }
    
    var mapIsLoaded = false
    
    override func viewDidLayoutSubviews() {
        if !mapIsLoaded {
            mapIsLoaded = true
            self.loadMapView()
            if let next = nextWarehouse {
                if let last = lastWarehouse {
                    self.drawWay(wareHouse1: last, wareHouse2: next)
                }
            }
        }
    }
    
    func startTimer() {
        TimerSingleton.shared.startTimer { (seconds) in
            self.updateTimerLabel(seconds: seconds)
            let differenceTime = self.updateMissingTimeLabel(timerSeconds: seconds)
            if differenceTime < 1 {
                TimerSingleton.shared.stopTimer()
            }
        }
    }
    
    func updateTimerLabel(seconds:Double) {
        let time = getStringTimeWithSeconds(seconds: seconds)
        self.timePastLabel.text = time
    }
    
    func updateMissingTimeLabel(timerSeconds:Double) -> Int {
        let differenceTime = totalSeconds - timerSeconds
        let time = getStringTimeWithSeconds(seconds: differenceTime)
        self.timeLabel.text = time
        return Int(differenceTime)
    }
    
    func transformIntToStringHour(int:Int) -> String {
        if int >= 0 && int <= 9 {
            return "0\(int)"
        } else {
            return "\(int)"
        }
    }
    
    func getStringTimeWithSeconds(seconds:Double) -> String {
        var secondsAux = 0
        var minutes = 0
        var hours = 0
        if seconds >= 3600 {
            hours = Int(Double(seconds)/3600.0)
            minutes = Int((Double(seconds) - Double(hours)*3600)/60)
            secondsAux = Int((Double(seconds) - Double(hours)*3600 - Double(minutes)*60))
        } else if seconds >= 60 && seconds < 3600 {
            minutes = Int((Double(seconds))/60)
            secondsAux = Int((Double(seconds) - Double(minutes)*60))
        } else {
            secondsAux = Int(seconds)
        }
        return "\(self.transformIntToStringHour(int: hours)):\(self.transformIntToStringHour(int: minutes)):\(self.transformIntToStringHour(int: secondsAux))"
        
    }
    
    func loadMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 22.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = self
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                print("Unable to find style")
            }
        } catch {
            print("One or more of the map styles failed to load. \(error)")
        }
        if let _ = mapViewBack {
            mapView.frame = mapViewBack.frame
            mapView.center = mapViewBack.center
            view.addSubview(mapView)
        }
        
        let heightButton:CGFloat = 40.0
        let widthButton:CGFloat = 120.0
        let button = UIButton(frame: CGRect(x: mapView.center.x + mapView.frame.width / 2.0 - widthButton - 20.0, y: mapView.center.y + mapView.frame.height / 2.0 - heightButton - 20.0, width: widthButton, height: heightButton))
        button.setTitle("NAVEGAR", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor(red: 71/255, green: 163/255, blue: 142/255, alpha: 1)
        button.layer.cornerRadius = button.frame.height/2.0
        button.addTarget(self, action: #selector(MainViewController.openWaze), for: .touchUpInside)
        view.addSubview(button)
        
    }
    
    @objc func openWaze() {
        
        if UIApplication.shared.canOpenURL(URL(string:"waze://")!) {
            let urlString = "waze://?ll=\(nextWarehouse.position.latitude),\(nextWarehouse.position.longitude)&navigate=yes"
            let url = URL(string:urlString)
            UIApplication.shared.open(url!, options: [:]) { (bool) in
                if bool {
                    
                } else {
                    self.createAlert(text: "Não foi possível abrir o waze, porfavor contate um desenvolvedor")
                }
            }
        } else {
            let url = URL(string:"http://itunes.apple.com/us/app/id323229106")
            UIApplication.shared.open(url!, options: [:]) { (bool) in
                if bool {
                    
                } else {
                    self.createAlert(text: "Não foi possível abrir o link da loja, porfavor contate um desenvolvedor")
                }
            }
        }
    }
    
    func createAlert(text:String) {
        let alert = UIAlertController(title: "", message: text, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    
    @objc func nextButtonTap() {
        self.activityindicator(on: true)
        FirestoreDatabase.shared.moveTruck(truck: truck, actualLocal: nextWarehouse) { (journey) in
            self.activityindicator(on: false)
            FirestoreDatabase.shared.getNextPoint(truck: self.truck, completionHandler: { (lastWarehouse,nextWarehouse) in
                
                self.nextWarehouse = FirestoreDatabase.shared.findWarehouse(withName: nextWarehouse!)!
                self.lastWarehouse = FirestoreDatabase.shared.findWarehouse(withName: lastWarehouse!)!
                
                if self.nextWarehouse.name == "Line" {
                    self.nextWarehouseLabel.text = "Fila"
                    self.mapView.isHidden = true
                    
                } else {
                    self.nextWarehouseLabel.text = self.nextWarehouse.name
                    self.warehouseStatusLabel.text = "\(journey.way.count)/\(self.totalJourney)"
                    self.actualJourney = journey
                    
                    if let next = self.nextWarehouse {
                        if let last = self.lastWarehouse {
                            self.drawWay(wareHouse1: last, wareHouse2: next)
                        }
                    }
                }
            })
            
        }
        
    }
    
    var activityIndicator:UIActivityIndicatorView!
    func activityindicator(on:Bool) {
        if let _ = activityIndicator {
            
        } else {
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            activityIndicator.color = UIColor.white
            activityIndicator.center = self.view.center
            activityIndicator.startAnimating()
            
        }
        if on {
            self.view.addSubview(activityIndicator)
            self.view.isUserInteractionEnabled = false
        } else {
            activityIndicator.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func getPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D){
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&key=AIzaSyBOAsoK8pPn7GisQmMf6lMW6QqmKZSYNbs")!
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }else{
                do {
                    let json = try JSON(data: data!)
                    let routes = json["routes"].arrayValue
                    for route in routes
                    {
                        let routeOverviewPolyline = route["overview_polyline"].dictionary
                        let points = routeOverviewPolyline?["points"]?.stringValue
                        self.showPath(polyStr: points!)
                    }
                } catch {
                    
                }
            }
        })
        task.resume()
    }
    
    func showPath(polyStr :String){
        DispatchQueue.main.async {
            let path = GMSPath(fromEncodedPath: polyStr)
            let polyline = GMSPolyline(path: path)
            
            polyline.strokeColor = UIColor(red: 71/255, green: 163/255, blue: 142/255, alpha: 1)
            polyline.strokeWidth = 3.0
            polyline.map = self.mapView
        }
    }
    
    func drawWay(wareHouse1:Warehouse,wareHouse2:Warehouse) {
        nextWarehouseLabel.text = "DOCA \(wareHouse2.name)"
        mapView.clear()
        let color = UIColor(red: 87/255, green: 123/255, blue: 115/255, alpha: 1)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 13, height: 13))
        view.backgroundColor = color
        view.layer.cornerRadius = view.frame.width / 2.0
        
        let shadowLayer = CAShapeLayer()
        
        shadowLayer.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        shadowLayer.fillColor = color.cgColor
        
        shadowLayer.shadowColor = color.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        shadowLayer.shadowOpacity = 1
        shadowLayer.shadowRadius = 10
        
        view.layer.insertSublayer(shadowLayer, at: 0)
        
        
        let pos1 = wareHouse1.position
        let pos2 = wareHouse2.position
        let marker = GMSMarker()
        marker.position = pos1
        marker.iconView = view
        marker.title = wareHouse1.name
        marker.map = mapView
        
        let marker2 = GMSMarker()
        marker2.position = pos2
        marker2.iconView = view
        marker2.title = wareHouse2.name
        marker2.map = mapView
        getPolylineRoute(from: pos1, to: pos2)
        mapView.camera = GMSCameraPosition.camera(withLatitude: pos1.latitude, longitude: pos1.longitude, zoom: 15.0)
        
        mapView.selectedMarker = marker2
        
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        let label  = UILabel(frame: view.frame)
        label.text = marker.title
        label.textColor = UIColor.white
        
        view.center = label.center
        view.addSubview(label)
        
        return view
    }
    
    @IBAction func nextWarehouseTap(_ sender: Any) {
        nextButtonTap()
    }
    var lastLocal:CLLocation!
}

extension MainViewController:CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let _ = lastLocal {
            
        } else {
            lastLocal = locations[0]
        }
        
        
        if let first = locations.first {
            
            if lastLocal.coordinate.longitude != first.coordinate.longitude || lastLocal.coordinate.latitude != first.coordinate.latitude {
                
                var speed: CLLocationSpeed = CLLocationSpeed()
                speed = (locations[0].speed)
                if speed < 0 {
                    speed = 0
                }
                
                self.speedLabel.text = String(format: "%.0f km/h", speed * 3.6)
                if let _ = nextWarehouse {
                    let destionation = CLLocation(latitude: nextWarehouse.position.latitude, longitude: nextWarehouse.position.longitude)
                    let distance = destionation.distance(from: locations[0] as CLLocation)
                    
                    self.distanceLabel.text = String(format: "%.0f km", distance/1000.0)
                }
                
                FirestoreDatabase.shared.updateCoord(truck: truck, location: first)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != CLAuthorizationStatus.denied {
            locationManager.startUpdatingLocation()
        }
    }
}
