//
//  BugsnagMetaData.m
//
//  Created by Conrad Irwin on 2014-10-01.
//
//  Copyright (c) 2014 Bugsnag, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "BugsnagMetaData.h"

void mergeDictionaries(NSMutableDictionary *destination, NSDictionary *source) {
    [source enumerateKeysAndObjectsUsingBlock: ^(id key, id value, BOOL *stop) {
        if ([destination objectForKey:key] && [value isKindOfClass:[NSDictionary class]]) {
            [[destination objectForKey: key] mergeWith: (NSDictionary *) value];
        } else {
            [destination setObject: value forKey: key];
        }
    }];
}

@interface BugsnagMetaData ()
@property (atomic, strong) NSMutableDictionary *dictionary;
@end

@implementation BugsnagMetaData

- (id) init {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    return [self initWithDictionary:dict];
}

- (id) initWithDictionary:(NSMutableDictionary*)dict {
    if(self = [super init]) {
        self.dictionary = dict;
    }
    [self.delegate metaDataChanged: self];
    return self;
}

- (id) mutableCopyWithZone:(NSZone *)zone {
    @synchronized(self) {
        NSMutableDictionary *dict = [self.dictionary mutableCopy];
        return [[BugsnagMetaData alloc] initWithDictionary:dict];
    }
}

- (NSMutableDictionary *) getTab:(NSString*)tabName {
    @synchronized(self) {
        NSMutableDictionary *tab = [self.dictionary objectForKey:tabName];
        if(!tab) {
            tab = [NSMutableDictionary dictionary];
            [self.dictionary setObject:tab forKey:tabName];
        }
        return tab;
    }
}

- (void) clearTab:(NSString*)tabName {
    @synchronized(self) {
        [self.dictionary removeObjectForKey:tabName];
    }
    
    [self.delegate metaDataChanged: self];
}

- (void) mergeWith:(NSDictionary*)data {
    @synchronized(self) {
        [data enumerateKeysAndObjectsUsingBlock: ^(id key, id value, BOOL *stop) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                mergeDictionaries([self getTab:key], value);
            } else {
                [[self getTab:@"customData"] setObject: value forKey: key];
            }
        }];
        
        [self.delegate metaDataChanged: self];
    }
}

- (NSDictionary*) toDictionary {
    @synchronized(self) {
        return [NSDictionary dictionaryWithDictionary:self.dictionary];
    }
}

- (void) addAttribute:(NSString*)attributeName withValue:(id)value toTabWithName:(NSString*)tabName {
    @synchronized(self) {
        if(value) {
            [[self getTab:tabName] setObject:value forKey:attributeName];
        } else {
            [[self getTab:tabName] removeObjectForKey:attributeName];
        }
        [self.delegate metaDataChanged: self];
    }
}

@end