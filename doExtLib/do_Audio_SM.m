//
//  do_AudioPlay_SM.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Audio_SM.h"
#import "doSTKAudioPlayer.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import "doIOHelper.h"
#import "VoiceConverter.h"
#import "doTextHelper.h"
#import "lame.h"
#import "doSTKAudioPlayer.h"
#import "NSTimer+doAudioTimer.h"

@interface do_Audio_SM(audio)<doSTKAudioPlayerDelegate>

@end
@implementation do_Audio_SM
{
    id avAudioPlayer;
    NSString* currentPlayFile;
    NSTimer* timer;
    NSTimer* timer1;
    NSMutableDictionary* formatDict;
    NSMutableDictionary* qualityDict;
    AVAudioRecorder* recoder;
    int currentTime;
    int maxTime;
    NSString* recordPath;
    NSString* recordType;
    
    NSString *returnPath;
    
    id<doIScriptEngine> scritEngine;
    
    BOOL _isPause;
}
#pragma mark -
#pragma mark - 同步异步方法的实现

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isPause = NO;
    }
    return self;
}

//同步
- (void)pause:(NSArray *)parms
{
    if(avAudioPlayer==nil) return;
    doInvokeResult* _result = [parms objectAtIndex:2];
    [avAudioPlayer pause];
    _isPause = YES;
    if([avAudioPlayer isKindOfClass:[doSTKAudioPlayer class]])
    {
        doSTKAudioPlayer* temp = (doSTKAudioPlayer*)avAudioPlayer;
        [_result SetResultFloat:temp.progress];
    }
    else if([avAudioPlayer isKindOfClass:[AVAudioPlayer class]])
    {
        AVAudioPlayer* temp = (AVAudioPlayer*)avAudioPlayer;
        [_result SetResultFloat:temp.currentTime];
    }
    [timer pause];
    //自己的代码实现
}
- (void)play:(NSArray *)parms
{
    _isPause = NO;
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    
    NSString* path = [doJsonHelper GetOneText:_dictParas : @"path" :nil ];
    float point =[doJsonHelper GetOneFloat:_dictParas : @"point" : 0 ]/1000.0;
    if(path==nil||path.length<=0){
        [self fireErrorInfo:@"path不能为空"];
        return;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayback error:&err];
    @try {
        if ([path hasPrefix:@"http"]) {
            [self playHttpAudio:path :point];
        }else{
            path = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentApp :path];
            if(path==nil ||path.length<=0){
                [self fireErrorInfo:[NSString stringWithFormat:@"文件%@找不到",path]];
                return;
            }
            [self playAudio:path : point];
        }
        currentPlayFile = path;
    }
    @catch (NSException *exception) {
        [self fireException:exception];
        return;
    }
    @finally {
        
    }
    
    //自己的代码实现
}
- (void)resume:(NSArray *)parms
{
    if(avAudioPlayer==nil) return;
    _isPause = NO;
    if([avAudioPlayer isKindOfClass:[doSTKAudioPlayer class]])
    {
        doSTKAudioPlayer* temp = (doSTKAudioPlayer*)avAudioPlayer;
        [temp resume];
    }
    else if([avAudioPlayer isKindOfClass:[AVAudioPlayer class]])
    {
        AVAudioPlayer* temp = (AVAudioPlayer*)avAudioPlayer;
        [temp play];
    }
    [timer resume];
    //自己的代码实现
}
- (void)stop:(NSArray *)parms
{
    _isPause = NO;
    if(avAudioPlayer==nil) return;
    [avAudioPlayer stop];
    if([avAudioPlayer isKindOfClass:[doSTKAudioPlayer class]])
    {
        doSTKAudioPlayer* temp = (doSTKAudioPlayer*)avAudioPlayer;
        [temp dispose];
    }
    [self stopTimer];
    avAudioPlayer = nil;
}

