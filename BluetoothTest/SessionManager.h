#import <GameKit/GameKit.h>
#import "DataHandler.h"
#import "DevicesManager.h"
#import "Device.h"

#define NOTIFICATION_DEVICE_AVAILABLE @"notif_device_available"
#define NOTIFICATION_DEVICE_UNAVAILABLE @"notif_device_unavailable"
#define NOTIFICATION_DEVICE_CONNECTED @"notif_device_connected"
#define NOTIFICATION_DEVICE_CONNECTION_FAILED @"notif_device_connection_failed"
#define NOTIFICATION_DEVICE_DISCONNECTED @"notif_device_disconnected"

#define DEVICE_KEY @"Device"

@interface SessionManager : NSObject<GKSessionDelegate> {
	GKSession *theSession;
	DevicesManager *devicesManager;
}

- (id)initWithDataHandler:(DataHandler *)handler devicesManager:(DevicesManager *)manager;
- (void)start;

@end
