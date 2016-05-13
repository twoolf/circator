//
//  MetabolicRadarChartView.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts

class MetabolicRadarChartView: RadarChartView {
    
    var iconsIndent = CGFloat(10)

    override var factor: CGFloat {
        let content = self.viewPortHandler.contentRect
        
        let width  = content.width - iconsIndent
        let height = content.height - iconsIndent
        
        return min(width / 2.0, height / 2.0)
            / CGFloat(self.yAxis.axisRange)
    }
    
    override var radius: CGFloat
    {
        let content = self.viewPortHandler.contentRect
        
        let width  = content.width - iconsIndent
        let height = content.height - iconsIndent
        
        return min(width / 2.0, height / 2.0)
    }
}
