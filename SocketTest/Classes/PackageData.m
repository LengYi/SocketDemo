//
//  PackageData.m
//  SocketDemo
//
//  Created by ice on 2017/10/24.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import "PackageData.h"

const short int ProtocolVer = 1000; // 协议版本

@implementation PackageData

+ (NSData *)packageDataWithOrder:(short int)order stringObject:(id)firstObject,...{
    id eachObject = nil;
    va_list argumentList;
    if (firstObject && [firstObject isKindOfClass:[NSString class]]) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        // 第一个参数转换成Data,并存储至数组
        [array addObject:[PackageData dataFromString:firstObject]];
        
        // 获取所有参数并存入 argumentList
        va_start(argumentList, firstObject);
        // 取出每一个参数
        while ((eachObject = va_arg(argumentList, id))) {
            [array addObject:[PackageData dataFromString:eachObject]];
        }
        
        va_end(argumentList);
        NSLog(@"222== %@ -> %@",firstObject,array);
        return [PackageData packageDataWithOrder:order dataArray:array];
    }else{
#ifdef DEBUG
        NSLog(@"参数仅支持NSString类型");
#endif
    }
    
    return nil;
}

+ (NSData *)packageDataWithOrder:(short int)order dataArray:(NSArray *)array{
    // 协议版本
    NSData *protocolVerData = [[NSData alloc] initWithBytes:&ProtocolVer length:sizeof(ProtocolVer)];
    
    // 协议ID
    //Byte orderByte[2] = {0x64};  // 100
    NSData *orderData = [[NSData alloc] initWithBytes:&order length:sizeof(order)];
    
    // 实际发送包
    NSMutableData *postData = [[NSMutableData alloc] init];
    for (NSData *data in array) {
        if (data == nil) {// 没有数据的包头长为 8 Byte
            NSInteger totalLength = 8;
            NSData *msgTotalLengthData = [[NSData alloc] initWithBytes:&totalLength length:sizeof(totalLength)];
            
            // 消息总长
            [postData appendData:msgTotalLengthData];
            // 协议版本
            [postData appendData:protocolVerData];
            // 协议ID
            [postData appendData:orderData];
            // 空数据
            continue;
        }else{
            int totalLength = (int)[data length] + 8; // 实际实际长度 + 头部长度
            NSLog(@"111 %d",totalLength);
            NSData *msgTotalLengthData = [[NSData alloc] initWithBytes:&totalLength length:sizeof(totalLength)];
            
            // 消息总长
            [postData appendData:msgTotalLengthData];
            // 协议版本
            [postData appendData:protocolVerData];
            // 协议ID
            [postData appendData:orderData];
            // 实际数据
            [postData appendData:data];
        }
    }
    
    return postData;
}

+ (NSData *)dataFromString:(NSString *)string{
    if (string == nil || ![string isKindOfClass:[NSString class]]) {
#ifdef DEBUG
        NSLog(@"参数 %@ 是 %@,不是NSStirng类型",string,[string class]);
#endif
        return nil;
    }
    
    NSData *resultData = [NSData dataWithBytes:[string UTF8String]
                                        length:strlen([string UTF8String])];
    return resultData;
}
@end
