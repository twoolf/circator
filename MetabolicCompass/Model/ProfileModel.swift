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
        fields.append(self.emailField)
        fields.append(self.genderField)
        fields.append(self.ageField)
        fields.append(self.unitsSystemField)
        fields.append(self.weightField)
        fields.append(self.heightField)

        if self.units == .Imperial {
            fields.append(self.heightInchesField)
        }

        return fields
    }

    func setupValues() {
        let profileInfo = UserManager.sharedManager.getProfileCache()

        let units: UnitsSystem! = UserManager.sharedManager.useMetricUnits() ? UnitsSystem.Metric : UnitsSystem.Imperial

        for item in items {
            if item.type == .Units {
                item.setNewValue(units.rawValue)
            }
            else if item.type == .FirstName {
                item.setNewValue(AccountManager.shared.userInfo?.firstName)
            }
            else if item.type == .LastName {
                item.setNewValue(AccountManager.shared.userInfo?.lastName)
            }
            else if item.type == .Photo {
                item.setNewValue(UserManager.sharedManager.userProfilePhoto())
            }
            else if item.type == .Email {
                item.setNewValue(UserManager.sharedManager.getUserId())
            } else {
                if item.type == .HeightInches {
                    var cmHeightAsDouble = 0.0
                    if let heightInfo = profileInfo[heightField.name] as? String, heightAsDouble = Double(heightInfo) {
                        cmHeightAsDouble = heightAsDouble
                    }
                    else if let heightAsDouble = profileInfo[heightField.name] as? Double {
                        cmHeightAsDouble = heightAsDouble
                    }
                    else if let heightAsInt = profileInfo[heightField.name] as? Int {
                        cmHeightAsDouble = Double(heightAsInt)
                    }

                    let heightFtIn = UnitsUtils.heightValue(valueInDefaultSystem: Float(cmHeightAsDouble), withUnits: units)
                    item.setNewValue(Int(floor((heightFtIn % 1.0) * 12.0)))
                }
                else if let profileItemInfo = profileInfo[item.name]{
                    if item.type == .Gender {
                        let gender = Gender.valueByTitle(profileItemInfo as! String)
                        item.setNewValue(gender.rawValue)
                    }
                    else if item.type == .Weight {
                        item.setNewValue(profileItemInfo)
                        if let value = item.floatValue() {
                            // Convert from kg to lb as needed
                            item.setNewValue(UnitsUtils.weightValue(valueInDefaultSystem: value, withUnits: units))
                        }
                    }
                    else if item.type == .Height {
                        item.setNewValue(profileItemInfo)
                        if let value = item.floatValue() {
                            // Convert from cm to ft/in as needed
                            var convertedValue = UnitsUtils.heightValue(valueInDefaultSystem: value, withUnits: units)
                            if units == .Imperial { convertedValue = floor(convertedValue) }
                            item.setNewValue(convertedValue)
                        }
                    }
                    else if item.type == .Weight || item.type == .Height {
                        item.setNewValue(profileItemInfo)
                        if let value = item.floatValue() {
                            if item.type == .Weight {
                                // Convert from kg to lb as needed
                                item.setNewValue(UnitsUtils.weightValue(valueInDefaultSystem: value, withUnits: units))
                            } else {
                                // Convert from cm to ft/in as needed
                                item.setNewValue(UnitsUtils.heightValue(valueInDefaultSystem: value, withUnits: units))
                            }
                        }
                    }
                    else {
                        item.setNewValue(profileItemInfo)
                    }
                } else {
                    log.warning("Could not find profile field for \(item.name)")
                }
            }

        }
    }

    private let uneditableFields:[UserInfoFieldType] = [.Email, .FirstName, .LastName]

    func isItemEditable(item: ModelItem) -> Bool {
        return !uneditableFields.contains(item.type)
    }

    override func profileItems() -> [String : String] {
        var newItems : [ModelItem] = [ModelItem]()
        for item in items {
            if isItemEditable(item) {
                newItems.append(item)
            }
        }
        return profileItems(newItems)
    }
    
    override func isModelValid() -> Bool {
        resetValidationResults()
        return isPhotoValid() && /* isEmailValid() && isPasswordValid() && isFirstNameValid() && isLastNameValid() && */ isAgeValid()
                    && isWeightValid() && isHeightValid() && (self.units == .Metric ? true : isHeightInchesValid())
    }
}
