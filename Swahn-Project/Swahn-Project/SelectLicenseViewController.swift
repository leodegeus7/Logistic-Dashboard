//
//  SelectLicenseViewController.swift
//  Swahn-Project
//
//  Created by Leonardo Geus on 13/08/2018.
//  Copyright © 2018 Leonardo Geus. All rights reserved.
//

import UIKit

class SelectLicenseViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var textFieldLicense: UITextField!
    
    
    var license = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textFieldLicense.delegate = self
        self.textFieldLicense.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        // Do any additional setup after loading the view.
    }
    
    @objc func handleTextChange() {
        if textFieldLicense.text!.count >= 3 {
            textFieldLicense.keyboardType = .numberPad
            textFieldLicense.reloadInputViews()
        } else {
            textFieldLicense.keyboardType = .default
            textFieldLicense.reloadInputViews()
        }
        
        if textFieldLicense.text?.count == 7 {
            self.view.endEditing(true)
        }
        
        textFieldLicense.text = textFieldLicense.text?.uppercased()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @IBAction func buttonTap(_ sender: Any) {
        let licenseAux = textFieldLicense.text
        if (licenseAux != "") {
            if isValidLicense(testStr: licenseAux!) {
                license = licenseAux!
                performSegue(withIdentifier: "segueToList", sender: self)
            } else {
                let alert = UIAlertController(title: "Atenção", message: "A placa digitada deve seguir o padrão de três letras seguida de quatro números.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
               
                
                self.present(alert, animated: true)
            }
            
        }
    }
    
    func isValidLicense(testStr:String) -> Bool {
        let regEx = "[A-Z]{3}[0-9]{4}"
        
        let test = NSPredicate(format:"SELF MATCHES %@", regEx)
        return test.evaluate(with: testStr)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToList" {
            let controller = segue.destination as! SelectWarehouseViewController
            controller.license = license
        }
    }

    
}
