//
//  main.swift
//  Created on 5/15/20
//

import Foundation
import ArgumentParser

struct RougeTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A tool for development with Rouge.",
        version: "1.0.0",
        subcommands: [SimulatorInject.self]
    )

}

RougeTool.main()
