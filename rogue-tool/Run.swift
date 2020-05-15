//
//  Run.swift
//  Created on 5/15/20
//

import Foundation

struct System {
    static func run(_ command: String, print shouldPrint: Bool = true,
                    blocking: Bool = true, onCompletion: @escaping (RunResult) -> Void) -> Void {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["bash", "-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let result = RunResult()

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard data.count > 0 else { return }
            if shouldPrint, let stringValue = String(data: data, encoding: .utf8) {
                print(stringValue, terminator: "")

            }
            result.addOutput(data: data)
        }
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard data.count > 0 else { return }
            if shouldPrint, let stringValue = String(data: data, encoding: .utf8) {
                print(stringValue, terminator: "")
            }
            result.addOutput(data: data, isError: true)
        }
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        var semaphore: NonRunLoopBlockingSemaphore?
        if blocking {
            semaphore = NonRunLoopBlockingSemaphore()
        }
        process.terminationHandler = { process in
            result.exitCode = process.terminationStatus
            if blocking {
                semaphore?.signal()
            } else {
                onCompletion(result)
            }

        }

        if shouldPrint {
            print(command)
        }

        process.launch()

        if blocking {
            semaphore?.wait()
            onCompletion(result)
        }
    }
}

class RunResult {
    var output: String {
        String(data: outputData, encoding: .utf8) ?? ""
    }
    var errors: String?
    var exitCode: Int32 = 0

    private var outputData: Data = Data()
    private var errorData: Data?
    fileprivate func addOutput(data: Data, isError: Bool = false) {
        outputData.append(data)

        if isError {
            errorData = errorData ?? Data()
            errorData?.append(data)
        }
    }
}
