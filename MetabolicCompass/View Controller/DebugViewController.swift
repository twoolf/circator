//
//  DebugViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/3/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MetabolicCompassKit
import UIKit
import Async
import Former
import HTPressableButton
import Crashlytics
import SwiftDate

private let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
private let noAnchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))

/**
 This class is used to support the creation of datasets for debugging purposes.  We expect that the models used in the creation can be further refined as real data is collected.  For now the data models are based on the NHANES data.

 - note: use of fields to support different metrics (e.g. start-date, end-date)
 */
class DebugViewController : FormViewController {

    var useDebugServer : Bool = false

    var generatorParams : [String: (String, String)] = [
        "rNumUsers"        : ("# Users",          "100"),
        "rUserId"          : ("User id",          "<hash>"),
        "rSize"            : ("Dataset size",     "1000000"),
        "rStart"           : ("Start date",       "1/1/2015"),
        "rEnd"             : ("End date",         "1/1/2016"),
        "cSamplesPerType"  : ("Samples per type", "20"),
        "cStart"           : ("Start date",       "1/1/2015"),
        "cEnd"             : ("End date",         "1/2/2015"),
    ]

    var generatorParamValues : [String: AnyObject] = [:]

    let genDateFormat = DateFormat.Custom("MM/dd/yyyy")

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
        var generateRandRows : [RowFormer] = []

        ["rNumUsers", "rUserId", "rSize", "rStart", "rEnd"].forEach { paramKey in
            if let (lbl, defaultVal) = generatorParams[paramKey] {
                generateRandRows.append(TextFieldRowFormer<FormTextFieldCell>() {
                    $0.titleLabel.text = lbl
                    }.configure {
                        let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                        $0.attributedPlaceholder = NSAttributedString(string: defaultVal, attributes: attrs)
                    }.onTextChanged { [weak self] txt in
                        self?.generatorParamValues[paramKey] = txt
                    })
            }
        }

        generateRandRows.append(LabelRowFormer<FormLabelCell>() {
                let button = MCButton(frame: $0.contentView.frame, buttonStyle: .Rounded)
                button.cornerRadius = 4.0
                button.buttonColor = UIColor.ht_emeraldColor()
                button.shadowColor = UIColor.ht_nephritisColor()
                button.shadowHeight = 4
                button.setTitle("Generate Samples", forState: .Normal)
                button.titleLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
                button.addTarget(self, action: "doGenRandom", forControlEvents: .TouchUpInside)
                button.enabled = true
                $0.contentView.addSubview(button)
            }.configure {
                $0.enabled = true
            })

        let generateRandHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.titleLabel.textColor = .grayColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Randomized Data Generation"
        }
        let generateRandSection = SectionFormer(rowFormers: Array(generateRandRows)).set(headerViewFormer: generateRandHeader)

        // Data generation inputs and button
        var generateCoverRows : [RowFormer] = []

        ["cSamplesPerType", "cStart", "cEnd"].forEach { paramKey in
            if let (lbl, defaultVal) = generatorParams[paramKey] {
                generateCoverRows.append(TextFieldRowFormer<FormTextFieldCell>() {
                    $0.titleLabel.text = lbl
                    }.configure {
                        let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                        $0.attributedPlaceholder = NSAttributedString(string: defaultVal, attributes: attrs)
                    }.onTextChanged { [weak self] txt in
                        self?.generatorParamValues[paramKey] = txt
                    })
            }
        }

        generateCoverRows.append(LabelRowFormer<FormLabelCell>() {
                let button = MCButton(frame: $0.contentView.frame, buttonStyle: .Rounded)
                button.cornerRadius = 4.0
                button.buttonColor = UIColor.ht_emeraldColor()
                button.shadowColor = UIColor.ht_nephritisColor()
                button.shadowHeight = 4
                button.setTitle("Generate Covering Data", forState: .Normal)
                button.titleLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
                button.addTarget(self, action: "doGenCover", forControlEvents: .TouchUpInside)
                button.enabled = true
                $0.contentView.addSubview(button)
            }.configure {
                $0.enabled = true
            })

        let generateCoverHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.titleLabel.textColor = .grayColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Covering Data Generation"
        }
        let generateCoverSection = SectionFormer(rowFormers: Array(generateCoverRows)).set(headerViewFormer: generateCoverHeader)

        former.append(sectionFormer: generateRandSection, generateCoverSection, debugAnchorsSection)
    }

    // TODO: use the cached profile rather than directly accessing the HealthManager.
    // The HealthManager will itself push to the profile.
    // Returns the anchor timestamp (i.e., the timestamp of the last sample accessed by an anchor query)
    func getTimestamp(type: HKSampleType) -> NSTimeInterval {
        let (_, ts) = HealthManager.sharedManager.getAnchorAndTSForType(type)
        return ts
    }

    func doGenRandom() {
        let genUserId : String! = generatorParamValues["rUserId"] as? String
        if let nuParam     = generatorParamValues["rNumUsers"] as? String,
               szParam     = generatorParamValues["rSize"]     as? String,
               genNumUsers = Int(nuParam),
               genSize     = Int(szParam),
               genStart    = generatorParamValues["rStart"]    as? String,
               genEnd      = generatorParamValues["rEnd"]      as? String
        {
            if genNumUsers > 0 || genUserId != nil {
                let asPopulation = genNumUsers > 0
                let desc = asPopulation ? "\(genNumUsers) users" : "user \(genUserId!)"
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
                    UINotifications.genericError(self.navigationController!, msg: "Invalid start/end date for randomized data generation")
                }
            } else {
                UINotifications.genericError(self.navigationController!, msg: "Please enter a valid # users or a user id for randomized data generation")
            }
        }
    }

    func doGenCover() {
        if let sptParam            = generatorParamValues["cSamplesPerType"] as? String,
               genSamplesPerType   = Int(sptParam),
               genStart            = generatorParamValues["cStart"]    as? String,
               genEnd              = generatorParamValues["cEnd"]      as? String
        {
            if let st = genStart.toDate(genDateFormat), en = genEnd.toDate(genDateFormat) {
                log.info("Generating covering dataset between \(st) and \(en)")
                DataGenerator.sharedInstance.generateInMemoryCoveringDataset(genSamplesPerType, startDate: st, endDate: en)
                {
                    $0.forEach { (_,block) in
//                        log.info("entering: )")
                        if !block.isEmpty {
                            autoreleasepool { _ in
                                log.info("Uploading block of size \(block.count)")
                                do {
                                    let jsonObjs = try block.map(HealthManager.sharedManager.jsonifySample)
//                                    log.info("For the following: \(block.first)")
                                    HealthManager.sharedManager.uploadSampleBlock(jsonObjs)
                                } catch  {
                                    log.info("problems with: (\(HealthManager.description())")
                                }
                            }
                        } else {
                            log.info("Empty block for covering data generator")
                        }
                    }
                }
            } else {
                UINotifications.genericError(self.navigationController!, msg: "Invalid start/end date for covering data generation")
            }
        }
    }

    class MCButton : HTPressableButton {}

}
