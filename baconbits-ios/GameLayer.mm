//
//  GameLayer.m
//  baconbits-ios
//
//  Created by Greg Williams on 9/29/13.
//  Copyright Atomic Object LLC 2013. All rights reserved.
//


// Import the interfaces
#import "GameLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "SimpleAudioEngine.h"

#pragma mark - GameLayer

// HelloWorldLayer implementation
@implementation GameLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];

	// 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];

	// add layer as a child to scene
	[scene addChild: layer];

	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    if ((self = [super init]))
    {
//        _scaleFactor = 0.85; // iPhone 3.5"
//        _scaleFactor = 0.85; // iPhone 4.0"
        _scaleFactor = 1.0; // iPad
//        _scaleFactor = 2.0; // iPad-Retina

        self.touchEnabled = YES;
        self.accelerometerEnabled = YES;

        _winSize = [CCDirector sharedDirector].winSize;
        _levelComplete = false;

        // Set the background image
        CCSprite * bg = [CCSprite spriteWithFile:@"background.png"];
        bg.scale = _scaleFactor;
        bg.position = ccp(_winSize.width * 0.5, _winSize.height * 0.5);
        [self addChild:bg z:0];

        // Add the title
        CCSprite * title = [CCSprite spriteWithFile:@"title.png"];
        title.scale = _scaleFactor;
        _headerYOffset = title.contentSize.height * _scaleFactor * 1.5;
        title.position = ccp(_winSize.width * 0.5,
                             _winSize.height - _headerYOffset);
        [self addChild:title z:0];

        // Add the lives
        for (int i = 0; i < 3; i++) {
            CCSprite * life = [CCSprite spriteWithFile:@"life.png"];
            life.scale = _scaleFactor;
            life.position = ccp((life.contentSize.width * _scaleFactor * 1.5 * (i + 1)),
                                _winSize.height - _headerYOffset);
            [self addChild:life z:0];
            [_lives addObject:life];
        }

        // Add the score label
        _scoreValue = 0;
        _score = [CCLabelTTF labelWithString:@"0" fontName:@"Courier New" fontSize:(36)];
        _score.position = ccp((_winSize.width * 0.9) - (_score.contentSize.width * _scaleFactor),
                              _winSize.height - _headerYOffset);
        [_score setColor:ccc3(255, 255, 255)];
        [self addChild:_score z:0];

        // Makin' bacon...
        _bits = [[NSMutableArray alloc] init];
        for (int col = 0; col < 16; col++) {
            for (int row = 0; row < 3; row++) {
                CCSprite * bit;
                if (row == 0) {
                    bit = [CCSprite spriteWithFile:@"bacon-top.png"];
                }
                else if (row == 1) {
                    bit = [CCSprite spriteWithFile:@"bacon-middle.png"];
                }
                else if (row == 2) {
                    bit = [CCSprite spriteWithFile:@"bacon-bottom.png"];
                }
                bit.scale = _scaleFactor;

                int x = (_winSize.width * 0.2) + (bit.contentSize.width * _scaleFactor * col);
                int y = (_winSize.height * 0.5) - (bit.contentSize.height * _scaleFactor * row);

                bit.position = ccp(x, y);

                [self addChild:bit z:0];
                [_bits addObject:bit];
            }
        }

        // Add the shooter
        _shooter = [CCSprite spriteWithFile:@"actor.png"];
        _shooter.scale = _scaleFactor;
        _shooter.position = ccp(_winSize.width * 0.5,
                               (_winSize.height * 0.1) + (_shooter.contentSize.height * _scaleFactor * 0.5));
        [self addChild:_shooter z:0];

        // Create array to hold ammo yet to be fired
        _ammo = [[NSMutableArray alloc] init];

        // Load sound effects
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"boom.wav"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"applause.wav"];

        // Register update callback to handle collision detection
        [self schedule:@selector(update:)];
    }

    return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// In case you have something to dealloc, do it in this method.
	// In this particular example nothing needs to be released,
	// since cocos2d will automatically deallocate all children

    [_bits release];
    _bits = nil;
    [_ammo release];
    _ammo = nil;
    [_lives release];
    _lives = nil;

	// don't forget to call "super dealloc"
	[super dealloc];
}

- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);

    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);

    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();

    return newImage;
}

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    // Record start of touch
    UITouch *touch = [touches anyObject];
    _touchStart = [self convertTouchToNodeSpace:touch];
}

