//
//  HRMViewController.m
//  HeartMonitor
//
//  Created by Main Account on 12/13/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//
//  http://www.raywenderlich.com/52080/introduction-core-bluetooth-building-heart-rate-monitor
//

#import "HRMViewController.h"

@interface HRMViewController ()

@end

@implementation HRMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.polarH7DeviceData = nil;
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [self.heartImage setImage:[UIImage imageNamed:@"HeartImage"]];
    
    // Clear out textView
    [self.deviceInfo setText:@""];
    [self.deviceInfo setTextColor:[UIColor blackColor]];
    [self.deviceInfo setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [self.deviceInfo setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:12]];
    [self.deviceInfo setUserInteractionEnabled:NO];
    
    // Create your Heart Rate BPM Label
    self.heartRateBPM = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 75, 50)];
    [self.heartRateBPM setTextColor:[UIColor blackColor]];
    [self.heartRateBPM setText:[NSString stringWithFormat:@"%i", 0]];
    [self.heartRateBPM setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:28]];
    //[self.heartImage addSubview:self.heartRateBPM];
    
    // Scan for all available CoreBluetooth LE devices
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager = centralManager;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    NSLog(@"%@", self.connected);
    
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        NSLog(@"Found the heart rate monitor: %@", localName);
        [self.centralManager stopScan];
        self.polarH7HRMPeripheral = peripheral;
        peripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
        
    }
    
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        
        //NSArray *services = @[[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID], [CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]];
        //[self.centralManager scanForPeripheralsWithServices:services options:nil];
        
        //NSArray *services = @[[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID],[CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]];
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];

    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
    
}


#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // 1. First, check if the service is the the heart rate service.
    if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]])  {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            // Request heart rate notifications
            // 2. If so, iterate through the characteristics array and determine if the characteristic is a heart rate notification characteristic. If so, you subscribe to this characteristic, which tells CBCentralManager to watch for when this characteristic changes and notify your code using setNotifyValue:forCharacteristic when it does.
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID]]) {
                [self.polarH7HRMPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found heart rate measurement characteristic");
            }
            // Request body sensor location
            // 3. If the characteristic is the body location characteristic, there is no need to subscribe to it (as it won’t change), so just read this value.
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID]]) {
                [self.polarH7HRMPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found body sensor location characteristic");
            }
        }
    }
    
    // Retrieve Device Information Services for the Manufacturer Name
    // 4. If the service is the device info service, look for the manufacturer name and read it.
    if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]])  {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
                [self.polarH7HRMPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a device manufacturer name characteristic");
            }
        }
    }
    
    // Retrive battery information
    if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BATTERY_SERVICE_UUID]])  {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BATTERY_CHARACTERISTIC_UUID]]) {
                [self.polarH7HRMPeripheral readValueForCharacteristic:aChar];
                [self.polarH7HRMPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a battery characteristic");
            }
        }
    }
    
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Updated value for heart rate measurement received
    // 1. First check that a notification has been received to read heart rate BPM information. If so, call your instance method getHeartRateBPM:characteristic error: and pass in the value of the characteristic.
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID]]) {
        // Get the Heart Rate Monitor BPM
        [self getHeartBPMData:characteristic error:error];
    }
    // Retrieve the characteristic value for manufacturer name received
    // 2. Next, check if a notification has been received to obtain the manufacturer name of the device. If so, call your instance method getManufacturerName:characteristic: and pass in the characteristic value.
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
        [self getManufacturerName:characteristic];
    }
    // Retrieve the characteristic value for the body sensor location received
    // 3. Check if a notification has been received to determine the location of the device on the body. If so, call your instance method getBodyLocation:characteristic: and pass in the characteristic value.
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID]]) {
        [self getBodyLocation:characteristic];
    }
    
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BATTERY_CHARACTERISTIC_UUID]]) {
        [self getBatteryLevel:characteristic error:error];
    }
    
    // Add your constructed device information to your UITextView
    // 4. Finally, concatenate each of your values and output them to your UITextView control.
    self.deviceInfo.text = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n", self.heartRateBPM.text, self.connected, self.battery, self.bodyData, self.manufacturer];
    
    // if new value is diferent from last value then
    if (self.heartRate != self.lastHearthRate) {
        // Sends data to server trough HTTP POST
        [self updateServer];
        //NSLog(@"Upload!");
    } //else {
        //NSLog(@"Didn't");
    //}
    
}