-(void) startRecord:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    
    NSString* path = [doJsonHelper GetOneText:_dictParas : @"path" :nil ];
    NSString *savePath = path;
    if(path==nil||path.length<=0)
        [self fireErrorInfo:[NSString stringWithFormat:@"文件不能为空"]];
    recordType = [doJsonHelper GetOneText:_dictParas : @"type" :@"mp3" ];
    NSString* quality = [doJsonHelper GetOneText:_dictParas : @"quality" :@"normal" ];
    maxTime = [doJsonHelper GetOneInteger:_dictParas :@"limit" :-1];
    
    if(avAudioPlayer!=nil)
        [avAudioPlayer stop];
    if(formatDict==nil)
        [self setFormatDict];
    if(qualityDict==nil)
        [self setQualityDict];
    
    [self stopTimer];
    if((maxTime > 0) || (maxTime < 0 && maxTime == -1)){
        currentTime = 0;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self  selector:@selector(countTime)  userInfo:nil repeats:YES];
        timer1 = [NSTimer scheduledTimerWithTimeInterval:.05 target:self  selector:@selector(countTime1)  userInfo:nil repeats:YES];
    }
    scritEngine = [parms objectAtIndex:1];
    path = [doIOHelper GetLocalFileFullPath:scritEngine.CurrentApp :path];
    if(![doIOHelper ExistDirectory:path])
        [doIOHelper CreateDirectory:path];
    NSString *dateStr = [NSString stringWithFormat:@"%0.f",[NSDate date].timeIntervalSince1970];
    if([recordType isEqualToString:@"amr"])
    {
        path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",dateStr]];
        if ([savePath hasSuffix:@"/"]) {//路径是data://处理
            returnPath = [NSString stringWithFormat:@"%@%@.amr",savePath,dateStr];
        }
        else
        {
            returnPath = [NSString stringWithFormat:@"%@/%@.amr",savePath,dateStr];
        }
    }
    if([recordType isEqualToString:@"mp3"])
    {
        path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",dateStr]];
        if ([savePath hasSuffix:@"/"]) {
            returnPath = [NSString stringWithFormat:@"%@%@.mp3",savePath,dateStr];
        }
        else{
            returnPath = [NSString stringWithFormat:@"%@/%@.mp3",savePath,dateStr];
        }
    }
    if ([recordType isEqualToString:@"aac"])
    {
        path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.aac",dateStr]];
        if ([savePath hasSuffix:@"/"]) {
            returnPath = [NSString stringWithFormat:@"%@%@.aac",savePath,dateStr];
        }
        else{
            returnPath = [NSString stringWithFormat:@"%@/%@.aac",savePath,dateStr];
        }
    }
    recordPath = path;
    NSMutableDictionary* setting = [[NSMutableDictionary alloc]init];
    [setting setDictionary:[qualityDict objectForKey:quality]];
    [setting setObject:[formatDict objectForKey:recordType] forKey:AVFormatIDKey];
    NSError* error;
    recoder = [[AVAudioRecorder alloc]initWithURL:[NSURL URLWithString:path] settings: setting error:&error];
    recoder.delegate = self;
    recoder.meteringEnabled = YES;
    [recoder prepareToRecord];
    //开始录音
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    UInt32 doChangeDefault = 1;
    //7.0以下适用
    //AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefault), &doChangeDefault);
    
    NSError* newerror;
    [[AVAudioSession sharedInstance]setPreferredIOBufferDuration:sizeof(doChangeDefault) error:&newerror];
    [recoder record];
    [recoder peakPowerForChannel:0];
}
- (void)stopRecord:(NSArray *)parms
{
    [self stopRecord];
    doInvokeResult* _result = [parms objectAtIndex:2];
    [_result SetResultText:returnPath];
    //    returnPath = @"";
}
- (void)stopRecordAsync:(NSArray *)parms
{
    [self stopRecord];
}

