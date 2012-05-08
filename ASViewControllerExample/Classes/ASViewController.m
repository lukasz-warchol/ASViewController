//
//  Created by Lukasz Warchol on 11/21/11.
//

#import "ASViewController.h"
#import <objc/runtime.h>

#define IF_PRE_IOS5(...) \
if ([[[UIDevice currentDevice] systemVersion] intValue] < 5) \
{ \
    __VA_ARGS__ \
}

@interface NSArray(SelectiveMethodPerforming)
- (void) executeBlock:(void (^)(id obj))block
forObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

@end

@implementation NSArray(SelectiveMethodPerforming)

- (void) executeBlock:(void (^)(id obj))block
forObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (predicate(obj, idx, stop)) {
            block(obj);
        }
    }];
}
@end

@interface ASViewControllerSwizzler : NSObject
+ (void) associateChildViewController:(UIViewController *)childController
             withParentViewController:(UIViewController *)parentViewController;
+ (void) swizzleChildViewControllerMethods:(UIViewController *)childController;
+ (void) addRemoveFromParentViewControllerMethodIfNeeded:(UIViewController *)controller;
@end

@interface ASViewController()
@property(retain) NSMutableArray *subviewControllers;
@end


@implementation ASViewController
@synthesize subviewControllers = _subviewControllers;

- (BOOL)useIOS5Implementations {
    IF_PRE_IOS5(
        return NO;
    );
    return YES;
}

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        IF_PRE_IOS5(
            self.subviewControllers = [NSMutableArray array];
        );
    }
    return self;
}


- (void)dealloc
{
    [_subviewControllers release];
    _subviewControllers = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    for (UIViewController *viewController in _subviewControllers) {
        [viewController didReceiveMemoryWarning];
    }
}

#pragma mark - View lifecycle

- (BOOL)shouldForwardCallbackToChildViewController:(UIViewController *)childViewController {
    BOOL shouldForward = NO;
    if ([childViewController isViewLoaded]) {
        UIView * superview = childViewController.view.superview;
        while (superview != nil) {
            if (superview == self.view) {
                shouldForward = YES;
                break;
            }
            superview  = superview.superview;
        }
    }
    return shouldForward;
}

- (void) executeBlockOnApplicableSubviewControllers:(void(^)(UIViewController * viewController))block
{
    [_subviewControllers executeBlock:block
                forObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
                    return [self shouldForwardCallbackToChildViewController:obj];
                }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    //! if parent unloaded then its time to ask children to unload as parent view no longer retains their views
    //! this is the RIGHT way to make sub controllers unload their views if they are not retained in other places
    [_subviewControllers makeObjectsPerformSelector:@selector(didReceiveMemoryWarning)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        [viewController viewWillAppear:animated];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        [viewController viewDidAppear:animated];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        [viewController viewWillDisappear:animated];
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        [viewController viewDidDisappear:animated];
    }];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    __block BOOL rotate = YES;
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        rotate &= [viewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }];
    return rotate;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        [viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        [viewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self executeBlockOnApplicableSubviewControllers:^(UIViewController * viewController){
        [viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }];
}

#pragma mark - Managing Child View Controllers

- (NSArray*) childViewControllers
{
    if ([self useIOS5Implementations]) {
        return [super childViewControllers];
    }else{
        return [[_subviewControllers copy] autorelease];
    }
}

- (void) addChildViewController:(UIViewController *)childController
{
    if ([self useIOS5Implementations]) {
        [super addChildViewController:childController];
    }
    else {
        [childController willChangeValueForKey:@"parentViewController"];
        if ([childController respondsToSelector:@selector(willMoveToParentViewController:)]) {
            [childController willMoveToParentViewController:self];
        }

        [ASViewControllerSwizzler associateChildViewController:childController withParentViewController:self];
        [ASViewControllerSwizzler swizzleChildViewControllerMethods:childController];
        [ASViewControllerSwizzler addRemoveFromParentViewControllerMethodIfNeeded:childController];

        [_subviewControllers addObject:childController];
        [childController didChangeValueForKey:@"parentViewController"];
    }
}

- (void)removeFromParentViewController
{
    if ([self useIOS5Implementations]) {
        [super removeFromParentViewController];
    }
    else{
        [self willChangeValueForKey:@"parentViewController"];
        ASViewController* parentViewController = (ASViewController *) self.parentViewController;
        [parentViewController.subviewControllers removeObject:self];
        [ASViewControllerSwizzler associateChildViewController:self withParentViewController:nil];
        [self didChangeValueForKey:@"parentViewController"];
        if ([self respondsToSelector:@selector(didMoveToParentViewController:)]) {
            [self didMoveToParentViewController:nil];
        }
    }
}

- (void)transitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController duration:(NSTimeInterval)duration 
                             options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    if ([self useIOS5Implementations]) {
        [super transitionFromViewController:fromViewController toViewController:toViewController duration:duration options:options animations:animations completion:completion];
    }
    else{
        if (fromViewController.parentViewController != toViewController.parentViewController) {
            NSString* reason = [NSString stringWithFormat:@"Children view controllers %@ and %@ must have a common parent view controller when calling -[UIViewController transitionFromViewController:toViewController:duration:options:animations:completion:]", fromViewController, toViewController];
            [[NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil] raise];
        }
        BOOL animated = duration>0;
        [fromViewController viewWillDisappear:animated];
        [toViewController viewWillAppear:animated];
        
        void (^ OnTransitionEndedBlock)(BOOL finished) = ^(BOOL finished){
            if (completion) {
                completion(finished);
            }
            [fromViewController viewDidDisappear:animated];
            [toViewController viewDidAppear:animated];
        };
        
        [UIView transitionFromView:fromViewController.view toView:toViewController.view duration:duration options:options completion:^(BOOL finished) {
            if (animations) {
                [UIView animateWithDuration:duration delay:0 options:options animations:animations completion:OnTransitionEndedBlock];
            }else{
                OnTransitionEndedBlock(finished);
            }
        }];
    }
}

