//
//  DeleteActivityManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.   
//

import Foundation
import UIKit
import HealthKit
import MetabolicCompassKit
import Async
import SwiftDate
import Crashlytics
import Former
import AwesomeCache
import HTPressableButton
import AKPickerView_Swift
import MCCircadianQueries


public class DeleteActivityManager: UITableView, PickerManagerSelectionDelegate {

    private lazy var delFormer: Former = Former(tableView: self)

    private let buttonsTag: Int = 5000

    private let quickDelRecentItems = [
        "15m",
        "30m",
        "1h",
        "1h 30m",
        "2h",
        "3h",
        "4h",
        "6h",
        "8h",
        "12h",
        "18h",
        "24h"
    ]

    private let quickDelRecentData = [
        "15m"    : 15,
        "30m"    : 30,
        "1h"     : 60,
        "1h 30m" : 90,
        "2h"     : 120,
        "3h"     : 180,
        "4h"     : 240,
        "6h"     : 360,
        "8h"     : 480,
        "12h"    : 720,
        "18h"    : 1080,
        "24h"    : 1440
    ]

    private var delRecentImage: UIImageView! = nil
    private var delRecentManager: PickerManager! = nil
    private var delDates: [Date] = []

    private let delPickerSections = ["Delete Recent Activities", "Delete Activities By Date"]

    private var notificationView: UIView! = nil

    public init(frame: CGRect, style: UITableViewStyle, notificationView: UIView!) {
        self.notificationView = notificationView
        super.init(frame: frame, style: style)
        setupFormer()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open func setupFormer() {
        self.isHidden = true
        self.separatorStyle = .none

        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = UIEdgeInsets.zero
        self.cellLayoutMarginsFollowReadableWidth = false

        let datePickerFontSize: CGFloat = 16.0

        let mediumDateShortTime: (Date) -> String = { date in
            let dateFormatter = DateFormatter()
//            dateFormatter.locale = .Locale()
            dateFormatter.locale = .autoupdatingCurrent
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .medium
            return dateFormatter.string(from: date)
        }

        let deleteRecentRow = AKPickerRowFormer<AKPickerCell>() {
            $0.backgroundColor = .clear
            $0.manager.refreshData(items: self.quickDelRecentItems, data: self.quickDelRecentData as [String : AnyObject])
            $0.manager.delegate = self
            $0.picker.reloadData()
            $0.imageview.image = UIImage(named: "icon-delete-quick")
            self.delRecentImage = $0.imageview
            self.delRecentManager = $0.manager
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }

        var endDate = Date()
//        endDate = endDate.add(minutes: 15 - (endDate.minute % 15))
        endDate = endDate.addingTimeInterval(TimeInterval(15 - (endDate.minute % 15)))
        delDates = [endDate - 15.minutes, endDate]

        let deleteByDateRows = ["Start Date", "End Date"].enumerated().map { (index, rowName) in
            return InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
                $0.backgroundColor = .clear
                $0.titleLabel.text = rowName
                $0.titleLabel.textColor = .white
                $0.titleLabel.font = UIFont(name: "GothamBook", size: datePickerFontSize)!
                $0.displayLabel.textColor = .lightGray
                $0.displayLabel.font = UIFont(name: "GothamBook", size: datePickerFontSize)!
                }.inlineCellSetup {
                    $0.datePicker.datePickerMode = .dateAndTime
                    $0.datePicker.minuteInterval = 15
                    $0.datePicker.date = self.delDates[index]
                }.configure {
                    $0.displayEditingColor = .white
                    $0.date = self.delDates[index]
                }.displayTextFromDate(mediumDateShortTime)
        }

        deleteByDateRows[0].onDateChanged { self.delDates[0] = $0 }
        deleteByDateRows[1].onDateChanged { self.delDates[1] = $0 }

        let sectionHeaderSize = ScreenManager.sharedInstance.quickAddSectionHeaderFontSize()

        let headers = delPickerSections.map { sectionName in
            return LabelViewFormer<FormLabelHeaderView> {
                $0.contentView.backgroundColor = .clear
                $0.titleLabel.backgroundColor = .clear
                $0.titleLabel.textColor = .lightGray
                $0.titleLabel.font = UIFont(name: "GothamBook", size: sectionHeaderSize)!

                let button: MCButton = {
                    let button = MCButton(frame: CGRect(0, 0, 66, 66), buttonStyle: .rounded)
                    button?.buttonColor = .clear
                    button?.shadowColor = .clear
                    button?.shadowHeight = 0

                    button?.setImage(UIImage(named: "icon-trash"), for: .normal)
                    button?.imageView?.contentMode = .scaleAspectFit

                    if sectionName == self.delPickerSections[0] {
                        button?.addTarget(self, action: #selector(self.handleQuickDelRecentTap(sender:)), for: .touchUpInside)

                    } else {
                        button?.addTarget(self, action: #selector(self.handleQuickDelDateTap(sender: )), for: .touchUpInside)
                    }
                    return button!
                }()

                button.translatesAutoresizingMaskIntoConstraints = false
                $0.contentView.addSubview(button)

                let buttonConstraints : [NSLayoutConstraint] = [
                    $0.contentView.topAnchor.constraint(equalTo: button.topAnchor),
                    $0.contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                    $0.contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 10),
                    button.widthAnchor.constraint(equalToConstant: 66),
                    button.heightAnchor.constraint(equalToConstant: 66),
                    $0.titleLabel.heightAnchor.constraint(equalTo: button.heightAnchor)
                ]

                $0.contentView.addConstraints(buttonConstraints)

                }.configure { view in
                    view.viewHeight = 66
                    view.text = sectionName
            }
        }

        let deleteRecentSection = SectionFormer(rowFormer: deleteRecentRow).set(headerViewFormer: headers[0])
        let deleteByDateSection = SectionFormer(rowFormers: deleteByDateRows).set(headerViewFormer: headers[1])
        delFormer.append(sectionFormer: deleteRecentSection, deleteByDateSection)
    }

    func circadianOpCompletion(sender: UIButton?, pickerManager: PickerManager?, error: NSError?) {
        pickerManager?.finishProcessingSelection()
//        if error != nil { log.error(error!.localizedDescription) }
        if error != nil { print("in error") }
        else {
            Async.main {
                UINotifications.genericSuccessMsgOnView(view: self.notificationView ?? self.superview!, msg: "Successfully deleted events.")
                if let sender = sender {
                    sender.isEnabled = true
                    sender.setNeedsDisplay()
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MEMDidUpdateCircadianEvents), object: nil)
        }
    }

    public func handleQuickDelRecentTap(sender: UIButton)  {
//        log.debug("Delete recent tapped", feature: "deleteActivity")
        if let mins = delRecentManager.getSelectedValue() as? Int {
            let endDate = Date()
//            let startDate = endDate.dateByAddingTimeInterval(-(Double(mins) * 60.0))
            let startDate = endDate.addHours(hoursToAdd: -(mins)*60)
//            log.debug("Delete circadian events between \(startDate) \(endDate)", feature: "deleteActivity")
            Async.main { sender.isEnabled = false; sender.setNeedsDisplay() }
            MCHealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate) {
                self.circadianOpCompletion(sender: sender, pickerManager: nil, error: $0)
            }
        }
    }

