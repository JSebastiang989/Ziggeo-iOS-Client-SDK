//
//  Ziggeo.m
//  ZiggeoMediaSDK
//
//  Created by Sebastian Gomez on 11/11/25.
//


// Ziggeo.m
#import "ZiggeoApplication.h"
#import "RecorderConfig.h"

@implementation Ziggeo

- (instancetype)initWithToken:(NSString *)token {
    self = [super init];
    if (self) {
        // no-op
    }
    return self;
}

- (void)setRecorderConfig:(RecorderConfig *)config {
    // no-op
}

- (void)record {
    // no-op on Simulator
}

@end
