//
//  AppDelegate.m
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "AppDelegate.h"
#import <Analytics/SEGAnalytics.h>
#import "TrackingConstants.h"
#import "LoginViewController.h"

#include "ApiKeys.h"

// After two hours, reset session
static const double session_reset_age = (2 * 60 * 60);
//static const double session_reset_age = (20);

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Initially set session to old time, so it gets reset
    self.session_start = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    
    // Code to enable Segment analytics
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_KEY];
    
    // Enable this to record certain application events automatically!
    configuration.trackApplicationLifecycleEvents = YES;
    
    // Enable this to record screen views automatically!
    //configuration.recordScreenViews = YES;
    
    [SEGAnalytics setupWithConfiguration:configuration];
    
    [self checkSessionOnEnter];
    
    return YES;
}

-(void)checkSessionOnEnter {
    NSTimeInterval session_age = -[self.session_start timeIntervalSinceNow];
    if (session_age >= session_reset_age) {
        
        // kick user back to login
        NSLog(@"Kicking out");
        [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    [[SEGAnalytics sharedAnalytics] track:trk_enterFg];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[SEGAnalytics sharedAnalytics] track:trk_enterBg];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
    [self checkSessionOnEnter];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
