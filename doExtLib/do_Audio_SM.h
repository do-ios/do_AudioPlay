//
//  do_AudioPlay_SM.h
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Audio_ISM.h"
#import "doSingletonModule.h"
#import <AVFoundation/AVFoundation.h>

@interface do_Audio_SM : doSingletonModule<do_Audio_ISM,AVAudioPlayerDelegate,AVAudioRecorderDelegate>

@end