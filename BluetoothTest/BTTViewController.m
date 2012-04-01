//
//  BTTViewController.m
//  BluetoothTest
//
//  Created by RJ Hill on 3/29/12.
//  Copyright (c) 2012 omfgp.com. All rights reserved.
//

#import "BTTViewController.h"
#import "Device.h"

@implementation BTTViewController

@synthesize connectionSession = _connectionSession;
@synthesize connectionPeers = _connectionPeers;
@synthesize connectionPicker = _connectionPicker;
@synthesize receivedText = _receivedText;
@synthesize sentText = _sentText;

NSString *receivedData;
NSString *userName;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    _connectionPicker = [[GKPeerPickerController alloc] init];  
    _connectionPicker.delegate = self;

    //NOTE - GKPeerPickerConnectionTypeNearby is for Bluetooth connection, you can do the same thing over Wi-Fi with different type of connection  
    _connectionPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;  
    _connectionPeers = [[NSMutableArray alloc] init];  
}

- (void)viewDidUnload
{
    [self setReceivedText:nil];
    [self setSentText:nil];
    [super viewDidUnload];
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
    [self.connectionSession setDataReceiveHandler:self withContext:NULL];
    
    [picker dismiss];  
}  

//Method for sending data that can be used anywhere in your app  
- (void)sendData:(NSString*)data  
{  
    [self appendText:data];
    NSData* theData = [data dataUsingEncoding:NSASCIIStringEncoding];
    [_connectionSession sendDataToAllPeers:theData withDataMode:GKSendDataReliable error:nil];                           
}

#pragma mark - GKSessionDelegate  

// Function to receive data when sent from peer  
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context  
{  
    NSString* theData = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    [self appendText:theData];
    [self recData];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {  
    if (state == GKPeerStateConnected) {  
        // Add the peer to the Array  
        [_connectionPeers addObject:peerID];  
        
        // Used to acknowledge that we will be sending data  
        [session setDataReceiveHandler:self withContext:nil];
        
        [self appendText:@"Conversation connected..."];
        
        //In case you need to do something else when a peer connects, do it here  
    }  
    else if (state == GKPeerStateDisconnected) {  
        [self.connectionPeers removeObject:peerID];  
        //Any processing when a peer disconnects  
    }  
}

- (void)appendText:(NSString *)text
{
    NSString* concat = [NSString stringWithFormat:@"%@\n%@", receivedData, text];
    receivedData = [concat copy];
    [self refreshText];
}

- (void)refreshText
{
    self.receivedText.text = receivedData;
}

#pragma mark IBActions

- (IBAction)setUser:(UIBarButtonItem*)sender
{
    userName = self.sentText.text;
    //NSLog(@"userName is now: %@", userName);
    self.sentText.text = @"";
    sender.title = userName;
    sender.enabled = NO;
}

- (IBAction)recData
{
    [self refreshText];
    //NSLog(@"Data received: %@", receivedData);
}

- (IBAction)sendData;
{
    NSString *theData = [NSString stringWithFormat:@"%@: %@", userName, self.sentText.text];
    [self sendData:theData];
    //NSLog(@"Data sent: %@", theData);
    self.sentText.text = @"";
}

- (IBAction)connectBT 
{  
    [_connectionPicker show];
}  

- (IBAction)disconnectBT
{  
    [_connectionSession disconnectFromAllPeers];
    [_connectionPeers removeAllObjects];
}  

@end
