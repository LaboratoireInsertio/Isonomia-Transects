//
//  HRMViewController.h
//  HeartMonitor
//
//  Created by Main Account on 12/13/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

// Import CoreBluetooth and QuartzCore
@import CoreBluetooth;
@import QuartzCore;

// Define servises as found on Bluetooth services spesification:
// https://developer.bluetooth.org/gatt/services/Pages/ServicesHome.aspx
#define POLARH7_HRM_DEVICE_INFO_SERVICE_UUID @"180A"
#define POLARH7_HRM_HEART_RATE_SERVICE_UUID @"180D"
#define POLARH7_HRM_BATTERY_SERVICE_UUID @"180F"


// Define characteristics as found on Bluetooth characteristics specification:
// https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicsHome.aspx
#define POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID @"2A37"
#define POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID @"2A38"
#define POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID @"2A29"
#define POLARH7_HRM_BATTERY_CHARACTERISTIC_UUID @"2A19"

@interface HRMViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, NSURLConnectionDelegate>

// Properties for handling Bluetoth device
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral     *polarH7HRMPeripheral;

// Properties for your Object controls
@property (nonatomic, strong) IBOutlet UIImageView *heartImage;
@property (nonatomic, strong) IBOutlet UITextView  *deviceInfo;

// Properties to hold data characteristics for the peripheral device
@property (nonatomic, strong) NSString   *connected;
@property (nonatomic, strong) NSString   *bodyData;
@property (nonatomic, strong) NSString   *manufacturer;
@property (nonatomic, strong) NSString   *battery;
@property (nonatomic, strong) NSString   *polarH7DeviceData;
@property (assign) uint16_t heartRate;
@property uint16_t lastHearthRate;

// Properties to handle storing the BPM and heart beat
@property (nonatomic, strong) UILabel    *heartRateBPM;
@property (nonatomic, retain) NSTimer    *pulseTimer;

// Propertie to handle URL responses
@property NSMutableData *responseData;

// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error;

// Instance methods to grab device Manufacturer Name, Body Location
- (void) getManufacturerName:(CBCharacteristic *)characteristic;
- (void) getBodyLocation:(CBCharacteristic *)characteristic;

- (void) getBatteryLevel:(CBCharacteristic *)characteristic error:(NSError *)error;

// Instance method to perform heart beat animations
- (void) doHeartBeat;

@end
