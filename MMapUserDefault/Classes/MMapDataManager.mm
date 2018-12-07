//
//  MMapDataManager.mm
//  demo1
//
//  Created by lylaut on 2018/12/5.
//  Copyright © 2018 lylaut. All rights reserved.
//

#include "MMapDataManager.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#import <Foundation/Foundation.h>
#import "MMapUserDefault.h"

const MMapDataManagerType MMapDataManagerType_None = 0;
const MMapDataManagerType MMapDataManagerType_NSString = 1;
const MMapDataManagerType MMapDataManagerType_NSURL = 2;
const MMapDataManagerType MMapDataManagerType_NSData = 3;
const MMapDataManagerType MMapDataManagerType_NSNumber = 4;
const MMapDataManagerType MMapDataManagerType_NSDate = 5;
const MMapDataManagerType MMapDataManagerType_NSContainer = 6;

const int DEFAULT_MMAP_SIZE = getpagesize();
inline double doubleWithPtr(unsigned char *ptr, int valueSize);

MMapDataManager MMapDataManager::instance;

MMapDataManager::MMapDataManager() {
    setUp();
}

MMapDataManager::~MMapDataManager() {
    if (m_ptr != MAP_FAILED) {
        msync(m_ptr, m_size, MS_ASYNC);
        munmap(m_ptr, m_size);
    }
    if (m_fd != 0) {
        close(m_fd);
    }
}

void MMapDataManager::expansion() {
    // 扩容
    size_t t_size = m_size * 2;
    if (ftruncate(m_fd, t_size) != 0) {
        perror("fail to truncate");
        return;
    }
    munmap(m_ptr, m_size);
    m_ptr = nullptr;
    m_size = t_size;
    m_ptr = (char *)mmap(nullptr, m_size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
    if (m_ptr == MAP_FAILED) {
        perror("fail to mmap");
    }
}

void MMapDataManager::setUp() {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"mem.map"];
    NSLog(@"path %@", path);
    m_fd = open([path cStringUsingEncoding:NSUTF8StringEncoding], O_CREAT | O_RDWR, 0644);
    if (m_fd == 0) {
        perror("error fd");
        return;
    }
    
    m_size = 0;
    struct stat st = {0};
    if (fstat(m_fd, &st) != -1) {
        m_size = (size_t)st.st_size;
    }
    
    if (m_size < DEFAULT_MMAP_SIZE || (m_size % DEFAULT_MMAP_SIZE != 0)) {
        m_size = ((m_size / DEFAULT_MMAP_SIZE) + 1) * DEFAULT_MMAP_SIZE;
        if (ftruncate(m_fd, m_size) != 0) {
            perror("fail to truncate");
            m_size = (size_t)st.st_size;
            return;
        }
    }
    
    m_ptr = (char *)mmap(nullptr, m_size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
    if (m_ptr == MAP_FAILED) {
        perror("fail to mmap");
    }
}

void MMapDataManager::write(id object, size_t &offset) {
    MMapDataManagerType type = MMapDataManagerType_None;
    unsigned int valueSize = 0;
    char *value = nullptr;
    bool isNumber = false;
    double numberValue = 0.0f;
    if ([object isKindOfClass:[NSString class]]) {
        type = MMapDataManagerType_NSString;
        const char *res = [object cStringUsingEncoding:NSUTF8StringEncoding];
        value = (char *)res;
        valueSize = (unsigned int)strlen(res);
    } else if ([object isKindOfClass:[NSURL class]]) {
        type = MMapDataManagerType_NSURL;
        const char *res = [[object description] cStringUsingEncoding:NSUTF8StringEncoding];
        value = (char *)res;
        valueSize = (unsigned int)strlen(res);
    } else if ([object isKindOfClass:[NSData class]]) {
        type = MMapDataManagerType_NSData;
        value = (char *)[object bytes];
        valueSize = (unsigned int)[object length];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        type = MMapDataManagerType_NSNumber;
        isNumber = true;
        numberValue = [object doubleValue];
    } else if ([object isKindOfClass:[NSDate class]]) {
        type = MMapDataManagerType_NSDate;
        isNumber = true;
        numberValue = [object timeIntervalSince1970];
    } else if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]) {
        type = MMapDataManagerType_NSContainer;
        NSData *resData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
        if (resData == nil) {
            return;
        }
        value = (char *)[resData bytes];
        valueSize = (unsigned int)[resData length];
    }
    size_t willWriteSize = sizeof(type) + (isNumber ? sizeof(double) : (valueSize + sizeof(size_t)));
    if (offset + willWriteSize >= m_size) {
        if (needsSort) {
            needsSort = false;
            // 重排
            size_t t_offset = [[MMapUserDefault shared] refresh];
            if (t_offset + willWriteSize < m_size) {
                memset(m_ptr+t_offset, 0, m_size-t_offset);
                offset = t_offset;
            } else {
                expansion();
            }
        } else {
            expansion();
        }
    }
    memcpy(m_ptr+offset, &type, sizeof(type));
    offset += sizeof(type);
    if (isNumber) {
        memcpy(m_ptr+offset, &numberValue, sizeof(numberValue));
        offset += sizeof(numberValue);
    } else {
        memcpy(m_ptr+offset, &valueSize, sizeof(valueSize));
        offset += sizeof(valueSize);
        memcpy(m_ptr+offset, value, valueSize);
        offset += valueSize;
    }
}

