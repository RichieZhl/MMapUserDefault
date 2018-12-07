//
//  MMapDataManager.h
//  demo1
//
//  Created by lylaut on 2018/12/5.
//  Copyright © 2018 lylaut. All rights reserved.
//

#ifndef MMapDataManager_h
#define MMapDataManager_h

#include <sys/types.h>

typedef char MMapDataManagerType;
extern const MMapDataManagerType MMapDataManagerType_None;
extern const MMapDataManagerType MMapDataManagerType_NSString;
extern const MMapDataManagerType MMapDataManagerType_NSURL;
extern const MMapDataManagerType MMapDataManagerType_NSData;
extern const MMapDataManagerType MMapDataManagerType_NSNumber;
extern const MMapDataManagerType MMapDataManagerType_NSDate;
extern const MMapDataManagerType MMapDataManagerType_NSContainer;

class MMapDataManager {
public:
    
    struct MMapData {
        unsigned char *value;
        size_t valueSize;
        MMapDataManagerType type;
    };
private:
    MMapDataManager();
    ~MMapDataManager();
    MMapDataManager (const MMapDataManager &) = delete;
    MMapDataManager(MMapDataManager &&) = delete;
    MMapDataManager& operator = (const MMapDataManager &) = delete;
    static MMapDataManager instance;
public:
    static MMapDataManager* getInstance() {
        return &instance;
    }
    void write(id object, size_t &offset);
    id read(size_t &offset);
    
private:
    void setUp();
    void expansion();
    
private:
    int m_fd = 0;
    size_t m_size = 0;
    char *m_ptr;
    
public:
    bool needsSort = false;
};


#endif /* MMapDataManager_hpp */
