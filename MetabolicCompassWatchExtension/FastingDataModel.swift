//
//  FastingDataModel.swift
//  MetabolicCompass
//
//  Created by twoolf on 8/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MCcircadianQueries
import SwiftyBeaver
import MCcircadianQueries

public enum SamplesCollectedIndex {
    case HKType(HKSampleType)
    case Other
}

public class FastingDataModel : NSObject {
    private let log = SwiftyBeaver.self
    public var samplesCollected: [HKSampleType: Int] = [:]
//    public var samplesCollectedDataEntries: [(SamplesCollectedIndex, ChartDataEntry)] = []
    
    public var fastSleep: Double = 0.0
    public var fastAwake: Double = 0.0
    
    public var fastEat: Double = 0.0
    public var fastExercise: Double = 0.0
    
    public var cumulativeWeeklyFasting: Double = 0.0
    public var cumulativeWeeklyNonFast: Double = 0.0
    public var weeklyFastingVariability: Double = 0.0
    
    // Max number of entries to display in the pie chart
    public var maxEntries: Int = 10
    
    // Percentage when sample type is considered as "Other" for the pie chart.
    public var collectedAsOtherThreshold: Double = 0.01
    
    override public init() {
        super.init()
//        initialData()
    }
    
/*    func initialData() {
        for sampleType in PreviewManager.manageChartsSampleTypes {
            samplesCollected[sampleType] = 100
        }
//        self.refreshChartEntries()
        //self.logModel()
    }*/
    
    public func updateData(completion: NSError? -> Void) {
        var someError: [NSError?] = []
        let group = dispatch_group_create()
        
/*        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchSampleCollectionDays(PreviewManager.manageChartsSampleTypes) { (table, error) in
            guard error == nil else {
                self.log.error(error as! String)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.samplesCollected = table
            dispatch_group_leave(group)
        } */
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyFastState { (cFast, cNonFast, error) in
            guard error == nil else {
                self.log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            print("WF STATE result: \(cFast) \(cNonFast)")
            self.cumulativeWeeklyFasting = cFast
            self.cumulativeWeeklyNonFast = cNonFast
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyFastingVariability { (variability, error) in
            guard error == nil else {
                self.log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            print("WF variability result: \(variability)")
            self.weeklyFastingVariability = variability
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyFastType { (fSleep, fAwake, error) in
            guard error == nil else {
                self.log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            print("WF TYPE result: \(fSleep) \(fAwake)")
            self.fastSleep = fSleep
            self.fastAwake = fAwake
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyEatAndExercise { (tEat, tExercise, error) in
            guard error == nil else {
                self.log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            print("WEE result: \(tEat) \(tExercise)")
            self.fastEat = tEat
            self.fastExercise = tExercise
            dispatch_group_leave(group)
        }
        
        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            guard someError.count == 0 else {
                completion(someError[0])
                return
            }
            
//            self.refreshChartEntries()
            self.logModel()
            completion(nil)
        }
    }
    
/*    func refreshChartEntries() {
        var typeFraction : [(SamplesCollectedIndex, Double)] = []
        var typeFractionForOther : [(SamplesCollectedIndex, Double)] = [] // Types to be summarized as "Other"
        
        let sorted = self.samplesCollected.sort({ (a,b) in return a.1 > b.1 })
        let total = sorted.reduce(0.0, combine: { (acc, e) in acc + Double(e.1) })
        
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
            
            self.samplesCollectedDataEntries = typeFraction.enumerate().map {
                return ($0.1.0, ChartDataEntry(value: total == 0.0 ? 0.0 : ( $0.1.1 / total ), xIndex: $0.0))
            }
            
            if !typeFractionForOther.isEmpty {
                let otherTotal = typeFractionForOther.reduce(0.0, combine: { return $0.0 + $0.1.1 })
                let entry = ChartDataEntry(value: otherTotal / total, xIndex: self.samplesCollectedDataEntries.count)
                self.samplesCollectedDataEntries.append((.Other, entry))
            }
        }
    } */
    
    func logModel() {
        print("in logModel")
        log.info("fastSlp: \(self.fastSleep)")
        MetricsStore.sharedInstance.fastSleep = String(self.fastSleep)
        log.info("fastAwk: \(self.fastAwake)")
        MetricsStore.sharedInstance.fastAwake = String(self.fastAwake)
        log.info("fastEat: \(self.fastEat)")
        MetricsStore.sharedInstance.fastEat = String(self.fastEat)
        log.info("fastExc: \(self.fastExercise)")
        MetricsStore.sharedInstance.fastExercise = String(self.fastExercise)
        log.info("cwf: \(self.cumulativeWeeklyFasting)")
        MetricsStore.sharedInstance.cumulativeWeeklyFasting = String(self.cumulativeWeeklyFasting)
        log.info("cwnf: \(self.cumulativeWeeklyNonFast)")
        MetricsStore.sharedInstance.cumulativeWeeklyNonFast = String(self.cumulativeWeeklyNonFast)
        log.info("wvf: \(self.weeklyFastingVariability)")
        MetricsStore.sharedInstance.weeklyFastingVariability = String(self.weeklyFastingVariability)
        log.info("sd: \(self.samplesCollected)")
        MetricsStore.sharedInstance.samplesCollected = String(self.samplesCollected)
    }
}