    public func handleQuickDelDateTap(sender: UIButton) {
        let startDate = delDates[0]
        let endDate = delDates[1]
        if startDate < endDate {
//            log.debug("Delete circadian events between \(startDate) \(endDate)", feature: "deleteActivity")
            Async.main { sender.isEnabled = false; sender.setNeedsDisplay() }
            MCHealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate) {
                self.circadianOpCompletion(sender: sender, pickerManager: nil, error: $0)
            }
        } else {
            UINotifications.genericErrorOnView(view: self.notificationView ?? self.superview!, msg: "Start date must be before the end date")
        }
    }

    func pickerItemSelected(pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) {
//        log.debug("Delete recent picker selected \(item) \(data)", feature: "deleteActivity")
        if let mins = data as? Int {
            let endDate = Date()
//            let startDate = endDate.dateByAddingTimeInterval(-(Double(mins) * 60.0))
            let startDate = endDate.addHours(hoursToAdd: -mins*60)
//            log.debug("Delete circadian events between \(startDate) \(endDate)", feature: "deleteActivity")

            if let rootVC = UIApplication.shared.delegate?.window??.rootViewController {
                var interval = "\(mins) minutes"
                if mins == 60 { interval = "1 hour" }
                else if mins % 60 == 0 { interval = "\(mins/60) hours" }

                let msg = "Are you sure you wish to delete all events in the last \(interval)?"
                let alertController = UIAlertController(title: "", message: msg, preferredStyle: .alert)

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction: UIAlertAction!) in
                    rootVC.dismiss(animated: true, completion: nil)
                    pickerManager.finishProcessingSelection()
                }

                let okAction = UIAlertAction(title: "OK", style: .default) { (alertAction: UIAlertAction!) in
                    rootVC.dismiss(animated: true, completion: nil)
                    MCHealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate) {
                        self.circadianOpCompletion(sender: nil, pickerManager: pickerManager, error: $0)
                    }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                rootVC.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
}
