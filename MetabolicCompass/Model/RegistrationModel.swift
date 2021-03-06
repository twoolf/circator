//
//  RegistrationModel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class RegistrationModel: UserInfoModel {
    
    override init() {
        
        super.init()
        
        var indexes = [String]()
        
        for i in UserProfile.sharedInstance.requiredRange {
            indexes.append(UserProfile.sharedInstance.profileFields[i])
        }

    }
    
    override func modelItems() -> [ModelItem] {
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

        if self.units == .Imperial {
            fields.append(self.heightInchesField)
        }

        return fields
    }
    
    override func isModelValid() -> Bool {
        
        resetValidationResults()
        
        return isPhotoValid() && isEmailValid() && isPasswordValid() && isFirstNameValid() && isLastNameValid()
                && isAgeValid() && isWeightValid() && isHeightValid() && (self.units == .Metric ? true : isHeightInchesValid())
    }

}
