//
//  WeightMetric.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

final class WeightMetric: NSObject {
    private static let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }()
    
    let date: NSDate
    let pounds: Double
    
    // Calculated by HealthConditions
    var situation: HealthConditions.HealthSituation
    
    init(date: NSDate, pounds: Double) {
        self.date = date
        self.pounds = pounds
        self.situation = .Unknown
        super.init()
    }
    
    convenience init?(json: [String: AnyObject]) {
        guard let dateString = json["t"] as? String, poundsString = json["v"] as? String else {
            return nil
        }
        
        guard let date = WeightMetric.dateFormatter.dateFromString(dateString), let pounds = Double(poundsString) else {
            return nil
        }
        self.init(date: date, pounds: pounds)
    }
    
    override var description: String {
        return "WaterLevel: \(pounds)"
    }
}

// MARK: For Complication
extension WeightMetric {
    var shortTextForComplication: String {
        return String(format: "%.1fm", self.pounds)
    }
    
    var longTextForComplication: String {
        return String(format: "%@, %.1fm",self.situation.rawValue, self.pounds)
    }
}

// MARK: NSCoding
extension WeightMetric: NSCoding {
    private struct CodingKeys {
        static let date = "date"
        static let pounds = "pounds"
        static let situation = "situation"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        let date = aDecoder.decodeObjectForKey(CodingKeys.date) as! NSDate
        let pounds = aDecoder.decodeDoubleForKey(CodingKeys.pounds)
        self.init(date: date, pounds: pounds)
        
        self.situation = HealthConditions.HealthSituation(rawValue: aDecoder.decodeObjectForKey(CodingKeys.situation) as! String)!
    }
    
    func encodeWithCoder(encoder: NSCoder) {
        encoder.encodeObject(date, forKey: CodingKeys.date)
        encoder.encodeDouble(pounds, forKey: CodingKeys.pounds)
        encoder.encodeObject(situation.rawValue, forKey: CodingKeys.situation)
    }
}
