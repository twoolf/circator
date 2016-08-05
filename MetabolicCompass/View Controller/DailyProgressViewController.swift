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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var fastingSquare: UIView!
    @IBOutlet weak var sleepSquare: UIView!
    @IBOutlet weak var eatingSquare: UIView!
    @IBOutlet weak var exerciseSquare: UIView!

    @IBOutlet weak var dailyEatingLabel: UILabel!
    @IBOutlet weak var maxDailyFastingLabel: UILabel!
    @IBOutlet weak var lastAteLabel: UILabel!
    @IBOutlet weak var chartLegendHeight: NSLayoutConstraint!
    @IBOutlet weak var dailyValuesTopMargin: NSLayoutConstraint!

    @IBOutlet weak var dailyEatingContainer: UIView!
    @IBOutlet weak var maxDailyFastingContainer: UIView!
    @IBOutlet weak var lastAteContainer: UIView!

    private var dailyEatingTip: TapTip! = nil
    private var maxDailyFastingTip: TapTip! = nil
    private var lastAteTip: TapTip! = nil

    private var updateContentWithAnimation = true

    //MARK: View life circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTooltips()
        self.fastingSquare.layer.borderColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)?.CGColor
        self.dailyChartModel.daysTableView = self.daysTableView
        self.dailyChartModel.delegate = self
        self.dailyChartModel.registerCells()
        self.dailyProgressChartDaysTable.dataSource = self.dailyChartModel

        self.dailyProgressChartView.changeColorCompletion = { _ in
            Async.main {
                self.updateContentWithAnimation = false
                self.dailyChartModel.toggleHighlightFasting()
                if self.dailyChartModel.highlightFasting {
                    self.fastingSquare.backgroundColor  = MetabolicDailyPorgressChartView.highlightFastingColor
                    self.sleepSquare.backgroundColor    = MetabolicDailyPorgressChartView.mutedSleepColor
                    self.eatingSquare.backgroundColor   = MetabolicDailyPorgressChartView.mutedEatingColor
                    self.exerciseSquare.backgroundColor = MetabolicDailyPorgressChartView.mutedExerciseColor
                } else {
                    self.fastingSquare.backgroundColor  = MetabolicDailyPorgressChartView.fastingColor
                    self.sleepSquare.backgroundColor    = MetabolicDailyPorgressChartView.sleepColor
                    self.eatingSquare.backgroundColor   = MetabolicDailyPorgressChartView.eatingColor
                    self.exerciseSquare.backgroundColor = MetabolicDailyPorgressChartView.exerciseColor
                }
                self.contentDidUpdate()
            }
        }

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
        self.contentDidUpdate()
    }

    func setupTooltips() {
        let dailyEatingMsg = "Total time spent eating meals today (in hours and minutes)"
        dailyEatingTip = TapTip(forView: dailyEatingContainer, text: dailyEatingMsg, asTop: true)
        dailyEatingContainer.addGestureRecognizer(dailyEatingTip.tapRecognizer)
        dailyEatingContainer.userInteractionEnabled = true

        let maxDailyFastingMsg = "Maximum duration spent in a fasting state in the last 24 hours. You are fasting when not eating, that is, while you are awake, sleeping or exercising."

        maxDailyFastingTip = TapTip(forView: maxDailyFastingContainer, text: maxDailyFastingMsg, asTop: true)
        maxDailyFastingContainer.addGestureRecognizer(maxDailyFastingTip.tapRecognizer)
        maxDailyFastingContainer.userInteractionEnabled = true

        let lastAteMsg = "Time (in hours and minutes) since your last meal"
        lastAteTip = TapTip(forView: lastAteContainer, text: lastAteMsg, asTop: true)
        lastAteContainer.addGestureRecognizer(lastAteTip.tapRecognizer)
        lastAteContainer.userInteractionEnabled = true
    }

    func contentDidUpdate() {
        Async.main {
            if self.activityIndicator != nil {
                self.activityIndicator.startAnimating()
            }
            self.dailyChartModel.prepareChartData()
            self.dailyChartModel.getDailyProgress()
        }
    }
    
    //MARK: DailyChartModelProtocol
    
    func dataCollectingFinished() {
        Async.main {
            self.activityIndicator.stopAnimating()
            self.dailyProgressChartView.updateChartData(self.updateContentWithAnimation,
                                                        valuesArr: self.dailyChartModel.chartDataArray,
                                                        chartColorsArray: self.dailyChartModel.chartColorsArray)
            self.updateContentWithAnimation = true
            self.dailyProgressChartView.setNeedsDisplay()
        }
    }
    
    func dailyProgressStatCollected() {
        self.dailyEatingLabel.attributedText = self.dailyChartModel.eatingText.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                                                                                                    format: [NSForegroundColorAttributeName: UIColor.whiteColor()],
                                                                                                    defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!])
        
        self.maxDailyFastingLabel.attributedText = self.dailyChartModel.fastingText.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
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

    //MARK: Deinit
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
