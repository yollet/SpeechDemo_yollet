//
//  RootVc.m
//  语音识别
//
//  Created by yollet on 16/9/27.
//  Copyright © 2016年 yollet. All rights reserved.
//

#import "RootVc.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
#import "DMPickView.h"

@interface RootVc () <AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioRecorder *audioRecorder; //  音频录音机
@property (nonatomic, strong) AVAudioPlayer *audioPlayer; // 音频播放器
@property (nonatomic, strong) NSTimer *timer; // 录音声波监控
@property (nonatomic, strong) UIButton *record; // 开始录音
@property (nonatomic, strong) UIButton *pause; // 暂停录音
@property (nonatomic, strong) UIButton *resume; // 回复录音
@property (nonatomic, strong) UIButton *stop; // 停止录音
@property (nonatomic, strong) UIButton *deleteBtn; // 删除
@property (nonatomic, strong) UIProgressView *audioPower; // 音频波动
@property (nonatomic, strong) UIButton *identify; // 识别语音
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *videoArray; // 录音文件
@property (nonatomic, strong) UILabel *identifyLabel; // 语音识别结果
@property (nonatomic, strong) NSURL *identifyUrl; // 识别路径
@property (nonatomic, strong) UIProgressView *playPower; // 播放进度条
@property (nonatomic, strong) NSTimer *playTimer; // 播放进度条控制定时器
@property (nonatomic, strong) NSString *localStr; // 国家
@property (nonatomic, strong) UIButton *localSelectBtn; // 国家选择
@property (nonatomic, strong) DMPickView *pick; // 选择器

@end

@implementation RootVc

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setViews];
    [self setAudioSession];
    
    NSInteger num = [[NSUserDefaults standardUserDefaults] integerForKey:@"audioNum"];
    if (num == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"audioNum"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self seachFile];
}

#pragma mark -- 查看文件 --
- (void)seachFile
{
    NSArray *firstSavePathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    for (NSString *path in firstSavePathArray) {
        NSLog(@"firstSavePathArray : %@", path);
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *fileList = [[NSArray alloc] init];
    fileList = [fileManager contentsOfDirectoryAtPath:firstSavePathArray[0] error:&error];
    self.videoArray = fileList;
    NSLog(@"%@",fileList);
}

#pragma mark -- 删除文件 --
- (void)deleteVideo
{
    NSArray *firstSavePathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [firstSavePathArray firstObject];
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *video in _videoArray) {
        NSString *newPath = [path stringByAppendingPathComponent:video];
        [manager removeItemAtPath:newPath error:nil];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"audioNum"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self seachFile];
    [self.tableView reloadData];
}

#pragma mark -- 布局 --
- (void)setViews
{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
//    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.record = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.record setTitle:@"开始" forState:UIControlStateNormal];
    self.record.frame = CGRectMake(20, 50, (width - 5 * 20) / 4.0, 30);
    [self.record addTarget:self action:@selector(recordClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_record];
    
    self.pause = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pause setTitle:@"暂停" forState:UIControlStateNormal];
    self.pause.frame = CGRectMake(20 + (width - 5 * 20) / 4.0 + 20, 50, (width - 5 * 20) / 4.0, 30);
    [self.pause addTarget:self action:@selector(pauseClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pause];
    
    self.resume = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.resume setTitle:@"继续" forState:UIControlStateNormal];
    self.resume.frame = CGRectMake(20 + ((width - 5 * 20) / 4.0 + 20) * 2, 50, (width - 5 * 20) / 4.0, 30);
    [self.resume addTarget:self action:@selector(resumeClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_resume];
    
    self.stop = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.stop setTitle:@"结束" forState:UIControlStateNormal];
    self.stop.frame = CGRectMake(20 + ((width - 5 * 20) / 4.0 + 20) * 3, 50, (width - 5 * 20) / 4.0, 30);
    [self.stop addTarget:self action:@selector(stopClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_stop];
    
    self.audioPower = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 100, width - 20 * 2, 20)];
    self.audioPower.progressTintColor = [UIColor orangeColor];
