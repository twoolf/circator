//
//  MCScatterChartDataSet.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/2/16.
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import Charts

enum DataSetType {
    case BloodPressureTop
    case BloodPressureBottom
    case HartRate
}

class MCScatterChartDataSet: ScatterChartDataSet {
    
    required init() {
        super.init()
    }
    
    override internal var yMin: Double {
        get {
            var entryValues: [Double] = []
            for dataEntry in self.yVals {
                let entry = dataEntry as? BarChartDataEntry
                if let values = entry?.values where values.count > 0 {
                    entryValues += values
                } else {
                    entryValues.append(dataEntry.value)
                }
            }
            if entryValues.count > 0 {
                return entryValues.reduce(entryValues[0], combine: { min($0, $1) })
            }
            return 0
        }
    }
    
    override internal var yMax: Double {
        get {
            var entryValues: [Double] = []
            for dataEntry in self.yVals {
                let entry = dataEntry as? BarChartDataEntry
                if let values = entry?.values where values.count > 0 {
                    entryValues += values
                } else {
                    entryValues.append(dataEntry.value)
                }
            }
            if entryValues.count > 0 {
                return entryValues.reduce(entryValues[0], combine: { max($0, $1) })
            }
            return 0.0
        }
    }
    
    override init(yVals: [ChartDataEntry]?, label: String?) {
        super.init(yVals: yVals, label: label)
        self.scatterShapeHoleColor = UIColor(colorLiteralRed: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        self.colors = [UIColor.whiteColor()]
    }
    
    var dataSetType: DataSetType = .HartRate {
        didSet {
            switch self.dataSetType {
                case .BloodPressureTop:
                    self.scatterShape = .Custom
                    self.customScatterShape = topBloodPressurePath()
                case .BloodPressureBottom:
                    self.scatterShape = .Custom
                    self.customScatterShape = bottomBloodPressurePath()
                default:
                    self.scatterShape = .Circle
                    self.scatterShapeSize = 6.0
                    self.scatterShapeHoleRadius = self.scatterShapeSize/4.0
                }
        }
    }
    
    func topBloodPressurePath() -> CGPath {
        let topPath = UIBezierPath()
        topPath.moveToPoint(CGPointMake(7, 0))
        topPath.addCurveToPoint(CGPointMake(3.5, 3.5), controlPoint1: CGPointMake(7, 1.93), controlPoint2: CGPointMake(5.43, 3.5))
        topPath.addCurveToPoint(CGPointMake(0, 0), controlPoint1: CGPointMake(1.57, 3.5), controlPoint2: CGPointMake(0, 1.93))
        topPath.addLineToPoint(CGPointMake(7, 0))
        topPath.closePath()
        topPath.moveToPoint(CGPointMake(0, 0.32))
        topPath.addLineToPoint(CGPointMake(7, 0.32))
        topPath.addLineToPoint(CGPointMake(0, 0.32))
        topPath.closePath()
        
        return topPath.CGPath
    }
    
    func bottomBloodPressurePath () -> CGPath {
        let bottomPath = UIBezierPath()
        bottomPath.moveToPoint(CGPointMake(7, 3.5))
        bottomPath.addCurveToPoint(CGPointMake(3.5, 0), controlPoint1: CGPointMake(7, 1.57), controlPoint2: CGPointMake(5.43, 0))
        bottomPath.addCurveToPoint(CGPointMake(0, 3.5), controlPoint1: CGPointMake(1.57, 0), controlPoint2: CGPointMake(0, 1.57))
        bottomPath.addLineToPoint(CGPointMake(7, 3.5))
        bottomPath.closePath()
        bottomPath.moveToPoint(CGPointMake(0, 3.18))
        bottomPath.addLineToPoint(CGPointMake(7, 3.18))
        bottomPath.addLineToPoint(CGPointMake(0, 3.18))
        bottomPath.closePath()
        
        return bottomPath.CGPath
    }
}
