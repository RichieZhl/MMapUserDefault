//
//  MemFile.h
//  MMapStorage
//
//  Created by lylaut on 2018/12/5.
//  Copyright © 2018 lylaut. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMapUserDefault : NSObject

+ (instancetype)shared;

- (void)setObject:(id)value forKey:(NSString *)defaultName;

- (void)setFloat:(float)value forKey:(NSString *)defaultName;

- (void)setDouble:(double)value forKey:(NSString *)defaultName;

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;

- (void)setURL:(NSURL *)url forKey:(NSString *)defaultName;

- (void)removeObjectForKey:(NSString *)defaultName;

- (id)objectForKey:(NSString *)defaultName;

- (NSURL *)URLForKey:(NSString *)defaultName;

- (NSString *)stringForKey:(NSString *)defaultName;

- (NSData *)dataForKey:(NSString *)defaultName;

- (BOOL)boolForKey:(NSString *)defaultName;

- (NSInteger)integerForKey:(NSString *)defaultName;

- (float)floatForKey:(NSString *)defaultName;

- (double)doubleForKey:(NSString *)defaultName;

- (size_t)refresh;

@end

NS_ASSUME_NONNULL_END
