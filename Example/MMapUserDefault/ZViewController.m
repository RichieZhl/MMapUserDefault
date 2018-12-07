//
//  ZViewController.m
//  MMapUserDefault
//
//  Created by RichieZhl on 12/07/2018.
//  Copyright (c) 2018 RichieZhl. All rights reserved.
//

#import "ZViewController.h"
#include <mach/mach_time.h>
#import "MMapUserDefault.h"

@interface ZViewController ()

@end

@implementation ZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        mach_timebase_info_data_t info;
        if (mach_timebase_info(&info) != KERN_SUCCESS) return;
        uint64_t start = mach_absolute_time();
        MMapUserDefault *file = [MMapUserDefault shared];
        for (long i = 0; i < 100000; ++i) {
            [file setObject:@(i) forKey:[NSString stringWithFormat:@"test%ld", i]];
        }
        uint64_t stop = mach_absolute_time();
        printf("MMapUserDefault cost time : %.3fms\n", 1.0 * (stop - start) * info.numer / info.denom / NSEC_PER_MSEC);
        //        [file setObject:@"asffadfff" forKey:@"test7"];
        //        [file setObject:@(1.25) forKey:@"test1"];
        //        [file setObject:@"asdfaf" forKey:@"test2"];
        //        [file setObject:[NSDate date] forKey:@"test3"];
        //        [file setObject:[NSURL URLWithString:@"https://www.baidu.com"] forKey:@"test4"];
        //        [file setObject:[NSArray arrayWithObjects:@"123", @"456", nil] forKey:@"test5"];
        //        [file setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"dvalue1", @"dkey1", @"dvalue2", @"dkey2", nil] forKey:@"test6"];
        start = mach_absolute_time();
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        for (long i = 0; i < 100000; ++i) {
            [userDefaults setObject:@(i) forKey:[NSString stringWithFormat:@"test%ld", i]];
        }
        stop = mach_absolute_time();
        printf("NSUserDefaults cost time : %.3fms\n", 1.0 * (stop - start) * info.numer / info.denom / NSEC_PER_MSEC);
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