- (void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    // Record end of touch
    UITouch *touch = [touches anyObject];
    CGPoint target = [self convertTouchToNodeSpace:touch];
    float swipeLength = ccpDistance(_touchStart, target);

    // Move the shooter to the end of a swipe
    if ([self isSwipe:swipeLength])
    {
        [self moveShooter:target];
    }

    // Otherwise, fire a projectile
    else
    {
        [self fireAmmo:target];
    }
}

- (bool) isSwipe:(float)length {
    return (length > 20);
}

- (void) fireAmmo:(CGPoint)end {

    // Set up initial location of projectile
    CCSprite *projectile = [CCSprite spriteWithFile:@"ammo.png"];
    projectile.scale = _scaleFactor;
    projectile.position = ccp(_shooter.position.x, _shooter.position.y + (_shooter.contentSize.width * _scaleFactor * 0.5));

    // Determine offset of location to projectile
    CGPoint offset = ccpSub(end, projectile.position);

    // Bail out if you are shooting down or backwards
    if (offset.y <= 0) return;

    // Ok to add now - we've double checked position
    [self addChild:projectile];

    int realY = _winSize.height + (projectile.contentSize.height * _scaleFactor * 0.5);
    float ratio = (float) offset.x / (float) offset.y;
    int realX = (realY * ratio) + projectile.position.x;
    CGPoint realDest = ccp(realX, realY);

    // Calculate duration of shot for fixed velocity
    int offRealX = realX - projectile.position.x;
    int offRealY = realY - projectile.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 480/1; // 480 pixels/sec
    float realMoveDuration = length/velocity;

    // Play sound effect
    [[SimpleAudioEngine sharedEngine] playEffect:@"boom.wav"];

    // Move projectile to actual endpoint
    [projectile runAction:
     [CCSequence actions:
      [CCMoveTo actionWithDuration:realMoveDuration position:realDest],
      [CCCallBlockN actionWithBlock:^(CCNode *node) {
         [_ammo removeObject:node];
         [node removeFromParentAndCleanup:YES];
     }],
      nil]
     ];

    projectile.tag = 2;

    [_ammo addObject:projectile];
}

- (void) moveShooter:(CGPoint)end {

    // Determine offset of for the move
    CGPoint offset = ccpSub(end, _shooter.position);
    CGPoint dest = ccp(end.x, _shooter.position.y);

    // Calculate duration of move for fixed velocity
    float length = sqrtf((offset.x * offset.x) + (offset.y * offset.y));
    float velocity = 480; // 480 pixels/sec
    float duration = length/velocity;

    // Move projectile to actual endpoint
    [_shooter runAction:
     [CCSequence actions:
      [CCMoveTo actionWithDuration:duration position:dest],
      nil]
     ];
}

- (void) update:(ccTime)timestamp {

    // Don't do anything if level complete
    if (_levelComplete) {
        return;
    }

    [self updateAmmo];
    [self checkLevelComplete];
}

- (void) updateAmmo {

    // Check all fireballs in flight for collisions
    NSMutableArray *fireballsToDelete = [[NSMutableArray alloc] init];
    for (CCSprite *fireball in _ammo) {
        NSMutableArray *bitsToDelete = [[NSMutableArray alloc] init];

        for (CCSprite *bit in _bits) {
            if (CGRectIntersectsRect(fireball.boundingBox, bit.boundingBox)) {
                [bitsToDelete addObject:bit];
                // break;
            }
        }

        for (CCSprite *bit in bitsToDelete) {
             _scoreValue += 100;
             _score.string = [NSString stringWithFormat:@"%d", _scoreValue];
            [_bits removeObject:bit];
            [self removeChild:bit cleanup:YES];
        }

        if (bitsToDelete.count > 0) {
            [fireballsToDelete addObject:fireball];
        }

        [bitsToDelete release];
    }

    for (CCSprite *fireball in fireballsToDelete) {
        [_ammo removeObject:fireball];
        [self removeChild:fireball cleanup:YES];
    }

    [fireballsToDelete release];
}

- (void) checkLevelComplete {
    // Check if level complete and announce
    if (!_levelComplete && _bits.count == 0)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"applause.wav"];
        _levelComplete = true;
    }
}


#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [[app navController] dismissViewControllerAnimated:YES completion:nil];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [[app navController] dismissViewControllerAnimated:YES completion:nil];
}
@end
