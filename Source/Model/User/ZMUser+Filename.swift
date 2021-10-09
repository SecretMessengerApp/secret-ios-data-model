//
//

import Foundation

public extension ZMUser {
    fileprivate static let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-hh.mm.ss"
        return formatter
    }()
    
    /// return a file name with length <= 255 - 4(reserve for extension) - 37(reserve for WireDataModel UUID prefix for meta) characters
    ///
    /// - Returns: a string <= 214 characters
    func filename(suffix: String? = nil)-> String {
        let dateString = "-" + ZMUser.dateFormatter.string(from: Date())
        let normalizedFilename = name!.normalizedFilename
        
        var numReservedChar = dateString.count
        
        if let suffixUnwrapped = suffix {
            numReservedChar += suffixUnwrapped.count
        }
        
        let trimmedFilename = normalizedFilename.trimmedFilename(numReservedChar: numReservedChar)
        
        if let suffixUnwrapped = suffix {
            return "\(trimmedFilename)\(dateString)\(suffixUnwrapped)"
        }
        else {
            return "\(trimmedFilename)\(dateString)"
        }
    }
}
