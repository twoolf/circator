//
//  AppLogViewController.h
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppLogViewController : UIViewController

//This method adds gesture recognizers to given window
+ (void) addAppLogRecognizersToView: (UIView *)view;

//This method adds gesture recognizers to current window
+ (void) addAppLogRecognizersToGlobalWindow;

+ (void)showAppLog;

@end
