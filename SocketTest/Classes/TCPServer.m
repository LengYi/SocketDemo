//
//  TCPServer.m
//  SocketDemo
//
//  Created by Ice on 2017/10/21.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import "TCPServer.h"
#import <GCDAsyncSocket.h>
#import "AnalyzeData.h"

#define  MAX_DATALENGTH 2000000
#define HDEART_BEAT 60

@interface TCPServer ()<GCDAsyncSocketDelegate>
@property (nonatomic,strong) GCDAsyncSocket *serverSocket;
@property (nonatomic,strong) NSMutableArray *clientSockets;  // 保存客户端连接过来的所有socket
@property (nonatomic,strong) NSMutableData *cacheData;
@property (nonatomic,assign) BOOL continueWaitData; // 是否继续等待数据
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

- (void) handleReceiveData:(NSData *)handleData{
    // 取出头部数据
    NSData *headerData = [handleData subdataWithRange:NSMakeRange(0, 8)];
    // 获取消息总长
    int totalLength;
    [headerData getBytes:&totalLength length:sizeof(totalLength)];
    
    [AnalyzeData analyzeData:handleData completion:^(AnalyzeCode code, short protocolVer, short orderID, NSArray *arr) {

    }];
    
    // 计算处理之后还剩余待数据的长度
    short int otherLength = [handleData length] - totalLength;
    _cacheData = (NSMutableData *)[handleData subdataWithRange:NSMakeRange(totalLength, otherLength)];
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
    
    // 先全部缓存起来,长度超过协议头长度才开始解析数据,解析完之后删除解析过的部分
    if (!_cacheData) {
        _cacheData = [[NSMutableData alloc] init];
    }
    [_cacheData appendData:data];
    
    if (_cacheData.length >= 8) {
        // 解析数据
        [self handleReceiveData:_cacheData];
    }
    
    // 执行以下操作才能持续获取到客户端发送来的数据
    [sock readDataWithTimeout:- 1 tag:0];

}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    NSLog(@"断开和服务器的连接 %@",err.userInfo);
    [_clientSockets removeObject:sock];
    
    _cacheData = nil; // 清空缓冲区数据
}
@end
