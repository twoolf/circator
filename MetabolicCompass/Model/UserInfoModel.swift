//
//  UserInfoModel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class UserInfoModel: NSObject {

    let emailIndex = 0
    let passwordIndex = 1
    let firstNameIndex = 2
    let lastNameIndex = 3
    let genderIndex = 4
    let ageIndex = 5
    let weightIndex = 6
    let heightIndex = 7
    
    lazy private(set) var loadPhotoField : ModelItem = {
        return ModelItem(name: "Load photo".localized, title: "Load photo", type: .Photo, iconImageName: nil, value: nil)
    }()
    
    lazy private(set) var emailField : ModelItem = {
        return self.modelItem(withIndex: self.emailIndex, iconImageName: "icon-email", value: nil, type: .Email)
    }()

    lazy private(set) var passwordField : ModelItem = {
        return self.modelItem(withIndex: self.passwordIndex, iconImageName: "icon-password", value: nil, type: .Password)
    }()
    
    lazy private(set) var firstNameField : ModelItem = {
        return self.modelItem(withIndex: self.firstNameIndex, iconImageName:"icon-profile", value: nil, type: .FirstName)
    }()

    lazy private(set) var lastNameField : ModelItem = {
        return self.modelItem(withIndex: self.lastNameIndex, iconImageName: nil, value: nil, type: .LastName)
    }()
    
    lazy private(set) var genderField : ModelItem = {
        return self.modelItem(withIndex: self.genderIndex, iconImageName: "icon-sex", value: Gender.Male.rawValue, type: .Gender)
    }()
    
    lazy private(set) var ageField : ModelItem = {
        return self.modelItem(withIndex: self.ageIndex, iconImageName: "icon-birthday", value: nil, type: .Age)
    }()
    
    lazy private(set) var weightField : ModelItem = {
        return self.modelItem(withIndex: self.weightIndex, iconImageName: "icon-weight", value: nil, type: .Weight)
    }()
    
    lazy private(set) var heightField : ModelItem = {
        return self.modelItem(withIndex: self.heightIndex, iconImageName: "icon-height", value: nil, type: .Height)
    }()
    
    lazy private(set) var unitsSystemField : ModelItem = {
         return ModelItem(name: "units", title: "Units", type: .Units, iconImageName: "icon-measure", value: UnitsSystem.Metric.rawValue)
    }()
    
    
    func modelItem(withIndex index: Int, iconImageName: String?, value: AnyObject?, type: UserInfoFiledType = .Other) -> ModelItem {
        let fieldItem = UserProfile.sharedInstance.fields[index]
        
        return ModelItem(name: fieldItem.profileFieldName, title: fieldItem.fieldName, type: type, iconImageName: iconImageName, value: value)
    }
    
    private(set) lazy var items:[ModelItem] = {
        return self.modelItems()
    }()
    
    func modelItems() -> [ModelItem] {
        // Override this
        return [ModelItem]()
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> ModelItem {
        return items[indexPath.row]
    }
    
    func setAtItem(itemIndex itemIndex: Int, newValue: AnyObject?) {
        let fieldItem = items[itemIndex]
        
        fieldItem.setNewValue(newValue)
    }
}
