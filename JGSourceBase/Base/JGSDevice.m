//
//  JGSDevice.m
//  JGSourceBase
//
//  Created by 梅继高 on 2021/3/16.
//  Copyright © 2021 MeiJigao. All rights reserved.
//

#import "JGSDevice.h"
#import <WebKit/WebKit.h>
#import "JGSBase.h"
#import <AdSupport/ASIdentifierManager.h>
#import <AppTrackingTransparency/ATTrackingManager.h>
#import <sys/utsname.h>
#import <sys/stat.h>
#import <dlfcn.h>

@implementation JGSDevice

static NSString *JGSourceBaseSystemUserAgent = nil;
+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JGSLog(@"默认 UserAgent");
        [self loadSystemUserAgen:nil];
    });
}

#pragma mark - APP
+ (NSDictionary *)appInfo {
    
    static NSDictionary *appInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appInfo = @{
            @"bundleId": [self bundleId],
            @"appVersion": [self appVersion],
            @"buildNumber": [self buildNumber]
        };
    });
    return appInfo;
}

+ (NSString *)bundleId {
    
    static NSString *bundleId = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    });
    return bundleId;
}

+ (NSString *)appVersion {
    
    static NSString *appVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0.0";
    });
    return appVersion;
}

+ (NSString *)buildNumber {
    
    static NSString *buildNumber = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"1";
    });
    return buildNumber;
}

#pragma mark - UA
+ (void)loadSystemUserAgen:(void (^ _Nullable)(NSString * _Nullable sysUA, NSError * _Nullable error))completion {
    
    if (JGSourceBaseSystemUserAgent.length > 0) {
        if (completion) {
            completion(JGSourceBaseSystemUserAgent, nil);
        }
        return;
    }
    
    // 异步获取系统UA
    static WKWebView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        JGSLog(@"默认 UserAgent Load");
        
        instance = instance ?: [[WKWebView alloc] init];
        [instance evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
            JGSLog(@"默认 UserAgent: %@, %@", result, error);
            if ([result isKindOfClass:[NSString class]] && [(NSString *)result length] > 0) {
                JGSourceBaseSystemUserAgent = (NSString *)result;
            }
            if (completion) {
                completion(JGSourceBaseSystemUserAgent, error);
            }
            
            if (JGSourceBaseSystemUserAgent.length == 0) {
                onceToken = 0;
            }
        }];
    });
}

+ (NSString *)sysUserAgent {
    
//    if (JGSourceBaseSystemUserAgent.length > 0) {
//        return JGSourceBaseSystemUserAgent;
//    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); //创建信号量
    [self loadSystemUserAgen:^(NSString * _Nullable sysUA, NSError * _Nullable error) {
        dispatch_semaphore_signal(semaphore);   //发送信号
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);  //等待
    
    return JGSourceBaseSystemUserAgent;
}

+ (NSString *)appUserAgent {
    
    static NSString *appUA = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *bids = [[self bundleId] componentsSeparatedByString:@"."];
        NSString *org = bids.count > 1 ? bids[1] : bids.firstObject;
        NSString *processName = [NSProcessInfo processInfo].processName;
        appUA = [NSString stringWithFormat:@"%@/%@ (Version %@; Build %@; %@)", org.uppercaseString, processName, [self appVersion], [self buildNumber], JGSUserAgent];
    });
    return appUA;
}

#pragma mark - Device
+ (NSDictionary<NSString *,id> *)deviceInfo {
    
    static NSDictionary *deviceInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL isFullScreen = [self isFullScreen];
        UIEdgeInsets insets = [self safeAreaInsets];
        deviceInfo = @{
            @"device": @{
                    @"id": [self deviceId],
            },
            @"edgeInsets": @{
                    @"top": @(isFullScreen ? MAX(MAX(insets.top, insets.bottom), MAX(insets.left, insets.right)) : 20),
                    @"left": @(0),
                    @"bottom": @(isFullScreen ? 34 : 0),
                    @"right": @(0),
            },
            @"constant": @{
                    @"navigationBarHeight": @(44),
                    @"tabBarHeight": @(49),
            },
        };
    });
    
    return deviceInfo;
}

