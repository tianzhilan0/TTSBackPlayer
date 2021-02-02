//
//  AppDelegate.m
//  TTSBackPlayer
//
//  Created by 李闯 on 2021/2/2.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

/// 锁屏页面的控制事件(必须在这里重写该方法，在播放页面重写不起作用)
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
  if (event.type == UIEventTypeRemoteControl) {
    // 发送通知给音频播放界面 进行某些处理
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AppDelegateReceiveRemoteEventsNotification" object:event];
  }
}

@end
