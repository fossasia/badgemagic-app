//
//  BLE.swift
//  badgemagic
//
//  Created by Aditya Gupta on 12/22/19.
//  Copyright © 2019 Aditya Gupta. All rights reserved.
//

import Foundation
import CoreBluetooth

open class BLE: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, ObservableObject {

    private var centralManager: CBCentralManager! = nil
    private var peripheral: CBPeripheral!
    private var scanTimer = Timer()

    var scannedBLEDevices: String?

    func startCentralManager() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        print("Central Manager State: \(self.centralManager.state)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.centralManagerDidUpdateState(self.centralManager)
        }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unsupported:
            print("BLE is Unsupported")
        case .unauthorized:
            print("BLE is Unauthorized")
        case .unknown:
            print("BLE is Unknown")
        case .resetting:
            print("BLE is Resetting")
        case .poweredOff:
            print("BLE is Powered Off")
        case .poweredOn:
            if !self.centralManager.isScanning, self.scannedBLEDevices == nil {
                print("Central scanning for", Constants.SERVICEUUID)
                self.centralManager.scanForPeripherals(
                    withServices: [Constants.SERVICEUUID],
                    options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
                )

                self.scanTimer.invalidate()
                self.scanTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false, block: stopScanning)
            }
        @unknown default:
            print("Unknown State")
        }
        if central.state != .poweredOn {
            return
        }
    }

    func stopScanning(timer: Timer) {
        if centralManager.isScanning {
            centralManager.stopScan()
            timer.invalidate()
            print("Stopping Scan")
        }
    }

    public func centralManager(_ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber) {

        print("Peripheral Name: \(String(describing: peripheral.name))  RSSI: \(String(RSSI.doubleValue))")
        self.stopScanning(timer: self.scanTimer)
        self.peripheral = peripheral
        self.scannedBLEDevices = peripheral.name!
        self.peripheral.delegate = self
        self.centralManager.connect(self.peripheral, options: nil)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your BLE Board")
            peripheral.discoverServices([Constants.SERVICEUUID])
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { print(error!); return }

        if let services = peripheral.services {
            for service in services where service.uuid == Constants.SERVICEUUID {
                print("BLE Service found")
                peripheral.discoverCharacteristics([Constants.CHARACTERISTICUUID], for: service)
                return
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { print(error!); return }

        print("BLE service characteristic found")
    }
}
