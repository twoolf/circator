//
//  DashboardFilterCellData.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import HealthKit

class DashboardFilterCellData: NSObject {
    var title    = ""
    var selected = false
    var predicate: MCQueryPredicate? {
        get {
            var hkQType : HKObjectType? = nil
            if let hkType = hkType {
                switch hkType {
                    case HKCategoryTypeIdentifierSleepAnalysis:
                        hkQType = HKObjectType.categoryTypeForIdentifier(hkType)!
                    case HKCategoryTypeIdentifierAppleStandHour:
                        hkQType = HKObjectType.categoryTypeForIdentifier(hkType)!
                    default:
                        hkQType = HKObjectType.quantityTypeForIdentifier(hkType)!
                }
                let mcQueryAttr : MCQueryAttribute = (hkQType!, nil)
                return (aggrType, mcQueryAttr, String(lowerBound), String(upperBound))
            }
            return nil
        }
    }
    var hkType: String? //something like HKCategoryTypeIdentifierSleepAnalysis etc.
    var aggrType: Aggregate = Aggregate.AggMin //which type of value are we using. If we use Between type will be AggAvg, less AggMin, more AggMax
    var lowerBound = 0
    var upperBound = 0
    
    init(title: String, hkType: String, aggrType: Aggregate, lowerBound: Int, upperBound: Int) {
        super.init()
        self.title = title
        self.aggrType = aggrType
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.hkType = hkType
    }
}