//    self.audioPower.progressImage = [UIImage imageNamed:@"dian"];
//    self.audioPower.progress = 0.5;
    [self.view addSubview:_audioPower];
    
    self.playPower = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 130, width - 20 * 2, 20)];
    self.playPower.progressTintColor = [UIColor cyanColor];
    //    self.audioPower.progressImage = [UIImage imageNamed:@"dian"];
    //    self.audioPower.progress = 0.5;
    [self.view addSubview:_playPower];
    
    self.identify = [UIButton buttonWithType:UIButtonTypeSystem];
    self.identify.frame = CGRectMake(20, 160, 40, 30);
    [self.identify setTitle:@"识别" forState:UIControlStateNormal];
    [self.identify addTarget:self action:@selector(identifyClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_identify];
    
    self.deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteBtn.frame = CGRectMake(80, 160, 40, 30);
    [self.deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [self.deleteBtn addTarget:self action:@selector(deleteVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_deleteBtn];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(20, 200, (width - 40 - 20) / 2.0, 300) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:_tableView];
    
    UILabel *identifyLabel = [[UILabel alloc] initWithFrame:CGRectMake(width / 2.0 + 10, 160, (width - 40 - 20) / 2.0, 20)];
    identifyLabel.text = @"识别结果";
    identifyLabel.textColor = [UIColor orangeColor];
    identifyLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:identifyLabel];
    
    self.identifyLabel = [[UILabel alloc] initWithFrame:CGRectMake(width / 2.0 + 10, 200, (width - 40 - 20) / 2.0, 300)];
    self.identifyLabel.numberOfLines = 0;
    self.identifyLabel.backgroundColor = [UIColor orangeColor];
    self.identifyLabel.textAlignment = NSTextAlignmentCenter;
    self.identifyLabel.font = [UIFont systemFontOfSize:12.0];
    [self.view addSubview:_identifyLabel];
    
    self.localSelectBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.localSelectBtn.frame = CGRectMake(20, CGRectGetMaxY(_identifyLabel.frame) + 20, 40, 30);
    [self.localSelectBtn setTitle:@"中文" forState:UIControlStateNormal];
    [self.localSelectBtn addTarget:self action:@selector(pickShow) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_localSelectBtn];
}

#pragma mark -- 路径读取 --
- (NSURL *)getSavePath
{
    NSString *urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSInteger audioNum = [[NSUserDefaults standardUserDefaults] integerForKey:@"audioNum"];
    urlStr = [urlStr stringByAppendingPathComponent:[NSString stringWithFormat:@"myAudio%ld.caf", audioNum - 1]];
//    audioNum += 1;
//    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"audioNum"];
//    NSLog(@"file path == %@", urlStr);
    NSURL *url = [NSURL fileURLWithPath:urlStr];
    NSLog(@"%ld", audioNum);
    return url;
}

#pragma mark -- 展示国家选择器 --
- (void)pickShow
{
    __weak RootVc *wself = self;
    if (!_pick) {
        self.pick = [[DMPickView alloc] initWithFrame:[UIScreen mainScreen].bounds dataArray:@[@"中文", @"英语", @"日语"] pickBlock:^(NSInteger row, NSString *data) {
            NSArray *arr = @[@"zh-CN", @"en-US", @"ja-JP"];
            [wself.localSelectBtn setTitle:data forState:UIControlStateNormal];
            wself.localStr = arr[row];
        }];
        [self.view addSubview:_pick];
    }
    else {
        self.pick.hidden = NO;
    }
}

#pragma mark -- 取得录音文件设置 --
- (NSDictionary *)getAudioSetting
{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    
    // 设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    // 设置录音采样率
    [dicM setObject:@(44100.0) forKey:AVSampleRateKey];
    // 设置通道 1为单声道
    [dicM setObject:@(2) forKey:AVNumberOfChannelsKey];
    // 每个采样点数 分为8 16 24 32
    [dicM setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    // 是否使用浮点采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //录音质量
    [dicM setObject:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    return dicM;
}

#pragma mark -- 获取录音机对象 --
- (AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder) {
        // 创建录音文件保存路径
        NSURL *url = [self getSavePath];
        // 创建录音格式设置
        NSDictionary *setting = [self getAudioSetting];
        // 创建录音机
        NSError *error = nil;
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES; // 如果要监控声波则设置为YES
        if (error) {
            NSLog(@"创建录音机对象发生错误，错误信息：%@", error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

#pragma mark -- 录音 --
- (void)recorderWithUrl:(NSURL *)url
{
    // 创建录音格式设置
    NSDictionary *setting = [self getAudioSetting];
    // 创建录音机
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error]; // 将播放设置调为录音模式
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
    self.audioRecorder.delegate = self;
    self.audioRecorder.meteringEnabled = YES; // 如果要监控声波则设置为YES
    if (error) {
        NSLog(@"创建录音机对象发生错误，错误信息：%@", error.localizedDescription);
    }
    else if (![self.audioRecorder isRecording]) {
        [self.audioRecorder record];
    }
}

#pragma mark -- 播放 --
- (void)playWithUrl:(NSURL *)url
{
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:&error]; // 将播放设置调为正常播放 不然会在录制模式下 音量过小
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioPlayer.volume = 1;
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops = 0;
    [self.audioPlayer prepareToPlay];
    if (error) {
        NSLog(@"创建播放器过程中发生错误，错误信息：%@", error.localizedDescription);
    }
    else if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
        self.playTimer.fireDate = [NSDate distantPast];
    }
}

#pragma mark -- 定时器 --
- (NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}

#pragma mark -- 播放定时器 --
- (NSTimer *)playTimer
{
    if (!_playTimer) {
        _playTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playPowerChange) userInfo:nil repeats:YES];
    }
    return _playTimer;
}

