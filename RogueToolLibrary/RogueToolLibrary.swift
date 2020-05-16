import Foundation
import os.log

let log = OSLog(subsystem: "com.rogue", category: "initialization")

@_cdecl("initialize")
func initialize() {
    let programPath = ProcessInfo.processInfo.arguments[0]
    os_log("%{public}@", log: log, "Initializing in \(programPath)")

    do {
        try processFilter()
    } catch let error {
        os_log("%{public}@", log: log, "Processing filter failed: \(error)")
        return
    }
}

struct FilterPropertyList: Decodable {
    let filter: Filter

    struct Filter: Decodable {
        let executables: [String]?
        let bundles: [String]?

        enum CodingKeys: String, CodingKey {
            case executables = "Executables"
            case bundles = "Bundles"
        }
    }

    enum CodingKeys: String, CodingKey {
        case filter = "Filter"
    }
}

func processFilter() throws {
    guard let filterFile = ProcessInfo.processInfo.environment["ROGUE_FILTER"] else {
        os_log("%{public}@", log: log, "Missing ROGUE_FILTER environment variable")
        return
    }

    guard FileManager.default.fileExists(atPath: filterFile) else {
        os_log("%{public}@", log: log, "\(filterFile) doesn't exist")
        return
    }

    let fileUrl = URL(fileURLWithPath: filterFile)

    let data = try Data(contentsOf: fileUrl)
    let decoder = PropertyListDecoder()
    let plist = try decoder.decode(FilterPropertyList.self, from: data)

    if let executables = plist.filter.executables {
        let programPath = ProcessInfo.processInfo.arguments[0]
        let programUrl = URL(fileURLWithPath: programPath)
        let executable = programUrl.lastPathComponent

        if executables.contains(executable) {
            injectLibrary()
            return
        }
    }

    if let bundleIds = plist.filter.bundles {
        for bundleId in bundleIds {
            if Bundle(identifier: bundleId) != nil {
                injectLibrary()
                return
            }
        }
    }
}

func injectLibrary() {
    guard let libraries = ProcessInfo.processInfo.environment["ROGUE_LIBRARY"] else {
        os_log("%{public}@", log: log, "Missing ROGUE_LIBRARY environment variable")
        return
    }

    libraries.components(separatedBy: "|").forEach { library in
        guard FileManager.default.fileExists(atPath: library) else {
            os_log("%{public}@", log: log, "\(library) doesn't exist")
            return
        }

        let libraryUrl = URL(fileURLWithPath: library)
        let loadBlock = {
            let handle = dlopen(library, RTLD_NOW)

            if handle == nil {
                os_log("Failed to load library: %{public}s", log: log, dlerror())
            } else {
                os_log("Injected: %{public}@", log: log, library)
            }
        }
        if libraryUrl.lastPathComponent == "RevealServer" {
            DispatchQueue.main.async {
                loadBlock()
                do {
                    let _IBARevealLoader: IBARevealLoader.Type = try RuntimeClass.from(protocol: IBARevealLoader.self)
                    _IBARevealLoader.startServer()
                } catch let error {
                    os_log("Failed to load Reveal: %{public}@", log: log, "\(error)")
                }
            }
        } else {
            loadBlock()
        }

    }
}
