#import "ViewController.h"
#import <SpriteKit/SpriteKit.h>

// K1 reference data that the HLE cannot derive: Xcode's compiled texture atlas, how SpriteKit
// reads it back, and the keyed-archive form of scenes, emitters and actions (the .sks format).
// Every result is one stdout line starting with SK_; main.m keeps stdout in tmp/ipa-hle-console.log.

static void SKLog(NSString *line) {
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

// Pixels top row first, each row run-length encoded as count*RRGGBBAA (premultiplied, as
// CGBitmapContext stores them). Images over 64x64 pixels are sampled on an 8x8 grid instead.
static NSString *Pixels(CGImageRef image) {
    if (image == NULL) {
        return @"nil";
    }
    size_t w = CGImageGetWidth(image), h = CGImageGetHeight(image);
    if (w == 0 || h == 0) {
        return @"0x0";
    }
    NSMutableData *buffer = [NSMutableData dataWithLength:w * h * 4];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(buffer.mutableBytes, w, h, 8, w * 4, space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), image);
    CGContextRelease(context);
    CGColorSpaceRelease(space);
    const uint8_t *bytes = buffer.bytes;
    NSMutableString *out = [NSMutableString stringWithFormat:@"%zux%zu", w, h];
    if (w * h > 64 * 64) {
        [out appendString:@" grid"];
        for (size_t gy = 0; gy < 8; gy++) {
            for (size_t gx = 0; gx < 8; gx++) {
                const uint8_t *p = bytes + (((gy * 2 + 1) * h / 16) * w + (gx * 2 + 1) * w / 16) * 4;
                [out appendFormat:@" %02x%02x%02x%02x", p[0], p[1], p[2], p[3]];
            }
        }
        return out;
    }
    for (size_t y = 0; y < h; y++) {
        [out appendString:@" "];
        size_t x = 0;
        while (x < w) {
            const uint8_t *p = bytes + (y * w + x) * 4;
            size_t run = 1;
            while (x + run < w && memcmp(p, p + run * 4, 4) == 0) {
                run++;
            }
            [out appendFormat:@"%@%zu*%02x%02x%02x%02x", x ? @"," : @"", run, p[0], p[1], p[2], p[3]];
            x += run;
        }
    }
    return out;
}

static NSString *Rect(CGRect r) {
    return [NSString stringWithFormat:@"%.4f %.4f %.4f %.4f", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

static void LogArchive(NSString *label, id object) {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:&error];
    if (data == nil) {
        SKLog([NSString stringWithFormat:@"SK_ARCHIVE %@ error %@ %ld", label, error.domain, (long)error.code]);
        return;
    }
    NSString *text = [data base64EncodedStringWithOptions:0];
    NSUInteger chunk = 800, count = (text.length + chunk - 1) / chunk;
    SKLog([NSString stringWithFormat:@"SK_ARCHIVE %@ bytes %lu chunks %lu", label, (unsigned long)data.length,
           (unsigned long)count]);
    for (NSUInteger i = 0; i < count; i++) {
        NSRange range = NSMakeRange(i * chunk, MIN(chunk, text.length - i * chunk));
        SKLog([NSString stringWithFormat:@"SK_ARCHIVE %@ %lu %@", label, (unsigned long)i, [text substringWithRange:range]]);
    }
    id back = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
    if ([back isKindOfClass:[SKNode class]]) {
        SKNode *node = back;
        SKLog([NSString stringWithFormat:@"SK_ROUNDTRIP %@ %@ children %lu", label, NSStringFromClass([node class]),
               (unsigned long)node.children.count]);
    } else {
        SKLog([NSString stringWithFormat:@"SK_ROUNDTRIP %@ %@", label, back ? NSStringFromClass([back class]) : @"nil"]);
    }
}

// Scene lifecycle around presentScene:transition: (K1 derives the order and the pausing).
@interface LoggingScene : SKScene
@property (nonatomic, copy) NSString *label;
@property (nonatomic) NSInteger updates;
@end

@implementation LoggingScene

- (void)didMoveToView:(SKView *)view {
    SKLog([NSString stringWithFormat:@"SK_LIFE %@ didMoveToView updates %ld paused %d", self.label, (long)self.updates,
           self.paused]);
}

- (void)willMoveFromView:(SKView *)view {
    SKLog([NSString stringWithFormat:@"SK_LIFE %@ willMoveFromView updates %ld view %d", self.label, (long)self.updates,
           self.view != nil]);
}

- (void)update:(NSTimeInterval)currentTime {
    self.updates += 1;
}

@end

@interface ViewController ()
@property (nonatomic, strong) SKView *skView;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic) NSInteger pending;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.skView = [[SKView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.skView];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 300, 30)];
    self.status.accessibilityIdentifier = @"sk.status";
    self.status.text = @"SK_WAIT";
    [self.view addSubview:self.status];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.skView presentScene:[SKScene sceneWithSize:self.skView.bounds.size]];
    [self logBundle];
    SKTextureAtlas *atlas = [self logAtlas];
    [self logLookups:atlas];
    [self logArchives:atlas];
    [self preload:atlas];
}