- (void)updateServer
{
    // Fils the three values
    // Map function:
    // newValue = outStart + (outEnd - outStart) * ((value - inStart) / (inEnd - inStart));
    // As shown here:
    // http://stackoverflow.com/questions/10696794/objective-c-map-one-number-range-to-another
    CGFloat const inMin = 50.0;
    CGFloat const inMax = 200.0;
    CGFloat in = self.heartRate;
    
    CGFloat const outMin1 = 0.0;
    CGFloat const outMax1 = 10000.0;
    CGFloat out1 = outMin1 + (outMax1 - outMin1) * (in - inMin) / (inMax - inMin);
    unsigned int lux = out1;
    
    CGFloat const outMin2 = 0.0;
    CGFloat const outMax2 = 1500.0;
    CGFloat out2 = outMin2 + (outMax2 - outMin2) * (in - inMin) / (inMax - inMin);
    unsigned int con = out2;
    
    unsigned int flo = self.heartRate;
    
    // Sends data to server
    // Esto también ayudó un montón:
    // http://www.cimgf.com/2010/02/12/accessing-the-cloud-from-cocoa-touch/
    NSString *dataString = [NSString stringWithFormat:@"{C:%u,F:%u,L:%u}", con, flo, lux];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://p-al.co/jaime/vitrinaqc/post.php"]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
    
    [request setValue:[NSString stringWithFormat:@"%d", [dataString length]] forHTTPHeaderField:@"Content-length"];
    
    [request setHTTPBody:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    NSLog(@"%@", dataString);
    
    
    // ---------------------------------------------------------------------------------------
    // El ejemplo que si sirvió:
    // http://codewithchris.com/tutorial-how-to-use-ios-nsurlconnection-by-example/
    
    // Send a synchronous request
    /*
     NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://p-al.co/jaime/vitrinaqc/L.php"]];
     NSURLResponse * response = nil;
     NSError * error = nil;
     NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest
     returningResponse:&response
     error:&error];
     
     if (error == nil)
     {
     // Parse data here
     
     // Converts bytes in data (NSData) to readable string (NSString)!
     NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
     
     // Prints result.
     NSLog(@"Response: %@", result);
     }
     */
    
    /*
     NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://p-al.co/jaime/vitrinaqc/post.php"]];
     
     [request setHTTPMethod:@"POST"];
     [request setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
     
     NSString *dataString = @"{C:10,F:10,L:10}";
     
     [request setValue:[NSString stringWithFormat:@"%d", [dataString length]] forHTTPHeaderField:@"Content-length"];
     
     [request setHTTPBody:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
     
     [[NSURLConnection alloc] initWithRequest:request delegate:self];
     */
    
    // esto de pronto también ayudó
    // https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/WorkingWithHTTPAndHTTPSRequests/WorkingWithHTTPAndHTTPSRequests.html
    // https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/Tasks/UsingNSURLConnection.html
    
    // ---------------------------------------------------------------------------------------
    
}


#pragma mark - CBCharacteristic helpers

// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Get the Heart Rate Monitor BPM
    // 1. Convert the contents of your characteristic value to a data object. Next, get the byte sequence of your data object and assign this to your reportData object. Then initialize your bpm variable which will store the heart rate information.
    NSData *data = [characteristic value];
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    // 2. Next, obtain the first byte at index 0 in the array as defined by reportData[0] and mask out all but the 1st bit. The result returned will either be 0, which means that the 2nd bit is not set, or 1 if it is set. If the 2nd bit is not set, retrieve the BPM value at the second byte location at index 1 in the array.
    if ((reportData[0] & 0x01) == 0) {
        // Retrieve the BPM value for the Heart Rate Monitor
        bpm = reportData[1];
    }
    // 3. If the second bit is set, retrieve the BPM value at second byte location at index 1 in the array and convert this to a 16-bit value based on the host’s native byte order.
    else {
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    // Display the heart rate value to the UI if no error occurred
    // 4. Output the value of bpm to your heartRateBPM UILabel control, and set the fontName and fontSize. Assign the value of bpm to heartRate, and again set the control’s font type and size. Finally, set up a timer object [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeat) userInfo:nil repeats:NO]; which calls doHeartBeat:at 60-second intervals; this performs the basic animation that simulates the beating of a heart through the use of Core Animation.
    if( (characteristic.value)  || !error ) {
        self.lastHearthRate = self.heartRate;
        self.heartRate = bpm;
        self.heartRateBPM.text = [NSString stringWithFormat:@"%i bpm", bpm];
        self.heartRateBPM.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:28];
        [self doHeartBeat];
        self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeat) userInfo:nil repeats:NO];
    }
    return;
    
}

