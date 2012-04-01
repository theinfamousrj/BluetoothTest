//
//  BTTViewController.h
//  BluetoothTest
//
//  Created by RJ Hill on 3/29/12.
//  Copyright (c) 2012 omfgp.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface BTTViewController : UIViewController <UIApplicationDelegate, GKSessionDelegate, GKPeerPickerControllerDelegate>

@property (retain) GKSession* connectionSession;  
@property (nonatomic, retain) NSMutableArray *connectionPeers;  
@property (nonatomic, retain) GKPeerPickerController* connectionPicker;  
@property (weak, nonatomic) IBOutlet UILabel *receivedText;
@property (weak, nonatomic) IBOutlet UITextField *sentText;

- (IBAction)recData;
- (IBAction)sendData;
- (IBAction)connectBT;
- (IBAction)disconnectBT;
- (IBAction)setUser:(UIBarButtonItem*)sender;

@end
