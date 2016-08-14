//
//  ViewController.swift
//  BluetoothPeripheral
//
//  Created by Jelte Liekens on 06/08/16.
//  Copyright © 2016 Jelte Liekens. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion

class ViewController: UIViewController {
    var manager: CBPeripheralManager!
    
    let characteristicUUID = CBUUID(string: "7EA7A792-B0A9-4EF2-96AE-D2A1D516E140")
    let serviceUUID = CBUUID(string: "3A2D52EF-EF63-4B90-AF25-1D6BC2C14FAA")
    
    var characteristic: CBMutableCharacteristic!
    var service: CBMutableService!
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var button: UIButton!
    
    var coreMotionManager: CMMotionManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        manager = CBPeripheralManager(delegate: self, queue: nil)
        
        textField.isEnabled = false
        button.isEnabled = false
        button.isHidden = true
        
        coreMotionManager = CMMotionManager()
        if coreMotionManager.isAccelerometerAvailable {
            coreMotionManager.accelerometerUpdateInterval = 0.05
            coreMotionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: { (data, error) in
                if let data = data {
                    let yValue = String(data.acceleration.y).data(using: String.Encoding.utf8)
//                    print(data.acceleration.y)
                    _ = self.manager?.updateValue(yValue!, for: self.characteristic, onSubscribedCentrals: nil
                    )
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updateText() {
//        print(textField.text!.data(using: String.Encoding.utf8))
        _ = manager.updateValue(
            textField.text!.data(using: String.Encoding.utf8)!,
            for: characteristic,
            onSubscribedCentrals: nil
        )
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Powered ON")
            
            characteristic = CBMutableCharacteristic(
                type: characteristicUUID,
                properties: CBCharacteristicProperties.read.union(.notify),
                value: nil,
                permissions: CBAttributePermissions.readable
            )
            
            service = CBMutableService(
                type: serviceUUID,
                primary: true
            )
            
            service.characteristics = [characteristic]
            
            manager.add(service)
            
        default:
            print("Other")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: NSError?) {
        guard error == nil else {
            print("Error publishing service: \(error?.localizedDescription)")
            return
        }
        
        print("Added service")
        
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
        print("Start advertising")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: NSError?) {
        guard error == nil else {
            print("Error advertising service: \(error?.localizedDescription)")
            return
        }
        
        print("Started Advertising")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Received read request: \(request)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Subscribed to characteristic: \(characteristic.uuid)")
        textField.isEnabled = true
        textField.becomeFirstResponder()
        button.isEnabled = true
    }
}