- (void)logBundle {
    NSString *folder = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Sprites.atlasc"];
    NSArray *names = [[NSFileManager.defaultManager contentsOfDirectoryAtPath:folder error:nil]
                      sortedArrayUsingSelector:@selector(compare:)];
    SKLog([NSString stringWithFormat:@"SK_BUNDLE atlasc %@", names ? [names componentsJoinedByString:@","] : @"missing"]);
    for (NSString *name in names) {
        NSDictionary *attributes = [NSFileManager.defaultManager
                                    attributesOfItemAtPath:[folder stringByAppendingPathComponent:name] error:nil];
        SKLog([NSString stringWithFormat:@"SK_FILE %@ %llu", name, attributes.fileSize]);
    }
}

- (SKTextureAtlas *)logAtlas {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Sprites"];
    NSArray *names = atlas.textureNames;
    SKLog([NSString stringWithFormat:@"SK_ATLAS names %@", [names componentsJoinedByString:@","]]);
    for (NSString *name in [names sortedArrayUsingSelector:@selector(compare:)]) {
        SKTexture *texture = [atlas textureNamed:name];
        SKLog([NSString stringWithFormat:@"SK_TEX %@ size %.4f %.4f rect %@", name, texture.size.width,
               texture.size.height, Rect(texture.textureRect)]);
        SKLog([NSString stringWithFormat:@"SK_TEXPIX %@ %@", name, Pixels(texture.CGImage)]);
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:texture];
        SKTexture *drawn = [self.skView textureFromNode:sprite];
        SKLog([NSString stringWithFormat:@"SK_RENDER %@ %@", name, Pixels(drawn.CGImage)]);
    }
    return atlas;
}

- (void)logLookups:(SKTextureAtlas *)atlas {
    for (NSString *name in @[@"hero", @"hero.png", @"hero@2x", @"hero@2x.png", @"star", @"nothing"]) {
        SKTexture *texture = [atlas textureNamed:name];
        SKLog([NSString stringWithFormat:@"SK_LOOKUP atlas %@ %@", name, texture
               ? [NSString stringWithFormat:@"%.4f %.4f %@", texture.size.width, texture.size.height, Pixels(texture.CGImage)]
               : @"nil"]);
    }
    for (NSString *name in @[@"star", @"tall", @"nothing"]) {
        SKTexture *texture = [SKTexture textureWithImageNamed:name];
        SKLog([NSString stringWithFormat:@"SK_LOOKUP image %@ %@", name, texture
               ? [NSString stringWithFormat:@"%.4f %.4f %@", texture.size.width, texture.size.height, Pixels(texture.CGImage)]
               : @"nil"]);
    }
    SKTextureAtlas *missing = [SKTextureAtlas atlasNamed:@"Missing"];
    SKLog([NSString stringWithFormat:@"SK_LOOKUP missing_atlas %@", missing
           ? [NSString stringWithFormat:@"names %lu", (unsigned long)missing.textureNames.count] : @"nil"]);
    SKTexture *sub = [SKTexture textureWithRect:CGRectMake(0.5, 0.5, 0.5, 0.5) inTexture:[atlas textureNamed:@"hero"]];
    SKLog([NSString stringWithFormat:@"SK_LOOKUP sub hero size %.4f %.4f rect %@ %@", sub.size.width, sub.size.height,
           Rect(sub.textureRect), Pixels(sub.CGImage)]);
}

