//
//  ModelItem.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit


enum UserInfoFiledType: Int {
    case Photo = 0, Email, Password, FirstName, LastName, Gender, Age, Units, Weight, Height, Other
}


enum Gender: Int {
    case Male = 0, Female
    
    var title: String {
        switch self {
        case .Male:
            return "Male"
        case .Female:
            return "Female"
        }
    }
}



class ModelItem: NSObject {

    private(set) var name: String
    private(set) var title: String;
    private(set) var type: UserInfoFiledType
    private(set) var iconImageName: String?
    
    private(set) var value: AnyObject?
    private(set) var unitsTitle: String?
    
    var dataType: FieldDataType = .String
    
    init(name itemName: String, title itemTitle: String, type itemType: UserInfoFiledType, iconImageName itemIconImageName: String?, value itemValue: AnyObject?, unitsTitle itemUnitsTitle: String? = nil) {
        
        type = itemType
        name = itemName
        title = itemTitle
        iconImageName = itemIconImageName
        
        super.init()
        
        value = itemValue
        
        unitsTitle = itemUnitsTitle
    }
    
    
    func setNewValue(newValue: AnyObject?) {
        value = newValue
    }
    
    
    func stringValue() -> String? {
        if let _value = value as? String {
            return _value.trimmed()
        }
        return nil
    }
    
    func intValue() -> Int? {
        if let _value = value as? Int {
            return _value
        }
        else if let _value = value as? String {
            return Int(_value)
        }
        
        return nil
    }
    
    func floatValue() -> Float? {
        if let _value = value as? Float {
            return _value
        }
        else if let _value = value as? String {
            return Float(_value)
        }
        return nil
    }

}
