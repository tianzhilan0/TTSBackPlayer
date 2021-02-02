# TTSBackPlayer

原文地址：[https://blog.csdn.net/tianzhilan0/article/details/113555863](https://blog.csdn.net/tianzhilan0/article/details/113555863)

### 需求分析
1、APP进入后台，防止被杀死；
2、APP在后台时也可以播报TTS；
3、TTS内容是后台通过socket推过来的数据；

### 实现计划
1、实现类似QQ一样的，APP进入后台，可以在锁屏页面继续播放音乐，而这个时候APP是不会被杀死的；
2、使用socket播放一个静音文件，循环播放；
3、当接收到socket消息时，暂停音乐播放，TTS播报socket消息；
4、TTS播报完毕，继续播放静音文件；
5、禁止掉锁屏页面按钮功能（上一首、下一首、开始、暂停）；

### 具体实现
- #### 1.项目设置
![在这里插入图片描述](https://img-blog.csdnimg.cn/20210202143828842.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RpYW56aGlsYW4w,size_16,color_FFFFFF,t_70)
- #### 2.具体实现

```objectivec
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()<AVSpeechSynthesizerDelegate>

@property (nonatomic, strong)AVPlayer *player;
@property (nonatomic, strong)AVSpeechSynthesizer *synthesizer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 开始播放音乐
    [self starPlayMusic];
    // 今天播放进度
    [self playerPressHandle];
    // 关闭锁屏页面按钮交互
    [self createRemoteCommandCenter];
    
    // 模拟socket 接收消息
    [self socketReceiveMessage];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [[commandCenter playCommand] removeTarget:self];
    [[commandCenter pauseCommand] removeTarget:self];
    [[commandCenter nextTrackCommand] removeTarget:self];
    [[commandCenter previousTrackCommand] removeTarget:self];
    [commandCenter.changePlaybackPositionCommand removeTarget:self];
    
}

#pragma mark - 模拟socket接收消息
- (void)socketReceiveMessage
{
    int number = random() % 180+60;
    NSLog(@"%d 秒后 tts播报", number);
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (ino64_t)(number * NSEC_PER_SEC));
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(time, dispatch_get_main_queue(), ^{
        [weakSelf pauseMusic];
        [weakSelf speekWithString: [NSString stringWithFormat:@"新客户来了 %ld", random() % 100]];
        
        NSLog(@"%f", [[NSDate date] timeIntervalSinceNow]);
        [weakSelf socketReceiveMessage];
    });
}
    

#pragma mark - 直接播放音乐
- (void)starPlayMusic
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://atyk.jzhunk.xyz/v130/upload/1.mp3"]];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self playMusic];
}


#pragma mark - 播放进度
- (void)playerPressHandle
{
    __weak __typeof__(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        //进度 当前时间/总时间
        CGFloat progress = CMTimeGetSeconds(weakSelf.player.currentItem.currentTime) / CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        NSLog(@"进度 == %f", progress);
        if (progress == 1.0f || progress >= 0.99f) {
            NSLog(@"播放完毕");
            //播放百分比为1表示已经播放完毕
            //循环播放，防止APP被杀死
            [weakSelf starPlayMusic];
        }
    }];
}



#pragma mark - 初始化音乐播放器
- (AVPlayer *)player
{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

#pragma mark - 初始化tts播放器
-(AVSpeechSynthesizer *)synthesizer
{
    if (!_synthesizer) {
        _synthesizer = [[AVSpeechSynthesizer alloc]init];
        _synthesizer.delegate = self;
    }
    return _synthesizer;
}

#pragma mark - tts播报
- (void)speekWithString:(NSString *)value
{
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:value];
    utterance.pitchMultiplier=0.8;
    //中式发音
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    utterance.voice = voice;
    [self.synthesizer speakUtterance:utterance];
}

#pragma mark - 处理锁屏页交互
- (void)createRemoteCommandCenter
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    // 暂停
    MPRemoteCommand *pauseCommand = [commandCenter pauseCommand];
    [pauseCommand setEnabled:NO];
    [pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 开始
    MPRemoteCommand *playCommand = [commandCenter playCommand];
    [playCommand setEnabled:NO];
    [playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"开始");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 下一首
    MPRemoteCommand *nextCommand = [commandCenter nextTrackCommand];
    [nextCommand setEnabled:NO];
    [nextCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"下一首");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 上一首
    MPRemoteCommand *previousCommand = [commandCenter previousTrackCommand];
    [previousCommand setEnabled:NO];
    [previousCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"上一首");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 进度条
    MPRemoteCommand *changePlaybackPositionCommand = [commandCenter changePlaybackPositionCommand];
    [changePlaybackPositionCommand setEnabled:NO];
    [changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"进度条");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

#pragma mark - 更新锁屏界面信息
- (void)updateLockScreenInfo {
    
    // 1.获取锁屏中心
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    // 初始化一个存放音乐信息的字典
    NSMutableDictionary *playingInfoDict = [NSMutableDictionary dictionary];
    
    // 2、设置歌曲名
    [playingInfoDict setObject:[NSString stringWithFormat:@"歌曲1111"]
                        forKey:MPMediaItemPropertyTitle];
    [playingInfoDict setObject:[NSString stringWithFormat:@"专辑2222"]
                        forKey:MPMediaItemPropertyAlbumTitle];
    
    // 3、设置封面的图片
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"image.jpg"]];
    if (image) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
        [playingInfoDict setObject:artwork forKey:MPMediaItemPropertyArtwork];
    }
    
    // 4、设置播放速度
    [playingInfoDict setObject:@(_player.rate) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    //音乐信息赋值给获取锁屏中心的nowPlayingInfo属性
    playingInfoCenter.nowPlayingInfo = playingInfoDict;
}

#pragma mark - 开始播放音乐
- (void)playMusic
{
    if (!self.player) {
        return;
    }
    [self.player play];
    [self updateLockScreenInfo];
}

#pragma mark - 暂停播放音乐
- (void)pauseMusic
{
    if (!self.player) {
        return;
    }
    
    [self.player pause];
    
    [self updateLockScreenInfo];
    
}

#pragma mark - AVSpeechSynthesizerDelegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"开始tts播报");
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"结束tts播报");
    [self starPlayMusic];
}


@end

```


### 遇到的问题
#### 1、APP进入后台，音乐播放被暂停，长时间APP会被杀死
处理：通过监听APP进入前/后台，让音乐可以继续播放

```objectivec
#pragma mark - 监听APP进入前/后台(处理APP进入后台，音乐播放暂停问题)
- (void)registerAllNotifications
{
    // 后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apllicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
 
    // 进入前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apllicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark - 移除监听
- (void)removeAllNotifications {
 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
}

#pragma mark - 进入后台通知
- (void)apllicationWillResignActiveNotification:(NSNotification *)n
{
    NSError *error = nil;
    // 后台播放代码
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&error];
    if(error) {
        NSLog(@"ListenPlayView background error0: %@", error.description);
    }
    //后台播放
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if(error) {
        NSLog(@"ListenPlayView background error1: %@", error.description);
    }
    //开启后台处理多媒体事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

#pragma mark - 进入前台通知
- (void)apllicationWillEnterForegroundNotification:(NSNotification *)n {
    // 进前台 设置不接受锁屏页面控制
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

```

### 最终结果

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210202151646244.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RpYW56aGlsYW4w,size_16,color_FFFFFF,t_70)

