//
//  Created by Lukasz Warchol on 4/25/12.
//


#import <Foundation/Foundation.h>


@interface FakeCopyingArray : NSArray
@property(nonatomic, retain) NSArray *persistentFakeCopy;
@end
