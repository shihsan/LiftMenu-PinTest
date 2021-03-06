//
//  UGViewController.m
//  PinTest
//
//  Created by Chung Yu Huang  on 2014/6/4.
//  Copyright (c) 2014年 bobo. All rights reserved.
//

#import "UGViewController.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

@interface UGViewController ()
{
    /* variable received via socket */
    float fx; // corrected finger's x
    float fy; // corrected finger's y
    float fz; // corrected finger's z
    float px; // uncorrected palm's x
    float py; // uncorrected palm's y
    float pz; // uncorrected palm's z
    float lx_; // finger's x where the key tap is registered deteced by leap
    float ly_; // finger's y where the key tap is registered deteced by leap
    float ox; // uncorrected finger's x
    float oy; // uncorrected finger's y
    float v; // finger[0]'s velocity
    NSInteger tap; // if tap triggered - 1 for YES, 0 for NO
    float pin; //for pinch
    
    
    /* variable used in App */
    float height; //
    float thickness; // menu's thickness
    float range; // menu's width
    float x; // mouse's x
    float y; // mouse's y
    float z; // mouse's z
    float lx; // leftmost position's x
    float ly; // leftmost position's y
    float lz; // leftmost position's z
    float rx; // rightmost position's x
    float ry; // rightmost position's y
    float rz; // rightmost position's z
    float mouse;
    float omouse;
    float lmouse;
    NSString *testData;
    NSInteger btnNum;
    NSInteger lbtnNum;
    NSInteger obtnNum;
    
    float pre_px;   //previous palm's x
    float pre_py;   //previous palm's y
    float pre_pz;   //previous palm's z
    
    /* setting */
    BOOL isSetting;
    
    /* variables for socket - no need to understand */
    char buf[256];
    int sockfd;
    int w;
    int bind_int;
    socklen_t adr_srvr_len;
    struct sockaddr_in adr_srvr;
    int broadcast;
    int port;
    
    
}
@end

@implementation UGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    isSetting = YES;
    
    /*-----------Socket Client----------*/
    port = 8000;
    
    printf("連結 server...\n");
    bzero(&adr_srvr, sizeof(adr_srvr));
    memset(&adr_srvr, 0, sizeof(adr_srvr));
    adr_srvr.sin_family = AF_INET;
    //adr_srvr.sin_addr.s_addr = INADDR_ANY;
    adr_srvr.sin_addr.s_addr = inet_addr("0.0.0.0");
    adr_srvr.sin_port = htons(port);
    adr_srvr_len = sizeof(adr_srvr);
    
    sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    
    if (sockfd == -1) {
        perror("socket error");
        exit(1);
    }
    
    //-----------broadcast Setup--------
    broadcast = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &broadcast, sizeof broadcast);
    //-----------------------------------
    
    //have to "bind" before "recvfrom"
    bind_int = bind(sockfd,(struct sockaddr *)&adr_srvr, sizeof(adr_srvr));
    
    if (bind_int == -1) {
        perror("bind error");
        exit(1);
    }
    /*-----------Socket Client----------*/
    
    [NSThread detachNewThreadSelector:@selector(connectLeap) toTarget:self withObject:nil];
    
    //Scroll view
    _scrollview.delegate = self;
    _scrollview.minimumZoomScale = 1.0;
    _scrollview.maximumZoomScale = 2.0;
    self.scrollview.contentSize = self.imageview.image.size ;
    self.imageview.frame = CGRectMake(0, 0, self.imageview.image.size.width, self.imageview.image.size.height);
    
    [_scrollview setScrollEnabled:YES];
    [_scrollview setShowsHorizontalScrollIndicator:YES];
    [_scrollview setShowsVerticalScrollIndicator:YES];
    
    
    pre_px = 0.0f;
    pre_py = 0.0f;
    pre_pz = 0.0f;
    
    
  
}

- (void)viewDidDisappear:(BOOL)animated
{
    close(sockfd);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connectLeap
{
    while(isSetting) {
        w = (int)recvfrom(sockfd, buf, sizeof(buf), 0, (struct sockaddr*)&adr_srvr, &adr_srvr_len);
        
        //傳送資料的socketid,暫存器指標buf,sizeof(buf),一般設為0,接收端網路位址,sizeof(接收端網路位址);
        if (w < 0) {
            perror("recv error");
            exit(1);
        }
        buf[w] = 0;
        
        NSString *string = [NSString stringWithUTF8String:buf];
        NSScanner *scanner = [NSScanner scannerWithString:string];
        
        // fz, fx, fy, pz, px, py, tap, pinch
        [scanner scanFloat:&fz];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&fx];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&fy];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&pz];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&px];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&py];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&v];
        [scanner scanString:@", " intoString:nil];
        [scanner scanInt:&tap];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&lx_];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&ly_];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&ox];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&oy];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&pin];                      //for pinch
        
        x = fx;
        y = fy;
        z = pz;
        
        
        NSLog(@"%s", buf);
        
        if(pin > 0.8 && pin <= 1){
            [self performSelectorOnMainThread:@selector(moveImg) withObject:nil waitUntilDone:YES];
        }
        
        if(pre_px != px)
            pre_px = px;
        if(pre_py != py)
            pre_py = py;
        if(pre_pz != pz)
            pre_pz = pz;
        
    }
}

int i=0,j=0;

-(void) moveImg
{
    
    NSLog(@"{MOVE!!!!!!!%f,%f,%f,%f,%f}",px-pre_px,py-pre_py,pz-pre_pz,_imageview.frame.origin.x, _imageview.frame.origin.y);
    [UIView animateWithDuration:0.5f
                     animations:^{
                         //Move the image view according to px , py
                         _imageview.frame =
                         CGRectMake(_imageview.frame.origin.x+px-pre_px,
                                    _imageview.frame.origin.y+py-pre_py,
                                    _imageview.frame.size.width,
                                    _imageview.frame.size.height);
                     }];
    //for ZOOMING
    if(pz-pre_pz > 1)
        [UIView animateWithDuration:0.5f
                         animations:^{
                             _scrollview.zoomScale += 0.01f;
                         }];
    else if(pz-pre_pz < -1)
        [UIView animateWithDuration:0.5f
                         animations:^{
                             _scrollview.zoomScale -= 0.01f;
                         }];
    
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)_scrollView {
    return _imageview;
}
@end
