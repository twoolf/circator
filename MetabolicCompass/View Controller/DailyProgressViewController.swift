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
import SwiftDate
import Crashlytics

enum UIUserInterfaceIdiom : Int
{
    case Unspecified
    case Phone
    case Pad
}

struct ScreenSize
{
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
    static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P         = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
}

class DailyProgressViewController : UIViewController, DailyChartModelProtocol, AppActivityIndicatorContainer {
    private(set) var activityIndicator: AppActivityIndicator?
    
    var dailyChartModel = DailyChartModel()

    @IBOutlet weak var daysTableView: UITableView!
    @IBOutlet weak var dailyProgressChartView: MetabolicDailyProgressChartView!
    @IBOutlet weak var dailyProgressChartScrollView: UIScrollView!
    @IBOutlet weak var dailyProgressChartDaysTable: UITableView!
    @IBOutlet weak var mainScrollView: UIScrollView!

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

    @IBOutlet weak var scrollRecentButton: UIButton!
    @IBOutlet weak var scrollOlderButton: UIButton!

    private var dailyEatingTip: TapTip! = nil
    private var maxDailyFastingTip: TapTip! = nil
    private var lastAteTip: TapTip! = nil

    private var updateContentWithAnimation = true

    private var lastViewDate: Date! = nil

    //MARK: View life circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator = AppActivityIndicator.forView(container: view)
        
        self.setupTooltips()
        self.fastingSquare.layer.borderColor = UIColor.colorWithHex(hex6: 0xffffff, alpha: 0.3).cgColor
        self.dailyChartModel.daysTableView = self.daysTableView
        self.dailyChartModel.delegate = self
        self.dailyChartModel.registerCells()
        self.dailyProgressChartDaysTable.dataSource = self.dailyChartModel

        self.dailyProgressChartView.changeColorCompletion = { 
            OperationQueue.main.addOperation {
                self.updateContentWithAnimation = false
                self.dailyChartModel.toggleHighlightFasting()
                if self.dailyChartModel.highlightFasting {
                    self.fastingSquare.backgroundColor  = MetabolicDailyProgressChartView.highlightFastingColor
                    self.sleepSquare.backgroundColor    = MetabolicDailyProgressChartView.mutedSleepColor
                    self.eatingSquare.backgroundColor   = MetabolicDailyProgressChartView.mutedEatingColor
                    self.exerciseSquare.backgroundColor = MetabolicDailyProgressChartView.mutedExerciseColor
                } else {
                    self.fastingSquare.backgroundColor  = MetabolicDailyProgressChartView.fastingColor
                    self.sleepSquare.backgroundColor    = MetabolicDailyProgressChartView.sleepColor
                    self.eatingSquare.backgroundColor   = MetabolicDailyProgressChartView.eatingColor
                    self.exerciseSquare.backgroundColor = MetabolicDailyProgressChartView.exerciseColor
                }
                self.contentDidUpdate()
            }
        }

        self.dailyProgressChartView.prepareChart()

        self.scrollRecentButton.setImage(UIImage(named: "icon-daily-progress-scroll-recent"), for: .normal)
        self.scrollOlderButton.setImage(UIImage(named: "icon-daily-progress-scroll-older"), for: .normal)

