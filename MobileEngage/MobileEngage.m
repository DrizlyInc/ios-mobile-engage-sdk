//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import "MobileEngage.h"
#import "MEConfig.h"
#import "MobileEngageInternal.h"
#import "MEInboxNotificationProtocol.h"
#import <CoreSDK/EMSSQLiteHelper.h>
#import "MESchemaDelegate.h"
#import "MENotificationCenterManager.h"
#import "MEInApp+Private.h"
#import "MERequestModelRepositoryFactory.h"
#import "MEExperimental.h"
#import "MEInboxV2.h"
#import "MEInbox.h"
#import "MEUserNotificationCenterDelegate.h"
#import "MEUserNotification.h"
#import <UIKit/UIKit.h>

#define DB_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"MEDB.db"]

@implementation MobileEngage

static MobileEngageInternal *_mobileEngageInternal;
static id <MEInboxNotificationProtocol> _inbox;
static MEInApp *_iam;
static id <MEUserNotificationCenterDelegate> _notification;
static EMSSQLiteHelper *_dbHelper;


+ (void)setupWithMobileEngageInternal:(MobileEngageInternal *)mobileEngageInternal
                               config:(MEConfig *)config
                        launchOptions:(NSDictionary *)launchOptions {
    [MEExperimental enableFeatures:config.experimentalFeatures];
    _dbHelper = [[EMSSQLiteHelper alloc] initWithDatabasePath:DB_PATH
                                               schemaDelegate:[MESchemaDelegate new]];
    [_dbHelper open];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [_dbHelper close];
                                                  }];

    _mobileEngageInternal = mobileEngageInternal;

    MERequestContext *requestContext = [[MERequestContext alloc] initWithConfig:config];
    if ([MEExperimental isFeatureEnabled:USER_CENTRIC_INBOX]) {
        _inbox = [[MEInboxV2 alloc] initWithConfig:config
                                    requestContext:requestContext
                                        restClient:[EMSRESTClient clientWithSession:[NSURLSession sharedSession]]
                                     notifications:[NSMutableArray new]
                                 timestampProvider:[EMSTimestampProvider new]];
    } else {
        _inbox = [[MEInbox alloc] initWithConfig:config
                                  requestContext:requestContext];
    }

    MELogRepository *logRepository = [MELogRepository new];

    _iam = [MEInApp new];
    _iam.logRepository = logRepository;
    _iam.timestampProvider = [EMSTimestampProvider new];

    _notification = [[MEUserNotification alloc] initWithApplication:[UIApplication sharedApplication]];

    _mobileEngageInternal.notificationCenterManager = [MENotificationCenterManager new];


    [_mobileEngageInternal setupWithConfig:config
                             launchOptions:launchOptions
                  requestRepositoryFactory:[[MERequestModelRepositoryFactory alloc] initWithInApp:_iam]
                             logRepository:logRepository
                            requestContext:requestContext];

    _iam.inAppTracker = _mobileEngageInternal;
}

+ (void)setupWithConfig:(MEConfig *)config
          launchOptions:(NSDictionary *)launchOptions {
    [MobileEngage setupWithMobileEngageInternal:[MobileEngageInternal new]
                                         config:config
                                  launchOptions:launchOptions];
}

+ (void)setPushToken:(NSData *)deviceToken {
    [_mobileEngageInternal setPushToken:deviceToken];
}

+ (BOOL)trackDeepLinkWith:(NSUserActivity *)userActivity
            sourceHandler:(nullable MESourceHandler)sourceHandler {
    return [_mobileEngageInternal trackDeepLinkWith:userActivity
                                      sourceHandler:sourceHandler];
}

+ (NSString *)appLogin {
    return [_mobileEngageInternal appLogin];
}

+ (NSString *)appLoginWithContactFieldId:(NSNumber *)contactFieldId
                       contactFieldValue:(NSString *)contactFieldValue {
    return [_mobileEngageInternal appLoginWithContactFieldId:contactFieldId
                                           contactFieldValue:contactFieldValue];
}

+ (NSString *)appLogout {
    return [_mobileEngageInternal appLogout];
}

+ (NSString *)trackMessageOpenWithUserInfo:(NSDictionary *)userInfo {
    NSNumber *inbox = userInfo[@"inbox"];
    if (inbox && [inbox boolValue]) {
        MENotification *notification = [[MENotification alloc] initWithUserinfo:userInfo];
        [_inbox addNotification:notification];

    }
    return [_mobileEngageInternal trackMessageOpenWithUserInfo:userInfo];
}

+ (NSString *)trackMessageOpenWithInboxMessage:(MENotification *)inboxMessage {
    return [_mobileEngageInternal trackMessageOpenWithInboxMessage:inboxMessage];
}

+ (NSString *)trackCustomEvent:(NSString *)eventName
               eventAttributes:(NSDictionary<NSString *, NSString *> *)eventAttributes {
    return [_mobileEngageInternal trackCustomEvent:eventName
                                   eventAttributes:eventAttributes];
}

+ (void)setStatusDelegate:(id <MobileEngageStatusDelegate>)statusDelegate {
    [_mobileEngageInternal setStatusDelegate:statusDelegate];
}

+ (id <MobileEngageStatusDelegate>)statusDelegate {
    return [_mobileEngageInternal statusDelegate];
}

+ (id <MEInboxProtocol>)inbox {
    return _inbox;
}

+ (MEInApp *)inApp {
    return _iam;
}

+ (void)setInApp:(MEInApp *)inApp {
    _iam = inApp;
}

+ (id <MEUserNotificationCenterDelegate>)notification {
    return _notification;
}

+ (EMSSQLiteHelper *)dbHelper {
    return _dbHelper;
}

+ (void)setDbHelper:(EMSSQLiteHelper *)dbHelper {
    _dbHelper = dbHelper;
}

@end
