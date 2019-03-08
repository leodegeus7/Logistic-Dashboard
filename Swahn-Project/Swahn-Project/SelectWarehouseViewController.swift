//
//  SelectWarehouseViewController.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 31/07/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit

class SelectWarehouseViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var selectWarehouseLabel: UILabel!
    @IBOutlet weak var viewBottomX: UIView!
    @IBOutlet weak var warehouseCollectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backTop: UIView!
    
    var selectedItems = [Int]()
    
    var license = ""
    
    var warehouses = [Warehouse]()
    var actualJourney:Journey!
    override func viewDidLoad() {
        super.viewDidLoad()
        activityindicator(on: true)
        FirestoreDatabase.shared.getWarehouses { (warehouses) in
            self.activityindicator(on: false)
            if let whouses = warehouses,whouses.count > 0 {
                var newWh = whouses
                newWh.removeAll(where: {$0.name == "Initial" || $0.name == "Final" || $0.name == "Line"})
                
                self.warehouses = newWh
                self.warehouseCollectionView.reloadData()
            }
        }
        
        self.warehouseCollectionView.delegate = self
        self.warehouseCollectionView.dataSource = self
        self.warehouseCollectionView.backgroundColor = UIColor(red: 1/255, green: 53/255, blue: 101/255, alpha: 1)
        nextButton.setTitleColor(UIColor.white, for: .normal)
        nextButton.backgroundColor = UIColor(red: 0/255, green: 130/255, blue: 250/255, alpha: 1)
        viewBottomX.backgroundColor = UIColor(red: 0/255, green: 130/255, blue: 250/255, alpha: 1)
        
        selectWarehouseLabel.textColor = UIColor.white
        backTop.backgroundColor = UIColor(red: 0/255, green: 65/255, blue: 124/255, alpha: 1)
        self.view.backgroundColor = UIColor(red: 0/255, green: 65/255, blue: 124/255, alpha: 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return warehouses.count
    }
    
    var buttonClicked = false
    
    @IBAction func nextButtonTap(_ sender: Any) {
        if !buttonClicked {
            buttonClicked = true
            if selectedItems.count > 0 {
                self.createAlert(msg: "Entregue o dispositivo para o caminhoneiro e clique no botão iniciar.", cancel: false, cancelAction: { (alert) in
                    self.buttonClicked = false
                }) { (bool) in
                    let warehouses = self.getWarehousesWithSelectedItems()
                    
                    let truck = Truck(license: self.license, actualJourney: Journey(way: warehouses))
                    self.activityindicator(on: true)
                    
                    FirestoreDatabase.shared.updateTruck(truck: truck) { (journey) in
                        self.activityindicator(on: false)
                        if let _ = journey {
                            FirestoreDatabase.shared.getNextPoint(truck: truck, completionHandler: { (lastWarehouse,nextWarehouse) in
                                self.nextWarehouse = FirestoreDatabase.shared.findWarehouse(withName: nextWarehouse!)!
                                self.lastWarehouse = FirestoreDatabase.shared.findWarehouse(withName: lastWarehouse!)!
                                self.truck = truck
                                self.actualJourney = journey
                                self.performSegue(withIdentifier: "showNavigation", sender: self)
                            })
                        } else {
                            self.createAlert(msg: "Problema ao adquirir sua rota, porfavor, contate um administrador", cancel: true, cancelAction: nil, completionHandler: { (bool) in
                            })
                            self.buttonClicked = false
                        }
                    }
                }
            }
        }
    }
    
    func removeData() {
        
    }
    
    var nextWarehouse:Warehouse!
    var lastWarehouse:Warehouse!
    var truck:Truck!
    
    func createAlert(msg:String,cancel:Bool,cancelAction:((UIAlertAction) -> Void)?,completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: cancelAction))
        if !cancel {
            alert.addAction(UIAlertAction(title: "Iniciar", style: .default, handler: { (alert) in
                completionHandler(true)
            }))
        }
        self.present(alert, animated: true)
    }
    
    var activityIndicator:UIActivityIndicatorView!
    func activityindicator(on:Bool) {
        if let _ = activityIndicator {
            
        } else {
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            activityIndicator.color = UIColor.black
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
    
    func getWarehousesWithSelectedItems() -> [Warehouse] {
        var ware = [Warehouse]()
        for int in selectedItems {
            ware.append(warehouses[int-1])
        }
        return ware
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNavigation" {
            var labels = [String]()
            for item in selectedItems {
                labels.append(warehouses[item - 1].name)
            }
            let controller = segue.destination as? MainViewController
            controller!.actualJourney = actualJourney
            controller?.nextWarehouse = nextWarehouse
            controller?.lastWarehouse = lastWarehouse
            controller?.truck = truck
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WarehouseCell", for: indexPath) as? SelectWarehouseCollectionViewCell
        cell?.numberWarehouseLabel.text = warehouses[indexPath.row].name
        cell?.backView.backgroundColor = UIColor(red: 17/255, green: 65/255, blue: 113/255, alpha: 1)
        
        cell?.numberWarehouseLabel.textColor = UIColor.white
        cell?.warehouseLabel.textColor = UIColor.white
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width)
        let height:CGFloat = 100.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? SelectWarehouseCollectionViewCell
        if selectedItems.contains(indexPath.row + 1) {
            cell?.backView.backgroundColor = UIColor(red: 17/255, green: 65/255, blue: 113/255, alpha: 1)
            
            selectedItems.remove(at: findIndexOf(indexPath.row + 1))
        } else {
            cell?.backView.backgroundColor = UIColor(red: 111/255, green: 159/255, blue: 193/255, alpha: 1)
            selectedItems.append(indexPath.row + 1)
        }
        
        
    }
    
    func findIndexOf(_ int:Int) -> Int {
        var count = 0
        for item in selectedItems {
            if int == item {
                break
            }
            count = count + 1
        }
        return count
    }
    
}
