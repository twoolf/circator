//
//  TextInputFilter.swift
//  MetabolicCompass 
//
//  Created by Vladimir on 5/20/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

public class TextInputFilter: NSObject{
    enum InputCharacterFiterType {
        case InputCharacterFiterAll
        case InputCharacterFiterDigits
        case InputCharacterFiterLetters
    }
    
    var filterType:InputCharacterFiterType = .InputCharacterFiterAll
    var maxLength: Int = Int.max
    
    func filterTextField(textField:UITextField, range:NSRange){
        var str = textField.text ?? ""
        switch filterType {
        case .InputCharacterFiterDigits:
            let sRange = str.strRange(range)
            str = str.stringByReplacingOccurrencesOfString("\\D", withString:"", options:.RegularExpressionSearch, range:sRange)
        case .InputCharacterFiterLetters:
            let sRange = str.strRange(range)
            str = str.stringByReplacingOccurrencesOfString("[^a-zA-Z]", withString:"", options:.RegularExpressionSearch, range:sRange)
        default: ()
        }
    }
    
}


