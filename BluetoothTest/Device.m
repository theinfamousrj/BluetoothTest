#import "Device.h"
#import "SessionManager.h"

#define CONNECTION_TIMEOUT 30

@implementation Device

@synthesize deviceName;
@synthesize peerID;

- (id)initWithSession:(GKSession *)openSession peer:(NSString *)ID {
	self = [super init];
	if (self) {
		session = openSession;
		
		peerID = [ID copy];
		deviceName = [[session displayNameForPeer:peerID] copy];
	}
    
	return self;
}

- (BOOL)isEqual:(id)object {
	// Basically, compares the peerIDs
	return object && ([object isKindOfClass:[Device class]]) && ([((Device *) object).peerID isEqual:peerID]);
}

- (void)connectAndReplyTo:(id)delegate selector:(SEL)connectionStablishedConnection errorSelector:(SEL)connectionNotStablishedConnection {
	// We need to persist this info, because the call to connect is assynchronous.
	delegateToCallAboutConnection = delegate;
	selectorToPerformWhenConnectionWasStablished = connectionStablishedConnection;
	selectorToPerformWhenConnectionWasNotStablished = connectionNotStablishedConnection;
	
	// The SessionManager will be responsible for sending the notification that will be caught here.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerConnectionSuccessfull:) name:NOTIFICATION_DEVICE_CONNECTED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerConnectionFailed:) name:NOTIFICATION_DEVICE_CONNECTION_FAILED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerConnectionFailed:) name:NOTIFICATION_DEVICE_UNAVAILABLE object:nil];

	[session connectToPeer:peerID withTimeout:CONNECTION_TIMEOUT];
}

- (void)triggerConnectionSuccessfull:(NSNotification *)notification {
	Device *device = [notification.userInfo objectForKey:DEVICE_KEY];
	
	if ([self isEqual:device] && delegateToCallAboutConnection &&
		[delegateToCallAboutConnection respondsToSelector:selectorToPerformWhenConnectionWasStablished]) {
		[delegateToCallAboutConnection performSelector:selectorToPerformWhenConnectionWasStablished];

		delegateToCallAboutConnection = nil;
		selectorToPerformWhenConnectionWasStablished = nil;
		selectorToPerformWhenConnectionWasNotStablished = nil;
	}
}

- (void)triggerConnectionFailed:(NSNotification *)notification {
	Device *device = [notification.userInfo objectForKey:DEVICE_KEY];
	
	if ([self isEqual:device] && delegateToCallAboutConnection &&
		[delegateToCallAboutConnection respondsToSelector:selectorToPerformWhenConnectionWasNotStablished]) {
		[delegateToCallAboutConnection performSelector:selectorToPerformWhenConnectionWasNotStablished];

		delegateToCallAboutConnection = nil;
		selectorToPerformWhenConnectionWasStablished = nil;
		selectorToPerformWhenConnectionWasNotStablished = nil;
	}
}

- (void)disconnect {
	[session disconnectPeerFromAllPeers:peerID];
}

- (void)cancelConnection {
	[session cancelConnectToPeer:peerID];
}

- (BOOL)isConnected {
	// Checks if this device is in the Sessions Connected List
	NSArray *peers = [session peersWithConnectionState:GKPeerStateConnected];
	
	BOOL found = NO;
	
	for (NSString *p in peers) {
		if ([p isEqual:peerID]) {
			found = YES;
			break;
		}
	}
	
	return found;
}

- (BOOL)sendData:(NSData *)data error:(NSError **)error {
	return [session sendData:data toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:error];
}

@end