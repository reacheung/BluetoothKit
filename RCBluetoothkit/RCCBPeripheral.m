//
//  RCCBPeripheral.m
//  
//
//  Created by reacheung on 16/10/19.
//
//

#import "RCCBPeripheral.h"
#import "RCCBCentralManager.h"

#define TIME_CONNECT_TMIEOUT    15 //超时时间
#define RE_CONNECT_COUNT_MAX    3  //重连最大次数

@interface RCCBPeripheral ()
{
    NSTimer  *_timeoutTimer;
    BOOL     _needReconnect;
}
@property (nonatomic, assign) NSInteger               reConnectCount;
@end

@implementation RCCBPeripheral

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                         macString:(NSString *)macString
                           central:(RCCBCentralManager *)centralManager
{
    self = [super init];
    if (self) {
        _central = centralManager;
        _cbPeripheral = peripheral;
        _macString = macString;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"RCCBPeripheral == dealloc");
}

- (CBPeripheralState)status
{
    return [_cbPeripheral state];
}

- (BOOL)isConnected
{
    return self.cbPeripheral.state == CBPeripheralStateConnected;
}

- (BOOL)isConnecting
{
    return self.cbPeripheral.state == CBPeripheralStateConnecting;
}

- (BOOL)isDisconnect
{
    return self.cbPeripheral.state == CBPeripheralStateDisconnected;
}

- (NSString*)name
{
    return [_cbPeripheral name];
}

- (NSString*)UUIDString
{
    return [[_cbPeripheral identifier] UUIDString];
}

#pragma mark - Action

- (void)connect
{
    NSLog(@"RCCBPeripheral == connect");
    _needReconnect = YES;
    _reConnectCount = 0;
    _cbPeripheral.delegate = self;
    [self dealConnect];
}

- (void)dealConnect
{
    NSLog(@"RCCBPeripheral == dealConnect:%@", [_cbPeripheral name]);

    [self.central.manager connectPeripheral:self.cbPeripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}];
}

- (void)reConnect
{
    if (_needReconnect) {
        //如果是自动断开则重连
        NSLog(@"RCCBPeripheral 状态变成未连接 触发自动连接");
        
        [self stopTimeoutTimer];
        
        _reConnectCount += 1;
        if (_reConnectCount < RE_CONNECT_COUNT_MAX)
        {
            [self startTimeoutTimer];
            
            //先取消
            [self.central.manager cancelPeripheralConnection:self.cbPeripheral];
            
            [self dealConnect];
            
            NSLog(@"RCCBPeripheral == reConnect Peripheral:%@", [_cbPeripheral name]);
        }
        else
        {
            NSLog(@"RCCBPeripheral == reConnect 超过次数:%@", [_cbPeripheral name]);
            
            [self makeConnectFailed];
            
            [self disconnectNeedCallBack:NO];//断开连接
            
            dispatch_main_sync_safe(^{
                //提交警报
                if ([_delegate respondsToSelector:@selector(didFailToConnectPeripheral:)])
                {
                    [_delegate didFailToConnectPeripheral:self.cbPeripheral];
                }
            });
            
        }
    }
    
}

- (void)disconnect
{
    [self disconnectNeedCallBack:YES];
}

- (void)disconnectNeedCallBack:(BOOL)needCallBack
{

    NSLog(@"RCCBPeripheral == disconnect:%@",[_cbPeripheral name]);
    [self stopTimeoutTimer];
    _needReconnect = NO;
    _reConnectCount = 0;
    _cbPeripheral.delegate = nil;
    
    [self.central.manager cancelPeripheralConnection:self.cbPeripheral];
    if (needCallBack)
    {
        dispatch_main_sync_saRC(^{
            //主动断开
            if ([_delegate respondsToSelector:@selector(didDisConnectPeripheral:)])
            {
                [_delegate didDisConnectPeripheral:self.cbPeripheral];
            }
        });
    }
}

//设置连接成功
- (void)makeConnectFinished
{
    [self stopTimeoutTimer];
    _reConnectCount = 0;
}

//设置连接失败
- (void)makeConnectFailed
{
    [self stopTimeoutTimer];
    _reConnectCount = 0;
}

- (void)readRSSI
{
    [self.cbPeripheral readRSSI];
}

#pragma mark - 连接超时

- (void)startTimeoutTimer
{
    [self stopTimeoutTimer];
    NSLog(@"RCCBPeripheral startTimeoutTimer");
    
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:TIME_CONNECT_TMIEOUT
                                                     target:self
                                                   selector:@selector(timeoutTimerHandler)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)stopTimeoutTimer
{
    if (_timeoutTimer)
    {
        NSLog(@"RCCBPeripheral stopTimeoutTimer");
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
}

- (void)timeoutTimerHandler
{
    NSLog(@"RCCBPeripheral == timeoutTimerHandler");
    [self reConnect];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)])
        {
            [weakSelf.delegate peripheral:peripheral didDiscoverServices:error];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
        }
    });
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
        }
    });
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didWriteValueForDescriptor:descriptor error:error];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error;
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)])
        {
            [weakSelf.delegate peripheral:peripheral didReadRSSI:RSSI error:error];
        }
    });
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_saRC(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheralDidUpdateName:)])
        {
            [weakSelf.delegate peripheralDidUpdateName:peripheral];
        }
    });
}
@end