#pragma mark - Managing the Layout of Contained View Controllers

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if ([self useIOS5Implementations]) {
        [super willMoveToParentViewController:parent];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if ([self useIOS5Implementations]) {
        [super didMoveToParentViewController:parent];
    }
}

@end

@implementation ASViewControllerSwizzler

static NSString *ASViewControllerParentControllerKey = @"ASViewControllerParentControllerKey";

+ (void) associateChildViewController:(UIViewController *)childController
             withParentViewController:(UIViewController *)parentViewController
{
    objc_setAssociatedObject(childController, ASViewControllerParentControllerKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(childController, ASViewControllerParentControllerKey, parentViewController, OBJC_ASSOCIATION_ASSIGN);
}

+ (void) swizzleChildViewControllerMethods:(UIViewController *)childController
{
    if (objc_getAssociatedObject(childController, ASViewControllerParentControllerKey) == nil){
        NSString * reason = [NSString stringWithFormat:@"No parent view controller assigned to this child view controller. You should use '%@' to achieve this.",
                                      NSStringFromSelector(@selector(associateChildViewController:withParentViewController:))];
        [[NSException exceptionWithName:NSObjectNotAvailableException reason:reason
                              userInfo:nil] raise];
    }

    {   // parentViewController
        Method replacingMethod = class_getInstanceMethod([self class], @selector(swizzlingParentViewController));
        Method replacedMethod = class_getInstanceMethod([childController class], @selector(parentViewController));
        class_addMethod([childController class], @selector(originalParentViewController), method_getImplementation(replacedMethod), method_getTypeEncoding(replacedMethod));
        class_addMethod([childController class], @selector(parentViewController), method_getImplementation(replacingMethod), method_getTypeEncoding(replacingMethod));
    }
    {   // navigationViewController
        Method replacingMethod = class_getInstanceMethod([self class], @selector(swizzlingNavigationController));
        Method replacedMethod = class_getInstanceMethod([childController class], @selector(navigationController));
        class_addMethod([childController class], @selector(originalNavigationController), method_getImplementation(replacedMethod), method_getTypeEncoding(replacedMethod));
        class_addMethod([childController class], @selector(navigationController), method_getImplementation(replacingMethod), method_getTypeEncoding(replacingMethod));
    }
    {   // tabBarViewController
        Method replacingMethod = class_getInstanceMethod([self class], @selector(swizzlingTabBarController));
        Method replacedMethod = class_getInstanceMethod([childController class], @selector(tabBarController));
        class_addMethod([childController class], @selector(originalTabBarController), method_getImplementation(replacedMethod), method_getTypeEncoding(replacedMethod));
        class_addMethod([childController class], @selector(tabBarController), method_getImplementation(replacingMethod), method_getTypeEncoding(replacingMethod));
    }
}

+ (void) addRemoveFromParentViewControllerMethodIfNeeded:(UIViewController *)controller {
    IF_PRE_IOS5(
        Method newRespondsMethod = class_getInstanceMethod([ASViewController class], @selector(useIOS5Implementations));
        Method newRemoveMethod = class_getInstanceMethod([ASViewController class], @selector(removeFromParentViewController));
        class_addMethod([controller class], @selector(useIOS5Implementations), method_getImplementation(newRespondsMethod), method_getTypeEncoding(newRespondsMethod));
        class_addMethod([controller class], @selector(removeFromParentViewController), method_getImplementation(newRemoveMethod), method_getTypeEncoding(newRemoveMethod));
    );
}

#pragma mark - Swizzling methods

- (UINavigationController*)swizzlingNavigationController
{
    UIViewController *parentController = objc_getAssociatedObject(self, ASViewControllerParentControllerKey);
    if (parentController) {
        return parentController.navigationController;
    } else {
        return [self performSelector:@selector(originalNavigationController)];
    }
}

- (UIViewController*)swizzlingParentViewController
{
    UIViewController *parentController = objc_getAssociatedObject(self, ASViewControllerParentControllerKey);
    if (parentController) {
        return parentController;
    } else {
        return [self performSelector:@selector(originalParentViewController)];
    }
}

- (UITabBarController*)swizzlingTabBarController
{
    UIViewController *parentController = objc_getAssociatedObject(self, ASViewControllerParentControllerKey);
    if (parentController) {
        return parentController.tabBarController;
    } else {
        return [self performSelector:@selector(originalTabBarController)];
    }
}

@end
