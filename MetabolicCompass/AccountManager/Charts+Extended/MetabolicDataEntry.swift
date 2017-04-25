//
//  MetabolicDataEntry.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts

class MetabolicDataEntry: ChartDataEntry {
    
    var pointColor = UIColor.white
    var image: UIImage?
    
    init(value: Double, xIndex: Int, pointColor: UIColor, image: UIImage?) {
        super.init(x: value, y: Double(xIndex))
        self.pointColor = pointColor
        self.image = image
    }
    
    required init()
    {
        super.init()
    }
}
