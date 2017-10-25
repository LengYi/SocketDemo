//
//  TCPServer.m
//  SocketDemo
//
//  Created by Ice on 2017/10/21.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import "TCPServer.h"
#import <GCDAsyncSocket.h>

@interface TCPServer ()<GCDAsyncSocketDelegate>
@property (nonatomic,strong) GCDAsyncSocket *serverSocket;
@property (nonatomic,strong) NSMutableArray *clientSockets;  // 保存客户端连接过来的所有socket
@end

@implementation TCPServer
+ (TCPServer *)shareInstance{
    static TCPServer *server = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!server) {
            server = [[TCPServer alloc] init];
        }
    });
    
    return server;
}

- (instancetype)init{
    if (self = [super init]) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _clientSockets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)beginListen:(uint16_t)port{
    NSError *error = nil;
    BOOL flag = [self.serverSocket acceptOnPort:port error:&error];
    if(flag){
        NSLog(@"服务端 %@ 端口成功开启",[NSString stringWithFormat:@"%d",port]);
    }else{
        NSLog(@"服务端 %@ 端口开启失败",[NSString stringWithFormat:@"%d",port]);
    }
}

- (void)sendData:(NSData *)data{
    if(self.clientSockets == nil || self.clientSockets.count == 0) return;
    [self.clientSockets enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj writeData:data withTimeout:-1 tag:0];
    }];
}

#pragma mark -
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    NSLog(@"接收到来自 %@:%@ 的连接",newSocket.connectedHost,[NSString stringWithFormat:@"%d",newSocket.connectedPort]);
    
    // 保存客户端的连接
    [_clientSockets addObject:newSocket];
    
    // 注意这边用的是newSocket不是自己创建的serverSocket
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *recvStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到客户端数据 %@",recvStr);
    
    // 执行以下操作才能持续获取到客户端发送来的数据
    [sock readDataWithTimeout:- 1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    NSLog(@"断开和服务器的连接 %@",err.userInfo);
    [_clientSockets removeObject:sock];
}
@end
