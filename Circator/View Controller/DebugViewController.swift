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
import HTPressableButton
import Fabric
import Crashlytics
import SwiftDate

private let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
private let noAnchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))

class DebugViewController : FormViewController {

    var genNumUsers : Int! = -1
    var genUserId : String! = "<hash>"
    var genSize   : Int! = 100
    var genStart  : String! = "1/1/2015"
    var genEnd    : String! = "1/1/2016"

    let genDateFormat = DateFormat.Custom("dd/MM/yyyy")

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

        // Data generation inputs and button
        var generateRows : [RowFormer] = []

        generateRows.append(TextFieldRowFormer<FormTextFieldCell>() {
            $0.titleLabel.text = "# Users"
            }.configure {
                let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                $0.attributedPlaceholder = NSAttributedString(string: "100", attributes: attrs)
            }.onTextChanged { [weak self] txt in
                self?.genNumUsers = Int(txt)
            })

        generateRows.append(TextFieldRowFormer<FormTextFieldCell>() {
            $0.titleLabel.text = "User ID"
            }.configure {
                let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                $0.attributedPlaceholder = NSAttributedString(string: self.genUserId, attributes: attrs)
            }.onTextChanged { [weak self] txt in
                self?.genUserId = txt
            })

        generateRows.append(TextFieldRowFormer<FormTextFieldCell>() {
                $0.titleLabel.text = "Dataset size"
            }.configure {
                let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                $0.attributedPlaceholder = NSAttributedString(string: String(self.genSize), attributes: attrs)
            }.onTextChanged { [weak self] txt in
                self?.genSize = Int(txt)
        })

        generateRows.append(TextFieldRowFormer<FormTextFieldCell>() {
            $0.titleLabel.text = "Start date"
            }.configure {
                let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                $0.attributedPlaceholder = NSAttributedString(string: self.genStart, attributes: attrs)
            }.onTextChanged { [weak self] txt in self?.genStart = txt
        })

        generateRows.append(TextFieldRowFormer<FormTextFieldCell>() {
            $0.titleLabel.text = "End date"
            }.configure {
                let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                $0.attributedPlaceholder = NSAttributedString(string: self.genEnd, attributes: attrs)
            }.onTextChanged { [weak self] txt in self?.genEnd = txt
            })

        generateRows.append(LabelRowFormer<FormLabelCell>() {
                let button = MCButton(frame: $0.contentView.frame, buttonStyle: .Rounded)
                button.cornerRadius = 4.0
                button.buttonColor = UIColor.ht_emeraldColor()
                button.shadowColor = UIColor.ht_nephritisColor()
                button.shadowHeight = 4
                button.setTitle("Generate Data", forState: .Normal)
                button.titleLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
                button.addTarget(self, action: "doGenerate", forControlEvents: .TouchUpInside)
                button.enabled = true
                $0.contentView.addSubview(button)
            }.configure {
                $0.enabled = true
            })

        let generateHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.titleLabel.textColor = .grayColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Data generation"
        }
        let generateSection = SectionFormer(rowFormers: Array(generateRows)).set(headerViewFormer: generateHeader)

        former.append(sectionFormer: generateSection, debugAnchorsSection)
    }

    // TODO: use the cached profile rather than directly accessing the HealthManager.
    // The HealthManager will itself push to the profile.
    // Returns the anchor timestamp (i.e., the timestamp of the last sample accessed by an anchor query)
    func getTimestamp(type: HKSampleType) -> NSTimeInterval {
        let (_, ts) = HealthManager.sharedManager.getAnchorAndTSForType(type)
        return ts
    }

    func doGenerate() {
        if genNumUsers > 0 || genUserId != nil {
            let asPopulation = genNumUsers > 0
            let desc = asPopulation ? "\(genNumUsers) users" : "user \(self.genUserId!)"
            if let st = genStart.toDate(genDateFormat), en = genEnd.toDate(genDateFormat) {
                log.info("Generating data for \(desc) between \(st) and \(en)")
                if asPopulation {
                    DataGenerator.sharedInstance.generateDatasetForService(
                        "output.json", numUsers: genNumUsers, size: genSize, startDate: st, endDate: en)
                } else {
                    DataGenerator.sharedInstance.generateDatasetForUser(
                        "output.json", userId: genUserId, size: genSize, startDate: st, endDate: en)
                }
            } else {
                UINotifications.genericError(self, msg: "Invalid start/end date for data generation")
            }
        } else {
            UINotifications.genericError(self, msg: "Please enter a valid # users or a user id for data generation")
        }
    }
    
    class MCButton : HTPressableButton {
        
    }

}
