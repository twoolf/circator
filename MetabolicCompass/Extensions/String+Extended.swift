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
        
        return self.mathesToRegEx(emailRegEx)
    }
    
    
    func containsOnlyLetters(allowSpaces: Bool = false) -> Bool {
        
        let strRegEx = allowSpaces ? "[A-Za-z ]{1,}" : "[A-Za-z]{1,}"
        
        return self.mathesToRegEx(strRegEx)
    }
    
    private func mathesToRegEx(regEx: String) -> Bool {
        
        let predicate = NSPredicate(format:"SELF MATCHES %@", regEx)
        let isValid = predicate.evaluateWithObject(self)
        
        return isValid
    }
    
    func trimmed() -> String {
       return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    
    var localized: String {
            return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
    
    func formatTextWithRegex(regex: String, format: [String: AnyObject], defaultFormat: [String: AnyObject]) -> NSAttributedString {
        
        let text = self
        
        guard let regex = try? NSRegularExpression(pattern: regex, options: NSRegularExpressionOptions.CaseInsensitive) else {
            return NSAttributedString(string: text)
        }
        
        let nsString = text as NSString
        let results = regex.matchesInString(text, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
        
        let attrString = NSMutableAttributedString(string: text, attributes: defaultFormat)
        
        for result in results {
            attrString.addAttributes(format, range: result.range)
        }
        
        return attrString
    }
    
    func strRange(range: NSRange) -> Range<String.Index> {
        let startIndex = self.startIndex.advancedBy(range.location)
        let endIndex = self.startIndex.advancedBy(range.length)
        return startIndex..<endIndex
    }
    
    var length: Int {
        return self.characters.count
    }
    
    var hasContent: Bool {
        return self.characters.count > 0
    }

}