// 异步
- (void)playAsync:(NSArray *)parms {
    _isPause = NO;
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    NSString *_callbackName = [parms objectAtIndex:2];
    NSString* path = [doJsonHelper GetOneText:_dictParas : @"path" :nil ];
    float point =[doJsonHelper GetOneFloat:_dictParas : @"point" : 0 ]/1000.0;
    if(path==nil||path.length<=0){
        [self fireErrorInfo:@"path不能为空"];
        return;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayback error:&err];
    @try {
        if ([path hasPrefix:@"http"]) {
            [self playHttpAudio:path :point];
        }else{
            path = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentApp :path];
            if(path==nil ||path.length<=0){
                [self fireErrorInfo:[NSString stringWithFormat:@"文件%@找不到",path]];
                return;
            }
            [self playAudio:path : point];
        }
        currentPlayFile = path;
    }
    @catch (NSException *exception) {
        [self fireException:exception];
        return;
    }
    @finally {
        doInvokeResult *_invokeResult = [[doInvokeResult alloc]init:self.UniqueKey];
        [_scritEngine Callback:_callbackName :_invokeResult];
    }
}
#pragma mark -
#pragma mark - private
-(void) countTime
{
    currentTime++;
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    [_result SetResultText:[@(currentTime * 1000) stringValue]];
    [self.EventCenter FireEvent:@"recordProgress" : _result ];
    if((currentTime * 1000>=maxTime) && (maxTime > 0)){
        [self stopRecord];
    }
}
-(void) countTime1
{
    [recoder updateMeters];
    double meters = [recoder peakPowerForChannel:0]+100;
    
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:@(meters) forKey:@"volume"];

    [_result SetResultNode:node];
    [self.EventCenter FireEvent:@"recordVolume" : _result];
}
-(void) stopRecord
{
    [self stopTimer];
    [recoder stop];
    [avAudioPlayer stop];
    recoder = nil;
    avAudioPlayer = nil;
    if([recordType isEqualToString:@"amr"]){
        [VoiceConverter wavToAmr:recordPath amrSavePath:[recordPath stringByReplacingOccurrencesOfString:@"wav" withString:@"amr"]];
        returnPath = [returnPath stringByReplacingOccurrencesOfString:@"wav" withString:@"amr"];
        [self fireFinishEvent];
    }
    if([recordType isEqualToString:@"mp3"]){
        //转换wavtomp3
        [self wav2mp3:recordPath:[recordPath stringByReplacingOccurrencesOfString:@"wav" withString:@"mp3"]];
        returnPath = [returnPath stringByReplacingOccurrencesOfString:@"wav" withString:@"mp3"];
        [self fireFinishEvent];
    }
}
- (void)stopTimer{
    if (timer && timer.isValid){
        [timer invalidate];
        timer = nil;
    }
    if (timer1 && timer1.isValid){
        [timer1 invalidate];
        timer1 = nil;
    }
}
-(void) setQualityDict
{
    int chanelsKey = [recordType isEqualToString:@"amr"] ? 1 : 2;
    qualityDict = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *lowSetting = [[NSMutableDictionary alloc] init];
    [lowSetting
     setValue:[NSNumber numberWithFloat:8000]
     forKey:AVSampleRateKey];
    [lowSetting
     setValue:[NSNumber numberWithInteger:chanelsKey]
     forKey:AVNumberOfChannelsKey];
    [lowSetting
     setValue:[NSNumber numberWithInteger:AVAudioQualityLow]
     forKey:AVEncoderAudioQualityKey];
    //    [lowSetting setObject:[NSNumber numberWithInt:12800] forKey:AVEncoderBitRateKey];//解码率
    //    [lowSetting setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];//采样位
    [qualityDict setObject:lowSetting forKey:@"low"];
    NSMutableDictionary *normalSetting = [[NSMutableDictionary alloc] init];
    [normalSetting
     setValue:[NSNumber numberWithFloat:8000]
     forKey:AVSampleRateKey];
    [normalSetting
     setValue:[NSNumber numberWithInteger:chanelsKey]
     forKey:AVNumberOfChannelsKey];
    [normalSetting
     setValue:[NSNumber numberWithInteger:AVAudioQualityLow]
     forKey:AVEncoderAudioQualityKey];
    //    [normalSetting setObject:[NSNumber numberWithInt:12800] forKey:AVEncoderBitRateKey];//解码率
    //    [normalSetting setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];//采样位
    [qualityDict setObject:normalSetting forKey:@"normal"];
    NSMutableDictionary *highSetting = [[NSMutableDictionary alloc] init];
    [highSetting
     setValue:[NSNumber numberWithFloat:8000]
     forKey:AVSampleRateKey];
    [highSetting
     setValue:[NSNumber numberWithInteger:chanelsKey]
     forKey:AVNumberOfChannelsKey];
    [highSetting
     setValue:[NSNumber numberWithInteger:AVAudioQualityMedium]
     forKey:AVEncoderAudioQualityKey];
    //    [highSetting setObject:[NSNumber numberWithInt:12800] forKey:AVEncoderBitRateKey];//解码率
    //    [highSetting setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];//采样位
    [qualityDict setObject:highSetting forKey:@"high"];
}
-(void) setFormatDict{
    formatDict = [[NSMutableDictionary alloc]init];
    [formatDict setObject:[NSNumber numberWithInteger:kAudioFormatLinearPCM] forKey:@"mp3"];
    
    [formatDict setObject:[NSNumber numberWithInteger:kAudioFormatMPEG4AAC] forKey:@"aac"];
    
    [formatDict setObject:[NSNumber numberWithInteger:kAudioFormatLinearPCM] forKey:@"amr"];
}