#pragma mark -- 录音声波状态设置 --
- (void)audioPowerChange
{
    [self.audioRecorder updateMeters]; // 更新测试值
    float power = [self.audioRecorder averagePowerForChannel:0]; // 取得第一个通道的音频 音频强度范围：(-160~0)
    CGFloat progress = (1 / 160.0) * (power + 160.0);
    [self.audioPower setProgress:progress];
}

#pragma mark -- 播放进度状态设置 --
- (void)playPowerChange
{
    CGFloat progress = self.audioPlayer.currentTime / self.audioPlayer.duration;
    [self.playPower setProgress:progress];
}

#pragma mark -- 点击录音 --
- (void)recordClick:(UIButton *)sender
{
    if (![self.audioRecorder isRecording]) {
        [self recorderWithUrl:[self getSavePath]];
        self.timer.fireDate = [NSDate distantPast]; // 开启timer
    }
}

#pragma mark -- 暂停 --
- (void)pauseClick:(UIButton *)sender
{
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder pause];
        self.timer.fireDate = [NSDate distantFuture]; // 暂停
    }
}

#pragma mark -- 恢复录音 --
- (void)resumeClick:(UIButton *)sender
{
    if (![self.audioRecorder isRecording]) {
        [self.audioRecorder record];
        self.timer.fireDate = [NSDate distantPast];
    };
}

#pragma mark -- 结束 --
- (void)stopClick:(UIButton *)sender
{
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
        self.timer.fireDate = [NSDate distantFuture];
        self.audioPower.progress = 0.0;
        
        NSString *urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSLog(@"file path == %@", urlStr);
        NSInteger audioNum = [[NSUserDefaults standardUserDefaults] integerForKey:@"audioNum"];
        audioNum += 1;
        [[NSUserDefaults standardUserDefaults] setInteger:audioNum forKey:@"audioNum"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark -- 录音代理方法 --
// 录音完成后调用
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (![self.audioPlayer isPlaying]) {
        [self playWithUrl:[self getSavePath]];
    }
    [self seachFile];
    [self.tableView reloadData];
    NSLog(@"录音完成");
}

#pragma mark -- 播放结束代理 --
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.playTimer.fireDate = [NSDate distantFuture];
    self.playPower.progress = 0.0;
}

#pragma mark -- 设置音频会话 --
- (void)setAudioSession
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 设置播放和录音状态（如录音完成后播放等）
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

#pragma mark -- 识别 --
- (void)identifyClick:(UIButton *)sender
{
    if (_identifyUrl) {
        [self speechRecognitionWithUrl:_identifyUrl];
    }
}

#pragma mark -- 语音识别 --
- (void)speechRecognitionWithUrl:(NSURL *)url
{
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        if (status == 3) {
            NSLog(@"授权成功");
        }
        else {
            NSLog(@"授权失败");
        }
    }];
    
    NSLocale *loc = [NSLocale localeWithLocaleIdentifier:_localStr ? _localStr : @"zh-CN"]; // zh-CN ja-JP
    // 创建语音识别操作类对象
    SFSpeechRecognizer *rec = [[SFSpeechRecognizer alloc] initWithLocale:loc];
    // 通过一个音频路劲常见音频识别请求
//    SFSpeechRecognitionRequest *request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"7011" withExtension:@"m4a"]];
    SFSpeechRecognitionRequest *request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    // 进行请求
    [rec recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        NSLog(@"%@", result.bestTranscription.formattedString);
        self.identifyLabel.text = result.bestTranscription.formattedString ? result.bestTranscription.formattedString : @"无法识别";
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"识别结果" message:(result.bestTranscription.formattedString ? result.bestTranscription.formattedString : @"无法识别") preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//            
//        }];
//        [alert addAction:cancel];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self presentViewController:alert animated:YES completion:nil];
//        });
    }];
}

