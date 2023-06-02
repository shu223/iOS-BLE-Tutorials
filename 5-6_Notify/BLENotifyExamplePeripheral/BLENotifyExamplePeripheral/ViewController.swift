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
    @IBOutlet var valueLabel: UILabel!
    private var peripheralManager: CBPeripheralManager!
    private var serviceUUID: CBUUID!
    private var characteristic: CBMutableCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        valueLabel.text = nil;

        // ペリフェラルマネージャ初期化
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    // MARK: - Private
    
    private func publishservice () {
        // サービスを作成
        serviceUUID = CBUUID(string: "0000")
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        // キャラクタリスティックを作成
        let characteristicUUID = CBUUID(string: "0001")
        let properties: CBCharacteristicProperties = [.notify, .read, .write]
        let permissions: CBAttributePermissions = [.readable, .writeable]
        characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: properties,
            value: nil,
            permissions: permissions)
        
        // キャラクタリスティックをサービスにセット
        service.characteristics = [characteristic]
        
        // サービスを Peripheral Manager にセット
        peripheralManager.add(service)
        
        // 値をセット
        let value = UInt8(arc4random() & 0xFF)
        let data = Data([value])
        characteristic.value = data;
    }
    
    private func startAdvertise() {
        // アドバタイズメントデータを作成する
        let advertisementData: [String : Any] = [
            CBAdvertisementDataLocalNameKey: "Test Device",
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
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
    
    private func updateValueLabel () {
        if let value = characteristic.value {
            valueLabel.text = "Characteristic value: \(value.hexString)"
        } else {
            valueLabel.text = nil
        }
    }
    
    // MARK: Actions
    
    @IBAction func advertiseButtonTapped(_ sender: UIButton) {
        if !peripheralManager.isAdvertising {
            startAdvertise()
        } else {
            stopAdvertise()
        }
    }
    
    @IBAction func updateButtonTapped(_ sender: UIButton) {
        // 新しい値となるNSDataオブジェクトを生成
        let value = UInt8(arc4random() & 0xFF)
        let data = Data([value])
        
        // 値を更新
        characteristic.value = data;

        let result = peripheralManager.updateValue(
            data,
            for: characteristic,
            onSubscribedCentrals: nil)
        print("result: \(result)")
        
        updateValueLabel()
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
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
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
    
    // Readリクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Readリクエスト受信！ requested service uuid:\(String(describing: request.characteristic.service?.uuid)) characteristic uuid:\(request.characteristic.uuid) value:\(String(describing: request.characteristic.value))")
        
        // プロパティで保持しているキャラクタリスティックへのReadリクエストかどうかを判定
        if request.characteristic.uuid.isEqual(characteristic.uuid) {
            // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
            request.value = characteristic.value;
            
            // リクエストに応答
            peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
    // Writeリクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("\(requests.count) 件のWriteリクエストを受信！")
        
        for request in requests {
            print("Requested value:\(String(describing: request.value)) service uuid:\(String(describing: request.characteristic.service?.uuid)) characteristic uuid:\(request.characteristic.uuid)")
            
            if request.characteristic.uuid.isEqual(characteristic.uuid) {
                // CBCharacteristicのvalueに、CBATTRequestのvalueをセット
                characteristic.value = request.value;
            }
        }
        
        // リクエストに応答
        peripheralManager.respond(to: requests[0], withResult: .success)
    }
    
    // Notify開始リクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic)
    {
        print("Notify開始リクエストを受信")
        print("Notify中のセントラル: \(String(describing: self.characteristic.subscribedCentrals))")
    }
    
    // Notify停止リクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic)
    {
        print("Notify停止リクエストを受信")
        print("Notify中のセントラル: \(String(describing: self.characteristic.subscribedCentrals))")
    }
}

extension Data {
    var hexString: String {
        return map { String(format: "%02X", $0) }.joined()
    }
}
