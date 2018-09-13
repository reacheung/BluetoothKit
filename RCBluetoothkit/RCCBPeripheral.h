//
//  RCCBPeripheral.h
//  
//
//  Created by reacheung on 16/10/19.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class RCCBPeripheral;
@protocol RCCBPeripheralDelegate <CBPeripheralDelegate>
@optional
- (void)didFailToConnectPeripheral:(CBPeripheral *)peripheral;
- (void)didDisConnectPeripheral:(CBPeripheral *)peripheral;
@end

@class RCCBCentralManager;
@interface RCCBPeripheral : NSObject
<
    CBPeripheralDelegate
>
{

}
@property (nonatomic, strong) CBPeripheral              * cbPeripheral;
@property (nonatomic, weak  ) RCCBCentralManager        * central;
@property (nonatomic, weak  ) id<RCCBPeripheralDelegate>  delegate;

@property (nonatomic, readonly) NSString                * name;
@property (nonatomic, readonly) NSString                * UUIDString;
@property (nonatomic, copy    ) NSString                * macString;
@property (nonatomic, readonly) CBPeripheralState       status;

@property (nonatomic, readonly) BOOL                    isConnected;
@property (nonatomic, readonly) BOOL                    isConnecting;
@property (nonatomic, readonly) BOOL                    isDisconnect;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                         macString:(NSString *)macString
                           central:(RCCBCentralManager *)centralManager;

- (void)connect;
- (void)disconnect;
- (void)readRSSI;

//重连
- (void)reConnect;

//设置连接成功
- (void)makeConnectFinished;

//设置连接失败
- (void)makeConnectFailed;
@end
