//
//  JGSBase+JGSPrivate.m
//  JGSourceBase
//
//  Created by 梅继高 on 2022/6/7.
//  Copyright © 2022 MeiJiGao. All rights reserved.
//

#import "JGSBase+JGSPrivate.h"

@implementation JGSBaseUtils (JGSPrivate)

+ (void)requestGitRepositoryFileContent:(NSString *)filePath retryTimes:(NSInteger)retryTimes completion:(void (^)(NSData * _Nullable))completion {
    
    if (filePath.length == 0) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    static NSMutableDictionary *retryTimesInfo = nil;
    if (retryTimesInfo == nil) {
        retryTimesInfo = @{}.mutableCopy;
    }
    
    // https://raw.githubusercontent.com/用户名/仓库名/分支名/文件路径
    // DOC: https://www.cnblogs.com/chen-xing/p/14058096.html
    
    NSMutableCharacterSet *mutSet = [NSCharacterSet URLPathAllowedCharacterSet].mutableCopy;
    [mutSet formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [mutSet formUnionWithCharacterSet:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    filePath = [filePath stringByAddingPercentEncodingWithAllowedCharacters:mutSet];
    
    /**
     // https://api.github.com/repos/Dengni8023/JGSourceBase/contents 获取仓库内容
     {
         "name": "LatestGlobalConfiguration.json.sec",
         "path": "LatestGlobalConfiguration.json.sec",
         "sha": "8913981d9b86a5080db01b25b4a59ba8e54d7d11",
         "size": 124,
         "url": "https://api.github.com/repos/Dengni8023/JGSourceBase/contents/LatestGlobalConfiguration.json.sec?ref=master",
         "html_url": "https://github.com/Dengni8023/JGSourceBase/blob/master/LatestGlobalConfiguration.json.sec",
         "git_url": "https://api.github.com/repos/Dengni8023/JGSourceBase/git/blobs/8913981d9b86a5080db01b25b4a59ba8e54d7d11",
         "download_url": "https://raw.githubusercontent.com/Dengni8023/JGSourceBase/master/LatestGlobalConfiguration.json.sec",
         "type": "file",
         "_links": {
           "self": "https://api.github.com/repos/Dengni8023/JGSourceBase/contents/LatestGlobalConfiguration.json.sec?ref=master",
           "git": "https://api.github.com/repos/Dengni8023/JGSourceBase/git/blobs/8913981d9b86a5080db01b25b4a59ba8e54d7d11",
           "html": "https://github.com/Dengni8023/JGSourceBase/blob/master/LatestGlobalConfiguration.json.sec"
         }
       }
     */
    // 以下地址受限于网络，可能存在请求不到数据情况
    // 同一地址可能4G请求报错，WiFi则正常
    NSString *fileContentAPI = @"https://raw.githubusercontent.com/Dengni8023/JGSourceBase/master";
    NSString *fileURL = [fileContentAPI stringByAppendingPathComponent:filePath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fileURL]];
    request.HTTPMethod = @"GET";
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    request.timeoutInterval = 10;
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        JGSPrivateLog(@"statusCode: %@, data length: %@, error: %@", @(httpResp.statusCode), @(data.length), error);
        if (httpResp.statusCode == 200 || httpResp.statusCode == 404) {
            if (completion) {
                completion(httpResp.statusCode == 200 && data.length > 0 ? data : nil);
            }
            return;
        }
        
        switch (error.code) {
            case NSURLErrorBadURL: {
                if (completion) {
                    completion(nil);
                }
                return;
            }
                break;
                
            default:
                break;
        }
        
        NSInteger retry = [retryTimesInfo[filePath] integerValue] + 1;
        NSInteger maxRetryTimes = MAX(retryTimes, 5); // 为避免网络阻塞，无限重试限制次数
        if (retry > maxRetryTimes) {
            
            // 避免下次无法重试问题
            [retryTimesInfo removeObjectForKey:filePath];
            if (completion) {
                completion(nil);
            }
            return;
        }
        
        retryTimesInfo[filePath] = @(retry);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * (1 + log2(retry)) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [JGSBaseUtils requestGitRepositoryFileContent:filePath retryTimes:retryTimes completion:completion];
        });
        
    }] resume];
}

@end

BOOL JGSPrivateLogEnable = NO; // 默认不打印日志
@implementation JGSLogFunction (JGSPrivate)

@end

FOUNDATION_EXTERN NSString * const JGSTemporaryFileSavedDirectory(void) {
    
    static NSString *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *directory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        directory = [directory stringByAppendingPathComponent:@"com.meijigao.JGSoureBase"];
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir] || !isDir) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        instance = directory;
    });
    return instance;
}

FOUNDATION_EXTERN NSString * const JGSPermanentFileSavedDirectory(void) {
    
    static NSString *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        directory = [directory stringByAppendingPathComponent:@"com.meijigao.JGSoureBase"];
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir] || !isDir) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        instance = directory;
    });
    return instance;
}

FOUNDATION_EXTERN NSString * const JGSLatestGlobalConfigurationSavedPath(void) {
    
    static NSString *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *dir = JGSPermanentFileSavedDirectory();
        instance = [dir stringByAppendingPathComponent:@"LatestGlobalConfiguration.json.sec"];
    });
    return instance;
}

FOUNDATION_EXTERN NSDictionary<NSString *, id> * const JGSLatestGlobalConfiguration(void) {
    
    static NSDictionary<NSString *, id> *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); //创建信号量
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSString *path = JGSLatestGlobalConfigurationSavedPath();
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                
                // 因版本问题，版本内置资源不一定为最新，需要读取网络仓库最新资源
                NSString *gitFilePath = @"LatestGlobalConfiguration.json.sec";
                [JGSBaseUtils requestGitRepositoryFileContent:gitFilePath retryTimes:0 completion:^(NSData * _Nullable fileData) {
                    
                    if (fileData.length > 0) {
                        //JGSPrivateLog(@"Use remote git file: %@", [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding]);
                        NSError *error = nil;
                        [fileData writeToFile:path options:(NSDataWritingAtomic) error:&error];
                        if (error) {
                            JGSPrivateLog(@"%@", error);
                        }
                    }
                }];
            });
            
            NSData *jsonData = [[NSFileManager defaultManager] fileExistsAtPath:path] ? [NSData dataWithContentsOfFile:path] : nil;
            if (jsonData.length > 0) {
                
                // 配置文件Base64解密
                // Baes64替换规则：同时从首尾遍历，每xx位字符串块首尾替换
                NSMutableString *base64String = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding].mutableCopy;
                NSInteger stringLen = base64String.length;
                NSInteger blockSize = 5;
                for (NSInteger i = 0; i < (stringLen / blockSize) * 0.5; i++) {
                    NSRange headrange = NSMakeRange(i * blockSize, blockSize);
                    NSString *headStr = [base64String substringWithRange:headrange];
                    NSRange tailRange = NSMakeRange(stringLen - (i + 1) * blockSize, blockSize);
                    NSString *tailStr = [base64String substringWithRange:tailRange];
                    [base64String replaceCharactersInRange:headrange withString:tailStr];
                    [base64String replaceCharactersInRange:tailRange withString:headStr];
                }
                
                NSData *originData = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
                NSError *error = nil;
                instance = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:originData options:kNilOptions error:&error];
                if (error != nil) {
                    //JGSPrivateLog(@"%@", error);
                }
            }
            dispatch_semaphore_signal(semaphore);   //发送信号
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);  //等待
    });
    
    return instance;
}