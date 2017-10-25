//
//  PackageData.h
//  SocketDemo
//
//  Created by ice on 2017/10/24.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import <UIKit/UIKit.h>

//   * +--------------------------------------------------------------------+----------------------+
//   * |                         Header                                     |      Body            |
//   * +----------------------+----------------------+----------------------+----------------------+
//   * |       消息总长        |       协议版本         |       协议ID          |      实际数据         |
//   * |      (4 bytes)       |     (2 bytes)        |     (2 bytes)        |      (? bytes)       |
//   * +----------------------+----------------------+----------------------+----------------------+
//   消息总长 = Header + Body = 4 + 2 + 2 + [Body length]
//   协议版本 当前协议的版 初始为1.0，用于协议变更兼容
//   协议ID 请求的服务器命令ID 服务器用于区分客户端请求的那个接口
//   实际数据 实际需要发送的数据

@interface PackageData : NSObject

+ (NSData *)packageDataWithOrder:(short int)order stringObject:(id)firstObject,...;

@end
