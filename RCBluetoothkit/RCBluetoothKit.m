//
//  RCBluetoothKit.m
//  
//
//  Created by ios on 16/10/17.
//
//

#import "RCBluetoothKit.h"
#import "RCCBCentralManager.h"
#import "RCCBPeripheral.h"

#define TIME_SCAN_TMIEOUT   30
#define ADV_DATA_LEN        14


@interface RCBluetoothKit()
<
CBCentralManagerDelegate
,RCCBPeripheralDelegate
>
{
    RCCBCentralManager         *_cetralManager;
    NSTimer                    *_scanTimeoutTimer;
}
@end

@implementation RCBluetoothKit

- (id)init
{
    self = [super init];
    if (self)
    {
        [self centralManager];
    }
    return self;
}

- (RCCBCentralManager*)centralManager
{
    if (_cetralManager == nil)
    {
        dispatch_queue_t queue = dispatch_queue_create("com.yourpet.bluetoothkit.default", NULL);
        _cetralManager = [[RCCBCentralManager alloc] initWithKnownPeripheralNames:nil queue:queue delegate:self];
    }
    return _cetralManager;
}

- (void)openBluetoothKit
{
    [self centralManager];
    [self startScan];
}

- (void)closeBluetoothKit
{
    [self stopScan];
    [_cetralManager stopContent];
}

- (void)stopConnectPeripheralWithMac:(NSString *)mac
{
   RCCBPeripheral * peripheral = [_cetralManager findPeripheralWithMac:[mac uppercaseString]];
    if (peripheral && [peripheral isConnected])
    {
        [peripheral disconnect];
    }
}
#pragma mark - 工具方法

//开始扫描
- (void)startScan
{
    if ([_delegate respondsToSelector:@selector(bluetoothKitDidStartScan)])
    {
        [_delegate bluetoothKitDidStartScan];
    }
    [self startScanAction];
}

- (void)startScanAction
{
    [[self centralManager] startScan];
    
    [self startScanTimeoutTimer];
}


//结束扫描
- (void)stopScan
{
    [self cancelScanTimeoutTimer];
    [_cetralManager stopScan];
    if ([_delegate respondsToSelector:@selector(bluetoothKitDidStopScan)])
    {
        [_delegate bluetoothKitDidStopScan];
    }
}

