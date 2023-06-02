//
//  ViewController.swift
//  BLEAdvertiseExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController {

    @IBOutlet var advertiseBtn: UIButton!
    private var peripheralManager: CBPeripheralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ペリフェラルマネージャ初期化
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    // MARK: - Private
    
    private func publishservice () {
        
        // サービスを作成
        let serviceUUID = CBUUID(string: "0000")
        let service = CBMutableService(type: serviceUUID, primary: true)

        // キャラクタリスティックを作成
        let characteristicUUID = CBUUID(string: "0001")
        let properties: CBCharacteristicProperties = [.notify, .read, .read]
        let permissions: CBAttributePermissions = [.readable, .writeable]
        let characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: properties, value: nil, permissions: permissions)

        // キャラクタリスティックをサービスにセット
        service.characteristics = [characteristic]

        // サービスを Peripheral Manager にセット
        peripheralManager.add(service)
    }
    
    private func startAdvertise() {

        // アドバタイズしたいサービスのUUIDのリスト
        let serviceUUIDs = [CBUUID(string: "0000")]
        
        // アドバタイズメントデータを作成する
        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "Test Device",
            CBAdvertisementDataServiceUUIDsKey: serviceUUIDs
        ]
        
        // アドバタイズ開始
        peripheralManager.startAdvertising(advertisementData)
        
        advertiseBtn.setTitle("STOP ADVERTISING", for: .normal)
    }
    
    private func stopAdvertise () {
        // アドバタイズ停止
        peripheralManager.stopAdvertising()
        
        advertiseBtn.setTitle("START ADVERTISING", for: .normal)
    }
    
    // MARK: - Action
    
    @IBAction func advertiseButtonTapped(_ sender: UIButton) {
        if (!peripheralManager.isAdvertising) {
            startAdvertise()
        } else {
            stopAdvertise()
        }
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    // ペリフェラルマネージャの状態が変化すると呼ばれる
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("state: \(peripheral.state)")
        
        switch peripheral.state {
        case .poweredOn:
            // サービス登録開始
            publishservice()
        default:
            break
        }
    }
    
    // サービス追加処理が完了すると呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didAdd service: CBService,
                           error: Error?)
    {
        if let error = error {
            print("サービス追加失敗！ error: \(error)")
            return
        }
        print("サービス追加成功！")
        
        // アドバタイズ開始
        startAdvertise()
    }
    
    // アドバタイズ開始処理が完了すると呼ばれる
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("アドバタイズ開始失敗！ error: \(error)")
            return
        }
        print("アドバタイズ開始成功！")
    }
}
