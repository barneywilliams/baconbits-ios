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
    float _fontSize;
    float _headerYOffset;
    float _xMin, _xMax, _yMin, _yMax;
    float _swipeMin;
    int _scoreValue;
    bool _levelComplete;

    CGSize _winSize;
    CGPoint _touchStart;
    CCLabelTTF * _score;
    CCLabelTTF * _message;
    CCSprite * _shooter;
    NSMutableArray * _bits;
    NSMutableArray * _ammo;
    NSMutableArray * _lives;
}

// returns a CCScene that contains the GameLayer as the only child
+(CCScene *) scene;

- (void) configureForDevice;
- (void) setupLevel;
- (void) checkLevelComplete;
- (void) fireAmmo:(CGPoint)end;
- (void) moveShooter:(CGPoint)end;

@end
