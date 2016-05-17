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
    
    var dailyChartModel = DailyChartModel()
    
    @IBOutlet weak var daysTableView: UITableView!
    @IBOutlet weak var dailyProgressChartView: MetabolicDailyPorgressChartView!
    @IBOutlet weak var dailyProgressChartScrollView: UIScrollView!
    @IBOutlet weak var dailyProgressChartDaysTable: UITableView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var fastingSquare: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fastingSquare.layer.borderColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)?.CGColor
        self.dailyChartModel.daysTableView = self.daysTableView
        self.dailyChartModel.registerCells()
        self.dailyProgressChartDaysTable.dataSource = self.dailyChartModel
        self.dailyProgressChartView.prepareChart()
        self.dailyProgressChartView.animate(yAxisDuration: 1.0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let width = self.dailyProgressChartScrollView.contentSize.width
        let height = CGRectGetHeight(self.dailyProgressChartView.frame)
        self.dailyProgressChartScrollView.contentSize = CGSizeMake(width, height)
        self.dailyChartModel.updateRowHeight()
        let mainScrollViewContentWidth = CGRectGetWidth(self.mainScrollView.frame)
        let mainScrollViewContentHeight = self.mainScrollView.contentSize.height
        self.mainScrollView.contentSize = CGSizeMake(mainScrollViewContentWidth, mainScrollViewContentHeight)
    }
}