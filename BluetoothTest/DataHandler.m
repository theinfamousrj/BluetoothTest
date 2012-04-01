#import "DataHandler.h"

#define BEAM_IT_REQUESTING_PERMISSION_TO_SEND @"SEND"
#define BEAM_IT_ACCEPT_CONTACT @"ACPT"
#define BEAM_IT_REJECT_CONTACT @"RJCT"
#define BEAM_IT_INFO_SIZE @"SIZE"
#define BEAM_IT_ACKNOWLEDGE @"ACKN"
#define BEAM_IT_SUCCESS @"SUCS"
#define BEAM_IT_I_AM_BUSY @"BUSY"
#define BEAM_IT_ERROR @"ERRO"
#define BEAM_IT_CANCEL @"CNCL"

#define PROCESSING_TAG 0
#define CONFIRMATION_RETRY_TAG 1
#define CONFIRMATION_RECEIVE_TAG 2

#define ERROR_SOUND_FILE_NAME "error"
#define RECEIVED_SOUND_FILE_NAME "received"
#define REQUEST_SOUND_FILE_NAME "request"
#define SEND_SOUND_FILE_NAME "sent"

@interface DataHandler ()

- (void)loadSounds;

- (NSData *)dataFromString:(NSString *)str;

- (NSString *)getCommandFromMessage:(NSData *)message;
- (NSString *)getValueFromMessage:(NSData *)message;

- (void)handleReceivingData:(NSData *)data;
- (void)handleSendingData:(NSData *)data;

- (void)sendErrorData;
- (void)sendCancelData;
- (void)sendBusyData:(Device *)device;
- (void)sendRequestData;
- (void)sendAcceptData;
- (void)sendRejectData;
- (void)sendSizeData;
- (void)sendAcknowledgeData;
- (void)sendSuccessData;
- (void)sendRealData;

- (void)throwUnexpectedCommandError;
- (void)throwError:(NSString *)message;
- (void)cleanCurrentState;
- (void)closeCurrentPopup;

- (void)updateLastCommandReceived:(NSString *)command;

- (void)showMessageWithTitle:(NSString *)title message:(NSString *)msg;
- (void)promptConfirmationWithTag:(int)tag title:(NSString *)title message:(NSString *)msg;
- (void)showProcess:(NSString *)message;

- (void)deviceConnected;

@end

@implementation DataHandler

- (id)initWithDataProvider:(NSObject<DataProvider> *)provider devicesManager:(DevicesManager *)manager {
	self = [super init];
	
	if (self) {
		currentState = DHSNone;
		
		dataProvider = provider;
		
		devicesManager = manager;
	}
	
	[self loadSounds];
	
	return self;
}

