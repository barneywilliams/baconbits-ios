//
//  GameLayer.h
//  baconbits-ios
//
//  Created by Greg Williams on 9/29/13.
//  Copyright Atomic Object LLC 2013. All rights reserved.
//
#import <GameKit/GameKit.h>
#import "cocos2d.h"

@interface GameLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    float _scaleFactor;
    float _fontSize;
    float _headerYOffset;
    float _swipeMin;
    int _scoreValue;
    int _livesLeft;
    int _maxLives;
    int _level;
    bool _levelComplete;
    bool _gameOver;

    CGSize _winSize;
    CGRect _stageRect;
    CGPoint _touchStart;
    CCLabelTTF * _score;
    CCLabelTTF * _message;
    CCLabelTTF * _messageGameOver;
    CCSprite * _shooter;
    NSMutableArray * _bits;
    NSMutableArray * _bitsFalling;
    NSMutableArray * _ammo;
    NSMutableArray * _lives;
}

// returns a CCScene that contains the GameLayer as the only child
+(CCScene *) scene;

- (void) configureForDevice;
- (void) setupLevel;
- (void) gameOver;
- (void) checkLevelComplete;
- (void) fireAmmo:(CGPoint)end;
- (void) moveShooter:(CGPoint)end;

@end
