//
//  GMRecoderTool.m
//  myLawyer
//
//  Created by Marx on 2016/10/10.
//  Copyright © 2016年 lawyer. All rights reserved.
//

#import "GMRecorderTool.h"
#import <AVFoundation/AVFoundation.h>
#import "VoiceConverter.h"

@interface GMRecorderTool ()
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *preWavPath;

@property (nonatomic, copy) AUDIOBLOCK block;
@end

@implementation GMRecorderTool


+ (GMRecorderTool *)shareInstance {
    static GMRecorderTool *tool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[GMRecorderTool alloc] init];
    });
    return tool;
}

- (void)startRecord:(AUDIOBLOCK)block {
    self.block = block;
    self.fileName = [GMRecorderTool GetCurrentTimeString];
    self.preWavPath = [GMRecorderTool GetPathByFileName:self.fileName ofType:@"wav"];
    //初始化录音
    self.recorder = [self.recorder initWithURL:[NSURL fileURLWithPath:self.preWavPath] settings:[VoiceConverter GetAudioRecorderSettingDict] error:nil];
    //准备录音
    if ([self.recorder prepareToRecord]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        self.recorder.meteringEnabled = YES;
        //开始录音
        if ([self.recorder record]){
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(levelTimerCallback:) userInfo:nil repeats:YES];
        }
    }
}

- (NSString *)stopRecord {
    if (!self.timer.isValid) {
        [self.timer invalidate];
        self.timer = nil;
    }
    if (self.recorder.isRecording) {//录音中
        //停止录音
        [self.recorder stop];
        self.recorder = nil;
        //开始转换格式
        NSString *amrPath = [GMRecorderTool GetPathByFileName:self.fileName ofType:@"amr"];
#warning wav转amr
        if ([VoiceConverter ConvertWavToAmr:self.preWavPath amrSavePath:amrPath]){
            NSLog(@"wav转amr成功");
        }else
            NSLog(@"wav转amr失败");
    }
    return self.fileName;
}

- (void)levelTimerCallback:(NSTimer *)timer {
    [self.recorder updateMeters];
    
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = [self.recorder averagePowerForChannel:0];
    
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    /* level 范围[0 ~ 1], 转为[0 ~120] 之间 */
    dispatch_async(dispatch_get_main_queue(), ^{
        self.block(level);
        NSLog(@"%f", level);
        //        [_textLabel setText:[NSString stringWithFormat:@"%f", level*120]];
    });
}

#pragma mark - 生成当前时间字符串
+ (NSString*)GetCurrentTimeString {
    NSDateFormatter *dateformat = [[NSDateFormatter  alloc]init];
    [dateformat setDateFormat:@"yyyyMMddHHmmss"];
    return [dateformat stringFromDate:[NSDate date]];
}
#pragma mark - 生成文件路径
+ (NSString*)GetPathByFileName:(NSString *)_fileName ofType:(NSString *)_type{
    NSString *directory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@"/recorder/%@/", _type]];
    NSString* fileDirectory = [[[directory stringByAppendingPathComponent:_fileName]
                                stringByAppendingPathExtension:_type]
                               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return fileDirectory;
}

- (AVAudioRecorder *)recorder {
    if (!_recorder) {
        _recorder = [AVAudioRecorder alloc];
    }
    return _recorder;
}

@end
