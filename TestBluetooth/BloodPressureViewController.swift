//
//  BloodPressureViewController.swift
//  TestBluetooth
//
//  Created by goapps on 28/05/2019.
//  Copyright © 2019 pl.goapps. All rights reserved.
//

import UIKit
import CoreBluetooth

class BloodPressureViewController: UIViewController {
    
    @IBOutlet weak var systolicLabel: UILabel!
    @IBOutlet weak var diastolicLabel: UILabel!
    @IBOutlet weak var meanLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var pulseLabel: UILabel!
    
    var pressureServiceId = "00001523-1212-EFDE-1523-785FEABCD123"
    var pressureCharacteriscticId = "00001524-1212-efde-1523-785feabcd123"
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var rxCharacteristic : CBCharacteristic?
    
    var characteristicASCIIValue = NSString()

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    override func viewDidDisappear(_ animated: Bool) {
        centralManager = nil
        systolicLabel.text = "--"
        diastolicLabel.text = "--"
        meanLabel.text = "--"
        timestampLabel.text = "--"
        pulseLabel.text = "--"
    }
    @IBAction func refreshButton(_ sender: Any) {
        centralManager = nil
        centralManager = CBCentralManager(delegate: self, queue: nil)
        systolicLabel.text = "--"
        diastolicLabel.text = "--"
        meanLabel.text = "--"
        timestampLabel.text = "--"
        pulseLabel.text = "--"
    }
}
extension BloodPressureViewController: CBCentralManagerDelegate {
    
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
            let pressureServiceUUId = CBUUID(string: "1810")
            centralManager.scanForPeripherals(withServices: [pressureServiceUUId])
            
        @unknown default:
            fatalError()
        }
    }
    
    // obtain bluetooth devices
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //shows nerby devics
        print(peripheral)
        self.peripheral = peripheral
        self.peripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to pressure")
        peripheral.discoverServices(nil)
    }
}
extension BloodPressureViewController: CBPeripheralDelegate {
    
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
        let pressureCharacteristicUUID = CBUUID(string: pressureCharacteriscticId)
        let bloodCharacteristicUUID = CBUUID(string: "2A35")
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.uuid == bloodCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == pressureCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.writeValue(Data([0x51, 0x2b, 0x02, 0x0, 0x0, 0x0, 0xa3]), for: characteristic, type: .withResponse)
                rxCharacteristic =  characteristic
                print("Rx characteristic: \(characteristic.uuid)")
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
                bloodPressureConvertValue(from: characteristic)
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

    private func bloodPressureConvertValue(from characteristic: CBCharacteristic) {
        if let characteristicData = characteristic.value {
            let byteArray = [UInt8](characteristicData)
            let firstBitValue = byteArray[0] & 0x01
            if firstBitValue == 0 {
                let sysValue = Float(byteArray[1])
                let diaValue = Float(byteArray[3])
                let meanValue = Float(byteArray[5])
                let hour = Int(byteArray[11])
                let minute = Int(byteArray[12])
                let secund = Int(byteArray[13])
                let day = Int(byteArray[10])
                let mounth = Int(byteArray[9])
                var year1 = String(Int(byteArray[7]),radix: 2)
                if year1.count < 8 {
                    let count = 8 - year1.count
                    for i in 0..<count {
                        year1 = "0" + year1
                    }
                }
                var year2 = String(Int(byteArray[8]),radix: 2)
                if year2.count < 8 {
                    let count = 8 - year2.count
                    for i in 0..<count {
                        year2 = "0" + year2
                    }
                }
                let year = Int(year2+year1, radix:2)!
                let pulseValue = Float(byteArray[14])
                
                print("Systolic: \(sysValue)")
                print("Diastolic: \(diaValue)")
                print("Mean AP: \(meanValue)")
                print("Timestamp: \(hour):\(minute):\(secund) \(day).\(mounth).\(year)")
                print("Pulse: \(pulseValue)")
                systolicLabel.text = "Systolic: \(sysValue) mmHg"
                diastolicLabel.text = "Diastolic: \(diaValue) mmHg"
                meanLabel.text = "Mean AP: \(meanValue) mmHg"
                timestampLabel.text = "Timestamp: \(hour):\(minute):\(secund) \(day).\(mounth).\(year)"
                pulseLabel.text = "Pulse: \(pulseValue) bpm"
            }
        }
    }
}
