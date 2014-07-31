//
//  LNGDrawViewController.m
//  TouchTracker
//
//  Created by Lumi on 14-7-10.
//  Copyright (c) 2014年 LumiNg. All rights reserved.
//

#import "LNGDrawViewController.h"
#import "LNGDrawView.h";

@interface LNGDrawViewController ()

@end

@implementation LNGDrawViewController

- (void)loadView
{
    self.view = [[LNGDrawView alloc] initWithFrame:CGRectZero];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