//可以连接的设备
- (BOOL)canConnectPeripheralWithMac:(NSString *)mac
{
    if (mac.length > 0)
    {
        for (NSString * curMac in _filters)
        {
            if ([[curMac uppercaseString] isEqualToString:[mac uppercaseString]])
            {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - scan timer

- (void)startScanTimeoutTimer
{
    [self cancelScanTimeoutTimer];
    
    _scanTimeoutTimer  = [NSTimer scheduledTimerWithTimeInterval:TIME_SCAN_TMIEOUT
                                                          target:self
                                                        selector:@selector(scanTimetoutTimerHandler)
                                                        userInfo:nil
                                                          repeats:NO];
}

- (void)cancelScanTimeoutTimer
{
    if (_scanTimeoutTimer)
    {
        [_scanTimeoutTimer invalidate];
        _scanTimeoutTimer = nil;
    }
}

- (void)scanTimetoutTimerHandler
{
    [self cancelScanTimeoutTimer];
    if ([_delegate respondsToSelector:@selector(didDiscoverPeripheralTimerOut)])
    {
        [_delegate didDiscoverPeripheralTimerOut];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    BluetoothState state = BluetoothStatePoweredOn;
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
        {
            self.bluetoothValid = YES;
            state = BluetoothStatePoweredOn;
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            self.bluetoothValid = NO;
            state = BluetoothStatePoweredOff;
            break;
        }
        case CBCentralManagerStateUnsupported:
        {
            self.bluetoothValid = NO;
            state = BluetoothStatePoweredOff;

            break;
        }
        case CBCentralManagerStateResetting:
        {
            [_cetralManager removeAllPeripherals];
            state = BluetoothStatePoweredOn;
            break;
        }
        case CBCentralManagerStateUnauthorized:
        {
            self.bluetoothValid = NO;
            state = BluetoothStateUnauthorized;

            break;
        }
        case CBCentralManagerStateUnknown:
        {
            self.bluetoothValid = NO;
            state = BluetoothStatePoweredOn;
            break;
        }
        default:
            break;
    }
    
    if ([_delegate respondsToSelector:@selector(bluetoothKitDidUpdateState:)])
    {
        [_delegate bluetoothKitDidUpdateState:state];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if (_filters.count > 0)
    {
        NSData * advData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
        NSString * advDataString = [advData description];
        if (advDataString.length > ADV_DATA_LEN)
        {
            NSString * curMac = [advDataString substringToIndex:ADV_DATA_LEN];
            curMac = [curMac stringByReplacingOccurrencesOfString:@" " withString:@""];
            curMac = [curMac stringByReplacingOccurrencesOfString:@"<" withString:@""];
            if ([self canConnectPeripheralWithMac:curMac])
            {
                NSLog(@"RCBluetoothKit == didDiscoverPeripheral:%@ %@ %@ mac:%@", [peripheral name], [peripheral identifier].UUIDString, [peripheral.services description],curMac);
                
                if ([_delegate respondsToSelector:@selector(didDiscoverPeripheralWithMac:)])
                {
                    [_delegate didDiscoverPeripheralWithMac:curMac];
                }
                
                RCCBPeripheral* RCPeripheral = [_cetralManager findPeripheral:peripheral];
                if (RCPeripheral == nil)
                {
                    RCPeripheral = [[RCCBPeripheral alloc] initWithPeripheral:peripheral macString:curMac central:_cetralManager];
                    [_cetralManager addPeripheral:RCPeripheral];
                }
                
                if ([RCPeripheral isDisconnect])
                {
                    [RCPeripheral connect];
                }
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"RCBluetoothKit == didConnectPeripheral:%@", [peripheral name]);

    RCCBPeripheral *yp = [_cetralManager findPeripheral:peripheral];
    if (yp)
    {
        if ([_delegate respondsToSelector:@selector(didConnectPeripheralWithMac:)])
        {
            [_delegate didConnectPeripheralWithMac:yp.macString];
        }
        yp.delegate = self;//设置代理很重要 方便发现服务，数据传输，didFailToConnectPeripheral回调
//        [yp readRSSI]; //获取信号强弱
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"RCBluetoothKit == didDisconnectPeripheral:%@", [peripheral name]);
    //用didFailToConnectPeripheral替代
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"RCBluetoothKit == didFailToConnectPeripheral:%@", [peripheral name]);
    //用didFailToConnectPeripheral替代
}

- (void)didFailToConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"RCBluetoothKit == retry didFailToConnectPeripheral:%@", [peripheral name]);
    RCCBPeripheral *yp = [_cetralManager findPeripheral:peripheral];
    if (yp)
    {
        if ([_delegate respondsToSelector:@selector(didFailToConnectPeripheralWithMac:)])
        {
            [_delegate didFailToConnectPeripheralWithMac:yp.macString];
        }
    }
}

- (void)didDisConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"RCBluetoothKit == retry didFailToConnectPeripheral:%@", [peripheral name]);
    RCCBPeripheral *yp = [_cetralManager findPeripheral:peripheral];
    if (yp)
    {
        if ([_delegate respondsToSelector:@selector(didDisconnectPeripheralWithMac:)])
        {
            [_delegate didDisconnectPeripheralWithMac:yp.macString];
        }
    }
}
#pragma mark - CBPeripheralDelegate Methods

- (void)performUpdateRSSI:(CBPeripheral *)peripheral
{
    [peripheral readRSSI];
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error
{
    NSLog(@"RCBluetoothKit == peripheralDidUpdateRSSI %@ %ld", [peripheral name], [RSSI integerValue]);
    if (error == nil)
    {
        RCCBPeripheral *yp = [_cetralManager findPeripheral:peripheral];
        if (yp)
        {
            if ([_delegate respondsToSelector:@selector(peripheralWithMac:rssiChanged:)])
            {
                [_delegate peripheralWithMac:yp.macString rssiChanged:[RSSI integerValue]];
            }
        }
    }
    
    /// 导入ExtensionKit NSObject分类
    [self performAfter:2.0 block:^{
        [self performUpdateRSSI:peripheral];
    }];
}

@end
