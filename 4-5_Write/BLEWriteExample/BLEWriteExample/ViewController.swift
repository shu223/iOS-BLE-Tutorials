//
//  ViewController.swift
//  BLEScanExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    var isScanning = false
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var settingCharacteristic: CBCharacteristic!
    var outputCharacteristic: CBCharacteristic!
    
    @IBOutlet weak var scanBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セントラルマネージャ初期化
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Actions

    @IBAction func scanButtonTapped(_ sender: UIButton) {
        
        if !isScanning {
            isScanning = true
            sender.setTitle("STOP SCAN", for: .normal)

            centralManager.scanForPeripherals(withServices: nil)
        } else {
            centralManager.stopScan()

            sender.setTitle("START SCAN", for: .normal)
            isScanning = false
        }
    }

    @IBAction func ledButtonTapped(_ sender: UIButton) {
        if settingCharacteristic == nil || outputCharacteristic == nil {
            print("Konashi is not ready!")
            return;
        }

        // LED2を光らせる
        
        // 書き込みデータ生成（LED2）
        let value: UInt8 = 0x01 << 1
        let data = Data([value])
        
        // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
        peripheral.writeValue(data, for: settingCharacteristic, type: .withoutResponse)
        
        // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
        peripheral.writeValue(data, for: outputCharacteristic, type: .withoutResponse)
    }
}

extension ViewController: CBCentralManagerDelegate {
    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
    }
    
    // ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber)
    {
        print("発見したBLEデバイス: \(peripheral)")
        
        if let name = peripheral.name, name.hasPrefix("konashi") {
            self.peripheral = peripheral
            
            // 接続開始
            centralManager.connect(peripheral)
            centralManager.stopScan()
        }
    }
    
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral)
    {
        print("接続成功！")
        
        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        
        // サービス探索開始
        peripheral.discoverServices(nil)
    }
    
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?)
    {
        print("接続失敗・・・")
    }
}

extension ViewController: CBPeripheralDelegate {

    // サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("エラー: \(error)")
            return
        }
        
        guard let services = peripheral.services, services.count > 0 else {
            print("no services")
            return
        }
        print("\(services.count) 個のサービスを発見！ \(services)")
        
        for service in services {
            // キャラクタリスティック探索開始
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?)
    {
        if let error = error {
            print("エラー: \(error)")
            return
        }
        
        guard let characteristics = service.characteristics, characteristics.count > 0 else {
            print("no characteristics")
            return
        }
        print("\(characteristics.count) 個のキャラクタリスティックを発見！ \(characteristics)")
        
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(CBUUID(string: "3000")) {
                settingCharacteristic = characteristic
                print("KONASHI_PIO_SETTING_UUID を発見！")
            } else if characteristic.uuid.isEqual(CBUUID(string: "3002")) {
                outputCharacteristic = characteristic
                print("KONASHI_PIO_OUTPUT_UUID を発見！")
            }
        }
    }
    
    // データ書き込みが完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        if let error = error {
            print("書き込み失敗...error: \(error), characteristic uuid: \(characteristic.uuid)")
            return
        }
        print("書き込み成功！service uuid: \(String(describing: characteristic.service?.uuid)), characteristic uuid: \(characteristic.uuid), value: \(String(describing: characteristic.value))")
    }
}

