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
        _maxLives = 3;
        _livesLeft = _maxLives;
        _lives = [[NSMutableArray alloc] init];
        for (int i = 0; i < _maxLives; i++) {
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

        // Add the Game Over message, but hide for now
        _messageGameOver = [CCLabelTTF
                    labelWithString:@"Game Over!\nTap to play again"
                    fontName:@"Courier New"
                    fontSize:(_fontSize * 1.5f)];
        _messageGameOver.horizontalAlignment = kCCTextAlignmentCenter;
        _messageGameOver.position = ccp(_winSize.width * 0.5f, _winSize.height * 0.5f);
        _messageGameOver.color = ccc3(255, 255, 255);
        _messageGameOver.visible = false;
        [self addChild:_messageGameOver z:0];

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
        _level = 1;
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
    [_bitsFalling release];
    _bitsFalling = nil;
    [_ammo release];
    _ammo = nil;
    [_lives release];
    _lives = nil;

	// don't forget to call "super dealloc"
	[super dealloc];
}

- (void) setupLevel {

    if (_gameOver) {
        _level = 1;
        _scoreValue = 0;
        _gameOver = false;
        _livesLeft = 3;
    }

    for (int i = 0; i < 3; i++) {
        [_lives[i] setVisible:(i < _livesLeft)];
    }

    _score.string = [NSString stringWithFormat:@"%d", _scoreValue];
    _levelComplete = false;

    // Hide the messages
    _message.visible = false;
    _messageGameOver.visible = false;

    // Empty any ammo and create a new array to hold shots
    for (CCSprite *fireball in _ammo) {
        [self removeChild:fireball cleanup:YES];
    }
    [_ammo release];
    _ammo = [[NSMutableArray alloc] init];
    for (CCSprite *bit in _bitsFalling) {
        [self removeChild:bit cleanup:YES];
    }
    [_bitsFalling release];
    _bitsFalling = [[NSMutableArray alloc] init];

    // Makin' bacon...
    CGPoint center = ccp(_winSize.width * 0.5f, _winSize.height * 0.5f);
    int baconWidth = (4 + _level) * 2;
    [self makeBacon:baconWidth at:center];

    // Reposition the shooter
    _shooter.position = ccp(_winSize.width * 0.5f,
                           (_winSize.height * 0.1f) + (_shooter.contentSize.height * _scaleFactor * 0.5f));
}

- (void) makeBacon:(int)width at:(CGPoint)center {
    for (CCSprite *bit in _bits) {
        [self removeChild:bit cleanup:YES];
    }
    [_bits release];
    _bits = [[NSMutableArray alloc] init];

    const int height = 3;

    for (int col = 0; col < width; col++) {
        for (int row = 0; row < height; row++) {
            CCSprite * bit = nil;
            if (row == 0)
                bit = [CCSprite spriteWithFile:@"bacon-top.png"];
            else if (row == 1)
                bit = [CCSprite spriteWithFile:@"bacon-middle.png"];
            else if (row == 2)
                bit = [CCSprite spriteWithFile:@"bacon-bottom.png"];

            CGPoint origin = ccp(center.x - (((width  * 0.5f) - 0.5f) * (bit.contentSize.width  * _scaleFactor)),
                                 center.y + (((height * 0.5f) - 0.5f) * (bit.contentSize.height * _scaleFactor)));

            bit.scale = _scaleFactor;
            bit.position = ccp(origin.x + (col * bit.contentSize.width  * _scaleFactor),
                               origin.y - (row * bit.contentSize.height * _scaleFactor));

            [self addChild:bit z:0];
            [_bits addObject:bit];
        }
    }
}

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    // Record start of touch
    UITouch *touch = [touches anyObject];
    _touchStart = [self convertTouchToNodeSpace:touch];
}

- (void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    // Record end of touch
    CGPoint target = [self convertTouchToNodeSpace:[touches anyObject]];
    float swipeLength = ccpDistance(_touchStart, target);

    // Move the shooter to the end of a swipe
    if ([self isSwipe:swipeLength]) {
        [self moveShooter:target];
    }
    else {
        // Setup a new level, if level complete
        if (_levelComplete) {
            _level++;
            [self setupLevel];
        }
        
        // Otherwise, fire a projectile
        else
            [self fireAmmo:target];
    }
}

- (bool) isSwipe:(float)length {
    return length > _swipeMin;
}

