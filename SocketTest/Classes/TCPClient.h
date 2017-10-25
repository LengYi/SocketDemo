//
//  TCPClient.h
//  SocketDemo
//
//  Created by Ice on 2017/10/21.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import <Foundation/Foundation.h>

enum{
    SocketOfflineByServer,      //服务器掉线
    SocketOfflineByUser,        //用户断开
    SocketOfflineByWifiCut,     //wifi 断开
};

@interface TCPClient : NSObject

+ (TCPClient *)shareInstance;

- (void)socketConnectToHost:(NSString *)host onPort:(uint16_t)port;
- (void)cutOffSocket;

/*
 */
- (void)sendData:(NSData *)data;
@end