- (void)sendToDevice:(Device *)device {
	// Called from the main ViewController when someone selects a device on the table
	
	// Sets the DataHandler to occupied
	currentState = DHSSending;
	currentStateRelatedDevice = device;
	
	// When the Provider gets the data to send properly (eg. a contact), the dataPrepared method will be called
	[dataProvider prepareDataAndReplyTo:self selector:@selector(dataPrepared)];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context {
	// Caller whenever data is received from the session
	
	Device *device = [devicesManager deviceWithID:peer];
	
	if (device) {
		// Checks if it's busy, otherwise call other handler methods
		switch (currentState) {
			case DHSNone:
				currentState = DHSReceiving;
				currentStateRelatedDevice = device;
				
				[self handleReceivingData:data];
				break;
			case DHSReceiving:
				if (![currentStateRelatedDevice isEqual:device] || [[self getCommandFromMessage:data] isEqual:BEAM_IT_REQUESTING_PERMISSION_TO_SEND]) {
					[self sendBusyData:device];
				} else {
					[self handleReceivingData:data];
				}
				break;
			case DHSSending:
				if (![currentStateRelatedDevice isEqual:device] || [[self getCommandFromMessage:data] isEqual:BEAM_IT_REQUESTING_PERMISSION_TO_SEND]) {
					[self sendBusyData:device];
				} else {
					[self handleSendingData:data];
				}
				break;
			default:
				break;
		}
	}
}

- (NSString *)getCommandFromMessage:(NSData *)message {
	// The 4 first bytes of the message represent the command
	NSString *strMsg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
	return [strMsg substringToIndex:4];
}

- (NSString *)getValueFromMessage:(NSData *)message {
	// All the data after the first 4 bytes are considered the value
	NSString *strMsg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
	return [strMsg substringFromIndex:4];
}

- (void)updateLastCommandReceived:(NSString *)command {
	if (lastCommandReceived)
	lastCommandReceived = [command copy];
}

- (void)handleReceivingData:(NSData *)data {
	NSString *command = [self getCommandFromMessage:data];
	
	// First, check for specific error situations
	if ([command isEqual:BEAM_IT_ERROR]) {
		[self throwError:[NSString stringWithFormat:NSLocalizedString(@"RECEIVED_ERROR_ERROR", @"Received an error message"), 
						  currentStateRelatedDevice.deviceName]];
	} else if ([command isEqual:BEAM_IT_CANCEL]) {
		[self throwError:[NSString stringWithFormat:NSLocalizedString(@"PEER_CANCELLED_ERROR", @"Transfer cancelled"),
						  currentStateRelatedDevice.deviceName]];
	} else if ([command isEqual:BEAM_IT_I_AM_BUSY]) {
		[self throwError:[NSString stringWithFormat:NSLocalizedString(@"RECEIVED_BUSY_ERROR", @"Receiver is busy"),
						  currentStateRelatedDevice.deviceName]];
	} else {
		// If it's not an error, then let's check the command and compare it to the last command received to check if the command is expected
		if (!lastCommandReceived) {
			if (![command isEqual:BEAM_IT_REQUESTING_PERMISSION_TO_SEND]) {
				[self sendErrorData];
				[self throwUnexpectedCommandError];
			} else {
				// Prompt the user whether to receive the contact or not
				[self promptConfirmationWithTag:CONFIRMATION_RECEIVE_TAG 
										  title:NSLocalizedString(@"RECEIVE_VIEW_TITLE", @"Dialog title when receiving data")
										message:[NSString stringWithFormat:NSLocalizedString(@"RECEIVE_VIEW_PROMPT", @"Dialog text when receiving data"),
												 currentStateRelatedDevice.deviceName, [self getValueFromMessage:data]]];
				[self updateLastCommandReceived:command];
			}
		} else if ([lastCommandReceived isEqual:BEAM_IT_REQUESTING_PERMISSION_TO_SEND]) {
			if (![command isEqual:BEAM_IT_INFO_SIZE]) {
				[self sendErrorData];
				[self throwUnexpectedCommandError];
			} else {
				bytesToReceive = [[self getValueFromMessage:data] intValue];
				[self sendAcknowledgeData];

				[self updateLastCommandReceived:command];
			}
		} else if ([lastCommandReceived isEqual:BEAM_IT_INFO_SIZE]) {
			// Check whether the data has the expected size
			if (bytesToReceive == [data length]) {
				// Receive the real data (eg. contact) and tell the provider to store it
				BOOL dataCanBeStored = [dataProvider storeData:data andReplyTo:self selector:@selector(dataStored)];
				
				if (dataCanBeStored) {
					[self sendSuccessData];
					[self closeCurrentPopup];
				} else {
					[self sendErrorData];
					[self throwError:[NSString stringWithFormat:NSLocalizedString(@"RECEPTION_ERROR", @"Error receiving data"), 
									  currentStateRelatedDevice.deviceName]];
				}
				
			} else {
				[self sendErrorData];
				[self throwError:[NSString stringWithFormat:NSLocalizedString(@"RECEPTION_ERROR", @"Error receiving data"), 
								  currentStateRelatedDevice.deviceName]];
			}
		} else {
			[self sendErrorData];
			[self throwUnexpectedCommandError];
		}
	}
}

- (void)dataStored {
	[self cleanCurrentState];
}

- (void)handleSendingData:(NSData *)data {
	NSString *command = [self getCommandFromMessage:data];
	
	// First, check for specific error situations
	if ([command isEqual:BEAM_IT_ERROR]) {
		[self throwError:[NSString stringWithFormat:NSLocalizedString(@"RECEIVED_ERROR_ERROR", @"Received an error message"), 
						  currentStateRelatedDevice.deviceName]];
	} else if ([command isEqual:BEAM_IT_CANCEL]) {
		[self throwError:[NSString stringWithFormat:NSLocalizedString(@"PEER_CANCELLED_ERROR", @"Transfer cancelled"), 
						  currentStateRelatedDevice.deviceName]];
	} else if ([command isEqual:BEAM_IT_I_AM_BUSY]) {
		[self throwError:[NSString stringWithFormat:NSLocalizedString(@"RECEIVED_BUSY_ERROR", @"Receiver is busy"), 
						  currentStateRelatedDevice.deviceName]];
	} else {
		// If it's not an error, then let's check the command and compare it to the last command received to check if the command is expected
		if (!lastCommandReceived) {
			if ([command isEqual:BEAM_IT_ACCEPT_CONTACT]) {
				[self sendSizeData];

				[self updateLastCommandReceived:command];
			} else if ([command isEqual:BEAM_IT_REJECT_CONTACT]) {
				// Prompt the user whether to retry to send or not
				[self promptConfirmationWithTag:CONFIRMATION_RETRY_TAG 
										  title:NSLocalizedString(@"RETRY_VIEW_TITLE", @"Transfer refused dialog title")
										message:[NSString stringWithFormat:NSLocalizedString(@"RETRY_VIEW_PROMPT", @"Transfer refused dialog text"),
												 currentStateRelatedDevice.deviceName, [dataProvider getLabelOfDataToSend]]];
			} else {
				[self sendErrorData];
				[self throwUnexpectedCommandError];
			}
		} else if ([lastCommandReceived isEqual:BEAM_IT_ACCEPT_CONTACT]) {
			if (![command isEqual:BEAM_IT_ACKNOWLEDGE]) {
				[self sendErrorData];
				[self throwUnexpectedCommandError];
			} else {
				[self sendRealData];

				[self updateLastCommandReceived:command];
			}
		} else if ([lastCommandReceived isEqual:BEAM_IT_ACKNOWLEDGE]) {
			if (![command isEqual:BEAM_IT_SUCCESS]) {
				[self sendErrorData];
				[self throwUnexpectedCommandError];
			} else {
				[self showMessageWithTitle:NSLocalizedString(@"SUCCESS_VIEW_TITLE", @"Transfer completed dialog title.")
								   message:[NSString stringWithFormat:NSLocalizedString(@"SEND_SUCCESS_MESSAGE", @"Transfer completed dialog text."),
											[dataProvider getLabelOfDataToSend], currentStateRelatedDevice.deviceName]];
				[self cleanCurrentState];
			}
		} else {
			[self sendErrorData];
			[self throwUnexpectedCommandError];
		}
	}	
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == CONFIRMATION_RECEIVE_TAG) {
		if (buttonIndex == 1) { // YES
			[self closeCurrentPopup];
			[self sendAcceptData];
		} else { // NO
			[self closeCurrentPopup];
			[self sendRejectData];
			[self cleanCurrentState];
		}
	} else if (alertView.tag == CONFIRMATION_RETRY_TAG) {
		if (buttonIndex == 1) { // YES
			[self closeCurrentPopup];
			[self sendRequestData];
		} else { // NO
			[self cleanCurrentState];
		}
	} else if (alertView.tag == PROCESSING_TAG) {
		// Clicked on CANCEL
		
		[self closeCurrentPopup];
		
		if ([currentStateRelatedDevice isConnected])
			[self sendCancelData];

		[self cleanCurrentState];
	}
}

