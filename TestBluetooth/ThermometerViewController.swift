//
//  ThermometerViewController.swift
//  TestBluetooth
//
//  Created by goapps on 17/05/2019.
//  Copyright © 2019 pl.goapps. All rights reserved.
//

import UIKit
import CoreBluetooth

class ThermometerViewController: UIViewController {

    let temperatureServiceId = "cdeacb80-5235-4c07-8846-93a37ee6b86d"
    let temperatureCharacteristicNotifyId = "cdeacb81-5235-4c07-8846-93a37ee6b86d"
    let temperatureCharacteristicWriteId = "cdeacb82-5235-4c07-8846-93a37ee6b86d"
    
    var centralManager: CBCentralManager!
    var termPeriferial: CBPeripheral!
    
    var rxCharacteristic : CBCharacteristic?
    
    var characteristicASCIIValue = NSString()
    
    @IBOutlet weak var tempLabel: UILabel!
     @IBOutlet weak var tempFarLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
//        let first = 15
//        var binary = String(first,radix: 2)
//        if binary.count < 8 {
//            let count = 8 - binary.count
//            for i in 0..<count {
//                binary = "0" + binary
//            }
//        }
//        let second = 82
//        var binary2 = String(second,radix: 2)
//        if binary2.count < 8 {
//            let count = 8 - binary2.count
//            for i in 0..<count {
//                binary2 = "0" + binary2
//            }
//        }
//        print("binary \(binary)")
//        print("binary2 \(binary2)")
//        print(binary + binary2)
//        let decimal = Int(binary+binary2, radix:2)!
//        let temp = Float(decimal)
//        print(decimal)
//        print(temp / 100)
        let rounded = 31.5
        let tempFar = (9/5) * rounded + 32
        print(tempFar)
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}
extension ThermometerViewController: CBCentralManagerDelegate {
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
        let glucoseServiceUUID = CBUUID(string: temperatureServiceId)
        centralManager.scanForPeripherals(withServices: [glucoseServiceUUID])
        @unknown default:
            fatalError()
        }
    }
    
    // obtain bluetooth devices
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //shows nerby devics
        print(peripheral)
        termPeriferial = peripheral
        termPeriferial.delegate = self
        centralManager.stopScan()
        centralManager.connect(termPeriferial)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to thermometer")
        termPeriferial.discoverServices(nil)
    }
}

extension ThermometerViewController: CBPeripheralDelegate {
    
    //obtain all services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for serivce in services {
            peripheral.discoverCharacteristics(nil, for: serivce)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        let temperatureCharacteristicNotifyUUID = CBUUID(string: temperatureCharacteristicNotifyId)
        let temperatureCharacteristicWriteUUID = CBUUID(string: temperatureCharacteristicWriteId)
        
        for characteristic in characteristics {
            print(characteristic)
            
            if characteristic.uuid == temperatureCharacteristicNotifyUUID {
                rxCharacteristic =  characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
            }
            
            if characteristic.uuid == temperatureCharacteristicWriteUUID {
                peripheral.writeValue(Data([0xAA, 0x22, 0x02, 0x80, 0x01, 0x00, 0x81]), for: characteristic, type: .withResponse)
                peripheral.discoverDescriptors(for: characteristic)
            }
//                peripheral.readValue(for: characteristic)
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
                temperatureConvertValue(from: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("didDiscoverDescriptorsFor \(error.debugDescription)")
            return
        }
        
        if ((characteristic.descriptors) != nil) {
            for x in characteristic.descriptors!{
                let descript = x as CBDescriptor?
                peripheral.readValue(for: descript!)
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript))")
                print("Rx Value \(String(describing: rxCharacteristic?.value))")
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
            print ("Subscribed. Notification has begun for: \(characteristic.uuid) \(String(describing: characteristic.value))")
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
    
    private func temperatureConvertValue(from characteristic: CBCharacteristic) {
        if let characteristicData = characteristic.value {
            let byteArray = [UInt8](characteristicData)
 
            let firstBitValue = byteArray[0] & 0x01
            if firstBitValue == 0 {
                // temp in Celsius
                var binary = String(Int(byteArray[2]),radix: 2)
                if binary.count < 8 {
                    let count = 8 - binary.count
                    for i in 0..<count {
                        binary = "0" + binary
                    }
                }
                var binary2 = String(Int(byteArray[3]),radix: 2)
                if binary2.count < 8 {
                    let count = 8 - binary2.count
                    for i in 0..<count {
                        binary2 = "0" + binary2
                    }
                }
                print("binary \(binary)")
                print("binary2 \(binary2)")
        
                print(binary + binary2)
                let decimal = Int(binary+binary2, radix:2)!
                let temp = Double(decimal) / 100
                print(decimal)
                print(temp)
                tempLabel.text = "\(roundedValue(value: temp)) °C"
                //temp in Fahrenheit
                let tempFar = (9/5) * temp + 32
                tempFarLabel.text = "\(roundedValue(value: tempFar)) °F"
            }
        }
    }
    
    func roundedValue(value: Double) -> Double{
        let multiplier = pow(10.0, 1.0)
        let rounded = round((value) * multiplier) / multiplier
        return rounded
    }
}
