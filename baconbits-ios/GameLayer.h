//
//  GameLayer.h
//  baconbits-ios
//
//  Created by Greg Williams on 9/29/13.
//  Copyright Atomic Object LLC 2013. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface GameLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    float _scaleFactor;
    int _fontSize;
    float _headerYOffset;
    float _xMin, _xMax, _yMin, _yMax;
    CGSize _winSize;
    CCLabelTTF * _score;
    int _scoreValue;
    bool _levelComplete;
    CCSprite * _shooter;
    NSMutableArray * _bits;
    NSMutableArray * _ammo;
    NSMutableArray * _lives;
    CGPoint _touchStart;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

- (void) configureForDevice;

// Rescales an image
- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize;

// Indicates if the latest touch is a swipe (vs a tap)
- (bool) isSwipe:(float)length;

// Fires a projectile towards the point
- (void) fireAmmo:(CGPoint)end;

// Moves the shooter to the point
- (void) moveShooter:(CGPoint)end;

- (void) checkLevelComplete;

@end
