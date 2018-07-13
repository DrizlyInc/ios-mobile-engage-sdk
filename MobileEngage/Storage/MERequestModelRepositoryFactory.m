//
// Copyright (c) 2018 Emarsys. All rights reserved.
//

#import <CoreSDK/EMSRequestModelRepository.h>
#import "MERequestModelRepositoryFactory.h"
#import "MEButtonClickRepository.h"
#import "MERequestRepositoryProxy.h"
#import "MEDisplayedIAMRepository.h"
#import "MEInApp.h"
#import "MobileEngage.h"
#import "MobileEngage+Private.h"
#import "MERequestContext.h"

@implementation MERequestModelRepositoryFactory

- (instancetype)initWithInApp:(MEInApp *)inApp
               requestContext:(MERequestContext *)requestContext {
    NSParameterAssert(inApp);
    NSParameterAssert(requestContext);
    if (self = [super init]) {
        _inApp = inApp;
        _requestContext = requestContext;
    }
    return self;
}

- (id <EMSRequestModelRepositoryProtocol>)createWithBatchCustomEventProcessing:(BOOL)batchProcessing {
    if (batchProcessing) {
        return [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:[[EMSRequestModelRepository alloc] initWithDbHelper:[[EMSSQLiteHelper alloc] initWithDefaultDatabase]]
                                                          buttonClickRepository:[[MEButtonClickRepository alloc] initWithDbHelper:[MobileEngage dbHelper]]
                                                         displayedIAMRepository:[[MEDisplayedIAMRepository alloc] initWithDbHelper:[MobileEngage dbHelper]]
                                                                          inApp:self.inApp
                                                                 requestContext:self.requestContext];
    }
    return [[EMSRequestModelRepository alloc] initWithDbHelper:[[EMSSQLiteHelper alloc] initWithDefaultDatabase]];
}

@end