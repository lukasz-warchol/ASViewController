//
//  AppDelegate.m
//  ASViewControllerExample
//
//  Created by Lukasz Warchol on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "ASFlipViewController.h"
#import "ASEColoredViewController.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    
    ASEColoredViewController* redVC = [[[ASEColoredViewController alloc] init] autorelease];
    redVC.viewColor = [UIColor redColor];
    ASEColoredViewController* greenVC = [[[ASEColoredViewController alloc] init] autorelease];
    greenVC.viewColor = [UIColor greenColor];
    ASEColoredViewController* blueVC = [[[ASEColoredViewController alloc] init] autorelease];
    blueVC.viewColor = [UIColor blueColor];
    
    //Flip view controller contains 3 different subviewcontrollers taht yser can switch between.
    ASFlipViewController* flipViewController = [[ASFlipViewController alloc] init];
    flipViewController.viewControllers = [NSArray arrayWithObjects:redVC, greenVC, blueVC, nil];

    UINavigationController* rootViewController = [[UINavigationController alloc]initWithRootViewController:flipViewController];
    self.window.rootViewController = rootViewController;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
