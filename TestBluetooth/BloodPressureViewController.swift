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
    @IBOutlet weak var userTextField: UITextField!
    
    var pressureServiceId = "00001523-1212-EFDE-1523-785FEABCD123"
    var pressureCharacteriscticId = "00001524-1212-efde-1523-785feabcd123"
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var rxCharacteristic : CBCharacteristic?
    
    var characteristicASCIIValue = NSString()
    var dataNumber: Int = 0
    var userNumber: Int = 0
    let userPicker = UIPickerView()
    var userData = ["1","2","3","4"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showUserPicker()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        centralManager = nil
        systolicLabel.text = "--"
        diastolicLabel.text = "--"
        meanLabel.text = "--"
        timestampLabel.text = "--"
        pulseLabel.text = "--"
    }
    
    func showUserPicker() {
        userPicker.delegate = self
        
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Ok", style: .plain, target: self, action: #selector(doneUserPicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelUserPicker));
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        userTextField.inputAccessoryView = toolbar
        userTextField.inputView = userPicker
    }
    
    @objc func doneUserPicker() {
        let choosedUser = userData[userPicker.selectedRow(inComponent: 0)]
        userTextField.text = choosedUser
        self.view.endEditing(true)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @objc func cancelUserPicker(){
        self.view.endEditing(true)
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

            let pressureServiceUUId = CBUUID(string: "1810")
            centralManager.scanForPeripherals(withServices: [pressureServiceUUId])
            
        @unknown default:
            fatalError()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

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
            
            if characteristic.uuid == bloodCharacteristicUUID {
                //                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == pressureCharacteristicUUID {
                if let userNumber = userTextField.text {
                    //  Read storage number of data, numberOfData[2] is user (1,2,3,4)
                    var numberOfData = Data([0x51, 0x2b, 0x3, 0x0, 0x0, 0x0, 0xa3])
                    self.userNumber = Int(userNumber) ?? 0
                    numberOfData[2] = UInt8(userNumber) ?? 0
                    let numberSum = UInt8(numberOfData.checksum)
                    numberOfData.append(numberSum)
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.writeValue(numberOfData, for: characteristic, type: .withResponse)
                }
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
                if let characteristicData = characteristic.value  {
                    let byteArray = [UInt8](characteristicData)
                    let secondBitValue = byteArray[1]
                    if secondBitValue == 43 {
                        numberOfDataConvertValue(from: characteristic,peripheral: peripheral)
                    }
                }
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
                print("Timestamp: \(hour):\(minute):\(secund) \(day).\(month).\(year)")
                timestampLabel.text = "Timestamp: \(hour):\(minute):\(secund) \(day).\(month).\(year)"
            }
            
            systolicLabel.text = "Systolic: \(sysValue) mmHg"
            diastolicLabel.text = "Diastolic: \(diaValue) mmHg"
            meanLabel.text = "Mean AP: \(meanValue) mmHg"
            pulseLabel.text = "Pulse: \(pulseValue) bpm"
        }
    }
    
    private func numberOfDataConvertValue(from characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        if let characteristicData = characteristic.value  {
            let byteArray = [UInt8](characteristicData)
            
            print("number: \(Int(byteArray[2]))")
            
            dataNumber = Int(byteArray[2])
            if dataNumber > 0 {
                for i in 0..<dataNumber {

                    //Start a Blood Pressure measurement
//                    var startData = Data([0x51, 0x43, 0x0, 0x0, 0x0, 0x0, 0xa3])
//                    var notifiactionData = Data([0x51, 0x54, 0x0, 0x0, 0x0, 0x0, 0xa
//          timeData[2] number of data (0, 1, 2...), timeData[5] is user (1,2,3,4)
                    var timeData = Data([0x51, 0x25, 0x0, 0x0, 0x0, 0x0, 0xa3])
                    timeData[2] = UInt8(i)
                    timeData[5] = UInt8(userNumber)
                    let timeSum = UInt8(timeData.checksum)
                    timeData.append(timeSum)
//          resultData[2] number of data (0, 1, 2...), resultData[5] is user (1,2,3,4)
                    var resultData = Data([0x51, 0x26, 0x0, 0x0, 0x0, 0x0, 0xa3])
                    resultData[2] = UInt8(i)
                    resultData[5] = UInt8(userNumber)
                    let resultSum = UInt8(resultData.checksum)
                    resultData.append(resultSum)

                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.writeValue(timeData, for: characteristic, type: .withResponse)
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.writeValue(resultData, for: characteristic, type: .withResponse)
                    
                    //turn off the deivce
//                    var turnOffData = Data([0x51, 0x50, 0x0, 0x0, 0x0, 0x0, 0xa3])
                }
            }
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

extension BloodPressureViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return userData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return userData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        return userTextField.text = userData[row]
    }
}

extension Data {
    var checksum: Int {
        return self.map { Int($0) }.reduce(0, +) &  0xff
    }
}
