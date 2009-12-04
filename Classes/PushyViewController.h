//
//  PushyViewController.h
//  Pushy
//
//  Created by Charlie Melbye on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PushyViewController : UITableViewController <MFMailComposeViewControllerDelegate> {
	NSString *deviceToken;
	NSMutableArray *data;
}

- (void)showDeviceToken;

@end

