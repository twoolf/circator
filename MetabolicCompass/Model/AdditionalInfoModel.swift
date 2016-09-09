//
//  AdditionalInfoModel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/29/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import MCCircadianQueries

class AdditionalSectionInfo: NSObject {

    private(set) var title: String!

    private(set) var items = [ModelItem]()

    init(title sectionTitle: String) {
        super.init()
        title = sectionTitle
    }

    func addItem(modelItem: ModelItem) {
        items.append(modelItem)
    }
}

class AdditionalInfoModel: NSObject {

    private let defaultPlaceholder = "Add your value".localized

    private(set) var sections = [AdditionalSectionInfo]()

    override init() {
        super.init()
        setupSections()
    }

    private func setupSections() {
        let recommendedSection = self.section(withTitle: "Recommended inputs".localized, inRange: UserProfile.sharedInstance.recommendedRange)
        sections.append(recommendedSection)

        let optionalSection = self.section(withTitle: "Optional inputs".localized, inRange: UserProfile.sharedInstance.optionalRange)
        sections.append(optionalSection)
    }

    func setupValues() {
        self.setupSections()
    }

    func loadValues(completion:() -> ()){
        UserManager.sharedManager.pullProfileIfNeeded { res in
            self.updateValues()
            completion()
        }
    }

    func convertFieldValue(fieldName: String, value: AnyObject, toServiceUnits: Bool = true) -> AnyObject {
        var result = value
        let specs = UserProfile.sharedInstance.fields.filter{($0.fieldName == fieldName)}
        if let profileFieldSpec = specs.first {
            let profileFieldName = profileFieldSpec.profileFieldName
            var profileFieldUnits: HKUnit! = nil

            if let customUnit = UserProfile.sharedInstance.customFieldUnits[profileFieldName] {
                profileFieldUnits = customUnit
            } else {
                profileFieldUnits = UserProfile.sharedInstance.profileUnitsMapping[profileFieldSpec.unitsTitle!]!
            }

            var serviceUnits: HKUnit! = nil
            if let (_, quantityType) = HMConstants.sharedInstance.mcdbActivityToHKQuantity[profileFieldName] {
                serviceUnits =  HKObjectType.quantityTypeForIdentifier(quantityType)!.serviceUnit
            }
            else if let type = HMConstants.sharedInstance.mcdbToHK[profileFieldName] {
                if type == HKCategoryTypeIdentifierAppleStandHour ||
                    type == HKCategoryTypeIdentifierSleepAnalysis
                {
                    serviceUnits = HKObjectType.categoryTypeForIdentifier(type)!.serviceUnit
                } else {
                    serviceUnits =  HKObjectType.quantityTypeForIdentifier(type)!.serviceUnit
                }
            }

            if serviceUnits != nil {
                let srcUnits = toServiceUnits ? profileFieldUnits : serviceUnits
                let dstUnits = toServiceUnits ? serviceUnits: profileFieldUnits
                
                if srcUnits != dstUnits {
                    if let d = value as? Double {
                        result = HKQuantity(unit: srcUnits, doubleValue: d).doubleValueForUnit(dstUnits)
                    }
                    else if let i = value as? Int {
                        result = HKQuantity(unit: srcUnits, doubleValue: Double(i)).doubleValueForUnit(dstUnits)
                    }
                    else if let s = value as? String, d = Double(s) {
                        result = HKQuantity(unit: srcUnits, doubleValue: d).doubleValueForUnit(dstUnits)
                    }
                }
            }
        }
        return result
    }

