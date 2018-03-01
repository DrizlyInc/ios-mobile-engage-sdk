//
// Copyright (c) 2018 Emarsys. All rights reserved.
//
#import "Kiwi.h"
#import "MEDisplayedIAMRepository.h"
#import "MEButtonClickRepository.h"
#import "EMSRequestModelRepository.h"
#import "MERequestRepositoryProxy.h"
#import "EMSRequestModelBuilder.h"
#import "EMSRequestModelSelectAllSpecification.h"
#import "EMSCompositeRequestModel.h"
#import "EMSRequestModelSelectFirstSpecification.h"
#import "FakeRequestRepository.h"
#import "MERequestModelSelectEventsSpecification.h"
#import "EMSRequestModelMatcher.h"
#import "EMSTimestampProvider.h"
#import "EMSDeviceInfo.h"
#import "MobileEngageVersion.h"
#import "MEInApp.h"

#define TEST_DB_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"TestMEDB.db"]


SPEC_BEGIN(MERequestRepositoryProxyTests)

    __block MEDisplayedIAMRepository *displayedRepository;
    __block MEButtonClickRepository *buttonClickRepository;
    __block EMSRequestModelRepository *requestModelRepository;
    __block MERequestRepositoryProxy *compositeRequestModelRepository;
    __block EMSTimestampProvider *timestampProvider;

    registerMatchers(@"EMS");

    id (^customEventRequestModel)(NSString *eventName, NSDictionary *eventAttributes) = ^id(NSString *eventName, NSDictionary *eventAttributes) {
        return [EMSRequestModel makeWithBuilder:^(EMSRequestModelBuilder *builder) {
            NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"type": @"custom",
                    @"name": eventName,
                    @"timestamp": [timestampProvider currentTimeStamp]}];

            if (eventAttributes) {
                event[@"attributes"] = eventAttributes;
            }

            [builder setUrl:@"https://mobile-events.eservice.emarsys.net/v3/devices/12345/events"];
            [builder setMethod:HTTPMethodPOST];
            [builder setPayload:@{@"events": @[event]}];
        }];
    };

    id (^normalRequestModel)(NSString *url) = ^id(NSString *url) {
        return [EMSRequestModel makeWithBuilder:^(EMSRequestModelBuilder *builder) {
            [builder setUrl:url];
            [builder setMethod:HTTPMethodGET];
        }];
    };

    id (^createFakeRequestRepository)(NSArray *nextRequest, NSArray *allCustomEvents, NSArray *AllRequests, MEInApp *inApp) = ^id(NSArray *nextRequest, NSArray *allCustomEvents, NSArray *AllRequests, MEInApp *inApp) {
        EMSRequestModelSelectFirstSpecification *selectFirstSpecification = [EMSRequestModelSelectFirstSpecification new];
        MERequestModelSelectEventsSpecification *selectAllCustomEventSpecification = [MERequestModelSelectEventsSpecification new];
        EMSRequestModelSelectAllSpecification *selectAllRequestsSpecification = [EMSRequestModelSelectAllSpecification new];

        FakeRequestRepository *fakeRequestRepository = [FakeRequestRepository new];
        fakeRequestRepository.queryResponseMapping = @{[selectFirstSpecification sql]: nextRequest,
                [selectAllCustomEventSpecification sql]: allCustomEvents,
                [selectAllRequestsSpecification sql]: AllRequests};

        compositeRequestModelRepository = [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:fakeRequestRepository
                                                                                     buttonClickRepository:buttonClickRepository
                                                                                    displayedIAMRepository:displayedRepository
                                                                                                     inApp:inApp];
        return compositeRequestModelRepository;
    };

    beforeEach(^{
        timestampProvider = [EMSTimestampProvider new];
        displayedRepository = [MEDisplayedIAMRepository nullMock];
        buttonClickRepository = [MEButtonClickRepository nullMock];
        requestModelRepository = [EMSRequestModelRepository mock];
        compositeRequestModelRepository = [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:requestModelRepository
                                                                                     buttonClickRepository:buttonClickRepository
                                                                                    displayedIAMRepository:displayedRepository
                                                                                                     inApp:[MEInApp mock]];
    });

    afterEach(^{
    });

    describe(@"initWithRequestModelRepository:buttonClickRepository:displayedIAMRepository:inApp:", ^{

        it(@"should set inApp after init", ^{
            MEInApp *inApp = [MEInApp mock];
            MERequestRepositoryProxy *factory = [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:[EMSRequestModelRepository mock]
                                                                                           buttonClickRepository:[MEButtonClickRepository mock]
                                                                                          displayedIAMRepository:[MEDisplayedIAMRepository mock]
                                                                                                           inApp:inApp];
            [[factory.inApp shouldNot] beNil];
        });

        it(@"should throw an exception when there is no inApp", ^{
            @try {
                MERequestRepositoryProxy *factory = [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:[EMSRequestModelRepository mock]
                                                                                               buttonClickRepository:[MEButtonClickRepository mock]
                                                                                              displayedIAMRepository:[MEDisplayedIAMRepository mock]
                                                                                                               inApp:nil];
                fail(@"Expected Exception when inApp is nil!");
            } @catch (NSException *exception) {
                [[exception.reason should] equal:@"Invalid parameter not satisfying: inApp"];
                [[theValue(exception) shouldNot] beNil];
            }
        });

        it(@"should throw an exception when there is no requestModelRepository", ^{
            @try {
                MERequestRepositoryProxy *factory = [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:nil
                                                                                               buttonClickRepository:[MEButtonClickRepository mock]
                                                                                              displayedIAMRepository:[MEDisplayedIAMRepository mock]
                                                                                                               inApp:[MEInApp mock]];
                fail(@"Expected Exception when requestModelRepository is nil!");
            } @catch (NSException *exception) {
                [[exception.reason should] equal:@"Invalid parameter not satisfying: requestModelRepository"];
                [[theValue(exception) shouldNot] beNil];
            }
        });

        it(@"should throw an exception when there is no clickRepository", ^{
            @try {
                MERequestRepositoryProxy *factory = [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:[EMSRequestModelRepository mock]
                                                                                               buttonClickRepository:nil
                                                                                              displayedIAMRepository:[MEDisplayedIAMRepository mock]
                                                                                                               inApp:[MEInApp mock]];
                fail(@"Expected Exception when clickRepository is nil!");
            } @catch (NSException *exception) {
                [[exception.reason should] equal:@"Invalid parameter not satisfying: buttonClickRepository"];
                [[theValue(exception) shouldNot] beNil];
            }
        });

        it(@"should throw an exception when there is no displayedIAMRepository", ^{
            @try {
                MERequestRepositoryProxy *factory = [[MERequestRepositoryProxy alloc] initWithRequestModelRepository:[EMSRequestModelRepository mock]
                                                                                               buttonClickRepository:[MEButtonClickRepository mock]
                                                                                              displayedIAMRepository:nil
                                                                                                               inApp:[MEInApp mock]];
                fail(@"Expected Exception when displayedIAMRepository is nil!");
            } @catch (NSException *exception) {
                [[exception.reason should] equal:@"Invalid parameter not satisfying: displayedIAMRepository"];
                [[theValue(exception) shouldNot] beNil];
            }
        });
    });

    describe(@"MERequestRepositoryProxy", ^{

        it(@"should add buttonClicks on the custom event requests", ^{
            NSArray<MEButtonClick *> *clicks = @[
                    [[MEButtonClick alloc] initWithCampaignId:@"campaignID" buttonId:@"buttonID" timestamp:[NSDate date]],
                    [[MEButtonClick alloc] initWithCampaignId:@"campaignID2" buttonId:@"buttonID2" timestamp:[NSDate date]]
            ];

            [[buttonClickRepository should] receive:@selector(query:) andReturn:clicks];

            EMSRequestModel *modelCustomEvent1 = customEventRequestModel(@"event1", nil);

            createFakeRequestRepository(
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    [MEInApp new]
            );

            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:[EMSRequestModelSelectAllSpecification new]];
            [[[result[0] payload][@"clicks"] should] equal:@[
                    @{@"message_id": [clicks[0] campaignId], @"button_id": [clicks[0] buttonId], @"timestamp": [EMSTimestampProvider utcFormattedStringFromDate:[clicks[0] timestamp]]},
                    @{@"message_id": [clicks[1] campaignId], @"button_id": [clicks[1] buttonId], @"timestamp": [EMSTimestampProvider utcFormattedStringFromDate:[clicks[1] timestamp]]}
            ]];
        });

        it(@"should add viewed_messages on the custom event requests", ^{
            NSArray<MEDisplayedIAM *> *viewedMessages = @[
                    [[MEDisplayedIAM alloc] initWithCampaignId:@"123" timestamp:[NSDate date]],
                    [[MEDisplayedIAM alloc] initWithCampaignId:@"42" timestamp:[NSDate date]]
            ];

            [[displayedRepository should] receive:@selector(query:) andReturn:viewedMessages];

            EMSRequestModel *modelCustomEvent1 = customEventRequestModel(@"event1", nil);

            createFakeRequestRepository(
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    [MEInApp new]
            );

            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:[EMSRequestModelSelectAllSpecification new]];
            [[[result[0] payload][@"viewed_messages"] should] equal:@[
                    @{@"message_id": [viewedMessages[0] campaignId], @"timestamp": [EMSTimestampProvider utcFormattedStringFromDate:[viewedMessages[0] timestamp]]},
                    @{@"message_id": [viewedMessages[1] campaignId], @"timestamp": [EMSTimestampProvider utcFormattedStringFromDate:[viewedMessages[1] timestamp]]}
            ]];
        });

        it(@"should add the element to the requestModelRepository", ^{
            EMSRequestModel *model = [EMSRequestModel makeWithBuilder:^(EMSRequestModelBuilder *builder) {
                [builder setUrl:@"https://www.url.com"];
                [builder setMethod:HTTPMethodGET];
            }];
            [[requestModelRepository should] receive:@selector(add:) withArguments:model];

            [compositeRequestModelRepository add:model];
        });

        it(@"should remove the element from the requestModelRepository", ^{
            id spec = [KWMock mockForProtocol:@protocol(EMSSQLSpecificationProtocol)];

            [[requestModelRepository should] receive:@selector(remove:) withArguments:spec];
            [compositeRequestModelRepository remove:spec];
        });

        it(@"should query normal RequestModels from RequestRepository", ^{
            EMSRequestModelSelectAllSpecification *specification = [EMSRequestModelSelectAllSpecification new];

            NSArray *const requests = @[[EMSRequestModel nullMock], [EMSRequestModel nullMock], [EMSRequestModel nullMock]];
            [[requestModelRepository should] receive:@selector(query:) andReturn:requests withArguments:specification];

            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:specification];
            [[result should] equal:requests];
        });

        it(@"should return empty array if no elements were found", ^{
            EMSRequestModelSelectAllSpecification *specification = [EMSRequestModelSelectAllSpecification new];

            NSArray *const requests = @[];
            [[requestModelRepository should] receive:@selector(query:) andReturn:requests withArguments:specification];

            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:specification];
            [[result should] equal:requests];
        });

        it(@"should query composite RequestModel from RequestRepository when select first", ^{
            EMSRequestModel *modelCustomEvent1 = customEventRequestModel(@"event1", nil);
            EMSRequestModel *model1 = normalRequestModel(@"https://www.google.com");
            EMSRequestModel *modelCustomEvent2 = customEventRequestModel(@"event2", @{@"key1": @"value1", @"key2": @"value2"});
            EMSRequestModel *model2 = normalRequestModel(@"https://www.google.com");
            EMSRequestModel *modelCustomEvent3 = customEventRequestModel(@"event3", @{@"star": @"wars"});

            EMSCompositeRequestModel *compositeModel = [EMSCompositeRequestModel makeWithBuilder:^(EMSRequestModelBuilder *builder) {
                [builder setUrl:@"https://mobile-events.eservice.emarsys.net/v3/devices/12345/events"];
                [builder setMethod:HTTPMethodPOST];
                [builder setPayload:@{
                        @"hardware_id": [EMSDeviceInfo hardwareId],
                        @"viewed_messages": @[],
                        @"clicks": @[],
                        @"events": @[
                                [modelCustomEvent1.payload[@"events"] firstObject],
                                [modelCustomEvent2.payload[@"events"] firstObject],
                                [modelCustomEvent3.payload[@"events"] firstObject]
                        ],
                        @"language": [EMSDeviceInfo languageCode],
                        @"ems_sdk": MOBILEENGAGE_SDK_VERSION,
                        @"application_version": [EMSDeviceInfo applicationVersion]
                }];
            }];
            compositeModel.originalRequestIds = @[modelCustomEvent1.requestId, modelCustomEvent2.requestId, modelCustomEvent3.requestId];

            createFakeRequestRepository(
                    @[modelCustomEvent1],
                    @[modelCustomEvent1, modelCustomEvent2, modelCustomEvent3],
                    @[modelCustomEvent1, model1, modelCustomEvent2, model2, modelCustomEvent3],
                    [MEInApp new]
            );

            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:[EMSRequestModelSelectFirstSpecification new]];
            [[theValue([result count]) should] equal:theValue(1)];
            [[[result firstObject] should] beSimilarWithRequest:compositeModel];
        });

        it(@"should query composite RequestModels from RequestRepository when select all", ^{
            EMSRequestModel *model1 = normalRequestModel(@"https://www.google.com");
            EMSRequestModel *modelCustomEvent1 = customEventRequestModel(@"event1", nil);
            EMSRequestModel *modelCustomEvent2 = customEventRequestModel(@"event2", @{@"key1": @"value1", @"key2": @"value2"});
            EMSRequestModel *model2 = normalRequestModel(@"https://mobile-events.eservice.emarsys.net/v3/devices/12345/events534");
            EMSRequestModel *modelCustomEvent3 = customEventRequestModel(@"event3", @{@"star": @"wars"});

            EMSCompositeRequestModel *compositeModel = [EMSCompositeRequestModel makeWithBuilder:^(EMSRequestModelBuilder *builder) {
                [builder setUrl:@"https://mobile-events.eservice.emarsys.net/v3/devices/12345/events"];
                [builder setMethod:HTTPMethodPOST];
                [builder setPayload:@{
                        @"hardware_id": [EMSDeviceInfo hardwareId],
                        @"viewed_messages": @[],
                        @"clicks": @[],
                        @"events": @[
                                [modelCustomEvent1.payload[@"events"] firstObject],
                                [modelCustomEvent2.payload[@"events"] firstObject],
                                [modelCustomEvent3.payload[@"events"] firstObject]
                        ],
                        @"language": [EMSDeviceInfo languageCode],
                        @"ems_sdk": MOBILEENGAGE_SDK_VERSION,
                        @"application_version": [EMSDeviceInfo applicationVersion]
                }];
            }];
            compositeModel.originalRequestIds = @[modelCustomEvent1.requestId, modelCustomEvent2.requestId, modelCustomEvent3.requestId];


            createFakeRequestRepository(
                    @[modelCustomEvent1],
                    @[modelCustomEvent1, modelCustomEvent2, modelCustomEvent3],
                    @[model1, modelCustomEvent1, modelCustomEvent2, model2, modelCustomEvent3],
                    [MEInApp new]
            );

            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:[EMSRequestModelSelectAllSpecification new]];
            [[theValue([result count]) should] equal:theValue(3)];
            [[result[0] should] beSimilarWithRequest:model1];
            [[result[1] should] beSimilarWithRequest:compositeModel];
            [[result[2] should] beSimilarWithRequest:model2];
        });

        it(@"should return NO if request repository is NOT empty", ^{
            [[requestModelRepository should] receive:@selector(isEmpty) andReturn:theValue(NO)];
            [[theValue([compositeRequestModelRepository isEmpty]) should] beNo];
        });

        it(@"should return YES if request repository is empty", ^{
            [[requestModelRepository should] receive:@selector(isEmpty) andReturn:theValue(YES)];
            [[theValue([compositeRequestModelRepository isEmpty]) should] beYes];
        });

        it(@"should add dnd on the custom event requests with 'YES' value when inApp is paused", ^{
            EMSRequestModel *modelCustomEvent1 = customEventRequestModel(@"event1", nil);

            MEInApp *meInApp = [MEInApp new];
            [meInApp setPaused:YES];

            createFakeRequestRepository(
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    meInApp
            );
            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:[EMSRequestModelSelectAllSpecification new]];
            [[[result[0] payload][@"dnd"] should] equal:@(YES)];
        });

        it(@"should not add dnd on the custom event requests when inApp is resumed", ^{
            EMSRequestModel *modelCustomEvent1 = customEventRequestModel(@"event1", nil);

            MEInApp *meInApp = [MEInApp new];

            createFakeRequestRepository(
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    @[modelCustomEvent1],
                    meInApp
            );
            NSArray<EMSRequestModel *> *result = [compositeRequestModelRepository query:[EMSRequestModelSelectAllSpecification new]];
            [[theValue([[[result[0] payload] allKeys] containsObject:@"dnd"]) should] beNo];
        });

    });


SPEC_END
