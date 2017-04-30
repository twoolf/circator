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
            var hkQType : HKSampleType? = nil
            if let hkType = hkType {
                switch hkType {
                    case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
                        hkQType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: hkType))!
                    case HKCategoryTypeIdentifier.appleStandHour.rawValue:
                        hkQType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: hkType))!
                    default:
                        hkQType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: hkType))!
                }
                let mcQueryAttr : MCQueryAttribute = (hkQType!, nil)

                let boundsUnit: HKUnit = hkUnit == nil ? hkQType!.defaultUnit! : hkUnit!
                var convertedLower = Double(lowerBound)
                if boundsUnit != hkQType!.serviceUnit! {
                    convertedLower = HKQuantity(unit: boundsUnit, doubleValue: convertedLower).doubleValue(for: hkQType!.serviceUnit!)
                }

                var convertedUpper = Double(upperBound)
                if hkUnit != hkQType!.serviceUnit! {
                    convertedUpper = HKQuantity(unit: boundsUnit, doubleValue: convertedUpper).doubleValue(for: hkQType!.serviceUnit!)
                }

                return (aggrType, mcQueryAttr, String(convertedLower), String(convertedUpper))
            }
            return nil
        }
    }
    var hkType: String? //something like HKCategoryTypeIdentifierSleepAnalysis etc.
    var hkUnit: HKUnit? = nil // Units for lower/upper bounds. A nil value imples the default unit for the type.
    var aggrType: Aggregate = Aggregate.AggMin //which type of value are we using. If we use Between type will be AggAvg, less AggMin, more AggMax
    var lowerBound = 0
    var upperBound = 0

    init(title: String, hkType: String, hkUnit: HKUnit?, aggrType: Aggregate, lowerBound: Int, upperBound: Int) {
        super.init()
        self.title = title
        self.aggrType = aggrType
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.hkType = hkType
        self.hkUnit = hkUnit
    }
}
