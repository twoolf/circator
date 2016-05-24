//
//  AppLogDetailViewController.m
//  Rituals
//
//  Created by Vladimir on 3/1/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogDetailViewController.h"
#import "AppLogFieldView.h"
#import "Masonry.h"
#import "AppLogItem+Appearance.h"

@interface AppLogDetailViewController ()

@property (strong, nonatomic) NSArray *fieldViews;
@property (weak, nonatomic) IBOutlet UIView *scrollContentView;

@end

@implementation AppLogDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateItemViews];

}

- (void) updateItemViews{
    [self.fieldViews enumerateObjectsUsingBlock:^(UIView *  _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        [view removeFromSuperview];
    }];
    NSArray * fields = self.appLogItem.fields;
    UIView * prevView = nil;
    NSMutableArray * mViews = [NSMutableArray new];
    for (NSString * fieldName in fields) {
        AppLogFieldView * fieldView = [[AppLogFieldView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)];
        [mViews addObject:fieldView];
        [self.scrollContentView addSubview:fieldView];
        if (fieldName != kAppLogNotShownTitleKey){
            fieldView.titleLabel.text = fieldName;
        }
        if (fieldName.length > 0){
            NSString * text = self.appLogItem.values[fieldName];
            NSInteger maxTextLengthToShow = 4000;
            if ([text length] > maxTextLengthToShow){
                text = [NSString stringWithFormat:@"!!! TEXT IS TOO LONG, TRUNCATED !!!\n%@", [text substringToIndex:maxTextLengthToShow]];
            }
            fieldView.textLabel.text = text;
        }
        fieldView.alpha = (fieldView.textLabel.text.length > 0) ? 1.0 : 0.3;

        [fieldView mas_makeConstraints:^(MASConstraintMaker *make) {
            UIView * sv = self.scrollContentView;
            make.left.equalTo(sv.mas_left).with.offset(8.0);
            make.right.equalTo(sv.mas_right).with.offset(-8.0);
            if (prevView != nil){
                make.top.equalTo(prevView.mas_bottom).with.offset(8.0);
            }
            else{
                make.top.equalTo(sv.mas_top).with.offset(8.0);
            }
        }];
        fieldView.backViewColor = self.appLogItem.backgroundColor;
        prevView = fieldView;
    }
    [prevView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.scrollContentView.mas_bottom).with.offset(-8.0);
    }];
}

- (IBAction)didClickCopyButton:(id)sender {
    [UIPasteboard generalPasteboard].string = self.appLogItem.description;
}

- (IBAction)didClickBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
