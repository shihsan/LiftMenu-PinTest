//
//  UGViewController.h
//  PinTest
//
//  Created by Chung Yu Huang  on 2014/6/4.
//  Copyright (c) 2014年 bobo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UGViewController : UIViewController <UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollview;
@property (strong, nonatomic) IBOutlet UIImageView *imageview;

@end
