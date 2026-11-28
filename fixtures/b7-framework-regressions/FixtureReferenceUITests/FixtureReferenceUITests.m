#import <XCTest/XCTest.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

// The native reference run starts a loopback HTTP server inside the UI test
// runner and hands its base URL to the app. App and test runner share the
// simulator's host network stack, so the I1 group executes against a real
// server instead of being skipped. The public JSON path keeps its default
// public URL.
@interface B7LocalHTTPServer : NSObject {
    int _listenSocket;
    BOOL _running;
    uint16_t _port;
}
@property (nonatomic, readonly) uint16_t port;
- (BOOL)start;
- (void)stop;
@end

@interface B7LocalHTTPServer ()
- (void)serve;
- (void)handleClient:(int)client;
- (NSData *)readRequest:(int)client;
- (void)sendStatus:(int)status contentType:(NSString *)contentType body:(NSData *)body to:(int)client;
@end

@implementation B7LocalHTTPServer

@synthesize port = _port;

- (BOOL)start {
    _listenSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (_listenSocket < 0) {
        return NO;
    }
    int yes = 1;
    setsockopt(_listenSocket, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = 0;
    if (bind(_listenSocket, (struct sockaddr *)&address, sizeof(address)) != 0 ||
        listen(_listenSocket, 8) != 0) {
        close(_listenSocket);
        _listenSocket = -1;
        return NO;
    }
    socklen_t length = sizeof(address);
    if (getsockname(_listenSocket, (struct sockaddr *)&address, &length) != 0) {
        close(_listenSocket);
        _listenSocket = -1;
        return NO;
    }
    _port = ntohs(address.sin_port);
    _running = YES;
    [NSThread detachNewThreadSelector:@selector(serve) toTarget:self withObject:nil];
    return YES;
}

- (void)stop {
    if (!_running) {
        return;
    }
    _running = NO;
    shutdown(_listenSocket, SHUT_RDWR);
}

- (void)serve {
    while (_running) {
        int client = accept(_listenSocket, NULL, NULL);
        if (client < 0) {
            break;
        }
        @autoreleasepool {
            [self handleClient:client];
        }
        close(client);
    }
    if (_listenSocket >= 0) {
        close(_listenSocket);
        _listenSocket = -1;
    }
}

- (NSData *)readRequest:(int)client {
    NSMutableData *data = [NSMutableData data];
    char buffer[4096];
    NSData *separator = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    NSUInteger headerLength = NSNotFound;
    while (headerLength == NSNotFound) {
        ssize_t received = recv(client, buffer, sizeof(buffer), 0);
        if (received <= 0) {
            return nil;
        }
        [data appendBytes:buffer length:(NSUInteger)received];
        NSRange range = [data rangeOfData:separator options:0 range:NSMakeRange(0, data.length)];
        if (range.location != NSNotFound) {
            headerLength = NSMaxRange(range);
        }
        if (data.length > 64 * 1024) {
            return nil;
        }
    }
    NSString *head = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, headerLength)]
                                            encoding:NSUTF8StringEncoding] autorelease];
    NSUInteger contentLength = 0;
    for (NSString *line in [head componentsSeparatedByString:@"\r\n"]) {
        if ([line.lowercaseString hasPrefix:@"content-length:"]) {
            contentLength = (NSUInteger)[[line substringFromIndex:15] integerValue];
        }
    }
    while (data.length < headerLength + contentLength) {
        ssize_t received = recv(client, buffer, sizeof(buffer), 0);
        if (received <= 0) {
            break;
        }
        [data appendBytes:buffer length:(NSUInteger)received];
        if (data.length > 1024 * 1024) {
            break;
        }
    }
    return data;
}

