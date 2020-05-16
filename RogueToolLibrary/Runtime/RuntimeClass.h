//
//  RuntimeClass.h
//  Created on 11/4/19
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface RuntimeClass : NSObject

+ (nullable Class)fromProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
