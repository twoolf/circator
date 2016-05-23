//
//  AppLogShakeView.m
//  Pods
//
//  Created by Some Name on 3/22/16.
//
//

#import "AppLogShakeView.h"

@implementation AppLogShakeView

-(BOOL)canBecomeFirstResponder{
    return YES;
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    [self.delegate shakeDetected];
}

@end