        self.scrollRecentButton.addTarget(self, action: #selector(self.scrollRecent), for: .touchUpInside)
        self.scrollOlderButton.addTarget(self, action: #selector(self.scrollOlder), for: .touchUpInside)

        self.scrollRecentButton.isEnabled = false
        self.scrollOlderButton.isEnabled = true

        NotificationCenter.default.addObserver(self, selector: #selector(self.syncAddedCircadianEvents), name: NSNotification.Name(rawValue: SyncDidUpdateCircadianEvents), object: nil)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let width = self.dailyProgressChartScrollView.contentSize.width
        let height = self.dailyProgressChartView.frame.height
        self.dailyProgressChartScrollView.contentSize = CGSize(width, height)
        self.dailyChartModel.updateRowHeight()
        let mainScrollViewContentWidth = mainScrollView.frame.width
        let mainScrollViewContentHeight = mainScrollView.frame.height
        self.mainScrollView.contentSize = CGSize(mainScrollViewContentWidth, mainScrollViewContentHeight)

        // Update chart data
        self.contentDidUpdate()
    }

    @IBAction private func refreshContent() {
        self.dailyChartModel.refreshChartDateRange(lastViewDate)
        self.contentDidUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dailyChartModel.refreshChartDateRange(lastViewDate)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshContent), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        logContentView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        
        self.lastViewDate = Date()
        logContentView(false)
    }

    func logContentView(_ asAppear: Bool = true) {
        Answers.logContentView(withName: "Body Clock",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().String(),
                                    contentId: Date().string(format: DateFormat.custom("YYYY-MM-dd:HH")),
                                       customAttributes: nil)
    }

    func setupTooltips() {
        let dailyEatingMsg = "Total time spent eating meals today (in hours and minutes)"
        dailyEatingTip = TapTip(forView: dailyEatingContainer, text: dailyEatingMsg, asTop: true)
        dailyEatingContainer.addGestureRecognizer(dailyEatingTip.tapRecognizer)
        dailyEatingContainer.isUserInteractionEnabled = true

        let maxDailyFastingMsg = "Maximum duration spent in a fasting state in the last 24 hours. You are fasting when not eating, that is, while you are awake, sleeping or exercising."

        maxDailyFastingTip = TapTip(forView: maxDailyFastingContainer, text: maxDailyFastingMsg, asTop: true)
        maxDailyFastingContainer.addGestureRecognizer(maxDailyFastingTip.tapRecognizer)
        maxDailyFastingContainer.isUserInteractionEnabled = true

        let lastAteMsg = "Time elapsed since your last meal (in hours and minutes)"
        lastAteTip = TapTip(forView: lastAteContainer, text: lastAteMsg, asTop: true)
        lastAteContainer.addGestureRecognizer(lastAteTip.tapRecognizer)
        lastAteContainer.isUserInteractionEnabled = true
    }

    func contentDidUpdate(withDailyProgress dailyProgress: Bool = true) {
        OperationQueue.main.addOperation {
            self.showActivity()
            
            self.dailyChartModel.prepareChartData()
            if dailyProgress { self.dailyChartModel.getDailyProgress() }
        }
    }
    
    //MARK: DailyChartModelProtocol
    
    func dataCollectingFinished() {
        OperationQueue.main.addOperation {
            self.hideActivity()

            self.dailyChartModel.prepareDataForChart(completion: {[weak self] data in
                self?.dailyChartModel.chartDataAndColors = data
                self?.dailyProgressChartView.updateChartData(animate: (self?.updateContentWithAnimation)!,
                                                             valuesAndColors: (self?.dailyChartModel.chartDataAndColors)!)
                self?.updateContentWithAnimation = true
                self?.dailyProgressChartView.setNeedsDisplay()
            })
        }
    }

    func dailyProgressStatCollected() {
        self.dailyEatingLabel.attributedText = self.dailyChartModel.eatingText.formatTextWithRegex(regex: "[-+]?(\\d*[.,])?\\d+",
                                                                                                   format: [NSAttributedStringKey.foregroundColor: UIColor.white],
                                                                                                   defaultFormat: [NSAttributedStringKey.foregroundColor: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3) as AnyObject])
        
        self.maxDailyFastingLabel.attributedText = self.dailyChartModel.fastingText.formatTextWithRegex(regex: "[-+]?(\\d*[.,])?\\d+",
                                                                                                        format: [NSAttributedStringKey.foregroundColor: UIColor.white],
                                                                                                        defaultFormat: [NSAttributedStringKey.foregroundColor: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3) as AnyObject])
        
        self.lastAteLabel.attributedText = self.dailyChartModel.lastAteText.formatTextWithRegex(regex: "[-+]?(\\d*[.,])?\\d+",
                                                                                                format: [NSAttributedStringKey.foregroundColor: UIColor.white],
                                                                                                defaultFormat: [NSAttributedStringKey.foregroundColor: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3) as AnyObject])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if DeviceType.IS_IPHONE_4_OR_LESS {
            self.chartLegendHeight.constant -= 10
        } else if DeviceType.IS_IPHONE_5 {
            self.chartLegendHeight.constant -= 5
        }
    }

    @objc func scrollRecent() {
        var newDate: Date? = nil
        if let date = self.dailyChartModel.getEndDate() {
//            if !date.isInToday() {
            let today = Date()
            if !date.isInSameDayOf(date: today) {
                let today = Date()
                newDate = today < (date + 1.weeks) ? today : (date + 1.weeks)

                self.scrollRecentButton.isEnabled = !(newDate?.isInSameDayOf(date: today) ?? false)
                self.scrollOlderButton.isEnabled = true

                self.dailyChartModel.setEndDate(newDate)
                self.dailyProgressChartDaysTable.reloadData()
                self.contentDidUpdate(withDailyProgress: false)
            }
        }
    }

    @objc func scrollOlder() {
        var newDate: Date? = nil
        if let date = self.dailyChartModel.getEndDate() {
            let oldest = 3.months.ago()!
            if !date.isInSameDayOf(date: oldest) {
                newDate = (date - 1.weeks) < oldest ? oldest : (date - 1.weeks)

                self.scrollOlderButton.isEnabled = !(newDate?.isInSameDayOf(date: oldest) ?? false)
                self.scrollRecentButton.isEnabled = true

                self.dailyChartModel.setEndDate(newDate)
                self.dailyProgressChartDaysTable.reloadData()
                self.contentDidUpdate(withDailyProgress: false)
            }
        }
    }

    @objc func syncAddedCircadianEvents() {
        Async.background(after: 1.0) {
            self.contentDidUpdate()
        }
    }

    // MARK :- Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
