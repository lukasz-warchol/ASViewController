//
//  ASFlipViewController.m
//  ASViewControllerExample
//
//  Created by Lukasz Warchol on 5/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ASFlipViewController.h"

@interface ASFlipViewController ()

@end

@implementation ASFlipViewController
@synthesize currentViewController = _currentViewController;
@synthesize currentIndex = _currentIndex;

@dynamic viewControllers;

#pragma mark - Getters
//---------------------------------------------------------------------------------------------
- (void) setViewControllers:(NSArray *)viewControllers
{
    for (UIViewController* vc in self.childViewControllers) {
        [vc willMoveToParentViewController:nil];
        [vc removeFromParentViewController];
    }
    for (UIViewController* vc in viewControllers) {
        [self addChildViewController:vc];
        [vc didMoveToParentViewController:self];
    }
    _currentViewController = nil;
    _currentIndex = 0;
    if (self.childViewControllers.count > 0) {
        if ([self isViewLoaded]) {
            [self switchToViewControllerAtIndex:_currentIndex animated:NO];
        }
    }else{
        [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
}

- (NSArray*) viewControllers
{
    return self.childViewControllers;
}

- (void) setCurrentIndex:(NSUInteger)currentIndex
{
    [self switchToViewControllerAtIndex:currentIndex animated:NO];
}

- (void) setCurrentViewController:(UIViewController *)currentViewController
{
    [self switchToViewController:currentViewController animated:NO];
}
//---------------------------------------------------------------------------------------------

#pragma mark - View lifecycle
//---------------------------------------------------------------------------------------------
- (void) viewDidLoad
{
    [super viewDidLoad];
    if (self.childViewControllers.count > 0) {
        [self switchToViewControllerAtIndex:_currentIndex animated:NO];
    }
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"flip" style:UIBarButtonItemStyleBordered target:self action:@selector(flipViews)];
    self.navigationItem.rightBarButtonItem = item;
    [item release];
}

- (void) flipViews
{
    NSInteger newIndex = self.currentIndex + 1;
    newIndex = newIndex%self.viewControllers.count;
    [self switchToViewControllerAtIndex:newIndex animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([self.currentViewController respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.currentViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    return YES;
}
//---------------------------------------------------------------------------------------------

#pragma mark - Child view controllers managment
//---------------------------------------------------------------------------------------------
- (void) switchToViewController:(UIViewController*)controller animated:(BOOL)animated
{
    NSInteger index = [self.viewControllers indexOfObject:controller];
    if (index != NSNotFound) {
        UIViewController* fromViewController = self.currentViewController;
        UIViewController* toViewController = controller;
        UIView* toView = toViewController.view;
        toView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        toView.frame = self.view.bounds;
        
        if ([fromViewController isViewLoaded] && fromViewController.view.superview) {
            UIViewAnimationOptions animationOptions = UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionTransitionFlipFromLeft;
            if (animated) {
                animationOptions |= UIViewAnimationOptionTransitionFlipFromLeft;
            }
            [[UIApplication sharedApplication] keyWindow].userInteractionEnabled = NO;
            [self transitionFromViewController:fromViewController toViewController:toViewController 
                                      duration:0.3 options:animationOptions animations:nil completion:^(BOOL finished) {
                                          if (finished) {
                                              _currentViewController = controller;
                                              _currentIndex = index;
                                          }
                                          [[UIApplication sharedApplication] keyWindow].userInteractionEnabled = YES;
                                      }];
        }
        else{
            [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self.view addSubview:toView];
            _currentViewController = controller;
            _currentIndex = index;
        }
	}
}

- (void) switchToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self switchToViewController:[self.viewControllers objectAtIndex:index] animated:animated];
}
//---------------------------------------------------------------------------------------------
@end
