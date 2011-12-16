//
//  Drag_DemoAppDelegate.m
//  Drag Demo
//
//  Created by Prateek Pradhan on 15/12/11.
//  Copyright 2011 Newput Infotech Pvt. Ltd. All rights reserved.
//

#import "Drag_DemoAppDelegate.h"
#import "UIDropTableViewController.h"

@implementation Drag_DemoAppDelegate

@synthesize window;



#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	NSArray* srcData = [NSArray arrayWithObjects:@"item0", @"item1", @"item2", @"item3", @"item4", nil];
	NSArray* dstData = [NSArray arrayWithObjects:@"item5", @"item6", nil];
	UIDropTableViewController *dropTable;
	dropTable = [[UIDropTableViewController alloc] initWithFrame:CGRectMake(100, 100, 600, 500) SourceData:srcData DestinationData:dstData];
	[dropTable setSrcTableTitle:@"Bla"];
	[dropTable setDstTableTitle:@"Blub"];
	[[dropTable.view layer] setBorderColor:[[UIColor darkGrayColor] CGColor]];
	[[dropTable.view layer] setBorderWidth:1];
	[[dropTable.view layer] setCornerRadius:2];
	[self.window addSubview:dropTable.view];
    [self.window makeKeyAndVisible];
	
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
