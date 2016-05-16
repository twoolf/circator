//
//  DailyProgressViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

class DailyProgressViewController : UIViewController {
    
    @IBOutlet weak var dailyProgressChartView: MetabolicDailyPorgressChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dailyProgressChartView.prepareChart()
        self.dailyProgressChartView.animate(yAxisDuration: 1.0)
    }
}