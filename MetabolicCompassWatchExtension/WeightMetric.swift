//
//  WeightMetric.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

final class WeightMetric: NSObject {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }()
    
    let date: Date
    let pounds: Double
    
    // Calculated by HealthConditions
    var situation: HealthConditions.HealthSituation
    
    init(date: Date, pounds: Double) {
        self.date = date
        self.pounds = pounds
        self.situation = .Unknown
        super.init()
    }
    
    convenience init?(json: [String: AnyObject]) {
        guard let dateString = json["t"] as? String, let poundsString = json["v"] as? String else {
            return nil
        }
        
        guard let date = WeightMetric.dateFormatter.date(from: dateString), let pounds = Double(poundsString) else {
            return nil
        }
        self.init(date: date as Date, pounds: pounds)
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
        let date = aDecoder.decodeObject(forKey: CodingKeys.date) as! Date
        let pounds = aDecoder.decodeDouble(forKey: CodingKeys.pounds)
        self.init(date: date, pounds: pounds)
        
        self.situation = HealthConditions.HealthSituation(rawValue: aDecoder.decodeObject(forKey: CodingKeys.situation) as! String)!
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(date, forKey: CodingKeys.date)
        encoder.encode(pounds, forKey: CodingKeys.pounds)
        encoder.encode(situation.rawValue, forKey: CodingKeys.situation)
    }
}
