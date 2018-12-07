//
//  MemFile.m
//  MMapStorage
//
//  Created by lylaut on 2018/12/5.
//  Copyright © 2018 lylaut. All rights reserved.
//

#import "MMapUserDefault.h"
#include <pthread.h>
#import "MMapDataManager.h"

@interface MMapUserDefault () {
    pthread_mutex_t mutex;
    size_t m_offset;
}

@property (nonatomic, strong) NSMutableDictionary *dictionary;

@property (nonatomic, strong) NSThread *thread;

@end

@implementation MMapUserDefault

static MMapUserDefault *sharedMemFile;
#pragma mark - share init dealloc
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMemFile = [[self alloc] initPrivate];
    });
    return sharedMemFile;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMemFile = [super allocWithZone:zone];
    });
    return sharedMemFile;
}

- (id)copy {
    return sharedMemFile;
}

- (id)mutableCopy {
    return sharedMemFile;
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        m_offset = 0;
        
        pthread_mutex_init(&mutex, nullptr);
        
        _dictionary = [NSMutableDictionary dictionary];
        MMapDataManager *manager = MMapDataManager::getInstance();
        while (YES) {
            size_t tmpOffset = m_offset;
            NSString *key = manager->read(tmpOffset);
            if (key == nil || ![key isKindOfClass:[NSString class]]) {
                break;
            }
            id object = manager->read(tmpOffset);
            if (object == nil) {
                break;
            }
            m_offset = tmpOffset;
            if (!manager->needsSort && [_dictionary objectForKey:key]) {
                manager->needsSort = true;
            }
            [_dictionary setObject:object forKey:key];
        }
        NSLog(@"-------%ld", _dictionary.count);
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_destroy(&mutex);
    
    [_dictionary removeAllObjects];
    _dictionary = nil;
}

#pragma mark - fresh
- (size_t)refresh {
    __block size_t t_offset = 0;
    [self.dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        MMapDataManager *manager = MMapDataManager::getInstance();
        manager->write(key, t_offset);
        manager->write(obj, t_offset);
    }];
    return t_offset;
}

#pragma mark - methods
- (void)setObject:(id)value forKey:(NSString *)defaultName {
    pthread_mutex_lock(&mutex);
    [self.dictionary setObject:value forKey:defaultName];
    MMapDataManager *manager = MMapDataManager::getInstance();
    if (!manager->needsSort && [_dictionary objectForKey:defaultName]) {
        manager->needsSort = true;
    }
    manager->write(defaultName, m_offset);
    manager->write(value, m_offset);
    pthread_mutex_unlock(&mutex);
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName {
    [self setObject:@(value) forKey:defaultName];
}

- (void)setDouble:(double)value forKey:(NSString *)defaultName {
    [self setObject:@(value) forKey:defaultName];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName {
    [self setObject:@(value) forKey:defaultName];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName {
    [self setObject:@(value) forKey:defaultName];
}

- (void)setURL:(NSURL *)url forKey:(NSString *)defaultName {
    [self setObject:url forKey:defaultName];
}

- (void)removeObjectForKey:(NSString *)defaultName {
    pthread_mutex_lock(&mutex);
    [self.dictionary removeObjectForKey:defaultName];
    pthread_mutex_unlock(&mutex);
}

- (id)objectForKey:(NSString *)defaultName {
    return [self.dictionary objectForKey:defaultName];
}

- (NSURL *)URLForKey:(NSString *)defaultName {
    return [self.dictionary objectForKey:defaultName];
}

- (NSString *)stringForKey:(NSString *)defaultName {
    return [self.dictionary objectForKey:defaultName];
}

- (NSData *)dataForKey:(NSString *)defaultName {
    return [self.dictionary objectForKey:defaultName];
}

- (BOOL)boolForKey:(NSString *)defaultName {
    NSNumber *number = [self.dictionary objectForKey:defaultName];
    if (number == nil) {
        return NO;
    }
    return number.boolValue;
}

- (NSInteger)integerForKey:(NSString *)defaultName {
    NSNumber *number = [self.dictionary objectForKey:defaultName];
    if (number == nil) {
        return NO;
    }
    return number.integerValue;
}

- (float)floatForKey:(NSString *)defaultName {
    NSNumber *number = [self.dictionary objectForKey:defaultName];
    if (number == nil) {
        return NO;
    }
    return number.floatValue;
}

- (double)doubleForKey:(NSString *)defaultName {
    NSNumber *number = [self.dictionary objectForKey:defaultName];
    if (number == nil) {
        return NO;
    }
    return number.doubleValue;
}

@end