- (void)handleClient:(int)client {
    int yes = 1;
    setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof(yes));
    struct timeval timeout;
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;
    setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));

    NSData *request = [self readRequest:client];
    if (request.length == 0) {
        return;
    }
    NSData *separator = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    NSRange headerRange = [request rangeOfData:separator options:0 range:NSMakeRange(0, request.length)];
    if (headerRange.location == NSNotFound) {
        return;
    }
    NSUInteger headerLength = NSMaxRange(headerRange);
    NSString *head = [[[NSString alloc] initWithData:[request subdataWithRange:NSMakeRange(0, headerLength)]
                                            encoding:NSUTF8StringEncoding] autorelease];
    if (head == nil) {
        return;
    }
    NSArray *lines = [head componentsSeparatedByString:@"\r\n"];
    NSArray *requestLine = [lines.firstObject componentsSeparatedByString:@" "];
    if (requestLine.count < 2) {
        return;
    }
    NSString *method = requestLine[0];
    NSString *path = [requestLine[1] componentsSeparatedByString:@"?"].firstObject;

    NSUInteger contentLength = 0;
    for (NSString *line in lines) {
        if ([line.lowercaseString hasPrefix:@"content-length:"]) {
            contentLength = (NSUInteger)[[line substringFromIndex:15] integerValue];
        }
    }
    NSData *body = [NSData data];
    if (headerLength + contentLength <= request.length) {
        body = [request subdataWithRange:NSMakeRange(headerLength, contentLength)];
    }

    if ([path isEqualToString:@"/json"] && [method isEqualToString:@"GET"]) {
        NSData *payload = [@"{\"ok\":true,\"source\":\"local\"}" dataUsingEncoding:NSUTF8StringEncoding];
        [self sendStatus:200 contentType:@"application/json" body:payload to:client];
    } else if ([path isEqualToString:@"/echo"] && [method isEqualToString:@"POST"]) {
        [self sendStatus:200 contentType:@"application/octet-stream" body:body to:client];
    } else if ([path isEqualToString:@"/download"] && [method isEqualToString:@"GET"]) {
        NSData *payload = [@"fixture-download" dataUsingEncoding:NSUTF8StringEncoding];
        [self sendStatus:200 contentType:@"application/octet-stream" body:payload to:client];
    } else {
        NSData *payload = [@"{\"error\":\"not found\"}" dataUsingEncoding:NSUTF8StringEncoding];
        [self sendStatus:404 contentType:@"application/json" body:payload to:client];
    }
}

- (void)sendStatus:(int)status contentType:(NSString *)contentType body:(NSData *)body to:(int)client {
    NSString *reason = status == 200 ? @"OK" : @"Not Found";
    NSString *header = [NSString stringWithFormat:
        @"HTTP/1.1 %d %@\r\nContent-Type: %@\r\nContent-Length: %lu\r\nConnection: close\r\n\r\n",
        status, reason, contentType, (unsigned long)body.length];
    NSMutableData *response = [NSMutableData dataWithData:[header dataUsingEncoding:NSUTF8StringEncoding]];
    [response appendData:body];
    const uint8_t *bytes = response.bytes;
    NSUInteger remaining = response.length;
    while (remaining > 0) {
        ssize_t sent = send(client, bytes, remaining, 0);
        if (sent <= 0) {
            break;
        }
        bytes += sent;
        remaining -= (NSUInteger)sent;
    }
}

@end

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testFrameworkGroupsAndPersistenceAcrossRelaunch {
    B7LocalHTTPServer *server = [[B7LocalHTTPServer alloc] init];
    XCTAssertTrue([server start], @"The loopback I1 server must start");
    NSString *baseURL = [NSString stringWithFormat:@"http://127.0.0.1:%u", (unsigned int)server.port];

    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchEnvironment = @{ @"B7_NETWORK_BASE_URL": baseURL };
    [app launch];

    XCUIElement *status = app.staticTexts[@"b7.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:30.0], @"The framework groups must report their result");
    XCTAssertEqualObjects(status.label, @"B7_OK", @"Failed framework checks: %@", status.label);

    XCUIElement *sqlite = app.staticTexts[@"persistence.sqlite"];
    XCTAssertTrue([sqlite waitForExistenceWithTimeout:5.0]);
    XCTAssertEqualObjects(sqlite.label, @"Rows: 2");

    XCUIElement *counter = app.staticTexts[@"persistence.counter"];
    XCTAssertTrue([counter waitForExistenceWithTimeout:5.0]);
    NSInteger initialCount = [[counter.label componentsSeparatedByString:@" "].lastObject integerValue];
    XCUIElement *save = app.buttons[@"persistence.save"];
    XCTAssertTrue([save waitForExistenceWithTimeout:5.0]);
    [save tap];
    NSString *expectedCount = [NSString stringWithFormat:@"Count: %ld", (long)(initialCount + 1)];
    XCTAssertEqualObjects(counter.label, expectedCount);

    [app terminate];
    [app launch];
    status = app.staticTexts[@"b7.status"];
    counter = app.staticTexts[@"persistence.counter"];
    sqlite = app.staticTexts[@"persistence.sqlite"];
    XCTAssertTrue([status waitForExistenceWithTimeout:30.0]);
    XCTAssertEqualObjects(status.label, @"B7_OK", @"Failed framework checks after relaunch: %@", status.label);
    XCTAssertEqualObjects(counter.label, expectedCount);
    XCTAssertEqualObjects(sqlite.label, @"Rows: 2");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"b7-framework-regressions";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];

    [server stop];
}

@end
