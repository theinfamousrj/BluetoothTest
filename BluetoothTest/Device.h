#import <GameKit/GameKit.h>

@interface Device : NSObject {
	GKSession *session;
	
	NSString *peerID;
	NSString *deviceName;
	
	id delegateToCallAboutConnection;
	SEL selectorToPerformWhenConnectionWasStablished;
	SEL selectorToPerformWhenConnectionWasNotStablished;
}

- (id)initWithSession:(GKSession *)openSession peer:(NSString *)peerID;

- (void)connectAndReplyTo:(id)delegate selector:(SEL)connectionStablishedConnection errorSelector:(SEL)connectionNotStablishedConnection;
- (void)disconnect;
- (void)cancelConnection;

- (BOOL)isConnected;

- (BOOL)sendData:(NSData *)data error:(NSError **)error;

@property (nonatomic, readonly) NSString *peerID;
@property (nonatomic, readonly) NSString *deviceName;

@end
