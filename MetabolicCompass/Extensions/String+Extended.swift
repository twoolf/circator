//
//  String+Extended.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

extension String {
    
    func isValidAsEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        return self.mathesToRegEx(regEx: emailRegEx)
    }
    
    
    func containsOnlyLetters(allowSpaces: Bool = false) -> Bool {
        
        let strRegEx = allowSpaces ? "[A-Za-z ]{1,}" : "[A-Za-z]{1,}"
        
        return self.mathesToRegEx(regEx: strRegEx)
    }
    
    private func mathesToRegEx(regEx: String) -> Bool {
        
        let predicate = NSPredicate(format:"SELF MATCHES %@", regEx)
        let isValid = predicate.evaluate(with: self)
        
        return isValid
    }
    
    func trimmed() -> String {
//       return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
//        return self(trimmingCharacters(in: NSCharacterSet.whitespaceCharacterSet()))
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
    
    
    var localized: String {
            return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func formatTextWithRegex(regex: String, format: [NSAttributedStringKey: Any], defaultFormat: [NSAttributedStringKey: Any]) -> NSAttributedString {
        
        let text = self
        
        guard let regex = try? NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive) else {
            return NSAttributedString(string: text)
        }
        
        let nsString = text as NSString
        let results = regex.matches(in: text, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, nsString.length))
        
        let attrString = NSMutableAttributedString(string: text, attributes: defaultFormat)
        
        for result in results {
            attrString.addAttributes(format, range: result.range)
        }
        
        return attrString
    }
    
    func strRange(range: NSRange) -> Range<String.Index> {
//        let startIndex = self.startIndex.advancedBy(range.location)
//        let startIndex = self.startIndex(index(offsetBy: range.location))
//        let startIndex = 0
        let startIndex = self.startIndex
//        let endIndex = self.startIndex.advancedBy(range.length)
//        let endIndex = self.startIndex(index(offsetBy: range.length))
        let endIndex = self.endIndex
        return startIndex..<endIndex
    }
    
    var length: Int {
        return self.characters.count
    }
    
    var hasContent: Bool {
        return self.characters.count > 0
    }

}
