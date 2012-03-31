//
//  BTTViewController.h
//  BluetoothTest
//
//  Created by RJ Hill on 3/29/12.
//  Copyright (c) 2012 omfgp.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface BTTViewController : UIViewController <UIApplicationDelegate, GKSessionDelegate, GKPeerPickerControllerDelegate> {
    GKPeerPickerController *connectionPicker;  
    GKSession* connectionSession;  
    NSMutableArray *connectionPeers;  
}

@property (retain) GKSession *connectionSession;  
@property (nonatomic, retain) NSMutableArray *connectionPeers;  
@property (nonatomic, retain) GKPeerPickerController *connectionPicker;
@property (weak, nonatomic) IBOutlet UITextField *textData;

- (IBAction)recData;
- (IBAction)sendData;
- (IBAction)connectBT;
- (IBAction)disconnectBT;

@end
