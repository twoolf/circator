//
//  DashboardFilterCellData.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DashboardFilterCellData: NSObject {
    var title    = ""
    var selected = false
    var filterType = 0
    
    init(title: String, selected: Bool, filterType: Int) {
        super.init()
        
        self.title      = title;
        self.selected   = selected;
        self.filterType = filterType;
    }
}
