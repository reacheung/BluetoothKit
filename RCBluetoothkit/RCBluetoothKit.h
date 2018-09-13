//
//  RCBluetoothKit.h
//  
//
//  Created by reacheung on 16/10/17.
//
//  Tips: ExtensionKit 找 GCD和NSObject分类

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger,BluetoothState)
{
    BluetoothStateUnauthorized,//拒绝授权
    BluetoothStatePoweredOff,
    BluetoothStatePoweredOn,
};


@protocol RCBluetoothKitDelegate <NSObject>
@optional

//开始扫描
- (void)bluetoothKitDidStartScan;

//停止扫描
- (void)bluetoothKitDidStopScan;

//扫描设备超时
- (void)didDiscoverPeripheralTimerOut;

//发现设备
- (void)didDiscoverPeripheralWithMac:(NSString *)mac;

//连接设备
- (void)didConnectPeripheralWithMac:(NSString *)mac;

//连接设备失败
- (void)didFailToConnectPeripheralWithMac:(NSString *)mac;

//取消连接设备
- (void)didDisconnectPeripheralWithMac:(NSString *)mac;

//设备距离变化
- (void)peripheralWithMac:(NSString*)mac rssiChanged:(NSInteger)rssiValue;


- (void)bluetoothKitDidUpdateState:(BluetoothState)state;

@end

@interface RCBluetoothKit : NSObject
{
    
}
@property (nonatomic, weak  ) id        <RCBluetoothKitDelegate> delegate;
@property (nonatomic, assign) BOOL      bluetoothValid; //蓝牙是否有效
@property (nonatomic, strong) NSArray   * filters;//过滤连接设备

- (void)openBluetoothKit;
- (void)closeBluetoothKit;

- (void)stopConnectPeripheralWithMac:(NSString *)mac;
@end