+ (UIEdgeInsets)safeAreaInsets {
    
    static UIEdgeInsets instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (@available(iOS 11.0, *)) {
            // keyWindow有时候会获取不到
            instance = [UIApplication sharedApplication].windows.firstObject.safeAreaInsets;
        } else {
            instance = UIEdgeInsetsZero;
        }
    });
    return instance;
}

+ (NSString *)idfa {
    
    static NSString *deviceIDFA = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if ([self isSimulator]) {
            deviceIDFA = nil;
        }
        
        // iOS14获取idfa需要申请权限，否则其他系统权限发生变化时，获取的idfa也会变化
        // Privacy - Tracking Usage Description
        NSString *trackDes = [NSBundle mainBundle].infoDictionary[@"NSUserTrackingUsageDescription"];
        if (trackDes.length > 0) {
            if (@available(iOS 14.0, *)) {
                ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
                if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); //创建信号量
                    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                        dispatch_semaphore_signal(semaphore);   //发送信号
                    }];
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);  //等待
                }
            }
        }
        
        deviceIDFA = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        if ([deviceIDFA hasPrefix:@"00000000"]) {
            // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
            // 00000000-0000-0000-0000-000000000000
            deviceIDFA = nil;
        }
    });
    
    return deviceIDFA;
}

+ (NSString *)deviceId {
    
    static NSString *deviceId = nil;
    if (deviceId.length > 0) {
        JGSLog(@"getDeviceId DeviceId Cached: %@", deviceId);
        return deviceId;
    }
    
    // iOS14其他权限变化时会导致idfa变化，因此做存储
    NSString *keychainDeviceIdKey = @"JGSourceBaseDeviceId";
    deviceId = [JGSNativeKeychainUtils readFromKeychain:keychainDeviceIdKey];
    if (deviceId.length > 0) {
        JGSLog(@"getDeviceId DeviceId Stored: %@", deviceId);
        return deviceId;
    }
    
    // 获取idfa，idfa获取失败则使用idfv，idfv也获取失败，则使用随机UUID
    deviceId = [self idfa];
    JGSLog(@"getDeviceId DeviceId idfa: %@", deviceId);
    
    if (deviceId.length == 0) {
        // idfv
        deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        JGSLog(@"getDeviceId DeviceId idfv: %@", deviceId);
    }

    if (deviceId.length == 0) {

        // 如果idfa、idfv均未取到，则使用随机UUID，随机UUID获取一次后存储KeyChain
        deviceId = [[NSUUID UUID] UUIDString];
        JGSLog(@"getDeviceId DeviceId uuid: %@", deviceId);
    }
    
    [JGSNativeKeychainUtils saveToKeychain:deviceId forKey:keychainDeviceIdKey];
    return deviceId;
}

+ (NSString *)systemName {
    // 获取iphone手机的操作系统名称
    return [[UIDevice currentDevice] systemName];
}

+ (NSString *)systemVersion {
    // 获取iphone手机的系统版本号
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)localizedModel {
    // 获取iphone手机的localizedModel
    return ([[UIDevice currentDevice] localizedModel]);
}

+ (NSString *)deviceName {
    // 获取iphone手机的自定义名称
    return ([[UIDevice currentDevice] name]);
}


+ (NSString *)deviceMachine {
    
    static NSString *machine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 获取设备信息（设备类型及版本号）
        struct utsname systemInfo;
        uname( &systemInfo );
        
        machine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        if ([machine isEqualToString:@"i386"] || [machine isEqualToString: @"x86_64"] ) {
            
            NSString *deviceType = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"iPad" : @"iPhone";
            machine = [NSString stringWithFormat:@"%@ Simulator", deviceType];
        }
    });
    
    return machine;
}

+ (NSString *)deviceModel {
    
    static NSString *deviceModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"iOSDeviceList-Sorted.json" ofType:nil];
        if (path.length == 0) {
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"iOSDeviceList-Sorted.json" ofType:nil];
        }
        
        NSData *jsonData = [NSData dataWithContentsOfFile:path];
        NSDictionary *deviceNamesByCode = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        
        NSString *machine = [self deviceMachine];
        NSDictionary *deviceInfo = [deviceNamesByCode objectForKey:machine];
        deviceModel = [deviceInfo objectForKey:@"Generation"] ?: machine;
    });
    
    return deviceModel;
}

