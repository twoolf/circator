//
//  UserInfoModel.swift
//  MetabolicCompass 
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import Navajo_Swift

class UserInfoModel: NSObject {

    let firstNameIndex    = 0
    let lastNameIndex     = 1
    let genderIndex       = 2
    let ageIndex          = 3
    let weightIndex       = 4
    let heightIndex       = 5
    let heightInchesIndex = 6

    lazy private(set) var loadPhotoField : ModelItem = {
        return ModelItem(name: "Load photo".localized, title: "Load photo", type: .Photo, iconImageName: "iconNoPhoto", value: nil)
    }()

    lazy private(set) var firstNameField : ModelItem = {
        return self.modelItem(withIndex: self.firstNameIndex, iconImageName:"icon-profile", value: nil, type: .FirstName)
    }()

    lazy private(set) var lastNameField : ModelItem = {
        return self.modelItem(withIndex: self.lastNameIndex, iconImageName: nil, value: nil, type: .LastName)
    }()

    lazy private(set) var genderField : ModelItem = {
        return self.modelItem(withIndex: self.genderIndex, iconImageName: "icon-sex", value: Gender.Male.rawValue as AnyObject, type: .Gender)
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

    lazy private(set) var heightInchesField : ModelItem = {
        return ModelItem(name: "", title: "", type: .HeightInches, iconImageName: nil, value: nil)
    }()

    lazy private(set) var unitsSystemField : ModelItem = {
         return ModelItem(name: "metric", title: "Units", type: .Units, iconImageName: "icon-measure", value: UnitsSystem.Imperial.rawValue as AnyObject?)
    }()


    func modelItem(withIndex index: Int, iconImageName: String?, value: AnyObject?, type: UserInfoFieldType = .Other) -> ModelItem {
        let fieldItem = UserProfile.sharedInstance.fields[index]
        return ModelItem(name: fieldItem.profileFieldName, title: fieldItem.fieldName, type: type, iconImageName: iconImageName, value: value)
    }

    private(set) lazy var items:[ModelItem] = {
        return self.modelItems()
    }()

    func reloadItems() {
        items = self.modelItems()
    }

    func modelItems() -> [ModelItem] {
        // Override this
        return [ModelItem]()
    }

    func itemAtIndexPath(indexPath: IndexPath) -> ModelItem {
        return items[indexPath.row]
    }

    func setAtItem(itemIndex: Int, newValue: AnyObject?) {
        let fieldItem = items[itemIndex]

        fieldItem.setNewValue(newValue: newValue)
    }

    func profileItems() -> [String : String] {
        return profileItems(newItems: items, excludeTypes: [.Photo])
    }
    
    //This function returns profile items without user's personal data
    func hipaaCompliantProfileItems() -> [String : String] {
        return profileItems(newItems: items, excludeTypes: [.Photo, .FirstName, .LastName])
    }

    // Note, this returns a profile in the standard units of the MC webservice (i.e., metric).
    // This allows us to directly push the results of this function to the webservice.
    func profileItems(newItems: [ModelItem], excludeTypes : [UserInfoFieldType] = []) -> [String : String]  {
        var profile = [String : String]()
        var heightInchesComponent: String! = nil
        for item in newItems {            
            if excludeTypes.contains(item.type)
            {
                continue
            } else {
                if item.type == .HeightInches {
                    heightInchesComponent = item.stringValue()
                }
                else if item.type == .Gender {
                    if let value = item.intValue() {
                        let gender = Gender(rawValue: value)!.title
                        profile[item.name] = gender
                    }
                }
                else if item.type == .Units {
                    if let value = item.intValue() {
                        profile[item.name] = value == 1 ? "true" : "false"
                    }
                }
                else if let value = item.stringValue() {
                    profile[item.name] = value
                }
            }
        }

        // Standardize to metric units.
        if units == .Imperial {
            if profile[weightField.name] != nil {
                let w = UnitsUtils.weightValueInDefaultSystem(fromValue: (weight ?? 0.0), inUnitsSystem: units)
                profile[weightField.name] = String(format: "%.5g", w)
            }
            if profile[heightField.name] != nil {
                let h : Float = UnitsUtils.heightValueInDefaultSystem(fromValue: (height ?? 0.0) + (Float(heightInches ?? 0) / 12.0), inUnitsSystem: units)
                profile[heightField.name] = String(format: "%.4g", h)
            }
        }

        log.info("PROFILE ITEMS \(heightInchesComponent) \(String(describing: profile[heightField.name])) \(String(describing: profile[weightField.name]))")

        return profile
    }

    func switchItemUnits() {
        if var value = heightField.floatValue() {
            var convertedValue: Float = 0.0
            if units == .Imperial {
                // Units were in metric before we switched
                convertedValue = UnitsUtils.heightValue(valueInDefaultSystem: value, withUnits: units)
            } else {
                // Units were in imperial before we switched
                if let inches = heightInchesField.floatValue() {
                    value += inches / 12.0
                }
                convertedValue = UnitsUtils.heightValueInDefaultSystem(fromValue: value, inUnitsSystem: .Imperial)
            }

            // Set to whole number of feet, and save remainder in inches field.
            if units == .Imperial {
                heightField.setNewValue(newValue: floor(convertedValue) as AnyObject)
                heightInchesField.setNewValue(newValue: Int(floor(convertedValue.truncatingRemainder(dividingBy: 1) * 12.0)) as AnyObject)
            } else {
                heightField.setNewValue(newValue: (round(1000.0*Double(convertedValue))/1000.0) as AnyObject?)
            }
        }

        if let value = weightField.floatValue() {
            var convertedValue: Float = 0.0
            if units == .Imperial {
                // Units were in metric before we switched
                convertedValue = UnitsUtils.weightValue(valueInDefaultSystem: value, withUnits: units)
            } else {
                // Units were in imperial before we switched
                convertedValue = UnitsUtils.weightValueInDefaultSystem(fromValue: value, inUnitsSystem: .Imperial)
            }

//            weightField.setNewValue(newValue: round(1000.0*convertedValue)/1000.0)
            weightField.setNewValue(newValue: round(1000.0*Double(convertedValue))/1000.0 as AnyObject?)
        }
    }

    func unitsDependedItemsIndexes() -> [IndexPath] {
        let indexes = [IndexPath]()

        let weightIndex = items.index(of: weightField)
//        indexes.append(IndexPath(forRow: weightIndex!, inSection: 0))
//        indexes.append(IndexPath(forRow: weightIndex!))
//        indexes.append(indexes)

        _ = items.index(of: heightField)
//        indexes.append(IndexPath(forRow: heightIndex!, inSection: 0))
//        indexes.append(IndexPath(forRow: heightIndex!))
//        indexes.append(indexes)

        return indexes
    }


    // MARK: - Getting properties

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

    var heightInches: Int? {
        return heightInchesField.intValue()
    }

    var units: UnitsSystem {
        return UnitsSystem(rawValue: unitsSystemField.intValue()!)!
    }

    var gender: Gender {
        return Gender(rawValue: genderField.intValue()!)!
//        let gender = genderField.intValue().flatMap { Gender(rawValue: $0) }
//        return gender ?? .Male
    }

    var photo: UIImage? {
        return loadPhotoField.value as? UIImage
    }

    // MARK: - Validate properties

    private let emptyFieldMessage  = "Please enter all fields".localized
    private let emailInvalidFormat = "Please provide a valid email address".localized
    
    private let passwordInvalidFormat  = "Please provide a valid password (must have 1 upper, 1 lower, and 1 number characters)".localized
    private let firstNameInvalidFormat = "Please enter a valid first name (must be at least 2 characters)".localized
    private let lastNameInvalidFormat  = "Please enter a valid surname (must be at least 2 characters)".localized
    private let ageInvalidFormat       = "Please enter a valid age (must be between 18 and 100 years)".localized

    private let metricWeightInvalidFormat    = "Please enter a valid weight (must be from 40kg to 350 kg)".localized
    private let metricHeightInvalidFormat    = "Please enter a valid height (must be from 75cm to 250 cm)".localized

    private let imperialWeightInvalidFormat    = "Please enter a valid weight (must be from 80 lb to 800 lb)".localized
    private let imperialHeightInvalidFormat    = "Please enter a valid height (must be from 2 ft 6in to 8 ft 6 in)".localized

    private let heightInchesInvalidFormat     = "Please enter a valid inches value (must be from 0 to 11)".localized

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

    func isFirstNameValid() -> Bool {
        return isValidString(string: firstName, minLength: 2, incorrectMessage: firstNameInvalidFormat) && containsOnlyLetters(string: firstName!.trimmed(), incorrectMessage: firstNameInvalidFormat)
    }

    func isLastNameValid() -> Bool {
        return isValidString(string: lastName, minLength: 2, incorrectMessage: lastNameInvalidFormat) && containsOnlyLetters(string: lastName!.trimmed(), incorrectMessage: lastNameInvalidFormat)
    }

    private func containsOnlyLetters(string: String, incorrectMessage: String) -> Bool {
        let result = string.containsOnlyLetters()
        if !result {
            validationMessage = incorrectMessage
        }
        return result
    }

    private func isValidString(string: String?, minLength: Int, incorrectMessage: String) -> Bool {
        var isValid = isRequiredStringValid(value: string)

        if isValid {
            isValid = string!.count > minLength

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
        let isValid = isRequiredIntValidInRange(value: age, minValue: 18, maxValue: 100)

        if !isValid {
            validationMessage = age == nil ? emptyFieldMessage : ageInvalidFormat
        }
        return isValid
    }


    private let minWeight:Float = 40     // kg
    private let maxWeight:Float = 350    // kg
    private let minWeightImp:Float = 80  // lbs
    private let maxWeightImp:Float = 800 // lbs

    func isWeightValid() -> Bool {
        let minWeightInUserUnits = self.units == .Metric ? minWeight : minWeightImp
        let maxWeightInUserUnits = self.units == .Metric ? maxWeight : maxWeightImp

        log.info("VALIDATING WEIGHT \(String(describing: weight)) \(minWeightInUserUnits) \(maxWeightInUserUnits)")
        let isValid = isRequiredFloatValidInRange(value: weight, minValue: minWeightInUserUnits, maxValue: maxWeightInUserUnits)

        if !isValid {
            validationMessage = weight == nil ? emptyFieldMessage : (self.units == .Metric ? metricWeightInvalidFormat : imperialWeightInvalidFormat)
        }

        return isValid
    }


    private let minHeight:Float = 75      // cm
    private let maxHeight:Float = 250     // cm
    private let minHeightImp: Float = 2.5 // ft w/ inches
    private let maxHeightImp: Float = 8.5 // ft w/ inches

    func isHeightValid() -> Bool {
        let minHeightInUserUnits = self.units == .Metric ? minHeight : minHeightImp
        let maxHeightInUserUnits = self.units == .Metric ? maxHeight : maxHeightImp

        var heightWithInches = height ?? 0.0
        if units == .Imperial { heightWithInches += Float(heightInches ?? 0) / 12.0 }

        log.info("VALIDATING HEIGHT \(heightWithInches) \(minHeightInUserUnits) \(maxHeightInUserUnits)")
        let isValid = isRequiredFloatValidInRange(value: heightWithInches, minValue: minHeightInUserUnits, maxValue: maxHeightInUserUnits)

        if !isValid {
            validationMessage = height == nil ? emptyFieldMessage : (self.units == .Metric ? metricHeightInvalidFormat : imperialHeightInvalidFormat)
        }
        return isValid
    }

    func isHeightInchesValid() -> Bool {
        let isValid = isRequiredIntValidInRange(value: heightInches, minValue: 0, maxValue: 11)

        if !isValid {
            validationMessage = heightInches == nil ? emptyFieldMessage : heightInchesInvalidFormat
        }
        return isValid
    }

    private func isRequiredStringValid(value: String?) -> Bool {
        if let stringValue = value {
            let trimmedString = stringValue.trimmed()

            return trimmedString.count > 0
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
