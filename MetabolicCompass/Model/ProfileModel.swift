//
//  ProfileModel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//
import UIKit
import MetabolicCompassKit

class ProfileModel: UserInfoModel {
    
    override func modelItems() -> [ModelItem] {
        var fields = [ModelItem]()
        
        fields.append(self.loadPhotoField)
        fields.append(self.firstNameField)
        fields.append(self.lastNameField)
        fields.append(self.genderField)
        fields.append(self.ageField)
        fields.append(self.unitsSystemField)
        fields.append(self.weightField)
        fields.append(self.heightField)

        let units: UnitsSystem! = UserManager.sharedManager.useMetricUnits() ? UnitsSystem.Metric : UnitsSystem.Imperial
        if units == .Imperial {
            fields.append(self.heightInchesField)
        }
        return fields
    }
    
    func setupValues() {
        let profileInfo = UserManager.sharedManager.getProfileCache()
        let personalProfileInfo = UserManager.sharedManager.getPersonalProfileCache()
        
        let units: UnitsSystem! = UserManager.sharedManager.useMetricUnits() ? UnitsSystem.Metric : UnitsSystem.Imperial
        for item in items {
            if item.type == .Units {
                item.setNewValue(newValue: units.rawValue as AnyObject?)
            }
            else if item.type == .FirstName {
                item.setNewValue(newValue: personalProfileInfo[firstNameField.name])
            }
            else if item.type == .LastName {
                item.setNewValue(newValue: personalProfileInfo[lastNameField.name])
            }
            else if item.type == .Photo {
                item.setNewValue(newValue: UserManager.sharedManager.userProfilePhoto())
            }
           else {
                if item.type == .HeightInches {
                    var cmHeightAsDouble = 0.0
                    if let heightInfo = profileInfo[heightField.name] as? String, let heightAsDouble = Double(heightInfo) {
                        cmHeightAsDouble = heightAsDouble
                    }
                    else if let heightAsDouble = profileInfo[heightField.name] as? Double {
                        cmHeightAsDouble = heightAsDouble
                    }
                    else if let heightAsInt = profileInfo[heightField.name] as? Int {
                        cmHeightAsDouble = Double(heightAsInt)
                    }
                    
                    let heightFtIn = UnitsUtils.heightValue(valueInDefaultSystem: Float(cmHeightAsDouble), withUnits: units)
                    //                    item.setNewValue(newValue: Int(floor((heightFtIn % 1.0) * 12.0)) as AnyObject?)
                    item.setNewValue(newValue: Int(floor((heightFtIn .truncatingRemainder(dividingBy: 1.0)) * 12.0)) as AnyObject?)
                }
                else if let profileItemInfo = profileInfo[item.name]{
                    if item.type == .Gender {
                        let gender = Gender.valueByTitle(title: profileItemInfo as! String)
                        item.setNewValue(newValue: gender.rawValue as AnyObject?)
                    }
                    else if item.type == .Weight {
                        item.setNewValue(newValue: profileItemInfo)
                        if let value = item.floatValue() {
                            // Convert from kg to lb as needed
                            item.setNewValue(newValue: UnitsUtils.weightValue(valueInDefaultSystem: value, withUnits: units) as AnyObject?)
                        }
                    }
                    else if item.type == .Height {
                        item.setNewValue(newValue: profileItemInfo)
                        if let value = item.floatValue() {
                            // Convert from cm to ft/in as needed
                            var convertedValue = UnitsUtils.heightValue(valueInDefaultSystem: value, withUnits: units)
                            if units == .Imperial { convertedValue = floor(convertedValue) }
                            item.setNewValue(newValue: convertedValue as AnyObject?)
                        }
                    }
                    else if item.type == .Weight || item.type == .Height {
                        item.setNewValue(newValue: profileItemInfo)
                        if let value = item.floatValue() {
                            if item.type == .Weight {
                                // Convert from kg to lb as needed
                                item.setNewValue(newValue: UnitsUtils.weightValue(valueInDefaultSystem: value, withUnits: units) as AnyObject?)
                            } else {
                                // Convert from cm to ft/in as needed
                                item.setNewValue(newValue: UnitsUtils.heightValue(valueInDefaultSystem: value, withUnits: units) as AnyObject?)
                            }
                        }
                    }
                    else {
                        item.setNewValue(newValue: profileItemInfo)
                    }
                } else {
                    log.warning("Could not find profile field for \(item.name)")
                }
            }
            
        }
    }

    private let uneditableFields:[UserInfoFieldType] = [.FirstName, .LastName]

    func isItemEditable(item: ModelItem) -> Bool {
        return !uneditableFields.contains(item.type)
    }
    
    override func profileItems() -> [String : String] {
        var newItems : [ModelItem] = [ModelItem]()
        for item in items {
            if isItemEditable(item: item) {
                newItems.append(item)
            }
        }
        return profileItems(newItems: newItems)
    }
    
    override func isModelValid() -> Bool {
        resetValidationResults()
        return isPhotoValid() && /* isEmailValid() && isPasswordValid() && isFirstNameValid() && isLastNameValid() && */ isAgeValid()
            && isWeightValid() && isHeightValid() && (self.units == .Metric ? true : isHeightInchesValid())
    }
}
