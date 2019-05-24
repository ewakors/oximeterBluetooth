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
    let weightIndicateCharacteristicId = "0000fec8-0000-1000-8000-00805f9b34fb"
    let weightCharacteristicDescriptorId = "00002902-0000-1000-8000-00805f9b34fb"
    
    var centralManager: CBCentralManager!
    var scalePeriferial: CBPeripheral!
    
    var rxCharacteristic : CBCharacteristic?
    
    var characteristicASCIIValue = NSString()
    
    @IBOutlet weak var weightLabel: UILabel!

    
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
//        var weight: String = String(describing: advertisementData["kCBAdvDataManufacturerData"])
//        weight = weight.replacingOccurrences(of: "<", with: "")
//        weight = weight.replacingOccurrences(of: ">", with: "")
//        print("weight: \(weight)")
   
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
                                decimal = Int(w1+w2, radix:2)!
                            } else {
                                decimal = Int(w1, radix:2)!
                            }
    
                            var weightKg = Double(decimal)
                            if decimal < 10000 {
                                weightKg = weightKg / 100
                            }
                            
                            if decimal >= 10000  {
                                weightKg = weightKg / 1000
                            }
                            
                            print(decimal)
                            print("weight: \(weightKg)")
                            weightKg = weightKg / 2.2046
                            weightLabel.text = "weight: \(roundedValue(value: weightKg)) kg"
                        }
        }

        
        scalePeriferial = peripheral
        scalePeriferial.delegate = self
        centralManager.stopScan()
        centralManager.connect(scalePeriferial)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to weight scale")
//        scalePeriferial.discoverServices(nil)
    }
    
    func roundedValue(value: Double) -> Double {
        let multiplier = pow(10.0, 1.0)
        let rounded = round((value) * multiplier) / multiplier
        return rounded
    }
}

extension WeightScaleViewController: CBPeripheralDelegate {
    
    //obtain all services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for serivce in services {
            print("service: \(serivce)")
            peripheral.discoverCharacteristics(nil, for: serivce)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        let weightCharacteristicUUID = CBUUID(string: weightIndicateCharacteristicId)
        
        for characteristic in characteristics {
            print(characteristic)
            
            if characteristic.uuid == weightCharacteristicUUID {
                rxCharacteristic =  characteristic
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)

            }
            
//            if characteristic.uuid == CBUUID(string: "FEC7") {
//                peripheral.writeValue(Data([0xf0]), for: characteristic, type: .withResponse)
//            }
//
//            if characteristic.uuid == CBUUID(string: "FEC9") {
//                peripheral.readValue(for: characteristic)
//            }
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
        
        print("characteristic uuid: \(characteristic))")
        
        if characteristic.value != nil {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                characteristicASCIIValue = ASCIIstring
                print("Value Recieved: \((characteristicASCIIValue as String))")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
            } else {
               print("didUpdateValueFor \(characteristic)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("error didDiscoverDescriptorsFor \(error.debugDescription)")
            return
        }
        
        if ((characteristic.descriptors) != nil) {
            for x in characteristic.descriptors!{
                let descript = x as CBDescriptor?
                peripheral.readValue(for: descript!)
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript))")
                print("Rx Value \(String(describing: characteristic.value))")
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid) \(String(describing: characteristic))")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error didWriteValueFor characteristic discovering services: \(error.debugDescription)")
            return
        }
        print("Message sent \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Succeeded!")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error didUpdateValueFor descriptor: \(error.debugDescription)")
            return
        }
        
        print("descriptor Succeeded! \(descriptor)")
        
        if descriptor.value != nil {
            print("descriptor value: \(String(describing: descriptor.value))")
        }
    }
}
