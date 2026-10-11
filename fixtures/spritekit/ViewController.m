#import "ViewController.h"
#import <SpriteKit/SpriteKit.h>
#include <stdio.h>

// K1: a small SpriteKit game. Results that do not depend on frame timing are printed as
// "SK_EVENT" lines: action end states, the first contact, the resting position of the ball
// and each tap. The UILabel "sk.status" lets the UI test wait and tap.

static const uint32_t kBallCategory = 1;
static const uint32_t kGroundCategory = 2;

@interface GameScene : SKScene <SKPhysicsContactDelegate>
@property (nonatomic, copy) void (^onStatus)(NSString *status);
@end

@implementation GameScene {
    BOOL _contact;
    BOOL _playerDone;
    BOOL _boxDone;
    BOOL _firstUpdate;
    NSInteger _score;
    SKLabelNode *_scoreLabel;
    SKShapeNode *_ball;
}

- (void)didMoveToView:(SKView *)view {
    printf("SK_EVENT didMoveToView size=%.0fx%.0f anchor=%.1f,%.1f\n", self.size.width, self.size.height,
           self.anchorPoint.x, self.anchorPoint.y);
    self.backgroundColor = [UIColor colorWithRed:0.1 green:0.12 blue:0.2 alpha:1];
    self.physicsWorld.gravity = CGVectorMake(0, -9.8);
    self.physicsWorld.contactDelegate = self;

    SKSpriteNode *ground = [SKSpriteNode spriteNodeWithColor:UIColor.grayColor size:CGSizeMake(self.size.width, 40)];
    ground.name = @"ground";
    ground.position = CGPointMake(self.size.width / 2, 20);
    ground.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ground.size];
    ground.physicsBody.dynamic = NO;
    ground.physicsBody.categoryBitMask = kGroundCategory;
    [self addChild:ground];

    _ball = [SKShapeNode shapeNodeWithCircleOfRadius:20];
    _ball.name = @"ball";
    _ball.fillColor = UIColor.yellowColor;
    _ball.lineWidth = 0;
    _ball.position = CGPointMake(self.size.width / 2, 700);
    _ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:20];
    _ball.physicsBody.restitution = 0;
    _ball.physicsBody.categoryBitMask = kBallCategory;
    _ball.physicsBody.contactTestBitMask = kGroundCategory;
    [self addChild:_ball];

    SKSpriteNode *player = [SKSpriteNode spriteNodeWithColor:UIColor.redColor size:CGSizeMake(60, 30)];
    player.name = @"player";
    player.position = CGPointMake(95, 300);
    [self addChild:player];
    SKAction *walk = [SKAction sequence:@[[SKAction moveByX:200 y:0 duration:1.0],
                                          [SKAction waitForDuration:0.25],
                                          [SKAction moveByX:-200 y:50 duration:1.0]]];
    [player runAction:walk completion:^{
        printf("SK_EVENT player_done position=%.1f,%.1f\n", player.position.x, player.position.y);
        self->_playerDone = YES;
        [self report];
    }];

    SKSpriteNode *box = [SKSpriteNode spriteNodeWithColor:UIColor.blueColor size:CGSizeMake(50, 50)];
    box.name = @"box";
    box.position = CGPointMake(195, 450);
    [self addChild:box];
    SKAction *spin = [SKAction group:@[[SKAction rotateByAngle:M_PI duration:0.5],
                                       [SKAction scaleTo:1.5 duration:0.5],
                                       [SKAction fadeAlphaTo:0.5 duration:0.5]]];
    [box runAction:[SKAction sequence:@[spin, [SKAction runBlock:^{
        printf("SK_EVENT box_done zRotation=%.3f scale=%.3f alpha=%.3f\n", box.zRotation, box.xScale, box.alpha);
        self->_boxDone = YES;
        [self report];
    }]]]];

    SKSpriteNode *spinner = [SKSpriteNode spriteNodeWithColor:UIColor.greenColor size:CGSizeMake(20, 20)];
    spinner.position = CGPointMake(320, 450);
    [self addChild:spinner];
    [spinner runAction:[SKAction repeatActionForever:[SKAction rotateByAngle:M_PI duration:1.0]]];

    _scoreLabel = [SKLabelNode labelNodeWithText:@"Punkte: 0"];
    _scoreLabel.fontName = @"Helvetica-Bold";
    _scoreLabel.fontSize = 28;
    _scoreLabel.fontColor = UIColor.whiteColor;
    _scoreLabel.position = CGPointMake(self.size.width / 2, self.size.height - 120);
    [self addChild:_scoreLabel];
    printf("SK_EVENT children=%lu\n", (unsigned long)self.children.count);
}

- (void)update:(NSTimeInterval)currentTime {
    if (!_firstUpdate) {
        _firstUpdate = YES;
        printf("SK_EVENT first_update\n");
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    if (_contact) {
        return;
    }
    _contact = YES;
    SKNode *a = contact.bodyA.node, *b = contact.bodyB.node;
    printf("SK_EVENT contact %s %s\n", a.name.UTF8String, b.name.UTF8String);
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:1.5], [SKAction runBlock:^{
        printf("SK_EVENT ball_rest y=%.0f\n", self->_ball.position.y);
        [self report];
    }]]]];
}

- (void)report {
    if (_contact && _playerDone && _boxDone && self.onStatus) {
        self.onStatus(@"SK_READY");
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInNode:self];
    SKSpriteNode *drop = [SKSpriteNode spriteNodeWithColor:UIColor.greenColor size:CGSizeMake(30, 30)];
    drop.position = point;
    drop.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:drop.size];
    [self addChild:drop];
    _score += 1;
    _scoreLabel.text = [NSString stringWithFormat:@"Punkte: %ld", (long)_score];
    SKNode *hit = [self nodeAtPoint:point];
    printf("SK_EVENT tap %.0f,%.0f score=%ld hit=%s\n", point.x, point.y, (long)_score,
           hit.name ? hit.name.UTF8String : "none");
    if (self.onStatus) {
        self.onStatus([NSString stringWithFormat:@"SK_TAP %ld", (long)_score]);
    }
}

@end

@implementation ViewController {
    UILabel *_status;
}

- (void)loadView {
    self.view = [[SKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    SKView *view = (SKView *)self.view;
    view.accessibilityIdentifier = @"sk.view";

    _status = [[UILabel alloc] initWithFrame:CGRectMake(16, 60, 200, 24)];
    _status.accessibilityIdentifier = @"sk.status";
    _status.text = @"SK_WAIT";
    _status.textColor = UIColor.whiteColor;
    _status.font = [UIFont systemFontOfSize:15];
    [view addSubview:_status];

    GameScene *scene = [GameScene sceneWithSize:view.bounds.size];
    scene.scaleMode = SKSceneScaleModeResizeFill;
    UILabel *status = _status;                    // manual reference counting: the view keeps the label
    scene.onStatus = ^(NSString *text) {
        status.text = text;
        printf("SK_STATUS %s\n", text.UTF8String);
    };
    [view presentScene:scene];
}

@end
