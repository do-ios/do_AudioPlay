//
//  ViewController.m
//  Do_Test
//
//  Created by linliyuan on 15/4/27.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "ViewController.h"
#import "doPage.h"
#import "doService.h"
#import "do_Audio_SM.h"
#import "doIOHelper.h"

@interface ViewController ()
{
@private
    NSString *Type;
    doModule* model;
}
@end
@implementation CallBackEvnet

-(void)eventCallBack:(NSString *)_data
{
    NSLog(@"异步方法回调数据:%@",_data);
}

@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self InitInstance];
    [self ConfigUI];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void) InitInstance
{
    NSString *testPath = [[NSBundle mainBundle] pathForResource:@"do_Test" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:testPath];
    NSMutableDictionary *_testDics = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    Type = [_testDics valueForKey:@"Type"];
    //如果是SM
    model = [[do_Audio_SM alloc]init];
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* target = [[cachePaths objectAtIndex:0] stringByAppendingString:@"/test/1.mp3"];
    NSString * source = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"mp3"];
    NSString* path = [target stringByDeletingLastPathComponent];
    if(![doIOHelper ExistFile:path])
    {
        [doIOHelper CreateDirectory:path];
    }
    if(![doIOHelper ExistFile:target])
        [doIOHelper FileCopy:source :target];
    
    target = [[cachePaths objectAtIndex:0] stringByAppendingString:@"/test/1.amr"];
    source = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"amr"];
    path = [target stringByDeletingLastPathComponent];
    if(![doIOHelper ExistFile:path])
    {
        [doIOHelper CreateDirectory:path];
    }
    if(![doIOHelper ExistFile:target])
        [doIOHelper FileCopy:source :target];

}
- (void)ConfigUI {
    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height;
    //在对应的测试按钮添加自己的测试代码, 如果6个测试按钮不够，可以自己添加
    
    if([Type isEqualToString:@"UI"]){
        //和SM，MM不一样，UI类型还得添加自己的View，所以测试按钮都在底部
        CGFloat height = h/6;
        CGFloat width = (w - 35)/6;
        for(int i = 0;i<6;i++){
            UIButton *test = [UIButton buttonWithType:UIButtonTypeCustom];
            test.frame = CGRectMake(5*(i+1)+width*i, h-h/6, width, height);
            NSString* title = [NSString stringWithFormat:@"Test%d",i ];
            [test setTitle:title forState:UIControlStateNormal];
            SEL customSelector = NSSelectorFromString([NSString stringWithFormat:@"test%d:",i]);
            [test addTarget:self action:customSelector forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:test];
        }
        //addsubview 自定义的UI
        
    }else{
        CGFloat height = (h-140)/6;
        CGFloat width = w - 60;
        for(int i = 0;i<6;i++){
            UIButton *test = [UIButton buttonWithType:UIButtonTypeCustom];
            test.frame = CGRectMake(30, 20*(i+1)+height*i, width, height);
            NSString* title = [NSString stringWithFormat:@"Test%d",i ];
            [test setTitle:title forState:UIControlStateNormal];
            SEL customSelector = NSSelectorFromString([NSString stringWithFormat:@"test%d:",i]);
            [test addTarget:self action:customSelector forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:test];
        }
    }
}

- (void)test0:(UIButton *)sender
{
    NSLog(@"请添加自己的测试代码");
    NSMutableDictionary* node = [[NSMutableDictionary alloc]init];
//    [node setObject:@"data://1.mp3" forKey:@"path"];
    [node setObject:@"data://2.amr" forKey:@"path"];
//    [node setObject:@"http://staff2.ustc.edu.cn/~wdw/softdown/index.asp/0042515_05.ANDY.mp3" forKey:@"path"];
    
    [[doService Instance] SyncMethod:model :@"play" :node];
    
}
- (void)test1:(UIButton *)sender
{
    NSLog(@"请添加自己的测试代码");
    NSMutableDictionary* node = [[NSMutableDictionary alloc]init];
    [[doService Instance] SyncMethod:model :@"pause" :node];
}
- (void)test2:(UIButton *)sender
{
    NSLog(@"请添加自己的测试代码");
    NSMutableDictionary* node = [[NSMutableDictionary alloc]init];
    [[doService Instance] SyncMethod:model :@"resume" :node];

}
- (void)test3:(UIButton *)sender
{
    NSLog(@"请添加自己的测试代码");
    NSMutableDictionary* node = [[NSMutableDictionary alloc]init];
    [[doService Instance] SyncMethod:model :@"stop" :node];

}
- (void)test4:(UIButton *)sender
{
    CallBackEvnet* event1 = [[CallBackEvnet alloc]init];
    [[doService Instance] SubscribeEvent:model :@"playFinished" :event1 ];
    CallBackEvnet* event2 = [[CallBackEvnet alloc]init];
    [[doService Instance] SubscribeEvent:model :@"error" :event2 ];
    CallBackEvnet* event3 = [[CallBackEvnet alloc]init];
    [[doService Instance] SubscribeEvent:model :@"playProgress" :event3 ];
    CallBackEvnet* event4 = [[CallBackEvnet alloc]init];
    [[doService Instance] SubscribeEvent:model :@"recordProgress" :event4 ];
    CallBackEvnet* event5 = [[CallBackEvnet alloc]init];
    [[doService Instance] SubscribeEvent:model :@"recordFinished" :event5 ];
}
- (void)test5:(UIButton *)sender
{
    NSMutableDictionary* node = [[NSMutableDictionary alloc]init];
//    [node setObject:@"data://2.amr" forKey:@"path"];
//    [node setObject:@"data://2.mp3" forKey:@"path"];
    [node setObject:@"data://2.aac" forKey:@"path"];
//    [node setObject:@"amr" forKey:@"type"];
//    [node setObject:@"mp3" forKey:@"type"];
    [node setObject:@"aac" forKey:@"type"];
    [node setObject:@"normal" forKey:@"quality"];
    [node setObject:[NSNumber numberWithInt:10] forKey:@"limit"];
    
    [[doService Instance] SyncMethod:model :@"startRecord" :node];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
