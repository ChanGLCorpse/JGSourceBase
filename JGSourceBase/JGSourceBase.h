//
//  JGSourceBase.h
//  JGSourceBase
//
//  Created by Mei Jigao on 2017/11/24.
//  Copyright © 2017年 MeiJigao. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for JGSourceBase.
FOUNDATION_EXPORT double JGSourceBaseVersionNumber;

//! Project version string for JGSourceBase.
FOUNDATION_EXPORT const unsigned char JGSourceBaseVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <JGSourceBase/PublicHeader.h>

// JGSC 缩写说明
// JG: 作者
// SC: Source Code

#if __has_include(<JGSourceBase/JGSourceBase.h>)

#import <JGSourceBase/JGSCCommon.h>
#import <JGSourceBase/JGSCLog.h>
#import <JGSourceBase/JGSCRuntime.h>
#import <JGSourceBase/JGSCWeakStrongProperty.h>

#else

#import "JGSCCommon.h"
#import "JGSCLog.h"
#import "JGSCRuntime.h"
#import "JGSCWeakStrongProperty.h"

#endif
