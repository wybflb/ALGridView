//
//  ALGridViewTests.m
//  ALGridViewTests
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ALGridViewTests : XCTestCase

@end

@implementation ALGridViewTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNSUInterger
{
    NSString *str = @"PdF";
    if ([str compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        NSLog(@"\n\nSame\n\n");
    } else {
        NSLog(@"\n\nNotSame\n\n");
    }
//    NSUInteger num = -1;
//#if __LP64__
//    NSLog(@"num=%lu", num);
//#else
//    NSLog(@"testNum:%u", num);
//#endif
}

@end
