/*
 
 File: DataHandler.h
 Abstract: Concentrates the management of the messages related to the application specific protocol. It retrieves the data to send and store from the DataProvider.
		   This is and example of the protocol (4 first bytes = command):
 
		   Peer A -> SENDFoo bar
		   Peer B -> ACPT
		   Peer A -> SIZE8
		   Peer B -> ACKN
		   Peer A -> Beam It!
		   Peer B -> SUCS
 
		   Refer to DataHandler.m for more details.
*/

#import "DataProvider.h"
#import "DevicesManager.h"
#import "Device.h"

typedef enum
{
	DHSNone,
	DHSReceiving,
	DHSSending
} DataHandlerState;

@interface DataHandler : NSObject {
	DataHandlerState currentState;
	Device *currentStateRelatedDevice;
	NSString *lastCommandReceived;
	
	DevicesManager *devicesManager;

	UIAlertView *currentPopUpView;
	
	int bytesToReceive;
	
	NSObject<DataProvider> *dataProvider;
}

- (id)initWithDataProvider:(NSObject<DataProvider> *)provider devicesManager:(DevicesManager *)manager;
- (void)sendToDevice:(Device *)device;
- (void)dataStored;

@end