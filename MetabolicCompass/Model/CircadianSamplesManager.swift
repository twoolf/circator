//
//  CircadianSamplesManager.swift
//  MetabolicCompass
//
//  Created by Petro Kolesnikov on 5/23/18.
//  Copyright © 2018 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MCCircadianQueries


class CircadianSamplesManager {
    static let sharedInstance = CircadianSamplesManager()
    
    func fetchCircadianSamples(startDate: Date, endDate:Date, completion: @escaping ([CircadianSample]) -> ()) {
        self.fetchHKSamples(startDate: startDate, endDate: endDate)  { samples in
            var circadianSamples = samples.flatMap  { CircadianSample(sample: $0) }.sorted {$0.startDate < $1.startDate}
            circadianSamples = truncate(samples: circadianSamples, from: startDate, to: endDate)
            circadianSamples = fillWithFasting(samples: circadianSamples, from: startDate, to: endDate)
            completion(circadianSamples)
        }
    }
    
    static func intervalDuration(from interval : (Date, Date)?) -> TimeInterval {
        guard let interval = interval else { return 0 }
        return interval.1.timeIntervalSince(interval.0)
    }
    
    private func fetchHKSamples(startDate: Date, endDate:Date, completion: @escaping ([HKSample]) -> ()) {
        var allSamples: ([HKSample]) = []
        let healthStore = HKHealthStore()
        let sleepType = HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let workoutType = HKWorkoutType.workoutType()
        let sampleTypes = [sleepType, workoutType]
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let group = DispatchGroup()
        
        sampleTypes.forEach{ type in
            group.enter()
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
                query, results, error in
                
                if let samples = results {
                    allSamples = allSamples + samples
                }
                group.leave()
            }
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            completion(allSamples)
        }
    }
}


struct CircadianSample {
    let startDate : Date
    let endDate : Date
    let event : CircadianEvent
    
    var duration : Double {
        return self.endDate.timeIntervalSince(self.startDate) / 3600
    }
    
    init(event: CircadianEvent, startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        self.event = event
    }
    
    init?(sample: HKSample) {
        startDate = sample.startDate
        
        if sample.startDate == sample.endDate, let workout = sample as? HKWorkout {
            endDate = startDate.addingTimeInterval(workout.duration)
        } else {
            endDate = sample.endDate
        }

        
        guard let type = sample.hkType else {return nil}
        switch type {
        case is HKWorkoutType:
            guard let workout = sample as? HKWorkout else { return nil }
            
            if workout.workoutActivityType == .preparationAndRecovery,
                let meta = workout.metadata,
                let mealStr = meta["Meal Type"] as? String,
                let mealType = MCCircadianQueries.MealType(rawValue: mealStr) {
                event = .meal(mealType: mealType)
            } else {
                event = .exercise(exerciseType: workout.workoutActivityType)
            }
        case is HKCategoryType:
            guard type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return nil }
            event = .sleep
        default:
            return nil
        }
    }
    
    
    func intersects(with sample: CircadianSample) -> Bool {
        return sample.startDate <= self.endDate && self.startDate <= sample.endDate
    }
}

extension CircadianSample: CustomStringConvertible {
    var description: String {
        var type = ""
        switch event {
        case .meal(let mealType):
            type = "Meal(\(mealType.rawValue))"
        case .fast:
            type = "Fast"
        case .sleep:
            type = "Sleep"
        case .exercise:
            type = "Excersise"
        }
        
        return "\(type) from \(startDate) to \(endDate)"
    }
}

func truncate(samples: [CircadianSample], from startDate: Date, to endDate: Date) -> [CircadianSample]
{
    return samples.filter {
        return $0.startDate < endDate && $0.endDate > startDate
        }
        .map {
            var result = $0
            if (result.startDate < startDate) {
                result = CircadianSample(event: result.event, startDate: startDate, endDate: result.endDate)
            }
            
            if (result.endDate > endDate) {
                result = CircadianSample(event: result.event, startDate: result.startDate, endDate: endDate)
            }
            return result
    }
}

func fillWithFasting(samples: [CircadianSample], from startDate: Date, to endDate: Date) -> [CircadianSample]
{
    guard let firstSample = samples.first, let lastSample = samples.last else {return [CircadianSample(event: .fast, startDate: startDate, endDate: endDate)]}
    
    var results = [CircadianSample]()
    
    if firstSample.startDate != startDate {
        results.append(CircadianSample(event: .fast, startDate: startDate, endDate: firstSample.startDate))
    }
    
    for (index, sample) in samples.enumerated() {
        results.append(sample)
        if index + 1 < samples.count {
            let nextSample = samples[index+1]
            var currentSample = sample
            // In case samples intersects we will truncate first sample to the start of next sample. And ignore such edge case when next sample contains fully inside previous
            if nextSample.intersects(with: currentSample) {
                results.removeLast()
                currentSample = CircadianSample(event: currentSample.event, startDate: currentSample.startDate, endDate: nextSample.startDate)
                results.append(currentSample)
            }
            
            if nextSample.startDate != currentSample.endDate {
                results.append(CircadianSample(event: .fast, startDate: currentSample.endDate, endDate: nextSample.startDate))
            }
        }
    }
    
    if lastSample.endDate != endDate {
        results.append(CircadianSample(event: .fast, startDate: lastSample.endDate, endDate: endDate))
    }
    return results
}