+ (BOOL)isFullScreen {
    
    static BOOL isFull = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        UIEdgeInsets insets = [self safeAreaInsets];
        isFull = ((insets.top > 0 && insets.bottom > 0) || (insets.left > 0 && insets.right > 0));
    });
    return isFull;
}

+ (BOOL)systemVersionBelow:(NSString *)cmp {
    
    NSProcessInfo *processInfo = NSProcessInfo.processInfo;
    if ([processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        NSArray<NSString *> *cmpVersionStr = [cmp componentsSeparatedByString:@"."];
        NSOperatingSystemVersion cmpInfo = {0, 0, 0};
        cmpInfo.majorVersion = [[cmpVersionStr firstObject] integerValue];
        if (cmpVersionStr.count > 1) {
            
            cmpInfo.minorVersion = [[cmpVersionStr objectAtIndex:1] integerValue];
        }
        else if (cmpVersionStr.count > 2) {
            
            cmpInfo.patchVersion = [[cmpVersionStr objectAtIndex:2] integerValue];
        }
        
        BOOL result = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:cmpInfo];
        return !result;
    }
    else {
        
        BOOL result = ([[[UIDevice currentDevice] systemVersion] compare:cmp options:NSNumericSearch] == NSOrderedAscending);
        return result;
    }
}

