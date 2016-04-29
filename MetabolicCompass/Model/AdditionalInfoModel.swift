//
//  AdditionalInfoModel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/29/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

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

    private func section(withTitle title: String, inRange range: Range<Int>) -> AdditionalSectionInfo {
        
        let section = AdditionalSectionInfo(title: title)
        
        for i in range {
            let fieldItem = UserProfile.sharedInstance.fields[i]
            let item = ModelItem(name: fieldItem.fieldName, placeholder: defaultPlaceholder, type: .Other, iconImageName: nil, value: nil, unitsTitle: fieldItem.unitsTitle)
            
            item.dataType = fieldItem.type
            
            section.addItem(item)
        }
        
        return section
    }
    
    func numberOfItemsInSection(section: Int) -> Int {
        return sections[section].items.count
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> ModelItem {
        return sections[indexPath.section].items[indexPath.row]
    }
    
    func sectionTitleAtIndexPath(indexPath: NSIndexPath) -> String {
        return sections[indexPath.section].title
    }
    
    func setNewValueForItem(atIndexPath indexPath: NSIndexPath, newValue: AnyObject?) {
        let item = self.itemAtIndexPath(indexPath)
        
        item.setNewValue(newValue)
    }
    
    func additionalInfoDict() -> [String: AnyObject] {
        var items = [ModelItem]()
        for section in sections {
            items.appendContentsOf(section.items)
        }
        
        var infoDict = [String : AnyObject]()
        
        items.forEach {
            let fieldName = $0.name
            let profileFieldName = UserProfile.sharedInstance.fields.filter{($0.fieldName == fieldName)}.first!.profileFieldName
            
            if let value = $0.value {
                infoDict[profileFieldName] = value
            }
            
        }
    
        return infoDict
    }
}
