//
//  Created by Lukasz Warchol on 11/21/11.
//

#import <UIKit/UIKit.h>

@interface ASViewController : UIViewController

// This is called only pre iOS 5. With this callback user can determine weather
// view controller lifecycle callback (like viewWillAppear: or willRotateToInterfaceOrientation:duration:)
// should be forwarded to child view controller.
// Default implementation of this method tries to determine that basing on weather this child view controller's
// view is visible from parent view controller's view. View hierarchy is revised.
- (BOOL)shouldForwardCallbackToChildViewController:(UIViewController *)childViewController;

@end
