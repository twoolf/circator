//
//  FastingDataModel.swift
//  MetabolicCompass 
//
//  Created by Yanif Ahmad on 7/9/16.     
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import Charts
import MCCircadianQueries

public enum SamplesCollectedIndex {
    case HKType(HKSampleType)
    case Other
}

public class FastingDataModel : NSObject {
    public var samplesCollected: [HKSampleType: Int] = [:]
    public var samplesCollectedDataEntries: [(SamplesCollectedIndex, ChartDataEntry)] = []

    public var fastSleep: Double = 0.0
    public var fastAwake: Double = 0.0

    public var fastEat: Double = 0.0
    public var fastExercise: Double = 0.0

    public var cumulativeWeeklyFasting: Double = 0.0
    //public var cumulativeWeeklyNonFast: Double = 0.0
    public var weeklyFastingVariability: Double = 0.0

    // Max number of entries to display in the pie chart
    public var maxEntries: Int = 10

    // Percentage when sample type is considered as "Other" for the pie chart.
    public var collectedAsOtherThreshold: Double = 0.01

    override public init() {
        super.init()
        initialData()
    }

    func initialData() {
        for sampleType in PreviewManager.manageChartsSampleTypes {
            samplesCollected[sampleType] = 100
        }
        self.refreshChartEntries()
        //self.logModel()
    }

    public func updateData(completion: @escaping (Error?) -> Void) {
        var someError: [Error?] = []
        let group = DispatchGroup()

        group.enter()
        MCHealthManager.sharedManager.fetchSampleCollectionDays(PreviewManager.manageChartsSampleTypes) { (table, error) in
            guard error == nil else {
 //               log.error(error!.localizedDescription)
                someError.append(error)
                group.leave()
                return
            }

            self.samplesCollected = table
            group.leave()
        }

        /*
        dispatch_group_enter(group)
        MCHealthManager.sharedManager.fetchWeeklyFastState { (cFast, cNonFast, error) in
            guard error == nil else {
                log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }

            log.info("WF F/NF STATE result: \(cFast) \(cNonFast)")
            self.cumulativeWeeklyFasting = cFast
            self.cumulativeWeeklyNonFast = cNonFast
            dispatch_group_leave(group)
        }
        */

        group.enter()
        let dateAgo = Date().addDays(daysToAdd: -7)
//        MCHealthManager.sharedManager.fetchMaxFastingTimes(1.weeks.ago) { (dailyMax, error) in
        MCHealthManager.sharedManager.fetchMaxFastingTimes(dateAgo as NSDate?) { (dailyMax, error) in
            guard error == nil else {
//                log.error(error!.localizedDescription)
                someError.append(error)
                group.leave()
                return
            }

            self.cumulativeWeeklyFasting = dailyMax.reduce(0.0, { $0 + $1.1 })
//            log.info("WF MAXF result: \(dailyMax) \(self.cumulativeWeeklyFasting)")
            group.leave()
        }

        group.enter()
        MCHealthManager.sharedManager.fetchWeeklyFastingVariability { (variability, error) in
            guard error == nil else {
//                log.error(error!.localizedDescription)
                someError.append(error)
                group.leave()
                return
            }

//            log.info("WF variability result: \(variability)")
            self.weeklyFastingVariability = variability
            group.leave()
        }

        group.enter()
        MCHealthManager.sharedManager.fetchWeeklyFastType { (fSleep, fAwake, error) in
            guard error == nil else {
//                log.error(error!.localizedDescription)
                someError.append(error)
                group.leave()
                return
            }

//            log.info("WF FS/FA TYPE result: \(fSleep) \(fAwake)")
            self.fastSleep = fSleep
            self.fastAwake = fAwake
            group.leave()
        }

        group.enter()
        MCHealthManager.sharedManager.fetchWeeklyEatAndExercise { (tEat, tExercise, error) in
            guard error == nil else {
//                log.error(error!.localizedDescription)
                someError.append(error)
                group.leave()
                return
            }

//            log.info("WEE result: \(tEat) \(tExercise)") 
            self.fastEat = tEat
            self.fastExercise = tExercise
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            guard someError.count == 0 else {
                completion(someError[0])
                return
            }
            self.refreshChartEntries()
            completion(nil)
        }

//        DispatchGroup.notify(qos: group, queue: DispatchQueue.global(DISPATCH_QUEUE_PRIORITY_BACKGROUND)) {
   /*    group.notify(qos: group, queue: DispatchQueue.main) {
            guard someError.count == 0 else {
                completion(someError[0])
                return
            }

            self.refreshChartEntries()
            // self.logModel()
            completion(nil)
        } */
    }

    func refreshChartEntries() {
        var typeFraction : [(SamplesCollectedIndex, Double)] = []
        var typeFractionForOther : [(SamplesCollectedIndex, Double)] = [] // Types to be summarized as "Other"

        let sorted = self.samplesCollected.sorted(by: { (a,b) in return a.1 > b.1 })
        let total = sorted.reduce(0.0, { (acc, e) in acc + Double(e.1) })

        if total == 0.0 {
            self.samplesCollectedDataEntries = []
        } else {
            var i: Int = 0
            sorted.forEach {
                if i >= maxEntries || ( (Double($0.1) / total) < collectedAsOtherThreshold ) {
                    typeFractionForOther.append((.HKType($0.0), Double($0.1)))
                }
                else { typeFraction.append((.HKType($0.0), Double($0.1))) }
                i += 1
            }

            self.samplesCollectedDataEntries = typeFraction.enumerated().map {
                return ($0.1.0, ChartDataEntry(x: total == 0.0 ? 0.0 : ( $0.1.1 / total ), y: Double($0.0)))
            }

            if !typeFractionForOther.isEmpty {
                let otherTotal = typeFractionForOther.reduce(0.0, { return $0.0 + $0.1.1 })
                let entry = ChartDataEntry(x: otherTotal / total, y: Double(self.samplesCollectedDataEntries.count))
                self.samplesCollectedDataEntries.append((.Other, entry))
            }
        }
    }

    func logModel() {
//        log.info("fastSlp: \(self.fastSleep)")
//        log.info("fastAwk: \(self.fastAwake)")
//        log.info("fastEat: \(self.fastEat)")
//        log.info("fastExc: \(self.fastExercise)")
//        log.info("cwf: \(self.cumulativeWeeklyFasting)")
        //log.info("cwnf: \(self.cumulativeWeeklyNonFast)")
//        log.info("wvf: \(self.weeklyFastingVariability)")
//        log.info("sd: \(self.samplesCollected)")
    }
}

