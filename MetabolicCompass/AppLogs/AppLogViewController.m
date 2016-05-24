//
//  AppLogViewController.m
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogViewController.h"
#import "AppLogTableViewCell.h"
#import "AppLogItem.h"
#import "AppLogManager.h"
#import "AppLogItem+Appearance.h"
#import "AppLogDetailViewController.h"

@interface AppLogViewController()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) NSArray * items;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSDateFormatter * formatter;

@end


@implementation AppLogViewController

+ (void) addAppLogRecognizersToView: (UIView *)view{
    
    if (view == nil) {
        [NSException raise:@"AppLogViewController : given view is nil. no gestures will be recognized" format:@"view = %@", nil];
    }
    
    UIPanGestureRecognizer *infoPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(infoPanGestureRecognized:)];
    infoPanGestureRecognizer.minimumNumberOfTouches = 2;
    [view addGestureRecognizer:infoPanGestureRecognizer];
    
    UITapGestureRecognizer *infoTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoTapGestureRecognized:)];
    infoTapGestureRecognizer.numberOfTapsRequired = 3;
    [view addGestureRecognizer:infoTapGestureRecognizer];
}

+ (void) addAppLogRecognizersToGlobalWindow{

    UIWindow * window = [[[UIApplication sharedApplication] windows] firstObject];
    
    [self addAppLogRecognizersToView:window];
}

+ (void)infoPanGestureRecognized:(id)recognizer{
    [self showAppLog];
}

+ (void)infoTapGestureRecognized:(id)recognizer{
    [self showAppLog];
}

+ (void)showAppLog{
    UIWindow * window = [[[UIApplication sharedApplication] windows] firstObject];
    UINavigationController * curPresentedNC = (UINavigationController *) window.rootViewController.presentedViewController;
    if ([curPresentedNC.viewControllers.firstObject isKindOfClass:[AppLogViewController class]]){
        NSLog(@"AppLogViewController already shown");
    }
    else{
        AppLogViewController * appLogVC = [[UIStoryboard storyboardWithName:@"AppLog" bundle:nil] instantiateInitialViewController];
        [window.rootViewController presentViewController:appLogVC animated:YES completion:^{
        }];
    }
}
+(NSBundle *)bundle{
    NSURL *bundleURL = [[NSBundle bundleForClass:self.classForCoder] URLForResource:@"AppLogBundle" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
    return bundle;
}

#pragma mark Shake Handler

-(void)shakeDetected{
    
}

- (void)viewDidLoad{
    [super viewDidLoad];

    [self.tableView registerClass:[AppLogTableViewCell class] forCellReuseIdentifier:@"AppLogTableViewCell"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 72.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.formatter = [self dateFormatterWithFormat:@"dd.MM hh:mm:ss.SS"];
}

- (NSDateFormatter *)dateFormatterWithFormat:(NSString *)format{
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:format];
    return formatter;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAppLogsItemChangedNotification:) name:ncAppLogItemsChanged object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) updateData{
    self.items = [AppLogManager sharedInstance].appLogItems;
    [self.tableView reloadData];
}

- (void) didReceiveAppLogsItemChangedNotification:(NSNotification *)notif{
    [self updateData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.items count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppLogTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppLogTableViewCell"];
    AppLogItem * item = [self.items objectAtIndex:indexPath.row];
    cell.infoLabel.text = [NSString stringWithFormat:@"%@: %@", @(indexPath.row), [self.formatter stringFromDate:item.date]];
    cell.titleLabel.text = item.title;
    cell.backViewColor = [item backgroundColor];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AppLogDetailViewController * logDetailVC = [[UIStoryboard storyboardWithName:@"AppLog" bundle:nil] instantiateViewControllerWithIdentifier:@"AppLogDetailViewController"];
    logDetailVC.appLogItem = [self.items objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:logDetailVC animated:YES];
}

- (IBAction)didClickBackButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)didClickCopyButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
