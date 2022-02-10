//
//  JGSBase.h
//  JGSBase
//
//  Created by 梅继高 on 2022/1/17.
//  Copyright © 2022 MeiJiGao. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for JGSBase.
FOUNDATION_EXPORT double JGSBaseVersionNumber;

//! Project version string for JGSBase.
FOUNDATION_EXPORT const unsigned char JGSBaseVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <JGSBase/PublicHeader.h>

#ifndef JGS_Base
#define JGS_Base

#if __has_include(<JGSBase/JGSBase.h>)
#import <JGSBase/JGSBaseUtils.h>
#import <JGSBase/JGSLogFunction.h>
#import <JGSBase/JGSWeakStrong.h>
#else
#import "JGSBaseUtils.h"
#import "JGSLogFunction.h"
#import "JGSWeakStrong.h"
#endif

#endif