- (NSData *)dataFromString:(NSString *)str {
	return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)sendBusyData:(Device *)device {
	[device sendData:[self dataFromString:BEAM_IT_I_AM_BUSY] error:nil];
}

- (void)sendCancelData {
	[currentStateRelatedDevice sendData:[self dataFromString:BEAM_IT_CANCEL] error:nil];
}

- (void)sendErrorData {
	[currentStateRelatedDevice sendData:[self dataFromString:BEAM_IT_ERROR] error:nil];
}

- (void)sendRequestData {
	[self showProcess:[NSString stringWithFormat:NSLocalizedString(@"WAITING_FOR_ACCEPTANCE_PROCESS", @"Waiting for acceptance"), 
					   currentStateRelatedDevice.deviceName]];
	NSString *strToSend = [NSString stringWithFormat:@"%@%@", BEAM_IT_REQUESTING_PERMISSION_TO_SEND, [dataProvider getLabelOfDataToSend]];
	[currentStateRelatedDevice sendData:[self dataFromString:strToSend] error:nil];
}

- (void)sendSizeData {
	[self showProcess:NSLocalizedString(@"SENDING_PROCESS", @"Sending data dialog")];
	NSString *strToSend = [NSString stringWithFormat:@"%@%d", BEAM_IT_INFO_SIZE, [[dataProvider getDataToSend] length]];
	[currentStateRelatedDevice sendData:[self dataFromString:strToSend] error:nil];
}