#pragma mark -- tableView代理 --
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _videoArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor cyanColor];
    cell.textLabel.text = _videoArray[indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = _videoArray[indexPath.row];
    NSString *urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr = [urlStr stringByAppendingPathComponent:title];
    [self playWithUrl:[NSURL fileURLWithPath:urlStr]];
    self.identifyUrl = [NSURL fileURLWithPath:urlStr];
    [self speechRecognitionWithUrl:_identifyUrl];
}

#pragma mark -- 类说明 --


//SFSpeechRecognizer类的主要作用是申请权限，配置参数与进行语音识别请求。其中比较重要的属性与方法如下

////获取当前用户权限状态
//+ (SFSpeechRecognizerAuthorizationStatus)authorizationStatus;
////申请语音识别用户权限
//+ (void)requestAuthorization:(void(^)(SFSpeechRecognizerAuthorizationStatus status))handler;
////获取所支持的所有语言环境
//+ (NSSet<NSLocale *> *)supportedLocales;
////初始化方法 需要注意 这个初始化方法将默认以设备当前的语言环境作为语音识别的语言环境
//- (nullable instancetype)init;
////初始化方法 设置一个特定的语言环境
//- (nullable instancetype)initWithLocale:(NSLocale *)locale NS_DESIGNATED_INITIALIZER;
////语音识别是否可用
//@property (nonatomic, readonly, getter=isAvailable) BOOL available;
////语音识别操作类协议代理
//@property (nonatomic, weak) id<SFSpeechRecognizerDelegate> delegate;
////设置语音识别的配置参数 需要注意 在每个语音识别请求中也有这样一个属性 这里设置将作为默认值
////如果SFSpeechRecognitionRequest对象中也进行了设置 则会覆盖这里的值
///*
// typedef NS_ENUM(NSInteger, SFSpeechRecognitionTaskHint) {
// SFSpeechRecognitionTaskHintUnspecified = 0,     // 无定义
// SFSpeechRecognitionTaskHintDictation = 1,       // 正常的听写风格
// SFSpeechRecognitionTaskHintSearch = 2,          // 搜索风格
// SFSpeechRecognitionTaskHintConfirmation = 3,    // 短语风格
// };
// */
//@property (nonatomic) SFSpeechRecognitionTaskHint defaultTaskHint;
////使用回调Block的方式进行语音识别请求 请求结果会在Block中传入
//- (SFSpeechRecognitionTask *)recognitionTaskWithRequest:(SFSpeechRecognitionRequest *)request resultHandler:(void (^)(SFSpeechRecognitionResult * __nullable result, NSError * __nullable error))resultHandler;
////使用代理回调的方式进行语音识别请求
//- (SFSpeechRecognitionTask *)recognitionTaskWithRequest:(SFSpeechRecognitionRequest *)request delegate:(id <SFSpeechRecognitionTaskDelegate>)delegate;
////设置请求所占用的任务队列
//@property (nonatomic, strong) NSOperationQueue *queue;


//SFSpeechRecognizerDelegate协议中只约定了一个方法，如下:

//当语音识别操作可用性发生改变时会被调用
//- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available;


//通过Block回调的方式进行语音识别请求十分简单，如果使用代理回调的方式，开发者需要实现SFSpeechRecognitionTaskDelegate协议中的相关方法，如下：

////当开始检测音频源中的语音时首先调用此方法
//- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task;
////当识别出一条可用的信息后 会调用
///*
// 需要注意，apple的语音识别服务会根据提供的音频源识别出多个可能的结果 每有一条结果可用 都会调用此方法
// */
//- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription;
////当识别完成所有可用的结果后调用
//- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult;
////当不再接受音频输入时调用 即开始处理语音识别任务时调用
//- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task;
////当语音识别任务被取消时调用
//- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task;
////语音识别任务完成时被调用
//- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully;


// SFSpeechRecognitionTask类中封装了属性和方法如下：

