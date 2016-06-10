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
    var settingCharacteristic: CBCharacteristic!
    var outputCharacteristic: CBCharacteristic!
    
    @IBOutlet weak var scanBtn: UIButton!
    
    
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
    
    // ペリフェラルを発見すると呼ばれる
    func centralManager(central: CBCentralManager,
        didDiscoverPeripheral peripheral: CBPeripheral,
        advertisementData: [String : AnyObject],
        RSSI: NSNumber)
    {
        print("発見したBLEデバイス: \(peripheral)")
        
        if let name = peripheral.name where name.hasPrefix("konashi") {

            self.peripheral = peripheral
            
            // 接続開始
            centralManager.connectPeripheral(peripheral, options: nil)
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
            
            if characteristic.UUID.isEqual(CBUUID(string: "3000")) {
                
                settingCharacteristic = characteristic
                print("KONASHI_PIO_SETTING_UUID を発見！")
            }
            else if characteristic.UUID.isEqual(CBUUID(string: "3002")) {
                
                outputCharacteristic = characteristic
                print("KONASHI_PIO_OUTPUT_UUID を発見！")
            }
        }
    }

    // データ書き込みが完了すると呼ばれる
    func peripheral(peripheral: CBPeripheral,
        didWriteValueForCharacteristic characteristic: CBCharacteristic,
        error: NSError?)
    {
        if let error = error {
            print("書き込み失敗...error: \(error), characteristic uuid: \(characteristic.UUID)")
            return
        }
        
        print("書き込み成功！service uuid: \(characteristic.service.UUID), characteristic uuid: \(characteristic.UUID), value: \(characteristic.value)")
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

    @IBAction func ledBtnTapped(sender: UIButton) {

        if settingCharacteristic == nil || outputCharacteristic == nil {
            
            print("Konashi is not ready!")
            return;
        }

        // LED2を光らせる
        
        // 書き込みデータ生成（LED2）
        var value: CUnsignedChar = 0x01 << 1
        let data = NSData(bytes: &value, length: 1)

        // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
        peripheral.writeValue(
            data,
            forCharacteristic: settingCharacteristic,
            type: CBCharacteristicWriteType.WithoutResponse)
        
        // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
        peripheral.writeValue(
            data,
            forCharacteristic: outputCharacteristic,
            type: CBCharacteristicWriteType.WithoutResponse)
    }
}