- (void)sendAcceptData {
	[currentStateRelatedDevice sendData:[self dataFromString:BEAM_IT_ACCEPT_CONTACT] error:nil];
}

- (void)sendRejectData {
	[currentStateRelatedDevice sendData:[self dataFromString:BEAM_IT_REJECT_CONTACT] error:nil];
}

- (void)sendAcknowledgeData {
	[self showProcess:NSLocalizedString(@"RECEIVING_PROCESS", @"Receiving data dialog")];
	[currentStateRelatedDevice sendData:[self dataFromString:BEAM_IT_ACKNOWLEDGE] error:nil];
}

- (void)sendSuccessData {
	[currentStateRelatedDevice sendData:[self dataFromString:BEAM_IT_SUCCESS] error:nil];
}

- (void)sendRealData {
	[self showProcess:NSLocalizedString(@"SENDING_PROCESS", @"Sending data dialog")];
	[currentStateRelatedDevice sendData:[dataProvider getDataToSend] error:nil];
}

- (void)dataPrepared {
	[self showProcess:NSLocalizedString(@"CONNECTION_PROCESS", @"Connecting dialog")];
	
	if (![currentStateRelatedDevice isConnected])
		[currentStateRelatedDevice connectAndReplyTo:self selector:@selector(deviceConnected) errorSelector:@selector(deviceConnectionFailed)];
	else
		[self deviceConnected];
}

- (void)deviceConnected {
	[self sendRequestData];
}

- (void)deviceConnectionFailed {
	[self throwError:[NSString stringWithFormat:NSLocalizedString(@"CONNECTION_ERROR", "Error when connecting to peer"), 
					  currentStateRelatedDevice.deviceName]];
}

- (void)throwUnexpectedCommandError {
	[self throwError:[NSString stringWithFormat:NSLocalizedString(@"UNEXPECTED_COMMAND_ERROR", @"Received unexpected command"), 
					  currentStateRelatedDevice.deviceName]];
}

- (void)showMessageWithTitle:(NSString *)title message:(NSString *)msg {
	[self closeCurrentPopup];

	UIAlertView *confirmationView = [[UIAlertView alloc] initWithTitle:title
															   message:msg
															  delegate:nil
													 cancelButtonTitle:@"OK"
													 otherButtonTitles:nil];
	
	[confirmationView show];
}

- (void)throwError:(NSString *)message {
	[self showMessageWithTitle:NSLocalizedString(@"ERROR_VIEW_TITLE", @"Error dialog title") message:message];
	[self cleanCurrentState];
}

- (void)cleanCurrentState {
	currentState = DHSNone;
	
	if (currentStateRelatedDevice) {
		currentStateRelatedDevice = nil;
	}
	
	if (lastCommandReceived) {
		lastCommandReceived = nil;
	}
	
	bytesToReceive = 0;
	
	[self closeCurrentPopup];
}

- (void)closeCurrentPopup {
	if (currentPopUpView) {
		currentPopUpView.delegate = nil;
		[currentPopUpView dismissWithClickedButtonIndex:0 animated:YES];
		currentPopUpView = nil;
	}
}

- (void)promptConfirmationWithTag:(int)tag title:(NSString *)title message:(NSString *)msg {
	[self closeCurrentPopup];
	
	currentPopUpView = [[UIAlertView alloc] initWithTitle:title
												  message:msg
												 delegate:self
										cancelButtonTitle:@"No"
										otherButtonTitles:@"Yes", nil];
	currentPopUpView.tag = tag;
	
	[currentPopUpView show];
}

- (void)showProcess:(NSString *)message {
	[self closeCurrentPopup];
	
	currentPopUpView = [[UIAlertView alloc] initWithTitle:message
												  message:@"\n\n"
												 delegate:self
										cancelButtonTitle:@"Cancel"
										otherButtonTitles:nil];
	
	currentPopUpView.tag = PROCESSING_TAG;

	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc]
											 initWithFrame:CGRectMake(130, 60, 20, 20)];
	[activityView startAnimating];
	[currentPopUpView addSubview:activityView];
	
	[currentPopUpView show];
}

@end
