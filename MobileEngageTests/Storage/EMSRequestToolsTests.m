//
// Copyright (c) 2018 Emarsys. All rights reserved.
//
#import <CoreSDK/EMSRequestModelBuilder.h>
#import <CoreSDK/EMSTimestampProvider.h>
#import <CoreSDK/EMSUUIDProvider.h>
#import "Kiwi.h"
#import "EMSRequestModel.h"
#import "MERequestTools.h"

SPEC_BEGIN(EMSRequestToolsTests)

        describe(@"isCustomEvent", ^{

            it(@"should return YES if the request is a custom event", ^{
                EMSRequestModel *customEvent = [EMSRequestModel makeWithBuilder:^(EMSRequestModelBuilder *builder) {
                        [builder setUrl:@"https://mobile-events.eservice.emarsys.net/v3/devices/2398732872/events"];
                    }
                                                              timestampProvider:[EMSTimestampProvider new]
                                                                   uuidProvider:[EMSUUIDProvider new]];

                [[theValue([MERequestTools isRequestCustomEvent:customEvent]) should] beYes];
            });

            it(@"should return NO if the request is a NOT custom event", ^{
                EMSRequestModel *customEvent = [EMSRequestModel makeWithBuilder:^(EMSRequestModelBuilder *builder) {
                        [builder setUrl:@"https://mobile-events.eservice.emarsys.net/v3/devices/2398732872/events2"];
                    }
                                                              timestampProvider:[EMSTimestampProvider new]
                                                                   uuidProvider:[EMSUUIDProvider new]];

                [[theValue([MERequestTools isRequestCustomEvent:customEvent]) should] beNo];
            });


        });

SPEC_END
