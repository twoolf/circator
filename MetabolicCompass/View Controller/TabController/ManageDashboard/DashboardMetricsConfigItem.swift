//
//  DashboardMetricsConfigItem.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DashboardMetricsConfigItem: NSObject {
    var type   = ""
    var active = true
    
    init(type: String, active: Bool) {
        super.init()
        self.type   = type
        self.active = active
    }
}
