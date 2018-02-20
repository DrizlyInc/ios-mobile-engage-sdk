#import "Kiwi.h"
#import "MEIAMTriggerMEEvent.h"
#import "MobileEngage.h"

SPEC_BEGIN(MEIAMTriggerMEEventTests)

        beforeEach(^{
        });

        describe(@"commandName", ^{

            it(@"should return 'triggerMEEvent'", ^{
                [[[MEIAMTriggerMEEvent commandName] should] equal:@"triggerMEEvent"];
            });

        });

        describe(@"handleMessage:resultBlock:", ^{

            it(@"should return false if there is no name", ^{
                MEIAMTriggerMEEvent *appEvent = [MEIAMTriggerMEEvent new];

                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                __block NSDictionary<NSString *, NSObject *> *returnedResult;

                [appEvent handleMessage:@{@"id": @"999"}
                            resultBlock:^(NSDictionary<NSString *, NSObject *> *result) {
                                returnedResult = result;
                                [exp fulfill];
                            }];
                [XCTWaiter waitForExpectations:@[exp] timeout:30];
                [[returnedResult should] equal:@{@"success": @NO, @"id": @"999", @"error": @"Missing name!"}];
            });

            it(@"should call the trackCustomEvent method on the MobileEngage and return with the ME eventId in the resultBlock", ^{
                MEIAMTriggerMEEvent *appEvent = [MEIAMTriggerMEEvent new];


                [[MobileEngage should] receive:@selector(trackCustomEvent:eventAttributes:)
                                     andReturn:@"ValueOfTheMEEventId"
                                 withArguments:@"nameOfTheEvent", kw_any()];

                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                __block NSDictionary<NSString *, NSObject *> *returnedResult;

                [appEvent handleMessage:@{
                                @"id": @"997",
                                @"name": @"nameOfTheEvent"
                        }
                            resultBlock:^(NSDictionary<NSString *, NSObject *> *result) {
                                returnedResult = result;
                                [exp fulfill];
                            }];
                [XCTWaiter waitForExpectations:@[exp] timeout:30];
                [[returnedResult should] equal:@{
                        @"success": @YES,
                        @"id": @"997",
                        @"meEventId": @"ValueOfTheMEEventId"
                }];
            });

            it(@"should call the trackCustomEvent method on the MobileEngage with payload and return with the ME eventId in the resultBlock", ^{
                MEIAMTriggerMEEvent *appEvent = [MEIAMTriggerMEEvent new];
                NSDictionary <NSString *, NSObject *> *payload = @{
                        @"payloadKey1": @{
                                @"payloadKey2": @"payloadValue"
                        }
                };

                [[MobileEngage should] receive:@selector(trackCustomEvent:eventAttributes:)
                                     andReturn:@"ValueOfTheMEEventId"
                                 withArguments:@"nameOfTheEvent", payload];

                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                __block NSDictionary<NSString *, NSObject *> *returnedResult;

                [appEvent handleMessage:@{
                                @"id": @"997",
                                @"name": @"nameOfTheEvent",
                                @"payload": payload
                        }
                            resultBlock:^(NSDictionary<NSString *, NSObject *> *result) {
                                returnedResult = result;
                                [exp fulfill];
                            }];
                [XCTWaiter waitForExpectations:@[exp] timeout:30];
                [[returnedResult should] equal:@{
                        @"success": @YES,
                        @"id": @"997",
                        @"meEventId": @"ValueOfTheMEEventId"
                }];
            });

        });

SPEC_END