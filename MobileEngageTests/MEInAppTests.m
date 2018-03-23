#import "Kiwi.h"
#import "MEInApp.h"
#import "MEInApp+Private.h"
#import "FakeInAppHandler.h"
#import "MEIAMProtocol.h"
#import "EMSTimestampProvider.h"

SPEC_BEGIN(MEInAppTests)
        __block MEInApp *iam;

        beforeEach(^{
            iam = [[MEInApp alloc] init];
            NSDate *renderEndTime = [NSDate dateWithTimeIntervalSince1970:103];
            EMSTimestampProvider *mockTimeStampProvider = [EMSTimestampProvider mock];
            [mockTimeStampProvider stub:@selector(provideTimestamp) andReturn:renderEndTime];
            iam.timestampProvider = mockTimeStampProvider;
        });

        describe(@"messageHandler", ^{
            it(@"should pass the eventName and payload to the given messageHandler's handleApplicationEvent:payload: method", ^{
                NSString *expectedName = @"nameOfTheEvent";
                NSDictionary <NSString *, NSObject *> *expectedPayload = @{
                    @"payloadKey1": @{
                        @"payloadKey2": @"payloadValue"
                    }
                };

                FakeInAppHandler *inAppHandler = [FakeInAppHandler mock];
                [iam setMessageHandler:inAppHandler];
                NSString *message = @"<!DOCTYPE html>\n"
                    "<html lang=\"en\">\n"
                    "  <head>\n"
                    "    <script>\n"
                    "      window.onload = function() {\n"
                    "        window.webkit.messageHandlers.triggerAppEvent.postMessage({id: '1', name: 'nameOfTheEvent', payload:{payloadKey1:{payloadKey2: 'payloadValue'}}});\n"
                    "      };\n"
                    "    </script>\n"
                    "  </head>\n"
                    "  <body style=\"background: transparent;\">\n"
                    "  </body>\n"
                    "</html>";
                [[inAppHandler shouldEventually] receive:@selector(handleApplicationEvent:payload:)
                                           withArguments:expectedName, expectedPayload];

                NSData *body = [NSJSONSerialization dataWithJSONObject:@{@"message": @{@"id": @"campaignId", @"html": message}}
                                                               options:0
                                                                 error:nil];
                EMSResponseModel *response = [[EMSResponseModel alloc] initWithStatusCode:200
                                                                                  headers:@{}
                                                                                     body:body
                                                                             requestModel:[EMSRequestModel mock]
                                                                                timestamp:[NSDate date]];
                [iam showMessage:[[MEInAppMessage alloc] initWithResponse:response] completionHandler:^{
                }];
            });

            it(@"should not try to display inapp in case if there is already one being displayed", ^{
                NSString *expectedName = @"nameOfTheEvent";
                NSDictionary <NSString *, NSObject *> *expectedPayload = @{
                    @"payloadKey1": @{
                        @"payloadKey2": @"payloadValue"
                    }
                };

                FakeInAppHandler *inAppHandler = [FakeInAppHandler mock];
                [iam setMessageHandler:inAppHandler];
                NSString *message = @"<!DOCTYPE html>\n"
                    "<html lang=\"en\">\n"
                    "  <head>\n"
                    "    <script>\n"
                    "      window.onload = function() {\n"
                    "        window.webkit.messageHandlers.triggerAppEvent.postMessage({id: '1', name: 'nameOfTheEvent', payload:{payloadKey1:{payloadKey2: 'payloadValue'}}});\n"
                    "      };\n"
                    "    </script>\n"
                    "  </head>\n"
                    "  <body style=\"background: transparent;\">\n"
                    "  </body>\n"
                    "</html>";
                [[inAppHandler shouldEventually] receive:@selector(handleApplicationEvent:payload:) withCountAtMost:1 arguments:expectedName, expectedPayload];

                NSData *body = [NSJSONSerialization dataWithJSONObject:@{@"message": @{@"id": @"campaignId", @"html": message}}
                                                               options:0
                                                                 error:nil];
                EMSResponseModel *response = [[EMSResponseModel alloc] initWithStatusCode:200
                                                                                  headers:@{}
                                                                                     body:body
                                                                             requestModel:[EMSRequestModel mock]
                                                                                timestamp:[NSDate date]];
                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                [iam showMessage:[[MEInAppMessage alloc] initWithResponse:response]
               completionHandler:^{
                   [iam showMessage:[[MEInAppMessage alloc] initWithResponse:response]
                  completionHandler:^{
                      [exp fulfill];
                  }];
               }];
                [XCTWaiter waitForExpectations:@[exp] timeout:3];
            });

        });


        describe(@"showMessage", ^{
            it(@"it should set currentCampaignId", ^{
                NSData *body = [NSJSONSerialization dataWithJSONObject:@{@"message": @{@"id": @"testIdForCurrentCampaignId", @"html": @"<html></html>"}}
                                                               options:0
                                                                 error:nil];
                EMSResponseModel *response = [[EMSResponseModel alloc] initWithStatusCode:200
                                                                                  headers:@{}
                                                                                     body:body
                                                                             requestModel:[EMSRequestModel mock]
                                                                                timestamp:[NSDate date]];
                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                [iam showMessage:[[MEInAppMessage alloc] initWithResponse:response]
               completionHandler:^{
                   [exp fulfill];
               }];
                [XCTWaiter waitForExpectations:@[exp] timeout:30];
                [[[((id <MEIAMProtocol>) iam) currentCampaignId] should] equal:@"testIdForCurrentCampaignId"];
            });

            it(@"should call trackInAppDisplay: on inAppTracker", ^{
                id inAppTracker = [KWMock mockForProtocol:@protocol(MEInAppTrackingProtocol)];
                [[inAppTracker shouldEventuallyBeforeTimingOutAfter(30)] receive:@selector(trackInAppDisplay:) withArguments:@"testIdForInAppTracker"];
                iam.inAppTracker = inAppTracker;
                NSData *body = [NSJSONSerialization dataWithJSONObject:@{@"message": @{@"id": @"testIdForInAppTracker", @"html": @"<html></html>"}}
                                                               options:0
                                                                 error:nil];
                EMSResponseModel *response = [[EMSResponseModel alloc] initWithStatusCode:200
                                                                                  headers:@{}
                                                                                     body:body
                                                                             requestModel:[EMSRequestModel mock]
                                                                                timestamp:[NSDate date]];
                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                [iam showMessage:[[MEInAppMessage alloc] initWithResponse:response]
               completionHandler:^{
                   [exp fulfill];
               }];
                [XCTWaiter waitForExpectations:@[exp] timeout:30];
            });

            it(@"should log the rendering time", ^{
                NSString *const campaignId = @"testIdForRenderingMetric";

                NSDictionary *loadingTimeMetric = @{@"loading_time": @3000, @"id": campaignId};
                MELogRepository *mockRepository = [MELogRepository mock];
                iam.logRepository = mockRepository;
                [[mockRepository should] receive:@selector(add:) withArguments:loadingTimeMetric];

                NSData *body = [NSJSONSerialization dataWithJSONObject:@{@"message": @{@"id": campaignId, @"html": @"<html></html>"}}
                                                               options:0
                                                                 error:nil];
                EMSResponseModel *response = [[EMSResponseModel alloc] initWithStatusCode:200
                                                                                  headers:@{}
                                                                                     body:body
                                                                             requestModel:[EMSRequestModel mock]
                                                                                timestamp:[NSDate dateWithTimeIntervalSince1970:100]];

                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                [iam showMessage:[[MEInAppMessage alloc] initWithResponse:response]
               completionHandler:^{
                   [exp fulfill];
               }];
                [XCTWaiter waitForExpectations:@[exp] timeout:30];
            });
        });

        describe(@"closeInAppMessage", ^{

            it(@"should close the inapp message", ^{
                UIViewController *rootViewControllerMock = [UIViewController nullMock];
                [[rootViewControllerMock should] receive:@selector(dismissViewControllerAnimated:completion:)];
                KWCaptureSpy *spy = [rootViewControllerMock captureArgument:@selector(dismissViewControllerAnimated:completion:) atIndex:1];

                UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
                window.rootViewController = rootViewControllerMock;

                iam.iamWindow = window;

                [((id <MEIAMProtocol>) iam) closeInAppMessage];

                void (^completionBlock)(void) = spy.argument;
                completionBlock();
                [[iam.iamWindow should] beNil];
            });

        });

SPEC_END
