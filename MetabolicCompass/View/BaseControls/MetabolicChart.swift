//
//  MetabolicChart.swift
//  MetabolicCompass
//
//  Created by Rostislav Roginevich on 7/26/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import SwiftChart

private let plotFontSize = ScreenManager.sharedInstance.eventTimeViewPlotFontSize()
/// initializations of these variables creates offsets so plots of event transitions are square waves
private let stWorkout = 0.0
private let stSleep = 0.33
private let stFast = 0.66
private let stEat = 1.0

class MetabolicChart : Chart {
    convenience init() {
        self.init()

        self.minX = 0.0
        self.maxX = 24.0
        self.minY = 0.0
        self.maxY = 1.3
        
        self.topInset = 25.0
        self.bottomInset = 50.0
        self.lineWidth = 2.0
//        self.labelColor = .whiteColor()
        self.labelFont = UIFont.systemFont(ofSize: plotFontSize)
        
        self.xLabels = [0.0, 6.0, 12.0, 18.0, 24.0]
        self.xLabelsTextAlignment = .left
//        self.xLabelsFormatter = { (labelIndex: Int, labelValue: Float) -> String in
//            let d = 24.hours.ago + (Int(labelValue)).hours
//            return d.toString(DateFormat.Custom("HH:mm"))!
//        }
        
        self.yLabels = [stWorkout, stSleep, stFast, stEat]
        self.yLabelsOnRightSide = true
        
    }
}
