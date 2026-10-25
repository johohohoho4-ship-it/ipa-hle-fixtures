//
//  m2048Tests.m
//  m2048Tests
//
//  Created by Danqing on 3/16/14.
//  Copyright (c) 2014 Danqing. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface m2048Tests : XCTestCase

@end

@implementation m2048Tests

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

- (void)testExample
{
    // Fixture smoke test: the app bundle is loaded as the test host.
    XCTAssertNotNil([NSBundle mainBundle].bundleIdentifier);
}

@end
