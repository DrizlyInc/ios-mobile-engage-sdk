//
// Copyright (c) 2018 Emarsys. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MEUserNotificationCenterDelegate.h"

@class MobileEngageInternal;

@interface MEUserNotificationDelegate: NSObject <MEUserNotificationCenterDelegate>

- (instancetype)initWithApplication:(UIApplication *)application
               mobileEngageInternal:(MobileEngageInternal *)mobileEngage;

@end
