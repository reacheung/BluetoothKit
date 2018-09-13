//
//  RCCBCentralManager.h
//  
//
//  Created by reacheung on 16/10/19.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class RCCBPeripheral;
@interface RCCBCentralManager : NSObject
<
CBCentralManagerDelegate
>
{

}

@property (nonatomic, weak  ) id <CBCentralManagerDelegate> delegate;
@property (atomic   , strong) CBCentralManager              *manager;
@property (atomic   , assign) BOOL                          isScanning;


- (instancetype)initWithKnownPeripheralNames:(NSArray *)nameList
                                       queue:(dispatch_queue_t)queue
                                    delegate:(id<CBCentralManagerDelegate>)delegate;

//搜索所有
- (void)startScan;

//搜索
- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs
                               options:(NSDictionary *)options;

//停止搜索
- (void)stopScan;

//停止连接
- (void)stopContent;

- (void)addPeripheral:(RCCBPeripheral *)yperipheral;

- (void)removePeripheral:(RCCBPeripheral *)yperipheral;
- (void)removePeripheralWithMac:(NSString*)mac;
- (void)removeAllPeripherals;

- (RCCBPeripheral *)findPeripheral:(CBPeripheral *)peripheral;
- (RCCBPeripheral *)findPeripheralWithMac:(NSString *)macText;
@end
