//
//  AnalyzeData.m
//  SocketDemo
//
//  Created by ice on 2017/10/24.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import "AnalyzeData.h"

@implementation AnalyzeData

+ (void)analyzeData:(NSData *)data completion:(void (^)(AnalyzeCode code,short int protocolVer,short int orderID ,NSArray *arr))handle{
    if (data) {
        int totalLength = (int)[data length];
        int index = 0;
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        do{
            if (data.length >= 8) {
                // 取出头部数据
                NSData *headerData = [data subdataWithRange:NSMakeRange(index, 8)];
                // 获取消息总长
                int totalLength;
                [headerData getBytes:&totalLength length:sizeof(totalLength)];
                
                // 获取协议版本
                NSData *protocolData = [headerData subdataWithRange:NSMakeRange(4,2)];
                short int protocolVer;
                [protocolData getBytes:&protocolVer length:sizeof(protocolVer)];
                
                // 获取协议ID
                NSData *orderData = [headerData subdataWithRange:NSMakeRange(6,2)];
                short int order;
                [orderData getBytes:&order length:sizeof(order)];
                
                // 解析实际数据
                int dataLength = totalLength - 8;
                
                index += 8;
                NSData *bodyData = [data subdataWithRange:NSMakeRange(index, dataLength)];
                NSString *str = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
                [arr addObject:str];
                index += dataLength;
                
                NSLog(@"解析实况-----> \n 消息总长 : %d \n 协议版本 : %u \n 协议ID : %u \n 实际数据 : %@",totalLength,protocolVer,order,str);
            }
        }while (index < totalLength);
        
        NSLog(@"解析结束 --- %@",arr);
    }
}

@end
