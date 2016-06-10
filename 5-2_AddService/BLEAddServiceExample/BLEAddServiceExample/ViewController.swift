//
//  ViewController.swift
//  BLEAdvertiseExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBPeripheralManagerDelegate {

    @IBOutlet var advertiseBtn: UIButton!
    var peripheralManager: CBPeripheralManager!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ペリフェラルマネージャ初期化
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // =========================================================================
    // MARK: Private
    
    func publishservice () {
        
        // サービスを作成
        let serviceUUID = CBUUID(string: "0000")
        let service = CBMutableService(type: serviceUUID, primary: true)

        // キャラクタリスティックを作成
        let characteristicUUID = CBUUID(string: "0001")
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: CBCharacteristicProperties.Read,
            value: nil,
            permissions: CBAttributePermissions.Readable)

        // キャラクタリスティックをサービスにセット
        service.characteristics = [characteristic]

        // サービスを追加
        self.peripheralManager.addService(service)
    }
    
    func startAdvertise() {

        // アドバタイズメントデータを作成する
        let advertisementData = [CBAdvertisementDataLocalNameKey: "Test Device"]
        
        // アドバタイズ開始
        self.peripheralManager.startAdvertising(advertisementData)
        
        self.advertiseBtn.setTitle("STOP ADVERTISING", forState: UIControlState.Normal)
    }
    
    func stopAdvertise () {
        
        // アドバタイズ停止
        self.peripheralManager.stopAdvertising()
        
        self.advertiseBtn.setTitle("START ADVERTISING", forState: UIControlState.Normal)
    }


    // =========================================================================
    // MARK: CBPeripheralManagerDelegate
    
    // ペリフェラルマネージャの状態が変化すると呼ばれる
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        print("state: \(peripheral.state)")

        switch peripheral.state {

        case CBPeripheralManagerState.PoweredOn:
            // サービス登録開始
            self.publishservice()
            break
        
        default:
            break
        }
    }
    
    // サービス追加処理が完了すると呼ばれる
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        
        if (error != nil) {
            print("サービス追加失敗！ error: \(error)")
            return
        }
        
        print("サービス追加成功！")

        // アドバタイズ開始
        self.startAdvertise()
    }

    // アドバタイズ開始処理が完了すると呼ばれる
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        
        if (error != nil) {
            print("アドバタイズ開始失敗！ error: \(error)")
            return
        }

        print("アドバタイズ開始成功！")
    }
    
    
    // =========================================================================
    // MARK: Actions
    
    @IBAction func advertiseBtnTapped(sender: UIButton) {

        if (!self.peripheralManager.isAdvertising) {
            
            self.startAdvertise()
        }
        else {
            self.stopAdvertise()
        }
    }
}

