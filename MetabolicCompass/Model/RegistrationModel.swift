//
//  RegistrationModel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

enum RegistrationFiledType: Int {
    case Photo = 0, Email, Password, FirstName, LastName, Gender, Age, Units, Weight, Height
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
    private(set) var placeholder: String
    private(set) var type: RegistrationFiledType
    private(set) var iconImageName: String
    
    private(set) var value: AnyObject?
    
    init(name itemName: String, placeholder itemPlaceholder: String, type itemType: RegistrationFiledType, iconImageName itemIconImageName: String, value itemValue: AnyObject?) {
        
        type = itemType
        name = itemName
        placeholder = itemPlaceholder
        iconImageName = itemIconImageName

        super.init()
        
        value = itemValue
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


class RegistrationModel: NSObject {
    
    private var loadPhotoField: ModelItem!
    private var emailField: ModelItem!
    private var passwordField: ModelItem!
    private var firstNameField: ModelItem!
    private var lastNameField: ModelItem!
    private var genderField: ModelItem!
    private var ageField: ModelItem!
    private var unitsSystemField: ModelItem!
    private var weightField: ModelItem!
    private var heightField: ModelItem!
    
    override init() {
        
        super.init()
        
        var indexes = [String]()
        
        for i in UserProfile.sharedInstance.requiredRange {
            indexes.append(UserProfile.sharedInstance.profileFields[i])
        }
        
        loadPhotoField = ModelItem(name: "Load photo", placeholder: "Load photo", type: .Photo, iconImageName: "icon-email", value: nil)
        emailField = ModelItem(name: indexes[0], placeholder: "E-mail", type: .Email, iconImageName: "icon-email", value: nil)
        passwordField = ModelItem(name: indexes[1], placeholder: "Password", type: .Password, iconImageName: "icon-password", value: nil)
        firstNameField = ModelItem(name: indexes[2], placeholder: "First Name", type: .FirstName, iconImageName: "icon-profile", value: nil)
        lastNameField = ModelItem(name: indexes[3], placeholder: "Last Name", type: .LastName, iconImageName: "", value: nil)
        genderField = ModelItem(name: indexes[4], placeholder: "Gender", type: .Gender, iconImageName: "icon-sex", value: Gender.Male.rawValue)
        ageField = ModelItem(name: indexes[5], placeholder: "Age", type: .Age, iconImageName: "icon-birthday", value: nil)
        weightField = ModelItem(name: indexes[6], placeholder: "Weight", type: .Weight, iconImageName: "icon-weight", value: nil)
        heightField = ModelItem(name: indexes[7], placeholder: "Height", type: .Height, iconImageName: "icon-height", value: nil)
        unitsSystemField = ModelItem(name: "units", placeholder: "Units", type: .Units, iconImageName: "icon-measure", value: UnitsSystem.Metric.rawValue)
        
    }
    
    private(set) lazy var items: [ModelItem] = {
        var fields = [ModelItem]()
        
        fields.append(self.loadPhotoField)
        fields.append(self.emailField)
        fields.append(self.passwordField)
        fields.append(self.firstNameField)
        fields.append(self.lastNameField)
        fields.append(self.genderField)
        fields.append(self.ageField)
        fields.append(self.unitsSystemField)
        fields.append(self.weightField)
        fields.append(self.heightField)
       
        return fields
    }()
    
    
    func profileItems() -> [String : String]  {
        var profile = [String : String]()
        
        for item in items {
            if item.type != .Photo {
                
                if item.type == .Gender {
                    if let value = item.intValue() {
                        let gender = Gender(rawValue: value)!.title
                        print("Selected gender: \(gender)")
                        profile[item.name] = gender
                    }
                }
                
                if let value = item.value as? String {
                    profile[item.name] = value
                }
            }
        }
        
        return profile
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> ModelItem {
        return items[indexPath.row]
    }
    
    func setAtItem(itemIndex itemIndex: Int, newValue: AnyObject?) {
        let fieldItem = items[itemIndex]
        
        fieldItem.setNewValue(newValue)
    }
    
    
    // MARK: - Getting properties
    
    var email: String? {
        return emailField.stringValue()
    }
    
    var password: String? {
        return passwordField.stringValue()
    }

    var firstName: String? {
        return firstNameField.stringValue()
    }
    
    var lastName: String? {
        return lastNameField.stringValue()
    }
    
    var age: Int? {
        return ageField.intValue()
    }
    
    var weight: Float? {
        return weightField.floatValue()
    }

    var height: Float? {
        return heightField.floatValue()
    }
    
    var units: UnitsSystem {
        return UnitsSystem(rawValue: unitsSystemField.intValue()!)!
    }
  
    var gender: Gender {
        return Gender(rawValue: genderField.intValue()!)!
    }
    
    var photo: UIImage? {
        return loadPhotoField.value as? UIImage
    }
    
    // MARK: - Validate properties
    
    private let emptyFieldMessage = "Please, fill all fields"
    private let emailInvalidFormat = "Please, provide valid email"
    private let passwordInvalidFormat = "Please, provide valid password. Password must have ..."
    private let firstNameInvalidFormat = "Please, provide valid password. First name must be ..."
    private let lastNameInvalidFormat = "Please, provide valid password. Last name must be ..."
    private let ageInvalidFormat = "Please, provide valid age. Age must be ..."
    private let weightInvalidFormat = "Please, provide valid weight. Weight must be ..."
    private let heightInvalidFormat = "Please, provide valid height. Heigth must be ..."
    
    private(set) var validationMessage: String?
    
    func isModelValid() -> Bool {
        
        validationMessage = nil
        
        return isPhotoValid() && isEmailValid() && isPasswordValid() && isFirstNameValid() && isLastNameValid() && isAgeValid() && isWeightValid() && isHeightValid()
    }
    
    
    func isPhotoValid() -> Bool {
        return true
    }
    
    func isEmailValid() -> Bool {
        print("email: \(email)")

        var isValid = isRequiredStringValid(email)
        
        if isValid {
            isValid = email!.isValidAsEmail()
            
            if !isValid {
                validationMessage = emailInvalidFormat
            }
            
        }
        else {
            validationMessage = emptyFieldMessage
        }
        
        return isValid
    }
    
    
    func isPasswordValid() -> Bool {
        return isValidString(password, minLength: 4, incorrectMessage: passwordInvalidFormat)
    }
    
    func isFirstNameValid() -> Bool {
        return isValidString(firstName, minLength: 2, incorrectMessage: firstNameInvalidFormat)
    }

    func isLastNameValid() -> Bool {
        
        return isValidString(lastName, minLength: 2, incorrectMessage: lastNameInvalidFormat)
    }
    
    private func isValidString(string: String?, minLength: Int, incorrectMessage: String) -> Bool {
        var isValid = isRequiredStringValid(string)
        
        if isValid {
            isValid = string!.characters.count > minLength
            
            if !isValid {
                validationMessage = incorrectMessage
            }
        }
        else {
            validationMessage = emptyFieldMessage
        }
        
        return isValid
    }
    
    
    func isAgeValid() -> Bool {
        let isValid = isRequiredIntValidInRange(age, minValue: 5, maxValue: 100)
        
        if !isValid {
            validationMessage = age == nil ? emptyFieldMessage : ageInvalidFormat
        }
        
        return isValid
    }
    
    
    private let minWeight:Float = 40 // kg
    private let maxWeight:Float = 350 // kg
    
    func isWeightValid() -> Bool {
        
        let minWidthInUserUnits = UnitsUtils.weightValue(valueInDefaultSystem: minWeight, withUnits: self.units)
        let maxWidthInUserUnits = UnitsUtils.weightValue(valueInDefaultSystem: maxWeight, withUnits: self.units)
        
        let isValid = isRequiredFloatValidInRange(weight, minValue: minWidthInUserUnits, maxValue: maxWidthInUserUnits)
        
        if !isValid {
            validationMessage = weight == nil ? emptyFieldMessage : weightInvalidFormat
        }
        
        return isValid
    }
    
    
    private let minHeight:Float = 75 // cm
    private let maxHeight:Float = 250 // cm
    
    func isHeightValid() -> Bool {
        
        let minHeightInUserUnits = UnitsUtils.weightValue(valueInDefaultSystem: minHeight, withUnits: self.units)
        let maxHeightInUserUnits = UnitsUtils.weightValue(valueInDefaultSystem: maxHeight, withUnits: self.units)
        
        let isValid = isRequiredFloatValidInRange(height, minValue: minHeightInUserUnits, maxValue: maxHeightInUserUnits)
        
        if !isValid {
            validationMessage = height == nil ? emptyFieldMessage : heightInvalidFormat
        }
        
        return isValid
    }
    
    private func isRequiredStringValid(value: String?) -> Bool {
        if let stringValue = value {
            let trimmedString = stringValue.trimmed()
            
            return trimmedString.characters.count > 0
        }
        
        return false
    }
    
    private func isRequiredIntValidInRange(value: Int?, minValue: Int, maxValue: Int) -> Bool {
        if let intValue = value {
            return intValue >= minValue && intValue <= maxValue
        }
        
        return false
    }
    
    private func isRequiredFloatValidInRange(value: Float?, minValue: Float, maxValue: Float) -> Bool {
        if let floatValue = value {
            return floatValue >= minValue && floatValue <= maxValue
        }
        
        return false
    }
}
