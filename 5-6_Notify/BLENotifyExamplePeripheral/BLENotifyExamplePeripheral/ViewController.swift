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
    @IBOutlet var valueLabel: UILabel!
    var peripheralManager: CBPeripheralManager!
    var serviceUUID: CBUUID!
    var characteristic: CBMutableCharacteristic!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ペリフェラルマネージャ初期化
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
        self.valueLabel.text = nil;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // =========================================================================
    // MARK: Private
    
    func publishservice () {
        
        // サービスを作成
        self.serviceUUID = CBUUID(string: "0000")
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        // キャラクタリスティックを作成
        let characteristicUUID = CBUUID(string: "0001")
        
        let properties: CBCharacteristicProperties =
            [CBCharacteristicProperties.Notify, CBCharacteristicProperties.Read, CBCharacteristicProperties.Write]

        let permissions: CBAttributePermissions =
            [CBAttributePermissions.Readable, CBAttributePermissions.Writeable]
        
        self.characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: properties,
            value: nil,
            permissions: permissions)
        
        // キャラクタリスティックをサービスにセット
        service.characteristics = [self.characteristic]
        
        // サービスを Peripheral Manager にセット
        self.peripheralManager.addService(service)
        
        // 値をセット
        let value = UInt8(arc4random() & 0xFF)
        let data = NSData(bytes: [value], length: 1)
        self.characteristic.value = data;
    }
    
    func startAdvertise() {
        
        // アドバタイズメントデータを作成する
        let advertisementData = [
            CBAdvertisementDataLocalNameKey: "Test Device",
            CBAdvertisementDataServiceUUIDsKey: [self.serviceUUID]
        ]
        
        // アドバタイズ開始
        self.peripheralManager.startAdvertising(advertisementData)
        
        self.advertiseBtn.setTitle("STOP ADVERTISING", forState: UIControlState.Normal)
    }
    
    func stopAdvertise () {
        
        // アドバタイズ停止
        self.peripheralManager.stopAdvertising()
        
        self.advertiseBtn.setTitle("START ADVERTISING", forState: UIControlState.Normal)
    }
    
    func updateValueLabel () {
        
        self.valueLabel.text = "Characteristic value: \(self.characteristic.value)"
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
    
    // Readリクエスト受信時に呼ばれる
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        
        print("Readリクエスト受信！ requested service uuid:\(request.characteristic.service.UUID) characteristic uuid:\(request.characteristic.UUID) value:\(request.characteristic.value)")
        
        // プロパティで保持しているキャラクタリスティックへのReadリクエストかどうかを判定
        if request.characteristic.UUID.isEqual(self.characteristic.UUID) {
            
            // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
            request.value = self.characteristic.value;
            
            // リクエストに応答
            self.peripheralManager.respondToRequest(request, withResult: CBATTError.Success)
        }
    }
    
    // Writeリクエスト受信時に呼ばれる
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {

        print("\(requests.count) 件のWriteリクエストを受信！")

        for request in requests {
            
            print("Requested value:\(request.value) service uuid:\(request.characteristic.service.UUID) characteristic uuid:\(request.characteristic.UUID)")
            
            if request.characteristic.UUID.isEqual(self.characteristic.UUID) {
                
                // CBCharacteristicのvalueに、CBATTRequestのvalueをセット
                self.characteristic.value = request.value;
            }
        }

        // リクエストに応答
        self.peripheralManager.respondToRequest(requests[0] , withResult: CBATTError.Success)
    }
    
    // Notify開始リクエスト受信時に呼ばれる
    func peripheralManager(
        peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeToCharacteristic characteristic: CBCharacteristic)
    {
        print("Notify開始リクエストを受信")
        print("Notify中のセントラル: \(self.characteristic.subscribedCentrals)")
    }
    
    // Notify停止リクエスト受信時に呼ばれる
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic)
    {
        print("Notify停止リクエストを受信")
        print("Notify中のセントラル: \(self.characteristic.subscribedCentrals)")
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
    
    @IBAction func updateBtnTapped(sender: UIButton) {
        
        // 新しい値となるNSDataオブジェクトを生成
        let value = UInt8(arc4random() & 0xFF)
        let data = NSData(bytes: [value] as [UInt8], length: 1)
        
        // 値を更新
        self.characteristic.value = data;

        let result =  self.peripheralManager.updateValue(
            data,
            forCharacteristic: self.characteristic,
            onSubscribedCentrals: nil)
        
        print("result: \(result)")
        
        self.updateValueLabel()
    }
}

