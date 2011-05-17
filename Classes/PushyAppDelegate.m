//
//  PushyAppDelegate.m
//  Pushy
//
//  Created by Charlie Melbye on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "PushyAppDelegate.h"
#import "PushyViewController.h"
#import "JSON.h"

// Insert your application's API keys
#define kApplicationKey @""
#define kApplicationSecret @""

@interface UIAlertView (extended)

- (void)addTextFieldWithValue:(NSString *)value label:(NSString *)label;
- (UITextField *)textFieldAtIndex:(NSInteger *)index;

@end

@implementation PushyAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize token;
@synthesize deviceAlias;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// Register for remote notifications
	NSLog(@"Registering for remote notifications");
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
    // Override point for customization after app launch    
    [window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"Remote notifications registered successfully");
	self.token = [NSString stringWithFormat:@"%@", deviceToken];
	
	// Normalize
	self.token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
	self.token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
	self.token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	[token retain];
	
	NSLog(@"Device token: %@", token);
	
    [self findAliasWithToken:token];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Error in registration. Error: %@", error);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ([alertView isEqual:aliasAlert]) {
		[self newAlias:[aliasTextField text] forToken:token];
	}
	
	// send device token in email, save for later
	//MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
	//[mail setMessageBody:token isHTML:NO];
	//[mail setMailComposeDelegate:self];
	//[viewController presentModalViewController:mail animated:YES];
}

- (void)newAlias:(NSString *)alias forToken:(NSString *)newToken {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
	NSURL *url = [NSURL URLWithString: @"http://frontend.pushy.dotcloud.com/api/v1/devices.json"];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	
	[request setPostValue:newToken forKey:@"token"];
    
    if (alias != nil && alias != @"") {
        [request setPostValue:alias forKey:@"alias"];
    }
    
	request.username = kApplicationKey;
	request.password = kApplicationSecret;
	
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(aliasDidRegister:)];
	[request setDidFailSelector: @selector(aliasRegistrationFailure:)];
	
    [request startAsynchronous];
    
	self.deviceAlias = alias;
}

- (void)updateAlias:(NSString *)alias withToken:(NSString *)newToken {
	
}

- (void)findAliasWithToken:(NSString *)deviceToken {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"http://frontend.pushy.dotcloud.com/api/v1/devices/by_token.json?token=%@", deviceToken]];
    
    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    request.requestMethod = @"GET";
    
    request.username = kApplicationKey;
    request.password = kApplicationSecret;
    
    [request setDelegate:self];
    [request setDidFinishSelector: @selector(aliasWasFound:)];
    [request setDidFailSelector: @selector(aliasFindFailure:)];
    
    [request startAsynchronous];
}

- (void)aliasDidRegister:(ASIHTTPRequest *) request {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    int statusCode = [request responseStatusCode];
    
    if (statusCode == 201) { // 201 Created
        UIAlertView *aliasRegistered = [[UIAlertView alloc] initWithTitle:@"Welcome to Pushy!"
                                                                  message:@"Your device has been registered"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Okay"
                                                        otherButtonTitles:nil];
        [aliasRegistered show];
        [aliasRegistered release];
        
        NSLog(@"YAY!");
    } else {
        UIAlertView *aliasRegisterProblem = [[UIAlertView alloc] initWithTitle:@"Pushy Error"
                                                                       message:@"Your device could not be registered. The alias might already be taken."
                                                                      delegate:self
                                                             cancelButtonTitle:@"Okay"
                                                             otherButtonTitles:nil];
        [aliasRegisterProblem show];
        [aliasRegisterProblem release];
        
        self.deviceAlias = nil;
    }
    
}

- (void)aliasRegistrationFailure:(ASIHTTPRequest *)request {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	UIAlertView *someError = [[UIAlertView alloc] initWithTitle: 
							  @"Pushy error" message: @"Error registering with server"
													   delegate: self
											  cancelButtonTitle: @"Okay"
											  otherButtonTitles: nil];
	[someError show];
	[someError release];
	NSLog(@"ERROR: NSError query result: %@", error);
}

- (void)aliasWasFound:(ASIHTTPRequest *)request {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    int statusCode = [request responseStatusCode];
    
    if (statusCode == 200) { // success
        NSDictionary *device = [[request responseString] JSONValue];
        
        self.deviceAlias = [device valueForKey:@"alias"];
        
        NSLog(@"Showing alert to welcome user");
        
        UIAlertView *welcomeAlert = [[UIAlertView alloc] init];
        [welcomeAlert setTitle:@"Welcome back!"];
        [welcomeAlert setMessage:[NSString stringWithFormat:@"Thanks for using Pushy, %@!", self.deviceAlias]];
        [welcomeAlert addButtonWithTitle:@"Okay"];
        
        [welcomeAlert show];
        [welcomeAlert release];
    } else if (statusCode == 404) { // not found
        NSLog(@"Showing alert with to set device alias");
		
        aliasAlert = [[UIAlertView alloc] initWithTitle:@"Welcome to Pushy!"
                                                message:@"Choose an alias that will represent your device on Pushy"
                                               delegate:self
                                      cancelButtonTitle:@"Save"
                                      otherButtonTitles:nil];
        
		[aliasAlert addTextFieldWithValue:@"" label:@"Alias"];
		
		aliasTextField = [aliasAlert textFieldAtIndex:0];
		aliasTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		
		[aliasAlert show];
    }
}

- (void)aliasFindFailure:(ASIHTTPRequest *)request {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
	NSError *error = [request error];
	UIAlertView *someError = [[UIAlertView alloc] initWithTitle: 
							  @"Pushy error" message: @"Error finding device"
													   delegate: self
											  cancelButtonTitle: @"Okay"
											  otherButtonTitles: nil];
	[someError show];
	[someError release];
	NSLog(@"ERROR: NSError query result: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSLog(@"%@", userInfo);
	int i, count;
	count = [userInfo count];
	for (i = 0; i < count; i++)
	{
		// create a temp array from user defaults
		NSArray *tempArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"_PDNotifications"];
		// create a mutable array and insert the above array
		NSMutableArray *data = [[NSMutableArray alloc] initWithArray:tempArray];
		
		NSDictionary *aps = [userInfo valueForKey:@"aps"];
		NSString *message = [aps valueForKey:@"alert"];
		
		// insert message into array
		[data insertObject:message atIndex:0];
		// save array to user defaults
		[[NSUserDefaults standardUserDefaults] setObject:data forKey:@"_PDNotifications"];
		
		// Reload table view
		[[NSNotificationCenter defaultCenter] postNotificationName:@"newNotif" object:self];
	}
}

- (void)dealloc {
    [navigationController release];
    [window release];
    [super dealloc];
}


@end
