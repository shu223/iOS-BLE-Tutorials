//
//  ViewController.m
//  BLESample
//
//  Created by Shuichi Tsutsumi on 10/9/14.
//  Copyright (c) 2014 Shuichi Tsutsumi. All rights reserved.
//

#import "ViewController.h"
@import CoreBluetooth;


@interface ViewController ()
<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    BOOL isScanning;
}
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;
@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
    
    self.valueLabel.text = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


// =============================================================================
#pragma mark - Private

- (void)updateValue {
    
    self.valueLabel.text = [NSString stringWithFormat:@"Characteristic value: %@", self.characteristic.value];
}


// =============================================================================
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    // 特に何もしない
    NSLog(@"centralManagerDidUpdateState:%ld", (long)central.state);
}

- (void)   centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
        advertisementData:(NSDictionary *)advertisementData
                     RSSI:(NSNumber *)RSSI
{
    NSLog(@"発見したBLEデバイス：%@", peripheral);

    self.peripheral = peripheral;
    
    // 接続開始
    [self.centralManager connectPeripheral:peripheral
                                   options:nil];
}

- (void)  centralManager:(CBCentralManager *)central
    didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"接続成功！");

    peripheral.delegate = self;

    // サービス探索開始
    [peripheral discoverServices:nil];
}

- (void)        centralManager:(CBCentralManager *)central
    didFailToConnectPeripheral:(CBPeripheral *)peripheral
                         error:(NSError *)error
{
    NSLog(@"接続失敗・・・");
}

- (void)     centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
                      error:(NSError *)error
{
    NSLog(@"接続が切断されました。");
    
    if (error) {
        NSLog(@"error: %@", error);
    }
    
    self.peripheral = nil;
    self.characteristic = nil;
    self.valueLabel.text = nil;
}


// =============================================================================
#pragma mark - CBPeripheralDelegate

// サービス発見時に呼ばれる
- (void)     peripheral:(CBPeripheral *)peripheral
    didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"エラー:%@", error);
        return;
    }
    
    NSArray *services = peripheral.services;
    NSLog(@"%lu 個のサービスを発見！:%@", (unsigned long)services.count, services);

    for (CBService *service in services) {
        
        // キャラクタリスティック探索開始
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// キャラクタリスティック発見時に呼ばれる
- (void)                      peripheral:(CBPeripheral *)peripheral
    didDiscoverCharacteristicsForService:(CBService *)service
                                   error:(NSError *)error
{
    if (error) {
        NSLog(@"エラー:%@", error);
        return;
    }
    
    NSArray *characteristics = service.characteristics;
    NSLog(@"%lu 個のキャラクタリスティックを発見！%@", (unsigned long)characteristics.count, characteristics);

    // 特定のキャラクタリスティックをプロパティに保持
    CBUUID *uuid = [CBUUID UUIDWithString:@"0001"];
    for (CBCharacteristic *aCharacteristic in characteristics) {
        
        if ([aCharacteristic.UUID isEqual:uuid]) {
            
            self.characteristic = aCharacteristic;
            break;
        }
    }
}

// Notify開始／停止時に呼ばれる
- (void)                             peripheral:(CBPeripheral *)peripheral
    didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                          error:(NSError *)error
{
    if (error) {
        NSLog(@"Notify状態更新失敗...error:%@", error);
    }
    else {
        NSLog(@"Notify状態更新成功！characteristic UUID:%@, isNotifying:%d",
              characteristic.UUID ,characteristic.isNotifying ? YES : NO);
    }
}


// データ更新時に呼ばれる
- (void)                 peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                              error:(NSError *)error
{
    if (error) {
        NSLog(@"データ更新通知エラー:%@", error);
        return;
    }
    
    NSLog(@"データ更新！ service UUID:%@, characteristic UUID:%@, value:%@",
          characteristic.service.UUID, characteristic.UUID, characteristic.value);
    
    [self updateValue];
}

- (void)                peripheral:(CBPeripheral *)peripheral
    didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                             error:(NSError *)error
{
    if (error) {
        NSLog(@"Write失敗...error:%@", error);
        return;
    }
    
    NSLog(@"Write成功！");

    // ※ このキャラクタリスティックの値には実はまだ更新が反映されていない
    [self updateValue];
}


// =============================================================================
#pragma mark - IBAction

- (IBAction)scanBtnTapped:(UIButton *)sender {

    if (!isScanning) {

        isScanning = YES;
        
        // スキャン開始
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"0000"]]
                                                    options:nil];
        [sender setTitle:@"STOP SCAN" forState:UIControlStateNormal];
    }
    else {
        
        // スキャン停止
        [self.centralManager stopScan];
        [sender setTitle:@"START SCAN" forState:UIControlStateNormal];
        isScanning = NO;
    }
}

- (IBAction)writeBtnTapped:(id)sender {

    Byte value = arc4random() & 0xff;
    NSData *data = [NSData dataWithBytes:&value length:1];

    [self.peripheral writeValue:data
              forCharacteristic:self.characteristic
                           type:CBCharacteristicWriteWithResponse];
}

- (IBAction)readBtnTapped:(id)sender {
    
    [self.peripheral readValueForCharacteristic:self.characteristic];
}

- (IBAction)notifyBtnTapped:(UIButton *)sender {

    if (!self.characteristic.isNotifying) {

        // Notify開始をリクエスト
        [self.peripheral setNotifyValue:YES
                      forCharacteristic:self.characteristic];
        
        [sender setTitle:@"STOP NOTIFY" forState:UIControlStateNormal];
    }
    else {
        // Notify停止をリクエスト
        [self.peripheral setNotifyValue:NO
                      forCharacteristic:self.characteristic];

        [sender setTitle:@"START NOTIFY" forState:UIControlStateNormal];
    }
}

@end