- (void) fireAmmo:(CGPoint)end {

    // Set up initial location of projectile
    CCSprite *projectile = [CCSprite spriteWithFile:@"ammo.png"];
    projectile.scale = _scaleFactor;
    projectile.position = ccp(_shooter.position.x, _shooter.position.y + (_shooter.contentSize.width * _scaleFactor * 0.5f));

    // Bail out if you are shooting down or backwards
    CGPoint offset = ccpSub(end, projectile.position);
    if (offset.y <= 0) return;

    float destY = _winSize.height + (projectile.contentSize.height * _scaleFactor * 0.5f);
    CGPoint destination = ccp(projectile.position.x, destY);

    // Calculate duration of shot for fixed velocity
    float distance = projectile.position.y + destY;
    float velocity = 300.0f * _scaleFactor;
    float duration = distance/velocity;

    // Play sound effect
    [[SimpleAudioEngine sharedEngine] playEffect:@"boom.wav"];

    // Move projectile to actual endpoint
    [_ammo addObject:projectile];
    [self addChild:projectile];
    [projectile runAction:
        [CCSequence actions:
            [CCMoveTo actionWithDuration:duration position:destination],
            [CCCallBlockN actionWithBlock:^(CCNode *node){[_ammo removeObject:node]; [node removeFromParentAndCleanup:YES];}],
            nil]];

    projectile.tag = 2;
}

- (void) moveShooter:(CGPoint)end {

    // Cancel any in-progress actions
    [_shooter stopAllActions];

    // Determine offset of for the move (don't allow shooter to go out-of-bounds)
    CGPoint dest = ccp(max( min(end.x, _stageRect.origin.x + _stageRect.size.width),
                           _stageRect.origin.x),
                       _shooter.position.y);

    // Calculate duration of move for fixed velocity
    float distance = abs(dest.x - _shooter.position.x);
    float velocity = 300.0f * _scaleFactor;
    float duration = distance/velocity;

    // Move shooter to actual endpoint
    [_shooter runAction:
        [CCSequence actions:
            [CCMoveTo actionWithDuration:duration position:dest], nil]];
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

    // Check for falling bit collisions with shooter
    NSMutableArray *bitsToDelete = [[NSMutableArray alloc] init];
    bool shooterHit = false;
    for (CCSprite *bit in _bitsFalling) {
        if (CGRectIntersectsRect(_shooter.boundingBox, bit.boundingBox)) {
            [bitsToDelete addObject:bit];
            shooterHit = true;
        }
    }
    if (shooterHit) {
        if (_livesLeft > 0) {
            _livesLeft--;
            [_lives[_livesLeft] setVisible:false];
        }
        else {
            [self gameOver];
        }
    }
    for (CCSprite *bit in bitsToDelete) {
        [self removeChild:bit cleanup:YES];
        [_bitsFalling removeObject:bit];
    }
    [bitsToDelete release];

    // Check all fireballs in flight for collisions
    NSMutableArray *fireballsToDelete = [[NSMutableArray alloc] init];
    for (CCSprite *fireball in _ammo) {

        // Check if the current fireball has struck any bits
        NSMutableArray *bitsHit = [[NSMutableArray alloc] init];
        for (CCSprite *bit in _bits) {
            if (CGRectIntersectsRect(fireball.boundingBox, bit.boundingBox))
                [bitsHit addObject:bit];
        }

        // Start struck bits falling
        for (CCSprite *bit in bitsHit) {
            [_bits removeObject:bit];
            [_bitsFalling addObject:bit];
            _scoreValue += 100;
            _score.string = [NSString stringWithFormat:@"%d", _scoreValue];
            CGPoint destination = ccp(bit.position.x, -(bit.boundingBox.size.height * _scaleFactor));
            float length = abs(bit.position.y + destination.y);
            float velocity = 45.0f * _scaleFactor;
            float duration = length/velocity;
            [bit runAction:
                [CCSequence actions:
                    [CCMoveTo actionWithDuration:duration position:destination],
                    [CCCallBlockN actionWithBlock:^(CCNode *node){[self removeChild:node cleanup:YES];[_bitsFalling removeObject:node];}],
                    nil]];
        }

        // Mark fireball for deletion, if strike detected
        if (bitsHit.count > 0)
            [fireballsToDelete addObject:fireball];
        [bitsHit release];
    }

    // Cleanup used fireballs
    for (CCSprite *fireball in fireballsToDelete) {
        [self removeChild:fireball cleanup:YES];
        [_ammo removeObject:fireball];
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

- (void) gameOver {
    [[SimpleAudioEngine sharedEngine] playEffect:@"applause.wav"];
    _levelComplete = true;
    _messageGameOver.visible = true;
    _gameOver = true;
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
        if (size.height == 480) _scaleFactor = 0.85f; // iPhone 3.5"
        else _scaleFactor = 0.85f; // iPhone 4.0"
    }
    else
    {
        if (scale == 1.0) _scaleFactor = 1.0; // iPad
        else _scaleFactor = 2.0; // iPad-Retina
    }

    // Scale font size
    _fontSize = 24.0f * _scaleFactor;

    // Scale swipe distance
    _swipeMin = 0.05f * _winSize.width;

    // Calculate game stage bounds
    _stageRect = CGRectMake(_winSize.width  * 0.12f,
                            _winSize.height * 0.10f,
                            _winSize.width  * 0.76f,
                            _winSize.height * 0.70f);
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
