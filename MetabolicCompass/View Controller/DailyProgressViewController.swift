//
//  DailyProgressViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit
import Async

class DailyProgressViewController : UIViewController, DailyChartModelProtocol {
    
    var dailyChartModel = DailyChartModel()

    @IBOutlet weak var daysTableView: UITableView!
    @IBOutlet weak var dailyProgressChartView: MetabolicDailyPorgressChartView!
    @IBOutlet weak var dailyProgressChartScrollView: UIScrollView!
    @IBOutlet weak var dailyProgressChartDaysTable: UITableView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var fastingSquare: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var dailyEatingLabel: UILabel!
    @IBOutlet weak var maxDailyFasting: UILabel!
    @IBOutlet weak var lastAteLabel: UILabel!

    //MARK: View life circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fastingSquare.layer.borderColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)?.CGColor
        self.dailyChartModel.daysTableView = self.daysTableView
        self.dailyChartModel.delegate = self
        self.dailyChartModel.registerCells()
        self.dailyProgressChartDaysTable.dataSource = self.dailyChartModel
        self.dailyProgressChartView.prepareChart()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.contentDidUpdate), name: MEMDidUpdateCircadianEvents, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let width = self.dailyProgressChartScrollView.contentSize.width
        let height = CGRectGetHeight(self.dailyProgressChartView.frame)
        self.dailyProgressChartScrollView.contentSize = CGSizeMake(width, height)
        self.dailyChartModel.updateRowHeight()
        let mainScrollViewContentWidth = CGRectGetWidth(self.mainScrollView.frame)
        let mainScrollViewContentHeight = self.mainScrollView.contentSize.height
        self.mainScrollView.contentSize = CGSizeMake(mainScrollViewContentWidth, mainScrollViewContentHeight)
        //updating chart data
        self.contentDidUpdate()
    }

    func contentDidUpdate() {
        Async.main {
            log.info("DPVC CDU")
            self.activityIndicator.startAnimating()
            self.dailyChartModel.prepareChartData()
            self.dailyChartModel.getDailyProgress()
        }
    }
    
    //MARK: DailyChartModelProtocol
    
    func dataCollectingFinished() {
        Async.main {
            log.info("DPVC DCF")
            self.activityIndicator.stopAnimating()
            self.dailyProgressChartView.updateChartData(self.dailyChartModel.chartDataArray, chartColorsArray: self.dailyChartModel.chartColorsArray)
            self.dailyProgressChartView.setNeedsDisplay()
        }
    }
    
    func dailyProgressStatCollected() {
        self.dailyEatingLabel.attributedText = self.dailyChartModel.eatingText.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                                                                                                    format: [NSForegroundColorAttributeName: UIColor.whiteColor()],
                                                                                                    defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!])
        
        self.maxDailyFasting.attributedText = self.dailyChartModel.fastingText.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                                                                                                  format: [NSForegroundColorAttributeName: UIColor.whiteColor()],
                                                                                                  defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!])
        
        self.lastAteLabel.attributedText = self.dailyChartModel.lastAteText.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                                                                                                format: [NSForegroundColorAttributeName: UIColor.whiteColor()],
                                                                                                defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!])
    }

    //MARK: Deinit
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}