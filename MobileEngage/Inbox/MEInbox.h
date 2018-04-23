//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MENotificationInboxStatus.h"
#import "MEInboxProtocol.h"
#import "MEInboxNotificationProtocol.h"

@class MERequestContext;

@interface MEInbox : NSObject <MEInboxNotificationProtocol>

- (instancetype)initWithConfig:(MEConfig *)config
                requestContext:(MERequestContext *)requestContext;

@end
