//
//  BTTViewController.m
//  BluetoothTest
//
//  Created by RJ Hill on 3/29/12.
//  Copyright (c) 2012 omfgp.com. All rights reserved.
//

#import "BTTViewController.h"

@implementation BTTViewController

@synthesize connectionSession = _connectionSession;
@synthesize connectionPeers = _connectionPeers;
@synthesize connectionPicker = _connectionPicker;
@synthesize textData = _textData;
NSArray *receivedData;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    connectionPicker = [[GKPeerPickerController alloc] init];  
    connectionPicker.delegate = self;
    
    //NOTE - GKPeerPickerConnectionTypeNearby is for Bluetooth connection, you can do the same thing over Wi-Fi with different type of connection  
    connectionPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;  
    connectionPeers = [[NSMutableArray alloc] init];  
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self disconnectBT];
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - GKPeerPickerControllerDelegate

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type  
{  
    // Create a session with a unique session ID - displayName:nil = Takes the iPhone Name  
    GKSession* session = [[GKSession alloc] initWithSessionID:@"com.myapp.connect" displayName:nil sessionMode:GKSessionModePeer];  
    return session;  
}  

// Tells us that the peer was connected  
- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session  
{  
    // Get the session and assign it locally  
    self.connectionSession = session;  
    session.delegate = self;  
    
    [picker dismiss];  
}

//Method for sending data that can be used anywhere in your app  
- (void)sendData:(NSArray*)data  
{  
    NSData* encodedArray = [NSKeyedArchiver archivedDataWithRootObject:data];
    [connectionSession sendDataToAllPeers:encodedArray withDataMode:GKSendDataReliable error:nil];                            
}

#pragma mark - GKSessionDelegate  

// Function to receive data when sent from peer  
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context  
{  
    receivedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{  
    if (state == GKPeerStateConnected) {  
        // Add the peer to the Array  
        [connectionPeers addObject:peerID];  
        
        // Used to acknowledge that we will be sending data  
        [session setDataReceiveHandler:self withContext:nil];  
        
        //In case you need to do something else when a peer connects, do it here  
    }  
    else if (state == GKPeerStateDisconnected) {  
        [connectionPeers removeObject:peerID];  
        //Any processing when a peer disconnects  
    }  
}

- (BOOL)sendData:(NSData *)data toPeers:(NSArray *)peers withDataMode:(GKSendDataMode)mode error:(NSError **)error
{
    return YES;
}

- (IBAction)recData
{
    
}

- (IBAction)sendData;
{
    NSMutableArray *theArray = [[NSMutableArray alloc] init];
    [theArray addObject:self.textData.text];
    [self sendData:theArray];
    NSLog(@"Data sent: %@", self.textData.text);
}

- (IBAction)connectBT 
{  
    [connectionPicker show];
}  

- (IBAction)disconnectBT
{  
    [connectionSession disconnectFromAllPeers];  
    [connectionPeers removeAllObjects];  
}  

@end
