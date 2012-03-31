//
//  SessionController.h
//  BluetoothTest
//
//  Created by RJ Hill on 3/30/12.
//  Copyright (c) 2012 omfgp.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface SessionController : NSObject <GKSessionDelegate>

@property(strong, nonatomic) GKSession *theSession;

@end