// Instance method to get the manufacturer name of the device
- (void) getManufacturerName:(CBCharacteristic *)characteristic
{
    // 1. Take the value of the characteristic discovered by your peripheral to obtain the manufacturer name. Use initWithData: to return the contents of your characteristic object as a data object and tell NSString that you want to use NSUTF8StringEncoding so it can be interpreted as a valid string.
    NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    // 2. Next, assign the value of the manufacturer name to self.manufacturer so that you can display this value in your UITextView control.
    self.manufacturer = [NSString stringWithFormat:@"Manufacturer: %@", manufacturerName];
    return;
    
}

// Instance method to get the body location of the device
- (void) getBodyLocation:(CBCharacteristic *)characteristic
{
    // 1. Use the value of the characteristic discovered by your peripheral to obtain the heart rate monitor’s body location. Next, convert the characteristic value to a data object consisting of byte sequences and assign this to your bodyData object.
    NSData *sensorData = [characteristic value];
    uint8_t *bodyData = (uint8_t *)[sensorData bytes];
    if (bodyData ) {
        // 2. Next, determine if you have device body location data to report and access the first byte at index 0 in your array as defined by bodyData[0].
        uint8_t bodyLocation = bodyData[0];
        // 3. Next, determine the body location of the device using the bodyLocation variable; here you’re only interested in the location on the chest. Finally, assign the body location data to bodyData so that it can be displayed in your UITextView control.
        self.bodyData = [NSString stringWithFormat:@"Body Location: %@", bodyLocation == 1 ? @"Chest" : @"Undefined"];
    }
    // 4. If no data is available, assign N/A as the body location and assign it to self.bodyData variable so that it can be displayed in your UITextView control.
    else {
        self.bodyData = [NSString stringWithFormat:@"Body Location: N/A"];
    }
    return;
    
}

// Instance method to get the battery level
- (void) getBatteryLevel:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Based on:
    // https://github.com/lmccart/pplkpr/blob/84cb6baf4a0252380414ce443fb143da262c241d/pplkpr/HeartRateMonitor.m
    // because nothing else worked
    char batteryValue;
    [characteristic.value getBytes:&batteryValue length:1];
    int n = (int)batteryValue;
    
    //NSData *data = [characteristic value];
    //int battLev = (int)[data bytes];
    
    if (!error) {
        self.battery = [NSString stringWithFormat:@"Battery Level: %d%%", n];
    }
}

// Helper method to perform a heartbeat animation
- (void)doHeartBeat
{
    CALayer *layer = [self heartImage].layer;
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.toValue = [NSNumber numberWithFloat:1.1];
    pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    
    pulseAnimation.duration = 60. / self.heartRate / 2.;
    pulseAnimation.repeatCount = 1;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [layer addAnimation:pulseAnimation forKey:@"scale"];
    
    self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeat) userInfo:nil repeats:NO];
    
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [self.responseData appendData:data];
    
    // Converts bytes in data (NSData) to readable string (NSString)!
    //NSString *result = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    
    // Prints result.
    //NSLog(@"Response: %@", result);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}

@end