- (void)logArchives:(SKTextureAtlas *)atlas {
    SKScene *scene = [SKScene sceneWithSize:CGSizeMake(200, 100)];
    scene.name = @"archived";
    scene.anchorPoint = CGPointMake(0.5, 0.5);
    scene.backgroundColor = [UIColor colorWithRed:0.1 green:0.2 blue:0.3 alpha:1];
    scene.scaleMode = SKSceneScaleModeAspectFit;

    SKSpriteNode *box = [SKSpriteNode spriteNodeWithColor:UIColor.redColor size:CGSizeMake(30, 20)];
    box.name = @"box";
    box.position = CGPointMake(10, 20);
    box.zRotation = 0.5;
    box.alpha = 0.7;
    box.zPosition = 2;
    box.anchorPoint = CGPointMake(0.25, 0.75);
    box.xScale = 1.5;
    [box runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction moveByX:10 y:0 duration:1],
                                                                       [SKAction waitForDuration:0.5]]]]
           withKey:@"patrol"];
    [scene addChild:box];

    SKSpriteNode *hero = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"hero"]];
    hero.name = @"hero";
    hero.color = UIColor.blueColor;
    hero.colorBlendFactor = 0.5;
    [scene addChild:hero];

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    label.text = @"Hello";
    label.fontSize = 20;
    label.fontColor = UIColor.greenColor;
    label.name = @"label";
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    [scene addChild:label];

    SKShapeNode *ball = [SKShapeNode shapeNodeWithCircleOfRadius:8];
    ball.name = @"ball";
    ball.fillColor = UIColor.orangeColor;
    ball.strokeColor = UIColor.whiteColor;
    ball.lineWidth = 2;
    ball.position = CGPointMake(-40, 10);
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:8];
    ball.physicsBody.categoryBitMask = 2;
    ball.physicsBody.restitution = 0.6;
    [scene addChild:ball];

    SKEmitterNode *sparks = [[SKEmitterNode alloc] init];
    sparks.name = @"sparks";
    sparks.position = CGPointMake(0, -30);
    sparks.particleTexture = [atlas textureNamed:@"ghost"];
    sparks.particleBirthRate = 20;
    sparks.numParticlesToEmit = 40;
    sparks.particleLifetime = 1.5;
    sparks.particleLifetimeRange = 0.5;
    sparks.particlePositionRange = CGVectorMake(10, 4);
    sparks.emissionAngle = M_PI_2;
    sparks.emissionAngleRange = 0.3;
    sparks.particleSpeed = 50;
    sparks.particleSpeedRange = 10;
    sparks.yAcceleration = -30;
    sparks.particleAlpha = 0.9;
    sparks.particleAlphaRange = 0.1;
    sparks.particleAlphaSpeed = -0.5;
    sparks.particleScale = 0.5;
    sparks.particleScaleRange = 0.2;
    sparks.particleScaleSpeed = -0.1;
    sparks.particleRotationSpeed = 1;
    sparks.particleColor = UIColor.yellowColor;
    sparks.particleColorBlendFactor = 1;
    sparks.particleBlendMode = SKBlendModeAdd;
    sparks.particleSize = CGSizeMake(8, 8);
    [scene addChild:sparks];

    SKCropNode *crop = [SKCropNode node];
    crop.name = @"crop";
    crop.maskNode = [SKSpriteNode spriteNodeWithColor:UIColor.whiteColor size:CGSizeMake(10, 10)];
    [crop addChild:[SKSpriteNode spriteNodeWithColor:UIColor.purpleColor size:CGSizeMake(20, 20)]];
    [scene addChild:crop];

    SKCameraNode *camera = [SKCameraNode node];
    camera.name = @"camera";
    camera.position = CGPointMake(5, 5);
    [scene addChild:camera];
    scene.camera = camera;

    LogArchive(@"scene", scene);
    LogArchive(@"emitter", [[SKEmitterNode alloc] init]);
    LogArchive(@"sparks", sparks);
    LogArchive(@"action", [SKAction sequence:@[[SKAction moveByX:10 y:-5 duration:0.25],
                                               [SKAction fadeAlphaTo:0.5 duration:0.5],
                                               [SKAction removeFromParent]]]);
}

