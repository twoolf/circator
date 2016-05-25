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

    func profileItems() -> [String : String] {
        return profileItems(items)
    }

    func profileItems(newItems: [ModelItem]) -> [String : String]  {
        var profile = [String : String]()

        for item in newItems {
            if item.type != .Photo {

                if item.type == .Gender {
                    if let value = item.intValue() {
                        let gender = Gender(rawValue: value)!.title
                        //                        print("Selected gender: \(gender)")
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

    func unitsDependedItemsIndexes() -> [NSIndexPath] {
        var indexes = [NSIndexPath]()

        let weightIndex = items.indexOf(weightField)
        indexes.append(NSIndexPath(forRow: weightIndex!, inSection: 0))

        let heightIndex = items.indexOf(heightField)
        indexes.append(NSIndexPath(forRow: heightIndex!, inSection: 0))

        return indexes
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

    private let emptyFieldMessage = "Please, fill all fields".localized
    private let emailInvalidFormat = "Please, provide valid email".localized
    
    private let passwordInvalidFormat = "Please, provide valid password. Password must have at least 4 characters".localized
    private let firstNameInvalidFormat = "Please, provide valid password. First name must be at least 2 characters".localized
    private let lastNameInvalidFormat = "Please, provide valid password. Last name must be at least 2 characters".localized
    private let ageInvalidFormat = "Please, provide valid age. Age must be form 5 to 100 years".localized
    private let weightInvalidFormat = "Please, provide valid weight. Weight must be from 40kg to 350 kg".localized
    private let heightInvalidFormat = "Please, provide valid height. Heigth must be from 75cm to 250 cm".localized
    
    private(set) var validationMessage: String?

    func resetValidationResults() {
        validationMessage = nil
    }

    func isModelValid() -> Bool {
        // Override it
        return false
    }


    func isPhotoValid() -> Bool {
        return true
    }

    func isEmailValid() -> Bool {
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
        return isValidString(firstName, minLength: 2, incorrectMessage: firstNameInvalidFormat) && containsOnlyLetters(firstName!.trimmed(), incorrectMessage: firstNameInvalidFormat)
    }

    func isLastNameValid() -> Bool {
        return isValidString(lastName, minLength: 2, incorrectMessage: lastNameInvalidFormat) && containsOnlyLetters(lastName!.trimmed(), incorrectMessage: lastNameInvalidFormat)
    }

    private func containsOnlyLetters(string: String, incorrectMessage: String) -> Bool {
        let result = string.containsOnlyLetters()
        if !result {
            validationMessage = incorrectMessage
        }
        return result
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
