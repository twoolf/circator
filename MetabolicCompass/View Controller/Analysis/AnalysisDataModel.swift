//
//  AnalysisDataModel.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 10/8/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import MetabolicCompassKit

public class AnalysisDataModel {

    public static let sharedInstance = AnalysisDataModel()

    // MARK: - Data models.

    public var studyStatsModel: StudyStatsModel = StudyStatsModel()

    public var fastingModel: FastingDataModel = FastingDataModel()

    public func refreshStudyStats(ringIndexKeys: [String], completion: Bool -> Void) {
        PopulationHealthManager.sharedManager.fetchStudyStats { (success, payload) in
            if success && payload != nil {
                if let response = payload as? [String:AnyObject], studystats = response["result"] as? [String:AnyObject] {
                    self.studyStatsModel = StudyStatsModel(ringIndexKeys: ringIndexKeys, studystats: studystats)
                    self.studyStatsModel.logModel()
                } else {
                    log.error("Failed to refresh study stats from \(payload)")
                }
            }
            completion(success)
        }
    }
}