#import "Kiwi.h"
#import "MEExperimental.h"

@interface MEExperimental(Tests)
+ (void)reset;
@end

SPEC_BEGIN(FlipperTest)


    describe(@"MEExperimental.featureEnabled", ^{

        beforeEach(^{
            [MEExperimental reset];
        });

        it(@"should default to being turned off", ^{
            [[theValue([MEExperimental isFeatureEnabled:INAPP_MESSAGING]) should] beFalse];
        });

        it(@"should return true if the flipper is turned on", ^{
            [MEExperimental enableFeature:INAPP_MESSAGING];
            [[theValue([MEExperimental isFeatureEnabled:INAPP_MESSAGING]) should] beTrue];
        });

        it(@"should return true for both features if we enabled both", ^{
            [MEExperimental enableFeature:INAPP_MESSAGING];
            NSString *feature = @"secondFeature";
            [MEExperimental enableFeature:feature];
            [[theValue([MEExperimental isFeatureEnabled:INAPP_MESSAGING]) should] beTrue];
            [[theValue([MEExperimental isFeatureEnabled:feature]) should] beTrue];
        });

    });

    describe(@"MEExperimental.reset", ^{
        it(@"should reset the state", ^{
            [MEExperimental enableFeature:INAPP_MESSAGING];
            [MEExperimental reset];
            [[theValue([MEExperimental isFeatureEnabled:INAPP_MESSAGING]) should] beFalse];
        }) ;
    });

SPEC_END
