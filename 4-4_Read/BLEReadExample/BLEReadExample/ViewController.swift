//
//  ViewController.swift
//  BLEScanExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var isScanning = false
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セントラルマネージャ初期化
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // =========================================================================
    // MARK: CBCentralManagerDelegate
    
    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(central: CBCentralManager) {

        print("state: \(central.state)")
    }
    
    // 周辺にあるデバイスを発見すると呼ばれる
    func centralManager(central: CBCentralManager,
        didDiscoverPeripheral peripheral: CBPeripheral,
        advertisementData: [String : AnyObject],
        RSSI: NSNumber)
    {
        print("発見したBLEデバイス: \(peripheral)")
        
        if let name = peripheral.name where name.hasPrefix("konashi") {
            
            self.peripheral = peripheral
            
            centralManager.connectPeripheral(peripheral, options: nil)
            
            centralManager.stopScan()
        }
    }
    
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(central: CBCentralManager,
        didConnectPeripheral peripheral: CBPeripheral)
    {
        print("接続成功！")

        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        
        // サービス探索開始
        peripheral.discoverServices(nil)
    }
    
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(central: CBCentralManager,
        didFailToConnectPeripheral peripheral: CBPeripheral,
        error: NSError?)
    {
        print("接続失敗・・・")
    }

    
    // =========================================================================
    // MARK:CBPeripheralDelegate
    
    // サービス発見時に呼ばれる
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        if let error = error {
            print("エラー: \(error)")
            return
        }
        
        guard let services = peripheral.services where services.count > 0 else {
            print("no services")
            return
        }
        print("\(services.count) 個のサービスを発見！ \(services)")

        for service in services {
            
            // キャラクタリスティック探索開始
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(peripheral: CBPeripheral,
        didDiscoverCharacteristicsForService service: CBService,
        error: NSError?)
    {
        if let error = error {
            print("エラー: \(error)")
            return
        }

        guard let characteristics = service.characteristics where characteristics.count > 0 else {
            print("no characteristics")
            return
        }
        print("\(characteristics.count) 個のキャラクタリスティックを発見！ \(characteristics)")
        
        for characteristic in characteristics {
            
            // Read専用のキャラクタリスティックに限定して読み出す場合
            if characteristic.properties == CBCharacteristicProperties.Read {
                
                peripheral.readValueForCharacteristic(characteristic)
            }
        }
    }
    
    // データ読み出しが完了すると呼ばれる
    func peripheral(peripheral: CBPeripheral,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic,
        error: NSError?)
    {
        if let error = error {
            print("読み出し失敗...error: \(error), characteristic uuid: \(characteristic.UUID)")
            return
        }
        
        print("読み出し成功！service uuid: \(characteristic.service.UUID), characteristic uuid: \(characteristic.UUID), value: \(characteristic.value)")
        
        // バッテリーレベルのキャラクタリスティックかどうかを判定
        if characteristic.UUID.isEqual(CBUUID(string: "2A19")) {
            
            var byte: CUnsignedChar = 0
            
            // 1バイト取り出す
            characteristic.value?.getBytes(&byte, length: 1)
            
            print("Battery Level: \(byte)")
        }
    }

    
    // =========================================================================
    // MARK: Actions

    @IBAction func scanBtnTapped(sender: UIButton) {
        
        if !isScanning {
            
            isScanning = true
            
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            
            sender.setTitle("STOP SCAN", forState: UIControlState.Normal)
        }
        else {
            
            centralManager.stopScan()
            
            sender.setTitle("START SCAN", forState: UIControlState.Normal)
            
            isScanning = false
        }
    }
}