////此任务的当前状态
///*
// typedef NS_ENUM(NSInteger, SFSpeechRecognitionTaskState) {
// SFSpeechRecognitionTaskStateStarting = 0,       // 任务开始
// SFSpeechRecognitionTaskStateRunning = 1,        // 任务正在运行
// SFSpeechRecognitionTaskStateFinishing = 2,      // 不在进行音频读入 即将返回识别结果
// SFSpeechRecognitionTaskStateCanceling = 3,      // 任务取消
// SFSpeechRecognitionTaskStateCompleted = 4,      // 所有结果返回完成
// };
// */
//@property (nonatomic, readonly) SFSpeechRecognitionTaskState state;
////音频输入是否完成
//@property (nonatomic, readonly, getter=isFinishing) BOOL finishing;
////手动完成音频输入 不再接收音频
//- (void)finish;
////任务是否被取消
//@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
////手动取消任务
//- (void)cancel;


// 关于音频识别请求类，除了可以使用SFSpeechURLRecognitionRequest类来进行创建外，还可以使用SFSpeechAudioBufferRecognitionRequest类来进行创建：

//@interface SFSpeechAudioBufferRecognitionRequest : SFSpeechRecognitionRequest
//
//@property (nonatomic, readonly) AVAudioFormat *nativeAudioFormat;
////拼接音频流
//- (void)appendAudioPCMBuffer:(AVAudioPCMBuffer *)audioPCMBuffer;
//- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;
////完成输入
//- (void)endAudio;
//
//@end


//SFSpeechRecognitionResult类是语音识别结果的封装，其中包含了许多套平行的识别信息，其每一份识别信息都有可信度属性来描述其准确程度。SFSpeechRecognitionResult类中属性如下：

////识别到的多套语音转换信息数组 其会按照准确度进行排序
//@property (nonatomic, readonly, copy) NSArray<SFTranscription *> *transcriptions;
////准确性最高的识别实例
//@property (nonatomic, readonly, copy) SFTranscription *bestTranscription;
////是否已经完成 如果YES 则所有所有识别信息都已经获取完成
//@property (nonatomic, readonly, getter=isFinal) BOOL final;


//SFSpeechRecognitionResult类只是语音识别结果的一个封装，真正的识别信息定义在SFTranscription类中，SFTranscription类中属性如下：

////完整的语音识别准换后的文本信息字符串
//@property (nonatomic, readonly, copy) NSString *formattedString;
////语音识别节点数组
//@property (nonatomic, readonly, copy) NSArray<SFTranscriptionSegment *> *segments;


//当对一句完整的话进行识别时，Apple的语音识别服务实际上会把这句语音拆分成若干个音频节点，每个节点可能为一个单词，SFTranscription类中的segments属性就存放这些节点。SFTranscriptionSegment类中定义的属性如下：

////当前节点识别后的文本信息
//@property (nonatomic, readonly, copy) NSString *substring;
////当前节点识别后的文本信息在整体识别语句中的位置
//@property (nonatomic, readonly) NSRange substringRange;
////当前节点的音频时间戳
//@property (nonatomic, readonly) NSTimeInterval timestamp;
////当前节点音频的持续时间
//@property (nonatomic, readonly) NSTimeInterval duration;
////可信度/准确度 0-1之间
//@property (nonatomic, readonly) float confidence;
////关于此节点的其他可能的识别结果
//@property (nonatomic, readonly) NSArray<NSString *> *alternativeSubstrings;

/*
 "nl-NL",
 "es-MX",
 "zh-TW",
 "fr-FR",
 "it-IT",
 "vi-VN",
 "fr-CH",
 "en-ZA",
 "ca-ES",
 "ko-KR",
 "es-CL",
 "ro-RO",
 "en-PH",
 "es-419",
 "en-CA",
 "en-SG",
 "en-IN",
 "en-NZ",
 "it-CH",
 "fr-CA",
 "hi-IN",
 "da-DK",
 "de-AT",
 "pt-BR",
 "yue-CN",
 "zh-CN",
 "sv-SE",
 "hi-IN-translit",
 "es-ES",
 "hu-HU",
 "ar-SA",
 "fr-BE",
 "en-GB",
 "ja-JP",
 "zh-HK",
 "fi-FI",
 "tr-TR",
 "nb-NO",
 "en-ID",
 "en-SA",
 "pl-PL",
 "id-ID",
 "ms-MY",
 "el-GR",
 "cs-CZ",
 "hr-HR",
 "en-AE",
 "he-IL",
 "ru-RU",
 "wuu-CN",
 "de-CH",
 "en-AU",
 "de-DE",
 "nl-BE",
 "th-TH",
 "pt-PT",
 "sk-SK",
 "en-US",
 "en-IE",
 "es-CO",
 "hi-Latn",
 "uk-UA",
 "es-US"
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation
 

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
