//
//  WeightScaleViewController.swift
//  TestBluetooth
//
//  Created by goapps on 22/05/2019.
//  Copyright © 2019 pl.goapps. All rights reserved.
//

import UIKit
import CoreBluetooth

class WeightScaleViewController: UIViewController {
    
    let weightServiceId = "0000fee7-0000-1000-8000-00805f9b34fb"
    
    var centralManager: CBCentralManager!
    
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var weightLbsLabel: UILabel!
    @IBOutlet weak var weight3Label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    override func viewDidDisappear(_ animated: Bool) {
        centralManager = nil
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}
extension WeightScaleViewController: CBCentralManagerDelegate {
    // shows bluettoth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            
            // set to discover devices only with this service id
            let weightServiceUUID = CBUUID(string: weightServiceId)
            centralManager.scanForPeripherals(withServices: [weightServiceUUID])
        @unknown default:
            fatalError()
        }
    }
    
    // obtain bluetooth devices
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //shows nerby devics
        print(peripheral)
        print("advertisementData: \(advertisementData)")
        
        if let weight = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let byteArray = [UInt8](weight)
            let firstBitValue = byteArray[0] & 0x01
            if firstBitValue == 0 {
                var w1 = String(Int(byteArray[5]),radix: 2)
                var w2 = String(Int(byteArray[6]),radix: 2)
                
                if w1.count < 8 {
                    let count = 8 - w1.count
                    for i in 0..<count {
                        w1 = "0" + w1
                    }
                }
                if w2.count < 8 {
                    let count = 8 - w2.count
                    for i in 0..<count {
                        w2 = "0" + w2
                    }
                }
                print(w1)
                print(w2)
                
                var decimal: Int = 0
                
                if w2 != "00000000" {
                    decimal = Int(w2+w1, radix:2)!
                } else {
                    decimal = Int(w1, radix:2)!
                }
                
                var weightKg = Double(decimal)
                
                if decimal <= 1000 {
                    weightKg = weightKg / 10
                }
                
                if decimal > 1000 && decimal < 10000 {
                    weightKg = weightKg / 100
                }
                
                if decimal >= 10000  {
                    weightKg = weightKg / 1000
                }
                
                print(decimal)
                print("weight: \(weightKg)")
                weightLabel.text = "\(roundedValue(value: weightKg)) kg"
                weightLbsLabel.text = "\(roundedValue(value: weightKg * 2.20462) ) lbs"
                weight3Label.text = "\(roundedValue(value: weightKg * 2) ) ft"
            }
        }
    
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to weight scale")
    }
    
    func roundedValue(value: Double) -> Double {
        let multiplier = pow(10.0, 1.0)
        let rounded = round((value) * multiplier) / multiplier
        return rounded
    }
}

