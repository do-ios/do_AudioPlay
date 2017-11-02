//
//  do_Audio_IMethod.h
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol do_Audio_ISM <NSObject>

//实现同步或异步方法，parms中包含了所需用的属性
@required
- (void)pause:(NSArray *)parms;
- (void)play:(NSArray *)parms;
- (void)resume:(NSArray *)parms;
- (void)startRecord:(NSArray *)parms;
- (void)stop:(NSArray *)parms;
- (void)stopRecord:(NSArray *)parms;
- (void)stopRecordAsync:(NSArray *)parms;
- (void)playAsync:(NSArray *)parms;
@end