- (void)preload:(SKTextureAtlas *)atlas {
    self.pending = 3;
    // A handler that never runs is a result too (e.g. for a missing atlas); do not hang the test.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self.pending > 0) {
            SKLog([NSString stringWithFormat:@"SK_DONE timeout pending %ld", (long)self.pending]);
            self.pending = -1;
            [self runLifecycle];
        }
    });
    [atlas preloadWithCompletionHandler:^{
        SKLog([NSString stringWithFormat:@"SK_PRELOAD instance main %d", NSThread.isMainThread]);
        [self finishOne];
    }];
    [SKTextureAtlas preloadTextureAtlasesNamed:@[@"Sprites"]
                         withCompletionHandler:^(NSError *error, NSArray<SKTextureAtlas *> *atlases) {
        SKLog([NSString stringWithFormat:@"SK_PRELOAD named main %d error %@ %ld atlases %lu", NSThread.isMainThread,
               error.domain ?: @"nil", (long)error.code, (unsigned long)atlases.count]);
        [self finishOne];
    }];
    [SKTextureAtlas preloadTextureAtlasesNamed:@[@"Sprites", @"Missing"]
                         withCompletionHandler:^(NSError *error, NSArray<SKTextureAtlas *> *atlases) {
        SKLog([NSString stringWithFormat:@"SK_PRELOAD named_missing main %d error %@ %ld atlases %lu",
               NSThread.isMainThread, error.domain ?: @"nil", (long)error.code, (unsigned long)atlases.count]);
        [self finishOne];
    }];
}

- (void)finishOne {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.pending <= 0) {
            SKLog(@"SK_PRELOAD late");
            return;
        }
        self.pending -= 1;
        if (self.pending == 0) {
            [self runLifecycle];
        }
    });
}

- (void)runLifecycle {
    LoggingScene *a = [LoggingScene sceneWithSize:self.skView.bounds.size];
    a.label = @"a";
    a.backgroundColor = UIColor.redColor;
    LoggingScene *b = [LoggingScene sceneWithSize:self.skView.bounds.size];
    b.label = @"b";
    b.backgroundColor = UIColor.blueColor;
    SKLog(@"SK_LIFE present a");
    [self.skView presentScene:a];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 2), dispatch_get_main_queue(), ^{
        SKTransition *fade = [SKTransition crossFadeWithDuration:1.0];
        SKLog([NSString stringWithFormat:@"SK_LIFE present b transition pausesIncoming %d pausesOutgoing %d updates a %ld",
               fade.pausesIncomingScene, fade.pausesOutgoingScene, (long)a.updates]);
        [self.skView presentScene:b transition:fade];
        SKLog([NSString stringWithFormat:@"SK_LIFE after present scene_is_b %d a.view %d b.view %d",
               self.skView.scene == b, a.view != nil, b.view != nil]);
        for (int i = 1; i <= 6; i++) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * NSEC_PER_SEC / 4), dispatch_get_main_queue(), ^{
                SKLog([NSString stringWithFormat:@"SK_LIFE t=%.2f updates a %ld b %ld a.view %d", i / 4.0,
                       (long)a.updates, (long)b.updates, a.view != nil]);
                if (i == 6) {
                    SKLog(@"SK_DONE");
                    self.status.text = @"SK_ARCHIVES_READY";
                }
            });
        }
    });
}

@end
