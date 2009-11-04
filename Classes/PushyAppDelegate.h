//
//  PushyAppDelegate.h
//  Pushy
//
//  Created by Charlie Melbye on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ASIFormDataRequest.h"

@class PushyViewController;

@interface PushyAppDelegate : NSObject <UIApplicationDelegate> {
	NSString *token;
	NSString *deviceAlias;
	
    UIWindow *window;
    UINavigationController *navigationController;
	
	UIAlertView *aliasAlert;
	UITextField *aliasTextField;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (copy) NSString *token;
@property (copy) NSString *deviceAlias;

- (void)updateAlias:(NSString *)alias withToken:(NSString *)newToken;
- (void)newAlias:(NSString *)alias forToken:(NSString *)newToken;

@end

