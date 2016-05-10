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
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let isValid = emailTest.evaluateWithObject(self)
        
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

}
