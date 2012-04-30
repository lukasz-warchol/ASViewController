#import <Cedar-iOS/SpecHelper.h>
#import <OCMock-iPhone/OCMock.h>

#define EXP_SHORTHAND
#import "Expecta.h"

#import "ASViewController.h"
#import "FakeCopyingArray.h"

@interface ASViewController(SpecPrivate)
@property(retain) NSMutableArray *subviewControllers;
@end

SPEC_BEGIN(ASViewControllerSpec)

describe(@"ASViewController", ^{
    __block ASViewController *viewController;
    __block UIViewController* childViewController;
    __block id mockChildViewController;

    context(@"when runned on pre iOS 5 system", ^{

        beforeEach(^{
            id mockCurrentDevice = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
            [(UIDevice*)[[mockCurrentDevice stub] andReturn:@"4.3"] systemVersion];

            viewController = [[[ASViewController alloc] init] autorelease];
            childViewController = [[[UIViewController alloc] init] autorelease];
            mockChildViewController = [OCMockObject partialMockForObject:childViewController];
        });

        describe(@"when requesting childViewController", ^{
            it(@"should return a copy of subviewControllers", ^{
                FakeCopyingArray * fakeCopyingArray = [FakeCopyingArray array];
                viewController.subviewControllers = (NSMutableArray *)fakeCopyingArray;

                NSArray * children1 = viewController.childViewControllers;
                NSArray * children2 = viewController.childViewControllers;
                expect(fakeCopyingArray.persistentFakeCopy).toEqual(children1);
                expect(children1).toEqual(children2);
            });
        });

        describe(@"when adding child view controller", ^{

            it(@"should call KVC notifications on this child view controller", ^{
                [[mockChildViewController expect] willChangeValueForKey:@"parentViewController"];
                [[mockChildViewController expect] didChangeValueForKey:@"parentViewController"];

                [viewController addChildViewController:mockChildViewController];

                [mockChildViewController verify];
            });

            it(@"should call willMoveToParentViewController: when responds to it", ^{
                [[mockChildViewController expect] willMoveToParentViewController:viewController];

                [viewController addChildViewController:mockChildViewController];

                [mockChildViewController verify];
            });

            it(@"should add view controller to childViewControllers", ^{

                [viewController addChildViewController:mockChildViewController];

                expect(viewController.childViewControllers).toContain(mockChildViewController);
            });

            it(@"should associate view controller as parent view controller", ^{

                [viewController addChildViewController:childViewController];

                expect(childViewController.parentViewController).toEqual(viewController);
            });

            it(@"should associate view controller's navigationController with child navigationController", ^{
                UINavigationController * navigationController = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];

                [viewController addChildViewController:childViewController];

                expect(childViewController.navigationController).toEqual(navigationController);
            });

            it(@"should associate view controller's tabBarController with child tabBarController", ^{
                UITabBarController * tabBarController = [[[UITabBarController alloc] init] autorelease];
                [tabBarController setViewControllers:[NSArray arrayWithObject:viewController]];

                [viewController addChildViewController:childViewController];

                expect(childViewController.tabBarController).toEqual(tabBarController);
            });

        });

        describe(@"when child removes self from parent view controller", ^{
            beforeEach(^{
                [viewController addChildViewController:childViewController];
            });

            it(@"should call KVC notifications on this child view controller", ^{
                [[mockChildViewController expect] willChangeValueForKey:@"parentViewController"];
                [[mockChildViewController expect] didChangeValueForKey:@"parentViewController"];

                [childViewController removeFromParentViewController];

                [mockChildViewController verify];
            });


            it(@"should add view controller to childViewControllers", ^{

                [childViewController removeFromParentViewController];

                expect(viewController.childViewControllers).Not.toContain(mockChildViewController);
            });


            it(@"should set parent view controller as nil", ^{
                expect(childViewController.parentViewController).toEqual(viewController);

                [childViewController removeFromParentViewController];

                expect(childViewController.parentViewController).toBeNil();
            });

        });

        context(@"fowarding calls", ^{
            __block UIViewController * forwardChildViewController;
            beforeEach(^{
                forwardChildViewController = [[[UIViewController alloc] init] autorelease];
            });

            describe(@"shouldForwardCallbackToChildViewController:", ^{
                context(@"when child view controller's view is not yet loaded", ^{
                    it(@"should retunr NO", ^{
                        BOOL result =[viewController shouldForwardCallbackToChildViewController:forwardChildViewController];
                        expect(result).toBeFalsy();
                    });
                });

                context(@"when child view controller's view is loaded", ^{
                    beforeEach(^{
                        [forwardChildViewController loadView];
                    });

                    context(@"and child view controller's view is not present in parent view controller's view's herachy tree", ^{
                        it(@"should return NO", ^{
                            BOOL result =[viewController shouldForwardCallbackToChildViewController:forwardChildViewController];
                            expect(result).toBeFalsy();
                        });
                    });

                    context(@"and child view controller's view is present in parent view controller's view's herachy tree", ^{
                        context(@"and it is it's subview", ^{
                            beforeEach(^{
                                [viewController.view addSubview:forwardChildViewController.view];
                            });

                            it(@"should return YES", ^{
                                BOOL result =[viewController shouldForwardCallbackToChildViewController:forwardChildViewController];
                                expect(result).toBeTruthy();
                            });
                        });

                        context(@"and it is one of subviews' subview", ^{
                            it(@"should pass at least up to 10 levels of depth", ^{
                                for (int numberOfViewInBetween = 1; numberOfViewInBetween <= 10; numberOfViewInBetween++) {
                                    ASViewController * localParentViewController = [[[ASViewController alloc] init] autorelease];
                                    UIViewController * localChildViewController = [[[UIViewController alloc] init] autorelease];
                                    UIView *topView = localParentViewController.view;
                                    for (int i = 0; i < numberOfViewInBetween; i++) {
                                        UIView *newTopView = [[[UIView alloc] init] autorelease];
                                        [topView addSubview:newTopView];
                                        topView = newTopView;
                                    }
                                    [topView addSubview:localChildViewController.view];

                                    BOOL result =[localParentViewController shouldForwardCallbackToChildViewController:localChildViewController];
                                    expect(result).toBeTruthy();
                                }
                            });
                        });
                    });

                });

            });
        });

        context(@"when view lifecycle changes", ^{
            __block id mockChildViewController1;
            __block id mockChildViewController2;
            __block id mockChildViewController3;

            beforeEach(^{
                UIViewController * childViewController1 = [[[UIViewController alloc] init] autorelease];
                [childViewController1 loadView];
                UIViewController * childViewController2 = [[[UIViewController alloc] init] autorelease];
                [childViewController2 loadView];
                UIViewController * childViewController3 = [[[UIViewController alloc] init] autorelease];
                [childViewController3 loadView];

                mockChildViewController1 = [OCMockObject partialMockForObject:childViewController1];
                mockChildViewController2 = [OCMockObject partialMockForObject:childViewController2];
                mockChildViewController3 = [OCMockObject partialMockForObject:childViewController3];

                [viewController addChildViewController:mockChildViewController1];
                [viewController addChildViewController:mockChildViewController2];
                [viewController addChildViewController:mockChildViewController3];

                [viewController.view addSubview:childViewController1.view];
                [viewController.view addSubview:childViewController2.view];
                //not adding view of 3rd child VC
            });

            describe(@"when container view controller did unload", ^{
                it(@"should call didReceiveMemoryWarning on children", ^{
                    [[mockChildViewController1 expect] didReceiveMemoryWarning];
                    [[mockChildViewController2 expect] didReceiveMemoryWarning];
                    [[mockChildViewController3 expect] didReceiveMemoryWarning];

                    [viewController viewDidUnload];

                    [mockChildViewController1 verify];
                    [mockChildViewController2 verify];
                    [mockChildViewController3 verify];
                });
            });
            
            describe(@"when view controller apperaince changes", ^{
                describe(@"on  displaying", ^{
                    it(@"should forward calls to subviewControllers", ^{
                        [[mockChildViewController1 expect] viewWillAppear:YES];
                        [[mockChildViewController2 expect] viewWillAppear:YES];
                        [[mockChildViewController3 reject] viewWillAppear:YES];

                        [[mockChildViewController1 expect] viewDidAppear:YES];
                        [[mockChildViewController2 expect] viewDidAppear:YES];
                        [[mockChildViewController3 reject] viewDidAppear:YES];

                        [viewController viewWillAppear:YES];
                        [viewController viewDidAppear:YES];

                        [mockChildViewController1 verify];
                        [mockChildViewController2 verify];
                        [mockChildViewController3 verify];
                    });
                });

                describe(@"on hidding", ^{
                    it(@"should forward calls to subviewControllers", ^{
                        [[mockChildViewController1 expect] viewWillDisappear:YES];
                        [[mockChildViewController2 expect] viewWillDisappear:YES];
                        [[mockChildViewController3 reject] viewWillDisappear:YES];

                        [[mockChildViewController1 expect] viewDidDisappear:YES];
                        [[mockChildViewController2 expect] viewDidDisappear:YES];
                        [[mockChildViewController3 reject] viewDidDisappear:YES];

                        [viewController viewWillDisappear:YES];
                        [viewController viewDidDisappear:YES];

                        [mockChildViewController1 verify];
                        [mockChildViewController2 verify];
                        [mockChildViewController3 verify];
                    });
                });
            });

            describe(@"when view controller rotates", ^{
                it(@"should forward calls to subviewControllers", ^{
                    [[mockChildViewController1 expect] willRotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];
                    [[mockChildViewController2 expect] willRotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];
                    [[mockChildViewController3 reject] willRotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];

                    [[mockChildViewController1 expect] willAnimateRotationToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];
                    [[mockChildViewController2 expect] willAnimateRotationToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];
                    [[mockChildViewController3 reject] willAnimateRotationToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];

                    [[mockChildViewController1 expect] didRotateFromInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown];
                    [[mockChildViewController2 expect] didRotateFromInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown];
                    [[mockChildViewController3 reject] didRotateFromInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown];

                    [viewController willRotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];
                    [viewController willAnimateRotationToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown duration:2];
                    [viewController didRotateFromInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown];

                    [mockChildViewController1 verify];
                    [mockChildViewController2 verify];
                    [mockChildViewController3 verify];
                });
            });

        });

    });

});

SPEC_END
