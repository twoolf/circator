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

        return fields
    }

    // TODO: Yanif: these should all be pulled from the UserManager.
    func setupValues() {
        let profileInfo = UserManager.sharedManager.getProfileCache()

        for item in items {
            if item.type == .FirstName {
                item.setNewValue(AccountManager.shared.userInfo?.firstName)
            }
            else if item.type == .LastName {
                item.setNewValue(AccountManager.shared.userInfo?.lastName)
            }
            else if item.type == .Photo {
                item.setNewValue(UserManager.sharedManager.userProfilePhoto())
            }
            else if item.type == .Units {
                // TODO: get REAL user units value
                item.setNewValue(UnitsSystem.Metric.rawValue)
            }
            else if item.type == .Email {
                item.setNewValue(UserManager.sharedManager.getUserId())
            }
            else {
                let profileItemInfo = profileInfo[item.name]

                if item.type == .Gender {
                    let gender = Gender.valueByTitle(profileItemInfo as! String)
                    item.setNewValue(gender.rawValue)
                }
                else {
                    item.setNewValue(profileItemInfo)
                }
            }

        }
    }

    private let uneditableFields:[UserInfoFiledType] = [.Email, .FirstName, .LastName]

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
        return isPhotoValid() && /* isEmailValid() && isPasswordValid() && isFirstNameValid() && isLastNameValid() && */ isAgeValid()  && isWeightValid() && isHeightValid()
    }
}