-(void) playAudio:(NSString*) path : (float) point
{
    AVAudioPlayer* temp ;
    NSString* wavPath = [[path stringByDeletingPathExtension] stringByAppendingString:@".wav"];
    if (![doIOHelper ExistFile:wavPath]) {
        if ([VoiceConverter isAMRFile:path]) {
            [VoiceConverter amrToWav:path wavSavePath:[[path stringByDeletingPathExtension] stringByAppendingString:@".wav"]];
            path = wavPath;
        }
    }
    else
    {
        path = wavPath;
    }
    if(avAudioPlayer==nil||![path isEqualToString:currentPlayFile]){
        NSError * _error;
        NSURL* _url = [NSURL fileURLWithPath:path];
        if(avAudioPlayer!=nil&&[avAudioPlayer isKindOfClass:[doSTKAudioPlayer class]])
            [((doSTKAudioPlayer*)avAudioPlayer) dispose];
        avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: _url error:&_error];
        if(_error!=nil){
            [self fireError:_error];
            return;
        }
    }
    temp = avAudioPlayer;
    temp.delegate = self;
    [temp prepareToPlay];
    temp.volume = 1.0;
    if(point<=0)
    {
        [temp setCurrentTime:0];
    }else{
        [temp setCurrentTime:point];
    }
    [self stopTimer];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self  selector:@selector(playProgress)  userInfo:nil repeats:YES];
    [temp play];
}
-(void) playHttpAudio:(NSString*) path : (float) point
{
    doSTKAudioPlayer* temp ;
    if(avAudioPlayer!=nil&&[avAudioPlayer isKindOfClass:[doSTKAudioPlayer class]])
        [((doSTKAudioPlayer*)avAudioPlayer) dispose];
    avAudioPlayer = [[doSTKAudioPlayer alloc] init];
    temp = avAudioPlayer;
    temp.delegate = self;
    temp.volume = 1.0;
    [self stopTimer];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self  selector:@selector(playProgress)  userInfo:nil repeats:YES];
    doSTKDataSource* dataSource = [doSTKAudioPlayer dataSourceFromURL:[NSURL URLWithString:path]];
    [temp setDataSource:dataSource withQueueItemId:[[NSObject alloc]init]];
    [temp play:path];
    if(point<=0)
    {
        [temp seekToTime:0];
    }else{
        [temp seekToTime:point];
    }
}
-(void) fireErrorInfo:(NSString*) error
{
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    [_result SetResultText:error];
    [self.EventCenter FireEvent:@"error" : _result ];
    [self stopTimer];
}
-(void) fireError:(NSError*) error
{
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    [_result SetResultText:error.localizedDescription];
    [self.EventCenter FireEvent:@"error" : _result ];
    [self stopTimer];
}
-(void) fireException:(NSException*) error
{
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    [_result SetResultText:error.reason];
    [self.EventCenter FireEvent:@"error" : _result ];
    [self stopTimer];
}
- (void)playProgress
{
    if (_isPause) {
        return;
    }
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    if([avAudioPlayer isKindOfClass:[doSTKAudioPlayer class]])
    {
        doSTKAudioPlayer* temp = (doSTKAudioPlayer*)avAudioPlayer;
        [dict setValue: [NSNumber numberWithDouble:(temp.progress * 1000)] forKey:@"currentTime"];
        [dict setValue: [NSNumber numberWithDouble:(temp.duration * 1000)] forKey:@"totalTime"];
    }
    else if([avAudioPlayer isKindOfClass:[AVAudioPlayer class]])
    {
        AVAudioPlayer* temp = (AVAudioPlayer*)avAudioPlayer;
        [dict setValue: [NSNumber numberWithDouble:(temp.currentTime * 1000)] forKey:@"currentTime"];
        [dict setValue: [NSNumber numberWithDouble:(temp.duration * 1000)] forKey:@"totalTime"];
    }
    [_result SetResultNode:dict];
    [self.EventCenter FireEvent:@"playProgress" : _result];
}
- (void)wav2mp3:(NSString*) source :(NSString*) target
{
    @try {
        int read, write;
        
        FILE *pcm = fopen([source cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([target cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 8000);
        lame_set_out_samplerate(lame, 16000);
        //        lame_set_brate(lame, 16);
        //        lame_set_mode(lame, 1);
        //        lame_set_quality(lame, 0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        
        NSLog(@"MP3生成成功");
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
    }
    
}
#pragma mark -@protocol AVAudioPlayerDelegate <NSObject>
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    [self.EventCenter FireEvent:@"playFinished" : _result ];
    [self stopTimer];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [self fireError:error];
}
#pragma mark -@doSTKAudioPlayerDelegate
/// Raised when an item has started playing
-(void) audioPlayer:(doSTKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
    
}
/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
-(void) audioPlayer:(doSTKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
    
}
/// Raised when the state of the player has changed
-(void) audioPlayer:(doSTKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    
}
/// Raised when an item has finished playing
-(void) audioPlayer:(doSTKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    [self.EventCenter FireEvent:@"playFinished" : _result ];
    [self stopTimer];
}
/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
-(void) audioPlayer:(doSTKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    [self fireErrorInfo:[NSString stringWithFormat:@"播放%@出错",currentPlayFile]];
}
#pragma mark -@AVAudioRecorderDelegate
/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"audioRecorderDidFinishRecording");
    if(![recordType isEqualToString:@"amr"] && ![recordType isEqualToString:@"mp3"]){
        [self fireFinishEvent];
    }
}

- (void)fireFinishEvent
{
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:returnPath forKey:@"path"];
    [node setObject:@(currentTime * 1000) forKey:@"time"];
    
    NSString *filePath = [doIOHelper GetLocalFileFullPath:scritEngine.CurrentApp :returnPath];
    NSFileManager* manager = [NSFileManager defaultManager];
    long long size = 0;
    if ([doIOHelper ExistFile:filePath]){
        size = [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    [node setObject:@(size) forKey:@"size"];
    
    [_result SetResultNode:node];
    [self.EventCenter FireEvent:@"recordFinished" : _result ];
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    [self fireError:error];
}
@end
