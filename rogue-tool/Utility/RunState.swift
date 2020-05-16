//
//  RunState.swift
//  Created on 5/15/20
//

import Foundation

struct RunState {
    static var projectDirectory: String {
        return #file.components(separatedBy: "/rogue-tool")[0]
    }

    static func inWorkingDirectory<T>(directory: String, execute: () -> T) -> T {
        let original = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(directory)
        let result = execute()
        FileManager.default.changeCurrentDirectoryPath(original)
        return result
    }
}

