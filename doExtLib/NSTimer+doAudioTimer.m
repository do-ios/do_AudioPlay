//
//  NSTimer+doAudioTimer.m
//  Do_Test
//
//  Created by yz on 16/12/5.
//  Copyright © 2016年 DoExt. All rights reserved.
//

#import "NSTimer+doAudioTimer.h"

NSString *kIsPausedKey = @"IsPaused Key";
NSString *kRemainingTimeIntervalKey = @"RemainingTimeInterval Key";

@implementation NSTimer (doAudioTimer)

- (NSMutableDictionary *)pauseDictionary {
    static NSMutableDictionary *globalDictionary = nil;
    
    if(!globalDictionary)
        globalDictionary = [[NSMutableDictionary alloc] init];
    
    if(![globalDictionary objectForKey:[NSNumber numberWithInt:(int)self]]) {
        NSMutableDictionary *localDictionary = [[NSMutableDictionary alloc] init];
        [globalDictionary setObject:localDictionary forKey:[NSNumber numberWithInt:(int)self]];
    }
    
    return [globalDictionary objectForKey:[NSNumber numberWithInt:(int)self]];
}

- (void)pause {
    if(![self isValid])
        return;
    
    NSNumber *isPausedNumber = [[self pauseDictionary] objectForKey:kIsPausedKey];
    if(isPausedNumber && YES == [isPausedNumber boolValue])
        return;
    
    NSDate *now = [NSDate date];
    NSDate *then = [self fireDate];
    NSTimeInterval remainingTimeInterval = [then timeIntervalSinceDate:now];
    
    [[self pauseDictionary] setObject:[NSNumber numberWithDouble:remainingTimeInterval] forKey:kRemainingTimeIntervalKey];
    
    [self setFireDate:[NSDate distantFuture]];
    [[self pauseDictionary] setObject:[NSNumber numberWithBool:YES] forKey:kIsPausedKey];
}

- (void)resume {
    if(![self isValid])
        return;
    
    NSNumber *isPausedNumber = [[self pauseDictionary] objectForKey:kIsPausedKey];
    if(!isPausedNumber || NO == [isPausedNumber boolValue])
        return;
    
    NSTimeInterval remainingTimeInterval = [[[self pauseDictionary] objectForKey:kRemainingTimeIntervalKey] doubleValue];
    
    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:remainingTimeInterval];
    
    [self setFireDate:fireDate];
    [[self pauseDictionary] setObject:[NSNumber numberWithBool:NO] forKey:kIsPausedKey];
}
@end
