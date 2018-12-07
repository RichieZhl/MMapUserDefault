#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MMapDataManager.h"
#import "MMapUserDefault.h"

FOUNDATION_EXPORT double MMapUserDefaultVersionNumber;
FOUNDATION_EXPORT const unsigned char MMapUserDefaultVersionString[];

