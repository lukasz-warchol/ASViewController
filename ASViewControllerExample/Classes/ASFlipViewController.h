//
//  ASFlipViewController.h
//  ASViewControllerExample
//
//  Created by Lukasz Warchol on 5/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ASViewController.h"

@interface ASFlipViewController : ASViewController
@property (nonatomic, assign) UIViewController* currentViewController;
@property (nonatomic, assign) NSUInteger currentIndex;

@property (nonatomic, copy) NSArray* viewControllers;

- (void) switchToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void) switchToViewController:(UIViewController*)controller animated:(BOOL)animated;

@end
