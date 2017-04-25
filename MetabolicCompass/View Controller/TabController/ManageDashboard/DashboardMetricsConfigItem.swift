//
//  DashboardMetricsConfigItem.swift
//  MetabolicCompass 
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit

class DashboardMetricsConfigItem: NSObject {
    var type   = ""
    var active = true
    var object: HKSampleType!
    
    init(type: String, active: Bool, object: HKSampleType) {
        super.init()
        self.type   = type
        self.active = active
        self.object = object
    }
}
