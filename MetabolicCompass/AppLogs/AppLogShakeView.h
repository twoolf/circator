//
//  AppLogShakeView.h
//  Pods
//
//  Created by Some Name on 3/22/16.
//
//

#import <UIKit/UIKit.h>


@protocol AppLogShakeDelegate <NSObject>

@required
-(void)shakeDetected;

@end

@interface AppLogShakeView : UIView

@property id <AppLogShakeDelegate> delegate;

@end
