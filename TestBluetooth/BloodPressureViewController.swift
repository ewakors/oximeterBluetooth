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
                //                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == pressureCharacteristicUUID {
                var notifiactionData = Data([0x51, 0x54, 0x0, 0x0, 0x0, 0x0, 0xa3])
//                user 1 time 2
//                var timeData = Data([0x51, 0x25, 0x1, 0x0, 0x0, 0x0, 0xa3])
                var timeData = Data([0x51, 0x25, 0x1, 0x0, 0x0, 0x2, 0xa3])
                let timeSum = UInt8(timeData.checksum)
                timeData.append(timeSum)
                //user 1 result 2
//                var resultData = Data([0x51, 0x26, 0x1, 0x0, 0x0, 0x0, 0xa3])
                var resultData = Data([0x51, 0x26, 0x1, 0x0, 0x0, 0x2, 0xa3])
                let resultSum = UInt8(resultData.checksum)
                resultData.append(resultSum)
                //Start a Blood Pressure measurement
                var startData = Data([0x51, 0x43, 0x0, 0x0, 0x0, 0x0, 0xa3])
                //turn off the deivce
                var turnOffData = Data([0x51, 0x50, 0x0, 0x0, 0x0, 0x0, 0xa3])

                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.writeValue(notifiactionData, for: characteristic, type: .withResponse)

                peripheral.writeValue(timeData, for: characteristic, type: .withResponse)
                peripheral.writeValue(resultData, for: characteristic, type: .withResponse)
                peripheral.setNotifyValue(true, for: characteristic)
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
        print("Message sent")
    }
    
    private func bloodPressureConvertValue(from characteristic: CBCharacteristic) {
        if let characteristicData = characteristic.value {
            let byteArray = [UInt8](characteristicData)
            let firstBitValue = byteArray[0] & 0x01
            let secondBitValue = byteArray[1]
            
            var sysValue: Float = 0
            var diaValue: Float = 0
            var meanValue: Float = 0
            var pulseValue: Float = 0
            var hour: Int = 0
            var minute: Int = 0
            var secund: Int = 0
            var day: Int = 0
            var month: Int = 0
            var year: Int = 0
            
            if firstBitValue == 0 {
                
                sysValue = Float(byteArray[1])
                diaValue = Float(byteArray[3])
                meanValue = Float(byteArray[5])
                pulseValue = Float(byteArray[14])
                hour = Int(byteArray[11])
                minute = Int(byteArray[12])
                secund = Int(byteArray[13])
                day = Int(byteArray[10])
                month = Int(byteArray[9])
                
                var year1 = String(Int(byteArray[7]),radix: 2)
                year1 = convertBinary(binary: year1)
          
                var year2 = String(Int(byteArray[8]),radix: 2)
                year2 = convertBinary(binary: year2)
    
                year = Int(year2+year1, radix:2)!
                
                print("Systolic: \(sysValue)")
                print("Diastolic: \(diaValue)")
                print("Mean AP: \(meanValue)")
                print("Timestamp: \(hour):\(minute):\(secund) \(day).\(month).\(year)")
                print("Pulse: \(pulseValue)")
                timestampLabel.text = "Timestamp: \(hour):\(minute):\(secund) \(day).\(month).\(year)"
            
            }
            if secondBitValue == 38 {
                // result
                 sysValue = Float(byteArray[2])
                 diaValue = Float(byteArray[4])
                 meanValue = Float(byteArray[3])
                 pulseValue = Float(byteArray[5])
                
                print("Systolic: \(sysValue)")
                print("Diastolic: \(diaValue)")
                print("Mean AP: \(meanValue)")
                print("Pulse: \(pulseValue)")

            }
            if secondBitValue == 37 {
                //date
                var binary = String(Int(byteArray[2]),radix: 2)
                binary = convertBinary(binary: binary)

                var binary2 = String(Int(byteArray[3]),radix: 2)
                binary2 = convertBinary(binary: binary2)

                let date = String(binary2) + String(binary)
                let yearIndex = date.index(date.startIndex, offsetBy: 7)
                let dayIndex = date.index(date.startIndex, offsetBy: 16)
                let monthIndex = date.index(date.startIndex, offsetBy: 11)
                
                year = Int(date[date.startIndex..<yearIndex], radix:2)!
                month = Int(date[yearIndex..<monthIndex], radix: 2)!
                day = Int(date[monthIndex..<dayIndex], radix: 2)!
                
                //time
                var binary3 = String(Int(byteArray[4]),radix: 2)
                binary3 = convertBinary(binary: binary3)
                var binary4 = String(Int(byteArray[5]),radix: 2)
                binary4 = convertBinary(binary: binary4)
                
                let time = String(binary4) + String(binary3)
            
                let startIndex = time.index(time.startIndex, offsetBy: 3)
                let hourIndex = time.index(time.startIndex, offsetBy: 8)
                let nextIndex = time.index(time.startIndex, offsetBy: 10)
                let minuteIndex = time.index(time.startIndex, offsetBy: 16)

                hour = Int(time[startIndex..<hourIndex], radix: 2)!
                minute = Int(time[nextIndex..<minuteIndex], radix: 2)!
                timestampLabel.text = "Timestamp: \(hour):\(minute):\(secund) \(day).\(month).\(year)"
            }
            
            systolicLabel.text = "Systolic: \(sysValue) mmHg"
            diastolicLabel.text = "Diastolic: \(diaValue) mmHg"
            meanLabel.text = "Mean AP: \(meanValue) mmHg"
            pulseLabel.text = "Pulse: \(pulseValue) bpm"
        }
    }
    
    func convertBinary(binary: String) -> String {
        var binary = binary
        if binary.count < 8 {
            let count = 8 - binary.count
            for _ in 0..<count {
                binary = "0" + binary
            }
        }
        return binary
    }
}

extension Data {
    var checksum: Int {
        return self.map { Int($0) }.reduce(0, +) &  0xff
    }
}
