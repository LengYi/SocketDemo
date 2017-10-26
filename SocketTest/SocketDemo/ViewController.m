//
//  ViewController.m
//  SocketDemo
//
//  Created by Ice on 2017/10/21.
//  Copyright © 2017年 Ice. All rights reserved.
//

#import "ViewController.h"
#import "TCPClient.h"
#import "TCPServer.h"
#import <DLProtocolPackage.h>
#import "PackageData.h"
#import "AnalyzeData.h"
#import "Person.pbobjc.h"

@interface ViewController ()
@property (nonatomic,strong) UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *serverBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 100, 200, 100)];
    [serverBtn setTitle:@"初始化服务器端" forState:UIControlStateNormal];
    serverBtn.backgroundColor = [UIColor redColor];
    [serverBtn addTarget:self action:@selector(initServer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:serverBtn];
    
    
    UIButton *clientBtn = [[UIButton alloc] initWithFrame:CGRectMake(230, 100, 200, 100)];
    [clientBtn setTitle:@"初始化客户端" forState:UIControlStateNormal];
    clientBtn.backgroundColor = [UIColor redColor];
    [clientBtn addTarget:self action:@selector(initClient) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:clientBtn];
    
    UIButton *serverSendBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 230, 200, 100)];
    [serverSendBtn setTitle:@"发送服务器端数据" forState:UIControlStateNormal];
    serverSendBtn.backgroundColor = [UIColor redColor];
    [serverSendBtn addTarget:self action:@selector(sendServerDataToClient) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:serverSendBtn];
    
    UIButton *clientSendBtn = [[UIButton alloc] initWithFrame:CGRectMake(230, 230, 200, 100)];
    [clientSendBtn setTitle:@"发送客户端数据" forState:UIControlStateNormal];
    clientSendBtn.backgroundColor = [UIColor redColor];
    [clientSendBtn addTarget:self action:@selector(sendClientDataToServer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:clientSendBtn];
    
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 340, 300, 300)];
    _textView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_textView];
}

- (void)initServer{
    [[TCPServer shareInstance] beginListen:1234];
}

- (void)initClient{
    [[TCPClient shareInstance] socketConnectToHost:@"192.168.2.20" onPort:1234];
}

// 发送服务端数据
- (void)sendServerDataToClient{
    NSData *data = [@"Hello 客户端" dataUsingEncoding:NSUTF8StringEncoding];
    [[TCPServer shareInstance] sendData:data];
}

// 发送客户端数据
- (void)sendClientDataToServer{
//    NSData *data1 = [@"Hello 服务端" dataUsingEncoding:NSUTF8StringEncoding];
//    [[TCPClient shareInstance] sendData:data1];
//    return;
    
    NSData *pdata = [PackageData packageDataWithOrder:1000 stringObject:@"Hello",@"爱我中国",@"500",@"900",nil];
    NSLog(@"pdata = %@",pdata);
    [[TCPClient shareInstance] sendData:pdata];
//    [AnalyzeData analyzeData:pdata completion:^(AnalyzeCode code, short protocolVer, short orderID, NSArray *arr) {
//
//    }];
    
    return;
    pdata = [PackageData packageDataWithOrder:2000 stringObject:@"100",@"300",@"500",@"900",nil];
    NSLog(@"pdata = %@",pdata);
    [[TCPClient shareInstance] sendData:pdata];
    
//    [AnalyzeData analyzeData:pdata completion:^(AnalyzeCode code, short protocolVer, short orderID, NSArray *arr) {
//
//    }];

    return;
    [self postData];
    return;
    NSData *data = [@"Hello 服务端" dataUsingEncoding:NSUTF8StringEncoding];
    [[TCPClient shareInstance] sendData:data];
}

- (NSData *)organizeData{
    return  nil;
}

