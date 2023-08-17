//
//  NotificationService.m
//  NotificationService
//
//  Created by pzheng on 2023/07/27.
//  Copyright © 2023 LeanCloud. All rights reserved.
//

#import "NotificationService.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface NotificationService ()

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    [self handleNotificationRequest:request
                              appId:@"6HKynQEeIYeWpHmF9e7ocY5R-TeStHjQi"
                             appKey:@"FLx5kVKBU04k6SxmuIVndMNy"
                          serverURL:@"https://api.uc-test1.leancloud.cn"
                  completionHandler:^{
        contentHandler(request.content);
    }];
}

- (void)handleNotificationRequest:(UNNotificationRequest *)notificationRequest
                            appId:(NSString *)appId
                           appKey:(NSString *)appKey
                        serverURL:(NSString *)serverURL
                completionHandler:(void (^)(void))completionHandler {
    NSDictionary *userInfo = notificationRequest.content.userInfo;
#if DEBUG
    NSLog(@"LCNS UserInfo: %@", userInfo);
#endif
    NSString *token = userInfo[@"__token"];
    NSString *notificationId = userInfo[@"__nid"];
    if (![token isKindOfClass:[NSString class]] ||
        ![notificationId isKindOfClass:[NSString class]]) {
        completionHandler();
        return;
    }
    
    int64_t timestamp = (int64_t)(1000 * [NSDate date].timeIntervalSince1970);
    
    NSString *urlString = [serverURL stringByAppendingPathComponent:@"push/v1/callback/ios"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:appId forHTTPHeaderField:@"X-LC-Id"];
    [request setValue:[self signatureFromKey:appKey timestamp:timestamp] forHTTPHeaderField:@"X-LC-Sign"];
    [request setValue:@"LCNS/1.0" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *object = [NSMutableDictionary dictionary];
    object[@"deviceToken"] = token;
    object[@"notificationId"] = notificationId;
    object[@"receivedAt"] = @(timestamp);
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:@[object] options:0 error:&error];
    if (error) {
        NSLog(@"LCNS ERROR: %@", error);
        completionHandler();
        return;
    }
    [request setHTTPBody:data];
    
#if DEBUG
    NSLog(@"LCNS Request URL: %@, Header: %@, Body: %@",
          request.URL,
          request.allHTTPHeaderFields,
          [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
#endif
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"LCNS ERROR: %@", error);
        } else if (response) {
            NSLog(@"LCNS Response: %@, Data: %@", response, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        completionHandler();
    }] resume];
}

- (NSString *)signatureFromKey:(NSString *)key timestamp:(int64_t)timestamp {
    NSString *string = [NSString stringWithFormat:@"%@%@", @(timestamp), key];
    NSString *sign = [self md5String:string].lowercaseString;
    return [NSString stringWithFormat:@"%@,%@", sign, @(timestamp)];
}

- (NSString *)md5String:(NSString *)string {
    const char *cstr = [string UTF8String];
    unsigned char result[16];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
#pragma clang diagnostic pop
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

@end
