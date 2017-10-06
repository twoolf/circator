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
    case HeartRate
}

class MCScatterChartDataSet: ScatterChartDataSet {
    
    required init() {
        super.init()
    }
 
    override internal var yMin: Double {
        get {
            var entryValues: [Double] = []
            for dataEntry in self.values {
                let entry = dataEntry as? BarChartDataEntry
                if let values = entry?.yValues, values.count > 0 {
                    entryValues += values
                } else {
                    entryValues.append(dataEntry.y)
                }
            }
            if entryValues.count > 0 {
                return entryValues.reduce(entryValues[0], { min($0, $1) })
            }
            return 0
        }
    }
    

    override internal var yMax: Double {
        get {
            var entryValues: [Double] = []
            for dataEntry in self.values {
                let entry = dataEntry as? BarChartDataEntry
                if let values = entry?.yValues, values.count > 0 {
                    entryValues += values
                } else {
                    entryValues.append(dataEntry.y)
                }
            }
            if entryValues.count > 0 {
                return entryValues.reduce(entryValues[0], { max($0, $1) })
            }
            return 0.0
        }
    }
    
    
    override init(values yVals: [ChartDataEntry]?, label: String?) {
        super.init(values: yVals, label: label)
        self.scatterShapeHoleColor = UIColor(red: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        self.colors = [UIColor.white]
    }
    
    var dataSetType: DataSetType = .HeartRate {
        didSet {
            switch self.dataSetType {
                case .BloodPressureTop:
//                    self.scatterShape = .Custom
 //                   self.customScatterShape = topBloodPressurePath()
                    self.scatterShapeSize = 3.0
                case .BloodPressureBottom:
//                    self.scatterShape = .Custom
 //                   self.customScatterShape = bottomBloodPressurePath()
                    self.scatterShapeSize = 9.0
                default:
 //                   self.scatterShape = .Circle
                    self.scatterShapeSize = 6.0
                    self.scatterShapeHoleRadius = self.scatterShapeSize/4.0
                }
        }
    }
    
    func topBloodPressurePath() -> CGPath {
        let topPath = UIBezierPath()
        topPath.move(to: CGPoint(7, 0))
        topPath.addCurve(to: CGPoint(3.5, 3.5), controlPoint1: CGPoint(7, 1.93), controlPoint2: CGPoint(5.43, 3.5))
        topPath.addCurve(to: CGPoint(0, 0), controlPoint1: CGPoint(1.57, 3.5), controlPoint2: CGPoint(0, 1.93))
        topPath.addLine(to: CGPoint(7, 0))
        topPath.close()
        topPath.move(to: CGPoint(0, 0.32))
        topPath.addLine(to: CGPoint(7, 0.32))
        topPath.addLine(to: CGPoint(0, 0.32))
        topPath.close()
        
        return topPath.cgPath
    }
    
    func bottomBloodPressurePath () -> CGPath {
        let bottomPath = UIBezierPath()
        bottomPath.move(to: CGPoint(7, 3.5))
        bottomPath.addCurve(to: CGPoint(3.5, 0), controlPoint1: CGPoint(7, 1.57), controlPoint2: CGPoint(5.43, 0))
        bottomPath.addCurve(to: CGPoint(0, 3.5), controlPoint1: CGPoint(1.57, 0), controlPoint2: CGPoint(0, 1.57))
        bottomPath.addLine(to: CGPoint(7, 3.5))
        bottomPath.close()
        bottomPath.move(to: CGPoint(0, 3.18))
        bottomPath.addLine(to: CGPoint(7, 3.18))
        bottomPath.addLine(to: CGPoint(0, 3.18))
        bottomPath.close()
        
        return bottomPath.cgPath
    }
}
