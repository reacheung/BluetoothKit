//
//  RCCBCentralManager.m
//  
//
//  Created by reacheung on 16/10/19.
//
//

#import "RCCBCentralManager.h"
#import "RCCBPeripheral.h"

@interface RCCBCentralManager ()
{
    NSMutableArray*     _RCPeripheralArray;
}
@end


@implementation RCCBCentralManager

- (instancetype)initWithKnownPeripheralNames:(NSArray *)nameList
                                       queue:(dispatch_queue_t)queue
                                    delegate:(id<CBCentralManagerDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _RCPeripheralArray = [[NSMutableArray alloc] init];
        _delegate = delegate;
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
    }
    return self;
}

- (void)startScan
{
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [self scanForPeripheralsWithServices:nil options:options];
}

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options
{
    [self.manager scanForPeripheralsWithServices:serviceUUIDs options:options];
    self.isScanning = YES;
}

- (void)stopScan
{
    [self.manager stopScan];
    self.isScanning = NO;
}

//停止连接
- (void)stopContent
{
    for (RCCBPeripheral * yp in _RCPeripheralArray)
    {
        if ([yp isConnected] || [yp isConnecting])
        {
            yp.delegate = nil;
            [yp disconnect];
        }
    }
}

#pragma mark - 设备记录

- (void)addPeripheral:(RCCBPeripheral *)peripheral
{
    [_RCPeripheralArray addObject:peripheral];
}

- (void)removePeripheral:(RCCBPeripheral *)peripheral
{
    peripheral.delegate = nil;
    [peripheral disconnect];
    [_RCPeripheralArray removeObject:peripheral];
}

- (void)removePeripheralWithMac:(NSString*)mac
{
    if (mac.length > 0)
    {
        for (RCCBPeripheral *yPeripheral in _RCPeripheralArray)
        {
            if ([[yPeripheral.macString uppercaseString] isEqualToString:[mac uppercaseString]])
            {
                [self removePeripheral:yPeripheral];
                break;
            }
        }
    }
}

- (void)removeAllPeripherals
{
    for (RCCBPeripheral *yPeripheral in _RCPeripheralArray)
    {
        yPeripheral.delegate = nil;
        [yPeripheral disconnect];
    }
    [_RCPeripheralArray removeAllObjects];
}

- (RCCBPeripheral *)findPeripheral:(CBPeripheral *)peripheral
{
    RCCBPeripheral *result = nil;
    NSArray *peripheralsCopy = [NSArray arrayWithArray:_RCPeripheralArray];
    for (RCCBPeripheral *yPeripheral in peripheralsCopy)
    {
        if (yPeripheral.cbPeripheral == peripheral)
        {
            result = yPeripheral;
            break;
        }
    }
    return result;
}


- (RCCBPeripheral *)findPeripheralWithMac:(NSString *)macText
{
    RCCBPeripheral *result = nil;
    if (macText.length > 0)
    {
        NSArray *peripheralsCopy = [NSArray arrayWithArray:_RCPeripheralArray];
        for (RCCBPeripheral *yPeripheral in peripheralsCopy)
        {
            if ([[yPeripheral.macString uppercaseString] isEqualToString:[macText uppercaseString]])
            {
                result = yPeripheral;
                break;
            }
        }
    }
    return result;
}


#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        if ([weakSelf.delegate respondsToSelector:@selector(centralManagerDidUpdateState:)])
        {
            [weakSelf.delegate centralManagerDidUpdateState:central];
        }
    });
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        if ([weakSelf.delegate respondsToSelector:@selector(centralManager:willRestoreState:)])
        {
            [weakSelf.delegate centralManager:central willRestoreState:dict];
        }
    });
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        if ([weakSelf.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)])
        {
            [weakSelf.delegate centralManager:central
                        didDiscoverPeripheral:peripheral
                            advertisementData:advertisementData
                                         RSSI:RSSI];
        }
    });
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        
        RCCBPeripheral* cbPeripheral = [weakSelf findPeripheral:peripheral];
        [cbPeripheral makeConnectFinished];
        
        if ([weakSelf.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)])
        {
            [weakSelf.delegate centralManager:central didConnectPeripheral:peripheral];
        }
    });
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        
        RCCBPeripheral* cbPeripheral = [weakSelf findPeripheral:peripheral];
        [cbPeripheral reConnect];
        
        if ([weakSelf.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)])
        {
            [weakSelf.delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
        }
    });
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        
        RCCBPeripheral* cbPeripheral = [weakSelf findPeripheral:peripheral];
        [cbPeripheral reConnect];
        
        if ([weakSelf.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)])
        {
            [weakSelf.delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
        }
    });
}


@end
