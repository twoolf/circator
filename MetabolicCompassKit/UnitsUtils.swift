//
//  UnitsUtils.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit


public enum UnitsSystem: Int {
    case Imperial = 0, Metric
    
    public var title: String {
        switch self {
        case .Imperial:
            return "Lbs/Ft in"
        case .Metric:
            return "Kg/Cm"
        }
    }
    
    public var weightTitle: String {
        switch self {
        case .Imperial:
            return "lbs"
        case .Metric:
            return "kg"
        }
    }
    
    public var heightTitle: String {
        switch self {
        case .Imperial:
            return "ft"
        case .Metric:
            return "cm"
        }
    }

    public var heightInchesTitle: String? {
        switch self {
        case .Imperial:
            return "in"
        default:
            return nil
        }
    }
}

public class UnitsUtils: NSObject {
    
    // MARK: - Weight
    
    // from Kg to Kg or Lbs
    public class func weightValue(valueInDefaultSystem value: Float, withUnits units: UnitsSystem) -> Float {
        if units == UnitsSystem.Metric {
            return value
        }
        
        return value * 2.20462
    }
 
    // from Kg or Lbs to Kg
    public class func weightValueInDefaultSystem(fromValue value: Float, inUnitsSystem units: UnitsSystem) -> Float {
        if units == UnitsSystem.Metric {
            return value
        }
        
        return value * 0.453592
    }
    
    // MARK: - Height
    
    // from Cm to Cm or Ft
    public class func heightValue(valueInDefaultSystem value: Float, withUnits units: UnitsSystem) -> Float {
        if units == UnitsSystem.Metric {
            return value
        }
        
        return value * 0.0328084
    }
    
    // from Cm or Ft to Cm
    public class func heightValueInDefaultSystem(fromValue value: Float, inUnitsSystem units: UnitsSystem) -> Float {
        if units == UnitsSystem.Metric {
            return value
        }
        
        return value * 30.48
    }
    

}
