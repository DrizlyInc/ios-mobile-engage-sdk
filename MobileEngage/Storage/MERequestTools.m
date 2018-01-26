//
// Copyright (c) 2018 Emarsys. All rights reserved.
//

#import "MERequestTools.h"
#import "EMSRequestModel.h"


@implementation MERequestTools

+ (BOOL)isRequestCustomEvent:(EMSRequestModel *)request {
    //.*/v3/devices/\d+/events$
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*/v3/devices/\\d+/events$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *url = [request.url absoluteString];
    return url && [regex numberOfMatchesInString:url options:0 range:NSMakeRange(0, [url length])] > 0;
}

@end