//
//  Created by Lukasz Warchol on 4/25/12.
//


#import "FakeCopyingArray.h"


@implementation FakeCopyingArray
@synthesize persistentFakeCopy = _persistentFakeCopy;


+ (id)array {
    FakeCopyingArray *array = [[[self alloc] init] autorelease];
    array.persistentFakeCopy = [NSArray array];
    return array;
}

- (id)copy {
    return [self.persistentFakeCopy retain];
}

- (void)dealloc {
    [_persistentFakeCopy release];
    [super dealloc];
}


@end
