//
//  ASEColoredViewController.m
//  ASViewControllerExample
//
//  Created by Lukasz Warchol on 5/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ASEColoredViewController.h"

@interface ASEColoredViewController ()

@end

@implementation ASEColoredViewController
@synthesize viewColor = _viewColor;

- (void)dealloc
{
    [_viewColor release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = self.viewColor;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
