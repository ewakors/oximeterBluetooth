//
//  ViewController.swift
//  TestBluetooth
//
//  Created by goapps on 10/05/2019.
//  Copyright © 2019 pl.goapps. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var fingerServiceId = "0000ffb0-0000-1000-8000-00805f9b34fb"
    var fingerCharacteriscticId = "0000ffb2-0000-1000-8000-00805f9b34fb"
    var fingerCharacteriscticDescriptorId = "00002902-0000-1000-8000-00805f9b34fb"
    
    var centralManager: CBCentralManager!
    var fingerPeriferial: CBPeripheral!
    
    var rxCharacteristic : CBCharacteristic?
    var txCharacteristic : CBCharacteristic?
    
    var characteristicASCIIValue = NSString()
    
    @IBOutlet weak var spo2Label: UILabel!
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var piLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    @IBAction func refreshButton(_ sender: Any) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension ViewController: CBCentralManagerDelegate {
    
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
            let fingerRateServiceUUId = CBUUID(string: fingerServiceId)
            centralManager.scanForPeripherals(withServices: [fingerRateServiceUUId])
            
        @unknown default:
            fatalError()
        }
    }
    
    // obtain bluetooth devices
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //shows nerby devics
        print(peripheral)
        fingerPeriferial = peripheral
        fingerPeriferial.delegate = self
        centralManager.stopScan()
        centralManager.connect(fingerPeriferial)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to finger")
        fingerPeriferial.discoverServices(nil)
    }
}

extension ViewController: CBPeripheralDelegate {
    
    //obtain all services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for serivce in services {
            //            print("ere")
            //            print(serivce)
            
            peripheral.discoverCharacteristics(nil, for: serivce)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        let fingerCharacteristicUUID = CBUUID(string: "0000ffb2-0000-1000-8000-00805f9b34fb")
        for characteristic in characteristics {
            print(characteristic)
            //uuid: FFB0, propertis: Write without response, notify
            if characteristic.uuid == fingerCharacteristicUUID {
                
                rxCharacteristic =  characteristic
                //send value _command_para_on Data(bytes: [-86, 85, 15, 3, -124, 1, -32]) 0xAA550F038401E0 [0xAA, 0x55, 0x0F, 0x03, 0x84, 0x01, 0xE0]
                //send value _command_wave_on Data(bytes: [-86, 85, 15, 3, -123, 1, 36]) 0xAA550F038401E0 [0xAA, 0x55, 0x0F, 0x03, 0x85, 0x01, 0x24]
                peripheral.writeValue(Data([0xAA, 0x55, 0x0F, 0x03, 0x84, 0x01, 0xE0]), for: characteristic, type: .withoutResponse)
//                peripheral.writeValue(Data([0xAA, 0x55, 0x0F, 0x03, 0x85, 0x01, 0x24]), for: characteristic, type: .withoutResponse)
                
                peripheral.setNotifyValue(true, for: characteristic)
                
                print("fantastish \(characteristic)")
                print("Rx characteristic: \(characteristic.uuid)")
                
                //descritors
                peripheral.discoverDescriptors(for: characteristic)
            } else {
                // Device information
                peripheral.readValue(for: characteristic)
            }
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
                oximeterSpO2ConvertValue(from: characteristic)
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
                print("Tx Value \(String(describing: txCharacteristic?.value))")
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
        print("Message sent")
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
    
    private func oximeterSpO2ConvertValue(from characteristic: CBCharacteristic) {
        //guard let characteristicData = characteristic.value else { print("oximeter converter error") }
        if let characteristicData = characteristic.value {
            let byteArray = [UInt8](characteristicData)
            // The SpO2 is in the 6 bytes, i.e. aa550f08 01603e00 0d00c063 => x60 in Hexadecimal = 96 decimal
            // The BPM (beat per minute) is in the 7 bytes, i.e. aa550f08 01603e00 0d00c063 => x3e in Hexadecimal = 62 decimal
            //  PI (Perfusion Index) is in the 9 bytes, i.e. aa550f08 01603e00 0d00c063 => x0d in Hexadecimal = 13 decimal => 1,3%
            let firstBitValue = byteArray[0] & 0x01
            if firstBitValue == 0 {
                let spo2Value = Int(byteArray[5])
                spo2Label.text = "SpO2: \(spo2Value)"
                let bpmValue = Int(byteArray[6])
                bpmLabel.text = "BPM: \(bpmValue)"
                let piValue = Float(byteArray[8]) / 10
                piLabel.text = "PI (%): \(piValue)"
            }
        }
    }
}
