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

enum UIUserInterfaceIdiom : Int
{
    case Unspecified
    case Phone
    case Pad
}

struct ScreenSize
{
    static let SCREEN_WIDTH         = UIScreen.mainScreen().bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.mainScreen().bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
    static let IS_IPHONE_4_OR_LESS  = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5          = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6          = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P         = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.currentDevice().userInterfaceIdiom == .Pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
}

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
    @IBOutlet weak var chartLegendHeight: NSLayoutConstraint!
    @IBOutlet weak var dailyValuesTopMargin: NSLayoutConstraint!

    //MARK: View life circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fastingSquare.layer.borderColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)?.CGColor
        self.dailyChartModel.daysTableView = self.daysTableView
        self.dailyChartModel.delegate = self
        self.dailyChartModel.registerCells()
        self.dailyProgressChartDaysTable.dataSource = self.dailyChartModel
        self.dailyProgressChartView.prepareChart()
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
        self.activityIndicator.startAnimating()
        self.dailyChartModel.prepareChartData()
        self.dailyChartModel.getDailyProgress()
    }
    
    //MARK: DailyChartModelProtocol
    
    func dataCollectingFinished() {
        self.activityIndicator.stopAnimating()
        self.dailyProgressChartView.updateChartData(self.dailyChartModel.chartDataArray, chartColorsArray: self.dailyChartModel.chartColorsArray)
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if DeviceType.IS_IPHONE_4_OR_LESS {
            self.chartLegendHeight.constant -= 10
        } else if DeviceType.IS_IPHONE_5 {
            self.chartLegendHeight.constant -= 5
        }
    }
}