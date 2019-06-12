//
//  BloodPressureCell.swift
//  TestBluetooth
//
//  Created by goapps on 12/06/2019.
//  Copyright © 2019 pl.goapps. All rights reserved.
//

import UIKit

struct BloodPressure {
    var systolic: Int
    var diastolic: Int
    var mean: Int
    var pulse: Int
}

class BloodPressureCell: UITableViewCell {

    @IBOutlet weak var systolicLabel: UILabel!
    @IBOutlet weak var diastolicLabel: UILabel!
    @IBOutlet weak var meanLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var pulseLabel: UILabel!

    func configure(with bloodPressure: [BloodPressure], indexRow: Int) {
        systolicLabel.text = "Systolic: \(bloodPressure[indexRow].systolic) mmHg"
        diastolicLabel.text = "Diastolic: \(bloodPressure[indexRow].diastolic) mmHg"
        meanLabel.text = "Mean AP: \(bloodPressure[indexRow].mean) mmHg"
        pulseLabel.text = "Pulse: \(bloodPressure[indexRow].pulse) bpm"
       
       print(bloodPressure)
    }
    
}
