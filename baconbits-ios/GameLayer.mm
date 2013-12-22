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
@implementation GameLayer

// Helper class method that creates a CCScene with the GameLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	GameLayer *layer = [GameLayer node];
	[scene addChild: layer];
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    if ((self = [super init]))
    {
        [self configureForDevice];

        // Set the background image
        CCSprite * bg = [CCSprite spriteWithFile:@"background.png"];
        bg.scale = _scaleFactor;
        bg.position = ccp(_winSize.width * 0.5, _winSize.height * 0.5f);
        [self addChild:bg z:0];

        // Add the title
        CCSprite * title = [CCSprite spriteWithFile:@"title.png"];
        title.scale = _scaleFactor;
        _headerYOffset = title.contentSize.height * _scaleFactor * 1.5f;
        title.position = ccp(_winSize.width * 0.5,
                             _winSize.height - _headerYOffset);
        [self addChild:title z:0];

        // Add the lives
        for (int i = 0; i < 3; i++) {
            CCSprite * life = [CCSprite spriteWithFile:@"life.png"];
            life.scale = _scaleFactor;
            life.position = ccp((life.contentSize.width * _scaleFactor * 1.5f * (i + 1)),
                                _winSize.height - _headerYOffset);
            [self addChild:life z:0];
            [_lives addObject:life];
        }

        // Add the score label
        _scoreValue = 0;
        _score = [CCLabelTTF labelWithString:@"0" fontName:@"Courier New" fontSize:(_fontSize)];
        _score.position = ccp((_winSize.width * 0.9f) - (_score.contentSize.width * _scaleFactor),
                              _winSize.height - _headerYOffset);
        [_score setColor:ccc3(255, 255, 255)];
        [self addChild:_score z:0];

        // Add the completion message, but hide for now
        _message = [CCLabelTTF
            labelWithString:@"Level Complete!\nTap to continue"
            fontName:@"Courier New"
            fontSize:(_fontSize * 1.5f)
        ];
        _message.horizontalAlignment = kCCTextAlignmentCenter;
        _message.position = ccp(_winSize.width * 0.5f, _winSize.height * 0.5f);
        _message.color = ccc3(255, 255, 255);
        _message.visible = false;
        [self addChild:_message z:0];

        // Add the shooter
        _shooter = [CCSprite spriteWithFile:@"actor.png"];
        _shooter.scale = _scaleFactor;
        _shooter.position = ccp(_winSize.width * 0.5f,
                               (_winSize.height * 0.1f) + (_shooter.contentSize.height * _scaleFactor * 0.5f));
        [self addChild:_shooter z:0];

        // Load sound effects
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"boom.wav"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"applause.wav"];

        // Setup the first level
        [self setupLevel];

        // Register update callback
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

- (void) setupLevel {

    _levelComplete = false;

    // Add the completion message, but hide for now
    _message.visible = false;

    // Empty any ammo and create a new array to hold shots
    [_ammo release];
    _ammo = [[NSMutableArray alloc] init];

    // Makin' bacon...
    [_bits release];
    _bits = [[NSMutableArray alloc] init];
    for (int col = 0; col < 16; col++) {
        for (int row = 0; row < 3; row++) {
            CCSprite * bit = nil;
            if (row == 0) {
                bit = [CCSprite spriteWithFile:@"bacon-top.png"];
            }
            else if (row == 1) {
                bit = [CCSprite spriteWithFile:@"bacon-middle.png"];
            }
            else if (row == 2) {
                bit = [CCSprite spriteWithFile:@"bacon-bottom.png"];
            }

            if (bit) {
                bit.scale = _scaleFactor;

                float x = (_winSize.width * 0.2f) + (bit.contentSize.width * _scaleFactor * col);
                float y = (_winSize.height * 0.5f) - (bit.contentSize.height * _scaleFactor * row);

                bit.position = ccp(x, y);

                [self addChild:bit z:0];
                [_bits addObject:bit];
            }
        }
    }

    // Reposition the shooter
    _shooter.position = ccp(_winSize.width * 0.5f,
                           (_winSize.height * 0.1f) + (_shooter.contentSize.height * _scaleFactor * 0.5f));
}

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    // Record start of touch
    UITouch *touch = [touches anyObject];
    _touchStart = [self convertTouchToNodeSpace:touch];
}

- (void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    // Record end of touch
    CGPoint target = [self convertTouchToNodeSpace:[touches anyObject]];
    float length = ccpDistance(_touchStart, target);

    // Move the shooter to the end of a swipe
    if (length > _swipeMin) {
        [self moveShooter:target];
    }
    else {
        // Setup a new level, if level complete
        if (_levelComplete)
            [self setupLevel];
        // Otherwise, fire a projectile
        else
            [self fireAmmo:target];
    }
}

- (void) fireAmmo:(CGPoint)end {

    // Set up initial location of projectile
    CCSprite *projectile = [CCSprite spriteWithFile:@"ammo.png"];
    projectile.scale = _scaleFactor;
    projectile.position = ccp(_shooter.position.x, _shooter.position.y + (_shooter.contentSize.width * _scaleFactor * 0.5f));
    CGPoint dest = ccp(_shooter.position.x, _yMin);

    // Determine offset of location to projectile
    CGPoint offset = ccpSub(dest, projectile.position);

    // Bail out if you are shooting down or backwards
    if (offset.y <= 0) return;

    // Ok to add now - we've double checked position
    [self addChild:projectile];

    float realY = _winSize.height + (projectile.contentSize.height * _scaleFactor * 0.5f);
    float ratio = (float) offset.x / (float) offset.y;
    float realX = (realY * ratio) + projectile.position.x;
    CGPoint realDest = ccp(realX, realY);

    // Calculate duration of shot for fixed velocity
    float offRealX = realX - projectile.position.x;
    float offRealY = realY - projectile.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 300.0f * _scaleFactor;
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

    // Cancel any in-progress actions
    [_shooter stopAllActions];

    // Don't allow shooter to go out-of-bounds
    float destX = max(min(end.x, _xMax), _xMin);

    // Determine offset of for the move
    CGPoint dest = ccp(destX, _shooter.position.y);

    // Calculate duration of move for fixed velocity
    float length = destX - _shooter.position.x;
    length *= length;
    length = sqrtf(length);
    float velocity = 300.0f * _scaleFactor;
    float duration = length/velocity;

    // Move shooter to actual endpoint
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
        _message.visible = true;
    }
}

- (void) configureForDevice
{
    self.touchEnabled = YES;
    self.accelerometerEnabled = YES;

    _winSize = [CCDirector sharedDirector].winSize;

    UIScreen * screen = [UIScreen mainScreen];
    CGSize size = screen.bounds.size;
    CGFloat scale = screen.scale;

    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        if (size.height == 480) {
            _scaleFactor = 0.85f; // iPhone 3.5"
        }
        else {
            _scaleFactor = 0.85f; // iPhone 4.0"
        }
    }
    else
    {
        if (scale == 1.0) {
            _scaleFactor = 1.0; // iPad
        }
        else {
            _scaleFactor = 2.0; // iPad-Retina
        }
    }

    // Scale font size
    _fontSize = 24.0f * _scaleFactor;

    // Scale swipe distance
    _swipeMin = 0.05f * _winSize.width;

    // Calculate game stage bounds
    _xMin = _winSize.width * 0.12f;
    _xMax = _winSize.width * 0.88f;
    _yMin = _winSize.height * 0.8f;
    _yMax = _winSize.height * 0.1f;
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
