//
//  ViewController.swift
//  BLEScanExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate {

    var isScanning = false
    var centralManager: CBCentralManager!
    
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
    }
    
    
    // =========================================================================
    // MARK: Actions

    @IBAction func scanBtnTapped(sender: UIButton) {
        
        if !isScanning {
            
            isScanning = true
            
            centralManager.scanForPeripheralsWithServices(
                nil,
                options: nil
            )
            
            sender.setTitle("STOP SCAN", forState: UIControlState.Normal)
        }
        else {
            
            centralManager.stopScan()
            
            sender.setTitle("START SCAN", forState: UIControlState.Normal)
            
            isScanning = false
        }
    }
}

