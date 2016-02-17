//
//  DebugViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/3/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import CircatorKit
import UIKit
import Async
import Former
import Crashlytics

private let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
private let noAnchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))

class DebugViewController : FormViewController {

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Debug View"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var labelRows = HMConstants.sharedInstance.healthKitTypesToObserve.map { type -> RowFormer in
            let tname = type.displayText ?? type.identifier
            return LabelRowFormer<FormLabelCell>() {
                    $0.textLabel?.textColor = .grayColor()
                    $0.textLabel?.text = "\(tname) \(self.getTimestamp(type))"
                }.configure {
                    $0.enabled = true
                }.onSelected { row in
                    log.info("\(tname) \(self.getTimestamp(type))")
                    row.text = "\(tname) \(self.getTimestamp(type))"
            }
        }

        labelRows.append(LabelRowFormer<FormLabelCell>() {
                            $0.textLabel?.text = "Reset anchors"
                            $0.textLabel?.textColor = .redColor()
                            $0.textLabel?.font = .boldSystemFontOfSize(22)
                            }.configure {
                                $0.enabled = true
                            }.onSelected { row in
                                HealthManager.sharedManager.resetAnchors()
                        })

        labelRows.append(LabelRowFormer<FormLabelCell>() {
                            $0.textLabel?.text = "Sync anchors (local)"
                            $0.textLabel?.textColor = .redColor()
                            $0.textLabel?.font = .boldSystemFontOfSize(22)
                            }.configure {
                                $0.enabled = true
                            }.onSelected { row in
                                HealthManager.sharedManager.syncAnchorTS()
            })

        labelRows.append(LabelRowFormer<FormLabelCell>() {
                            $0.textLabel?.text = "Sync anchors (remote)"
                            $0.textLabel?.textColor = .redColor()
                            $0.textLabel?.font = .boldSystemFontOfSize(22)
                            }.configure {
                                $0.enabled = true
                            }.onSelected { row in
                                HealthManager.sharedManager.syncAnchorTS(true)
            })

        labelRows.append(LabelRowFormer<FormLabelCell>() {
            $0.textLabel?.text = "Force a crash"
            $0.textLabel?.textColor = .redColor()
            $0.textLabel?.font = .boldSystemFontOfSize(22)
            }.configure {
                $0.enabled = true
            }.onSelected { row in
                Crashlytics.sharedInstance().crash()
            })

        let debugAnchorsHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.titleLabel.textColor = .grayColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Anchors"
        }

        let debugAnchorsSection = SectionFormer(rowFormers: Array(labelRows)).set(headerViewFormer: debugAnchorsHeader)
        former.append(sectionFormer: debugAnchorsSection)
    }

    // TODO: use the cached profile rather than directly accessing the HealthManager.
    // The HealthManager will itself push to the profile.
    // Returns the anchor timestamp (i.e., the timestamp of the last sample accessed by an anchor query)
    func getTimestamp(type: HKSampleType) -> NSTimeInterval {
        let (_, ts) = HealthManager.sharedManager.getAnchorAndTSForType(type)
        return ts
    }

}
