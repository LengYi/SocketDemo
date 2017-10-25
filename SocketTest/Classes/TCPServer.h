//
//  TCPServer.h
//  SocketDemo
//
//  Created by Ice on 2017/10/21.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCPServer : NSObject

+ (TCPServer *)shareInstance;
- (void)beginListen:(uint16_t)port;
- (void)sendData:(NSData *)data;
@end
