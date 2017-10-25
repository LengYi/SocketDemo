//
//  TCPClient.m
//  SocketDemo
//
//  Created by Ice on 2017/10/21.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import "TCPClient.h"
#import <GCDAsyncSocket.h>

@interface TCPClient ()<GCDAsyncSocketDelegate>
@property (nonatomic,strong) GCDAsyncSocket *socket;
@property (nonatomic,strong) NSString *host;
@property (nonatomic,assign) uint16_t port;
@property (nonatomic,strong) NSTimer *timer;
@end

@implementation TCPClient

+ (TCPClient *)shareInstance{
    static TCPClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!client) {
            client = [[TCPClient alloc] init];
        }
    });
    return client;
}

- (instancetype)init{
    if (self = [super init]) {
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)socketConnectToHost:(NSString *)host onPort:(uint16_t)port{
    self.socket.userData = @(SocketOfflineByServer);
    self.host = host;
    self.port = port;
    
    NSError *error = nil;
    [self.socket connectToHost:host onPort:port withTimeout:-1 error:&error];
    if (error) {
        NSLog(@"连接服务器失败 %@",error.userInfo);
    }else{
        NSLog(@"连接服务器成功");
    }
}

- (void)cutOffSocket{
    self.socket.userData = @(SocketOfflineByUser);
    [self.socket disconnect];
}

- (void)sendData:(NSData *)data{
    [self.socket writeData:data withTimeout:-1 tag:0];
}

#pragma mark - Private
// 心跳包检测
- (void)addLongConnectTimer{
    if(_timer){
        [_timer invalidate];
        _timer = nil;
    }
    
    _timer = [NSTimer timerWithTimeInterval:10
                                     target:self
                                   selector:@selector(keepLongConnect)
                                   userInfo:nil
                                    repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer
                                 forMode:NSRunLoopCommonModes];
}

// 向服务器发送固定格式的数据,进行心跳连接
- (void)keepLongConnect{
    NSString *longConnect = @"longConnect\r\n";
    NSData   *dataStream  = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:dataStream withTimeout:-1 tag:0];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"成功连接到服务器 %@:%@",host,[NSString stringWithFormat:@"%d",port]);
  
    // 连接成功后需执行以下操作,否则无法读取到服务器发送的数据
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *recvStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到服务端数据 %@",recvStr);
    
    // 继续执行以下操作,才能持续读取到服务器发送的数据
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    NSLog(@"断开和服务器的连接 %@",err.userInfo);
    // 用户断开连接,不自动重连
    NSInteger status = [self.socket.userData intValue];
    if(status == SocketOfflineByServer){// 服务器掉线重连
        self.socket.delegate = nil;
        [self.socket disconnect];
        
        NSError *error = nil;
        [self.socket connectToHost:self.host onPort:self.port withTimeout:-1 error:&error];
        if (error) {
            NSLog(@"重连接服务器失败 %@",error.userInfo);
        }else{
            NSLog(@"重连接服务器成功");
        }
    }else{// 用户自己断开连接和网络断开不重连
        self.socket = nil;
        self.socket.delegate = nil;
        [self.socket disconnect];
    }

}
@end
