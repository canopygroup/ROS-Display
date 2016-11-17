//
//  ConfigurationViewController.mm
//  ROS-Display
//
//  Created by FurutaYuki on 12/22/14.
//  Copyright (c) 2014 JSK Lab. All rights reserved.
//

#import "ConfigurationViewController.h"

#import <ros/init.h>
#import <ros/master.h>

#import <ifaddrs.h>
#import <arpa/inet.h>

#define kMasterURIHistory @"kMasterURIHistory"

#pragma mark - ConfigurationViewController

@interface ConfigurationViewController ()
@property (weak, nonatomic) IBOutlet UITextField *uriTextField;
@property (weak, nonatomic) IBOutlet UIButton *historyButton1;
@property (weak, nonatomic) IBOutlet UIButton *historyButton2;
@property (weak, nonatomic) IBOutlet UIButton *historyButton3;
@property (weak, nonatomic) IBOutlet UIButton *historyButton4;
@property (weak, nonatomic) IBOutlet UIButton *historyButton5;
@property (strong, nonatomic) NSArray *historyButtons;
@property (strong, readonly) NSString *nodeName;
@property (readonly) BOOL anonymous;
@end

@implementation ConfigurationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.historyButtons = [NSArray arrayWithObjects:self.historyButton1, self.historyButton2, self.historyButton3, self.historyButton4, self.historyButton5, nil];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *nodename = [ud objectForKey:@"kROSiOSNodeNameKey"];
    if (nodename) {
        _nodeName = nodename;
    } else {
        _nodeName = @"ros_ios_app";
    }
    _anonymous = [ud boolForKey:@"kROSiOSNodeAnonymous"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadHistory];
}

- (void)loadHistory
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *history = [ud arrayForKey:kMasterURIHistory];

    if (history) {
        NSLog(@"%ld history found", [history count]);
        for (NSInteger i = 0; i < [history count]; ++i) {
            UIButton *b = self.historyButtons[i];
            b.hidden = NO;
            [b setTitle:history[i] forState:UIControlStateNormal];
            [b addTarget:self action:@selector(historyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)historyButtonPressed:(UIButton*)button
{
    self.uriTextField.text = button.titleLabel.text;
}

- (void)saveHistory
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray *history = [ud mutableArrayValueForKey:kMasterURIHistory];
    NSString *uri = [self.uriTextField.attributedText string];
    if (history == nil || [history count] <= 0) {
        history = [NSMutableArray arrayWithObject:uri];
    } else if (![history containsObject:uri]) {
        [history insertObject:[self.uriTextField.attributedText string] atIndex:0];
        if ([history count] > 5) {
            [history  removeLastObject];
        }
    }
    
    [ud setObject:[NSArray arrayWithArray:history] forKey:kMasterURIHistory];
    [ud synchronize];
}


- (BOOL)connectToROSMaster
{

    if ([self isHostValid:[self.uriTextField.attributedText string]]) {
        [self saveHistory];
        NSString * master_uri = [@"ROS_MASTER_URI=" stringByAppendingString:[self.uriTextField.attributedText string]];
        NSLog(@"%@",master_uri);
        
        NSString * ip = [self getMyIPAddress];
        NSString * hostname = [@"ROS_HOSTNAME=" stringByAppendingString:ip];
        NSLog(@"%@",hostname);
        
        putenv((char *)[master_uri UTF8String]);
        putenv((char *)[hostname UTF8String]);
        putenv((char *)"ROS_HOME=/tmp");
        
        int argc = 0;
        char **argv = NULL;
        
        if(!ros::isInitialized())
        {
            if (self.anonymous) {
                ros::init(argc, argv, [self.nodeName UTF8String], ros::init_options::AnonymousName);
            } else {
                ros::init(argc, argv, [self.nodeName UTF8String]);
            }
        }
        else
        {
            NSLog(@"ROS already initialised. Can't change the ROS_MASTER_URI");
        }
        
        if(ros::master::check())
        {
            NSLog(@"Connected to the ROS master !");
        }
        else
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Couldn't join the ROS master" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    } else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Invalid ROS Master URI" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}

- (IBAction)okButtonPressed:(id)sender {
    // if ([self connectToROSMaster])
    #warning - do something here
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - IPConfigurationUtilities


- (NSString *)getMyIPAddress
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET || sa_type == AF_INET6) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name hasPrefix:@"en"]) {
                    // Interface is the wifi connection on the iPhone
                    if (![addr hasPrefix:@"0."])
                        wifiAddress = addr;
                } else {
                    if([name isEqualToString:@"pdp_ip0"]) {
                        // Interface is the cell connection on the iPhone
                        cellAddress = addr;
                    }
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    NSString *addr = wifiAddress ? wifiAddress : cellAddress;
    return addr ? addr : @"0.0.0.0";
}

- (BOOL)isHostValid:(NSString*)host
{
    NSURL* url = [NSURL URLWithString:host];
    if ([url scheme] && [url host] && [url port]) return YES;
    else return NO;
}

@end
