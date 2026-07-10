import Foundation

/// What a path field expects its value to point at, with live validation.
public enum PathRequirement {
    case directory
    case executable

    public func validate(_ raw: String) -> Bool {
        let expanded = (raw as NSString).expandingTildeInPath
        switch self {
        case .directory:
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir)
                && isDir.boolValue
        case .executable:
            return FileManager.default.isExecutableFile(atPath: expanded)
        }
    }
}
