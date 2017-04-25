//
//  DashboardFilterItem.swift
//  MetabolicCompass 
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DashboardFilterItem: NSObject {
    var title = ""
    var items: [DashboardFilterCellData] = []

    init(title: String, items: [DashboardFilterCellData]) {
        super.init()

        self.title = title;
        self.items = items
    }
}