#pragma mark - 越狱检测
+ (BOOL)isSimulator {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isAPPResigned:(NSArray<NSString *> *)teamIDs {
    
    // 检测plist文件
    NSDictionary *plistDict = [[NSBundle mainBundle] infoDictionary];
    if ([plistDict objectForKey: @"SignerIdentity"] != nil) {
        // 存在这个key，则说明被二次打包了
        return YES;
    }
    
    // 重签名检测
    NSString *embeddedPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"]; // 描述文件路径
    if (![[NSFileManager defaultManager] fileExistsAtPath:embeddedPath]) {
        return YES;
    }
    
    // 读取application-identifier
    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:embeddedPath encoding:NSASCIIStringEncoding error:nil];
    NSArray<NSString *> *provisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSInteger fullIdentifierLine = NSNotFound;
    for (NSInteger i = 0; i < provisioningLines.count; i++) {
        NSString *lineStr = [[provisioningLines objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([lineStr isEqualToString:@"<key>application-identifier</key>"]) {
            fullIdentifierLine =  i + 1;
            break;
        }
    }
    
    if (fullIdentifierLine == NSNotFound || fullIdentifierLine >= provisioningLines.count) {
        return YES;
    }
    
    NSString *fullIdentifier = [provisioningLines objectAtIndex:fullIdentifierLine];
    fullIdentifier = [fullIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    fullIdentifier = [fullIdentifier stringByReplacingOccurrencesOfString:@"<string>" withString:@""];
    fullIdentifier = [fullIdentifier stringByReplacingOccurrencesOfString:@"</string>" withString:@""];
    
    JGSLog(@"%@", fullIdentifier);
    NSString *teamId = [fullIdentifier componentsSeparatedByString:@"."].firstObject;
    if (![teamIDs containsObject:teamId]) {
        return YES;
    }
    
    if (teamId.length + 1 >= fullIdentifier.length) {
        return YES;
    }
    
    NSString *bundleId = [fullIdentifier substringFromIndex:teamId.length + 1];
    if (![bundleId isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]) {
        if (![bundleId isEqualToString:@"*"]) {
            return YES;
        }
    }
    return NO;
}

+ (JGSDeviceJailbroken)isDeviceJailbroken {
    
    /*
     参考：https://www.jianshu.com/p/a3fc10c70a29
     上述越狱检查总结如下：
     不要用NSFileManager，这是最容易被hook掉的。
     检测方法中所用到的函数尽可能用底层的C，如文件检测用stat函数(iPod7.0，越狱机检测越狱常见的会安装的文件只能检测到此步骤，下面的检测不出来)
     再进一步，就是检测stat是否出自系统库
     再进一步，就是检测链接动态库(尽量不要，appStore可能审核不过)
     再进一步，检测程序运行的环境变量
     链接：https://www.jianshu.com/p/a3fc10c70a29
     */
    
    // 可执行文件路径
    NSString *execPath = [[NSBundle mainBundle] executablePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:execPath]) {
        return JGSDeviceJailbrokenIsBroken;
    }
    
    // 目录是否有写入权限
    @try {
        CFUUIDRef puuid = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, puuid);
        NSString *deviceId = (NSString *)CFBridgingRelease(uuidString);
        CFRelease(puuid);
        NSString *path = [NSString stringWithFormat:@"/private/%@", deviceId];
        if ([@"Write Test" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            return JGSDeviceJailbrokenIsBroken;
        }
    }
    @catch (NSException *exception) {
        JGSLog(@"%@", exception);
    }
    
    // 检测plist文件
    NSDictionary *plistDict = [[NSBundle mainBundle] infoDictionary];
    if (plistDict.count == 0) {
        return JGSDeviceJailbrokenIsBroken;
    }
    
    // 使用NSFileManager判断设备是否安装了如下越狱常用工具
    NSArray<NSString *> *checkPath = @[
        @"/Applications/Cydia.app",
        @"/Applications/Icy.app",
        @"/Applications/IntelliScreen.app",
        @"/Applications/RockApp.app",
        @"/Applications/SBSettings.app",
        @"/Applications/MxTube.app",
        @"/Applications/WinterBoard.app",
        @"/bin/bash",
        @"/etc/apt",
        @"/etc/clutch.conf",
        @"/etc/clutch_cracked.plist",
        @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
        @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
        @"/Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/private/var/lib/apt",
        @"/private/var/lib/apt/",
        @"/private/var/lib/cydia",
        @"/private/var/stash",
        @"/private/var/tmp/cydia.log",
        @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        @"/usr/bin/sshd",
        @"/usr/libexec/sftp-server",
        @"/usr/sbin/sshd",
        @"/var/cache/clutch.plist",
        @"/var/cache/clutch_cracked.plist",
        @"/var/lib/clutch/overdrive.dylib",
        @"/var/root/Documents/Cracked/"
    ];
    for (NSString *path in checkPath) {
        //if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        //    return JGSDeviceJailbrokenIsBroken;
        //}
        
        // 攻击者可能会hook NSFileManager 的方法
        // 回避 NSFileManager，使用stat系列函数检测Cydia等工具
        @try {
            struct stat stat_info;
            if (stat(path.UTF8String, &stat_info) == 0) {
                return JGSDeviceJailbrokenIsBroken;
            }
        } @catch (NSException *exception) {
            JGSLog(@"%@", exception);
        }
    }
    
    // Symbolic Link Check
    // 尝试读取下应用列表，看看有无权限获取
    @try {
        // See if the Applications folder is a symbolic link
        struct stat stat_info;
        if (lstat("/Applications", &stat_info) != 0 && stat_info.st_mode & S_IFLNK) {
            return JGSDeviceJailbrokenIsBroken;
        }
    }
    @catch (NSException *exception) {
        JGSLog(@"%@", exception);
    }
    
    // 看看stat是不是出自系统库，有没有被攻击者换掉
    @try {
        int statCheck;
        Dl_info dylib_info;
        int (*func_stat)(const char *, struct stat *) = stat;
        if ((statCheck = dladdr(func_stat, &dylib_info))) {
            NSString *path = [NSString stringWithUTF8String:dylib_info.dli_fname];
            if (![path isEqualToString:@"/usr/lib/system/libsystem_kernel.dylib"]) {
                return JGSDeviceJailbrokenIsBroken;
            }
        }
    } @catch (NSException *exception) {
        JGSLog(@"%@", exception);
    }
    
    // 检测当前程序运行的环境变量
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    if (env != NULL) {
        return JGSDeviceJailbrokenIsBroken;
    }
    
    return JGSDeviceJailbrokenNone;
}

@end
