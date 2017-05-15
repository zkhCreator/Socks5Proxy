//
//  SPConnect.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPConnect.h"
#import "SPSocketUtil.m"

@interface SPRemoteConfig()

@property (nonatomic, copy) NSString *remoteAddress;
@property (nonatomic, assign) NSInteger remotePort;

@end

@implementation SPRemoteConfig

- (instancetype)initWithAddress:(NSString *)address port:(NSInteger)port {
    self = [super init];
    if (self) {
        _remoteAddress = address;
        _remotePort = port;
    }
    return self;
}

@end

typedef NS_ENUM(NSInteger, SPConnectStatus) {
    SPCheckSOCKSVersionStatus = 0,
    SPCheckAuthStatus = 1,
    SPSendMessageStatus = 2,
};

@interface SPConnect()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) SPRemoteConfig *remoteConfig;
@property (nonatomic, copy) NSData *currentData;

@end

@implementation SPConnect

- (instancetype)initWithSocket:(GCDAsyncSocket*) socket remoteConfig:(SPRemoteConfig *)config {
    if (self = [super init]) {
        _clientSocket = socket;
        _remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.socket.queue", 0)];
        _remoteConfig = config;
    }
    return self;
}

- (void)disconnect {
    [_remoteSocket disconnectAfterReadingAndWriting];
}

- (void)startConnectWithData:(NSData *)data {
    // 储存数据准备连接到远端的服务端。
    _currentData = data;
    NSError *error;
    BOOL isConnect = [_remoteSocket connectToHost:_remoteConfig.remoteAddress onPort:_remoteConfig.remotePort error:&error];
    if (isConnect) {
        NSLog(@"连接成功");
        NSData *requestData = [self makeUpSendData:SPCheckSOCKSVersionStatus];
        [_remoteSocket writeData:requestData withTimeout:-1 tag:SPCheckSOCKSVersionStatus];
    } else {
        NSLog(@"连接失败");
    }
}

- (NSData *)makeUpSendData:(SPConnectStatus)tag {
    
    if (tag == SPCheckSOCKSVersionStatus) {
        NSMutableData *data = [NSMutableData data];
        // 协议请求包。
        unsigned char whole_byte;
        char byte_chars[3] = {'\5', '\1', '\0'};
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
        
        return [data copy];
    } else if (tag == SPCheckAuthStatus) {
        // 验证，当前不需要验证
        return nil;
    } else if (tag == SPSendMessageStatus) {
        // 组装请求包
        NSMutableData *data = [NSMutableData data];
        NSString *string = [NSString stringWithFormat:@"5101"];
        [data appendData:[self dataFromHexString:string]];
        
        // URL
        NSString *url = _remoteConfig.remoteAddress;
        [data appendData:[url dataUsingEncoding:NSUTF8StringEncoding]];
        // Prot
        [data appendData:[self dataFromHexString:[NSString stringWithFormat:@"%ld", _remoteConfig.remotePort]]];
        
        [data appendData:_currentData];
        
        return [data copy];
    }
    
    return nil;
}

- (NSData *)dataFromHexString:(NSString *)string
{
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    NSUInteger length = string.length;
    while (i < length - 1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    NSLog(@"%@", data);
    return data;
}

#pragma mark - delegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"readData Sock:%@", sock);
    NSLog(@"data:%@", data);
    
    
}

@end