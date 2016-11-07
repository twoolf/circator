import Foundation

class Persistence {
    static let ModelFileName = "AppModel.serialized"
    static let FileMgr = NSFileManager.defaultManager()
    
    static func getStorageURL() throws -> NSURL {
        let dirPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if dirPaths.count == 0 {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "No paths found"])
        }
        let urlPath = NSURL(fileURLWithPath: dirPaths[0])
        if !FileMgr.fileExistsAtPath(dirPaths[0]) {
            try mkdir(urlPath)
        }
        return urlPath.URLByAppendingPathComponent(ModelFileName)
    }
    
    static func mkdir(newDirURL: NSURL) throws {
        try NSFileManager.defaultManager().createDirectoryAtURL(newDirURL, withIntermediateDirectories: false, attributes: nil)
    }
    
    static func save(model: NSObject) throws {
        let saveURL = try Persistence.getStorageURL()
        print("saveURL: \(saveURL)")
        // This is a recursive process that will push archiving to the children if set up that way
        let success = NSKeyedArchiver.archiveRootObject(model, toFile: saveURL.path!)
        if !success {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to archive"])
        }
        print("saved model success: \(success) at \(NSDate()) to path: \(saveURL)")
    }
    
    static func restore() throws -> NSObject {
        let saveURL = try Persistence.getStorageURL()
        guard let rawData = NSData(contentsOfFile: saveURL.path!) else {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve unarchival data"])
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: rawData)
        guard let model = unarchiver.decodeObjectForKey("root") as? NSObject else {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to find root object"])
        }
        print("restored model successfully at \(NSDate()): \(model.dynamicType)")
        return model
     }
}
