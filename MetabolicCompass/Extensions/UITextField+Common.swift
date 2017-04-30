//
//  UITextField+Common.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/19/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

extension UITextField {
    func setCursorPosition(position:Int){
        self.setSelectionRange(range: NSRange(location: position, length: 0))
    }

    func setSelectionRange(range:NSRange){
//        if let start = self.positionFromPosition(self.beginningOfDocument, offset: range.location){
//            if let end = self.positionFromPosition(start, offset: range.length){
//        if let start = self.position(position(from: self.beginningOfDocument, offset: range.location)) {
//            if let end = self.position(from: start, in: UITextLayoutDirection, offset: range.length) {
 //               self.selectedTextRange = self.textRangeFromPosition(start, toPosition: end)
//            }
//        }
    }
    
    func replaceRange(range:NSRange, replacementString:String, limitedToLength:Int){
        let text = self.text ?? ""
        let curLength =  text.characters.count
        let allowedRepLength = limitedToLength - (curLength - range.length)
        let repLength = replacementString.characters.count
        var validRepString = replacementString
        if repLength > allowedRepLength{
            validRepString = (replacementString as NSString).substring(to: allowedRepLength)
        }
        (text as NSString).replacingCharacters(in: range, with: validRepString);
        self.setCursorPosition(position: range.location + validRepString.characters.count)
    }

}
