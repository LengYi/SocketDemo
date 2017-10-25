//
//  AnalyzeData.h
//  SocketDemo
//
//  Created by ice on 2017/10/24.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,AnalyzeCode) {
    /* 协议解析成功 */
    kAnalyzeCodeSuccess = 1,
    /* 协议解析失败 */
    kAnalyzeCodeFailed = 0
};

@interface AnalyzeData : NSObject

+ (void)analyzeData:(NSData *)data completion:(void (^)(AnalyzeCode code,short int protocolVer,short int orderID ,NSArray *arr))handle;

@end
