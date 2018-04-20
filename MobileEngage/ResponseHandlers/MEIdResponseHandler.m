//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import "MEIdResponseHandler.h"
#import "MERequestContext.h"
#import "MEInboxV2.h"
#import "MobileEngage.h"
#import "MEExperimental.h"

@implementation MEIdResponseHandler {
    MERequestContext *_requestContext;
}

- (instancetype)initWithRequestContext:(MERequestContext *)requestContext {
    if (self = [super init]) {
        _requestContext = requestContext;
    }
    return self;
}

- (BOOL)shouldHandleResponse:(EMSResponseModel *)response {
    return [self getMeId:response] && [self getMeIdSignature:response];
}

- (void)handleResponse:(EMSResponseModel *)response {
    NSString *meId = [self getMeId:response];
    _requestContext.meId = meId;
    _requestContext.meIdSignature = [self getMeIdSignature:response];
    if ([MEExperimental isFeatureEnabled:INBOX_V2]) {
        [((MEInboxV2 *)MobileEngage.inbox) setMeId:meId];
    }
}

- (NSString *)getMeId:(EMSResponseModel *)response {
    NSString *result;
    id meId = response.parsedBody[@"api_me_id"];
    if ([meId isKindOfClass:[NSString class]]) {
        result = meId;
    } else if ([meId isKindOfClass:[NSNumber class]]) {
        result = [(NSNumber *)response.parsedBody[@"api_me_id"] stringValue];
    }
    return result;
}

- (NSString *)getMeIdSignature:(EMSResponseModel *)response {
    return response.parsedBody[@"me_id_signature"];
}

@end
