//
//  PushyAppDelegate.m
//  Pushy
//
//  Created by Charlie Melbye on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "PushyAppDelegate.h"
#import "PushyViewController.h"

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
	token = [NSString stringWithFormat:@"%@", deviceToken];
	
	// Normalize
	token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
	token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
	
	[token retain];
	
	NSLog(@"deviceToken: %@", token);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSString *lastToken = [userDefaults stringForKey: @"_PDLastToken"];
	self.deviceAlias = [userDefaults stringForKey: @"_PDDeviceAlias"];
	
	if (self.deviceAlias != nil) {
		if ( ![token isEqualToString:lastToken] ) {
			// Display network activity indicator
			[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
			
			// We need to update the device token on the server, lets do it right now
			[self updateAlias:self.deviceAlias withToken:token];
		}
	} else { // we don't have an alias yet is nil, set it
		NSLog(@"Showing alert with to set device alias");
		
		aliasAlert = [[UIAlertView alloc] init];
		[aliasAlert setDelegate:self];
		[aliasAlert setTitle:@"Welcome to Pushy!"];
		[aliasAlert setMessage:@"Choose an alias that will represent your device on Pushy"];
		[aliasAlert addButtonWithTitle:@"Save"];
		[aliasAlert addTextFieldWithValue:@"" label:@"Alias"];
		
		aliasTextField = [aliasAlert textFieldAtIndex:0];
		aliasTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		
		[aliasAlert show];
	}
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

//- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
//	[viewController dismissModalViewControllerAnimated:YES];
//}

- (void)newAlias:(NSString *)alias forToken:(NSString *)newToken {
	// Put it in a format that Pushy (currently) expects
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	// Setup a queue for API calls and stuff
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	
	NSURL *url = [NSURL URLWithString: @"http://pushyapp.com/api/v1/devices"];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"POST";
	
	[request setPostValue:newToken forKey:@"token"];
	[request setPostValue:alias forKey:@"alias"];
	
	request.username = kApplicationKey;
	request.password = kApplicationSecret;
	
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successMethod:)];
	[request setDidFailSelector: @selector(requestWentWrong:)];
	[queue addOperation:request];
	
	self.deviceAlias = alias;
}

- (void)updateAlias:(NSString *)alias withToken:(NSString *)newToken {
	
}

- (void)successMethod:(ASIHTTPRequest *) request {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setValue: self.token forKey: @"_PDLastToken"];
	[userDefaults setValue: self.deviceAlias forKey: @"_PDDeviceAlias"];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSLog(@"YAY!");
}

- (void)requestWentWrong:(ASIHTTPRequest *)request {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	UIAlertView *someError = [[UIAlertView alloc] initWithTitle: 
							  @"Network error" message: @"Error registering with server"
													   delegate: self
											  cancelButtonTitle: @"Ok"
											  otherButtonTitles: nil];
	[someError show];
	[someError release];
	NSLog(@"ERROR: NSError query result: %@", error);
}

- (void)dealloc {
    [navigationController release];
    [window release];
    [super dealloc];
}


@end
