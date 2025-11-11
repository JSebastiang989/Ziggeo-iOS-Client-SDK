//
//  RecorderConfig.m
//  ZiggeoMediaSDK
//
//  Created by Sebastian Gomez on 11/11/25.
//


// RecorderConfig.m
#import "RecorderConfig.h"

const NSInteger FACING_FRONT = 1;

@implementation RecorderConfig {
    BOOL _coverShotEnabled;
    int _facing;
    long _maxDuration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _coverShotEnabled = NO;
        _facing = FACING_FRONT;
        _maxDuration = 0.0;
    }
    return self;
}

- (void)setShouldEnableCoverShot:(BOOL)enable {
    _coverShotEnabled = enable; // store only (no behavior)
}

- (void)setFacing:(int)facing {
    _facing = facing; // store only (no behavior)
}

- (void)setMaxDuration:(long)seconds {
    _maxDuration = seconds; // store only (no behavior)
}

@end