inline double doubleWithPtr(char *ptr, int valueSize) {
    char buffer[valueSize+1];
    memcpy(buffer, ptr, valueSize);
    buffer[valueSize] = 0;
    return atof(buffer);
}

id MMapDataManager::read(size_t &offset) {
    MMapDataManagerType type = MMapDataManagerType_None;
    memcpy(&type, m_ptr+offset, sizeof(type));
    if (type == MMapDataManagerType_None) {
        return nil;
    }
    offset += sizeof(type);
    bool isNumber = type == MMapDataManagerType_NSNumber || type == MMapDataManagerType_NSDate;
    unsigned int valueSize = 0;
    if (!isNumber) {
        memcpy(&valueSize, m_ptr+offset, sizeof(valueSize));
        if (valueSize == 0) {
            offset -= sizeof(type);
            return nil;
        }
        offset += sizeof(valueSize);
    }
    id res = nil;
    if (type == MMapDataManagerType_NSString) {
        res = [[NSString alloc] initWithBytesNoCopy:m_ptr+offset length:valueSize encoding:NSUTF8StringEncoding freeWhenDone:NO];
    } else if (type == MMapDataManagerType_NSURL) {
        NSString *urlString = [[NSString alloc] initWithBytesNoCopy:m_ptr+offset length:valueSize encoding:NSUTF8StringEncoding freeWhenDone:NO];
        res = [NSURL URLWithString:urlString];
    } else if (type == MMapDataManagerType_NSData) {
        res = [NSData dataWithBytesNoCopy:m_ptr+offset length:valueSize freeWhenDone:NO];
    } else if (type == MMapDataManagerType_NSNumber) {
        double value = 0.0f;
        memcpy(&value, m_ptr+offset, sizeof(value));
        res = @(value);
    } else if (type == MMapDataManagerType_NSDate) {
        double value = 0.0f;
        memcpy(&value, m_ptr+offset, sizeof(value));
        res = [NSDate dateWithTimeIntervalSince1970:value];
    } else if (type == MMapDataManagerType_NSContainer) {
        NSData *data = [NSData dataWithBytesNoCopy:m_ptr+offset length:valueSize freeWhenDone:NO];
        res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    }
    if (res == nil) {
        offset -= sizeof(type) + (isNumber ? 0 : sizeof(valueSize));
        return nil;
    }
    offset += isNumber ? sizeof(double) : valueSize;
    
    return res;
}