    func updateValues() {
        let profileCache = UserManager.sharedManager.getProfileCache()

        for section in sections {
            for item in section.items {
                if let key = item.key {
                    if let (categoryType, _) = HMConstants.sharedInstance.mcdbActivityToHKQuantity[key],
                            profileCategory = profileCache["activity_value"] as? [String: AnyObject],
                            profileQuantity = profileCategory[categoryType] as? [String: AnyObject],
                            profileValue = profileQuantity[categoryType]
                    {
                        item.value = convertFieldValue(item.name, value: profileValue, toServiceUnits: false)
                    } else if let _ = HMConstants.sharedInstance.mcdbToHK[key], profileValue = profileCache[key] {
                        item.value = convertFieldValue(item.name, value: profileValue, toServiceUnits: false)
                    } else {
                        log.warning("AIM Invalid key \(key)")
                    }
                } else {
                    log.warning("AIM no key found for \(item.name)")
                }
            }
        }
    }

    private func section(withTitle title: String, inRange range: Range<Int>) -> AdditionalSectionInfo {
        let section = AdditionalSectionInfo(title: title)

        for i in range {
            let fieldItem = UserProfile.sharedInstance.fields[i]
            let item = ModelItem(name: fieldItem.fieldName, title: defaultPlaceholder, type: .Other, iconImageName: nil, value: nil, unitsTitle: fieldItem.unitsTitle)
            item.dataType = fieldItem.type
            section.addItem(item)
        }

        return section
    }

    func numberOfItemsInSection(section: Int) -> Int {
        return sections[section].items.count
    }

    func itemAtIndexPath(indexPath: NSIndexPath) -> ModelItem {
        let item = sections[indexPath.section].items[indexPath.row]
        return item
    }

    func sectionTitleAtIndexPath(indexPath: NSIndexPath) -> String {
        return sections[indexPath.section].title
    }

    func setNewValueForItem(atIndexPath indexPath: NSIndexPath, newValue: AnyObject?) {
        let item = self.itemAtIndexPath(indexPath)
        item.setNewValue(newValue)
    }

    func additionalInfoDict(standardizeUnits: Bool = true, completion: (String?, [String: AnyObject]) -> Void) -> Void {
        var error: String? = nil
        let profileCache = UserManager.sharedManager.getProfileCache()

        var items = [ModelItem]()
        for section in sections {
            items.appendContentsOf(section.items)
        }

        var infoDict = [String : AnyObject]()

        for item in items {
            let fieldName = item.name
            if let profileFieldSpec = UserProfile.sharedInstance.fields.filter({ $0.fieldName == fieldName }).first {
                let profileFieldName = profileFieldSpec.profileFieldName

                if let value = item.value {
                    if !validateItem(value) {
                        error = "Please enter a valid number for \(fieldName)"
                        break
                    }

                    if let (categoryType, _) = HMConstants.sharedInstance.mcdbActivityToHKQuantity[profileFieldName]
                    {
                        // Note for categorized types, we must manually do a merge with any existing profile values ourselves.
                        if var profileCategories = profileCache["activity_value"] as? [String: AnyObject],
                            var profileQuantities = profileCategories[categoryType] as? [String: AnyObject]
                        {
                            profileQuantities.updateValue(self.convertFieldValue(fieldName, value: value), forKey: categoryType)
                            profileCategories.updateValue(profileQuantities, forKey: categoryType)
                            infoDict["activity_value"] = profileCategories
                        } else {
                            infoDict["activity_value"] = [categoryType: [categoryType: self.convertFieldValue(fieldName, value: value)]]
                        }
                    }
                    else if let _ = HMConstants.sharedInstance.mcdbToHK[profileFieldName] {
                        infoDict[profileFieldName] = self.convertFieldValue(item.name, value: value)
                    }
                    else {
                        error = "No schema mapping found for \(fieldName) in additional info model"
                        break
                    }
                }
            } else {
                error = "No profile field found for \(fieldName) in additional info model"
                break
            }
        }

        if error != nil {
            completion(error, [:])
        } else {
            log.info("ADID result \(infoDict)")
            completion(nil, infoDict)
        }
    }

    func validateItem(value: AnyObject) -> Bool {
        if let d = value as? Double where d >= 0.0 {
            return true
        }
        else if let i = value as? Int where i >= 0 {
            return true
        }
        else if let s = value as? String, d = Double(s) where d >= 0.0 {
            return true
        }
        return false
    }
}