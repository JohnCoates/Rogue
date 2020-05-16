//
//  RuntimeClass+Swift.swift
//  Created on 11/4/19
//

import Foundation

public enum RuntimeError: Error {
    case failedToFindClassFromProtocol(protocol: Protocol)
    case failedToCast(protocol: Protocol)
}

public extension RuntimeClass {
    static func from<T, R>(protocol targetProtocol: T) throws -> R where T: Protocol {
        guard let targetClass = RuntimeClass.fromProtocol(targetProtocol) else {
            throw RuntimeError.failedToFindClassFromProtocol(protocol: targetProtocol)
        }

        guard let typedClass = targetClass as? R else {
            throw RuntimeError.failedToCast(protocol: targetProtocol)
        }

        return typedClass
    }
}
