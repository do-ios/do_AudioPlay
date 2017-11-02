//
//  do_AudioPlay_App.m
//  DoExt_SM
//
//  Created by 刘吟 on 15/4/9.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Audio_App.h"
static do_Audio_App* instance;
@implementation do_Audio_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Audio_App alloc]init];
    return instance;
}
@end
