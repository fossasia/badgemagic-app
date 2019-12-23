//
//  Constants.swift
//  badgemagic
//
//  Created by Aditya Gupta on 12/22/19.
//  Copyright © 2019 Aditya Gupta. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Constants {
    static let SERVICEUUID = CBUUID.init(string: "0000FEE0-0000-1000-8000-00805F9B34FB")
    static let CHARACTERISTICUUID = CBUUID.init(string: "FEE1")
}
