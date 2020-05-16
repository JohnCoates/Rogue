//
//  RuntimeClass.m
//  Created on 11/4/19
//

#import "RuntimeClass.h"
@import ObjectiveC;

@implementation RuntimeClass

+ (Class)named:(NSString *)className {
    Class value = NSClassFromString(className);
    if (!value) {
        NSLog(@"Error: Missing runtime class: %@", className);
    }

    return value;
}

+ (Class)fromProtocol:(Protocol *)protocol {
    const char *name = protocol_getName(protocol);
    Class targetClass = objc_getClass(name);
    BOOL conformsForProtocol = class_conformsToProtocol(targetClass, protocol);
    if (conformsForProtocol == FALSE) {
        class_addProtocol(targetClass, protocol);
    }

    return targetClass;
}

@end