- (NSData *)postData{
    // 头
    Byte byteHeader[2] = {0x4e,0x4d};
    NSMutableData *dataHeader = [NSMutableData dataWithBytes:byteHeader length:sizeof(byteHeader)];
    
    // 版本号
    Byte byteVer[4] = {0x01,0x00,0x00,0x01};
    NSData *verData = [NSData dataWithBytes:byteVer length:sizeof(byteVer)];
    
    // 备用字节
    Byte byteBeiYong[8] = {};
    NSData *byData = [NSData dataWithBytes:byteBeiYong length:sizeof(byteBeiYong)];
    
    // 时间
    Byte byteTime[7] = {};
    NSData *timeData = [NSData dataWithBytes:byteTime length:sizeof(byteTime)];
    
    // json 数据
    NSDictionary *dic = @{@"js":@"ok",@"key2":@[@"1",@"2",@"3"],@"key":@"123"};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:dic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    // 数据总长 4 字节
    int totalLength = (int)[postData length];
    NSData *totalData = [NSData dataWithBytes:&totalLength length:sizeof(totalLength)];
    
    // 尾部数据
    Byte tail[] = {'\0'};
    NSData *tailData = [NSData dataWithBytes:tail length:sizeof(tail)];
    //  2   4   8      7     4
    // |头|版本|备用字节|时间|实际数据总长|实际数据|尾部数据       25字节 + 实际数据
    [dataHeader appendData:verData];  // 6
    [dataHeader appendData:byData];   // 14
    [dataHeader appendData:timeData];  // 7
    [dataHeader appendData:totalData]; //
    [dataHeader appendData:postData];
    [dataHeader appendData:tailData];
    
    [self analyzeData:dataHeader];
    return dataHeader;
}

- (void)analyzeData:(NSData *)data{
    if (data.length >= 25) {
        NSData *headerData = [data subdataWithRange:NSMakeRange(0, 25)];
        NSData *realLengthData = [headerData subdataWithRange:NSMakeRange(21,4)];
        
        int length;
        [realLengthData getBytes:&length length:sizeof(length)];
        
        NSData *realData = [data subdataWithRange:NSMakeRange(26, length)];
        NSString *s = [[NSString alloc] initWithData:realData encoding:NSUTF8StringEncoding];
        
        NSLog(@"111 = %d,s = %@",length,s);
    }
}

- (void)sendPbData{
    AppContextMessage *builder = [AppContextMessage message];
    [builder setNetConnetionType:@"wifi"];
    [builder setScreenResolution:@""];
    [builder setMacAddress:@""];
    [builder setCarrierName:@"中国联通"];
    [builder setDeviceModel:@""];
    [builder setWifiName:@"my_wifi(8c:21:a:44:f0:c)"];
    [builder setDeviceType:@"iPhone"];
    [builder setSystemVersion:@""];
    [builder setDeviceUuid:@""];
    [builder setDeviceName:@""];
    [builder setGps:@""];
    [builder setAppVersion:@"1.0.1_20"];
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 3; i++) {
        User *us = [User message];
        NSString *name = [NSString stringWithFormat:@"name %d",i];
        NSString *age = [NSString stringWithFormat:@"age %d",i];
        us.name = name;
        us.age = age;
        
        [arr addObject:us];
    }
    
    builder.usersArray = arr;
    
    NSMutableDictionary *dc = [[NSMutableDictionary alloc] initWithDictionary:@{@"key1":@"value1",@"key2":@"爱我中华"}];
    builder.dic = dc;
    
    NSData *data11 = builder.data;
    
    AppContextMessage *d = [[AppContextMessage alloc] initWithData:data11 error:nil];
    NSLog(@"appVersion = %@",d.appVersion);
    NSLog(@"dic = %@",d.dic);
    
    NSLog(@"%@",[d description]);
    NSLog(@"data: %ld", data11.length);
    NSLog(@"length: %ld", d.description.length);
    
    return;
}

- (void)sendImageData{
    
    NSData *imageNameData = [self dataFromString:@"世界名画-->梵高的向日葵"];
    NSData *imageWidthData = [self dataFromString:@"1000"];
    NSData *imageHeightData = [self dataFromString:@"800"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Image" ofType:@"zip"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    NSArray *postDataArray = @[imageNameData,imageWidthData,imageHeightData,data];
    
    NSData *postData = [PackageData packageDataWithOrder:100 dataArray:postDataArray];
    
    [[TCPClient shareInstance] sendData:postData];
}

- (NSData *)dataFromString:(NSString *)string{
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
