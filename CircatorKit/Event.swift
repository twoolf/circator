//
//  RepeatedEvent.swift
//  Circator
//
//  Created by Sihao Lu on 2/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

public struct Weekdays: OptionSetType, CustomStringConvertible {
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(indices: Set<Int>) {
        self.rawValue = indices.map { 1 << $0 }.reduce(0, combine: +)
    }
    
    private static let dayNames = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    private static let shortDayNames = ["M", "T", "W", "Th", "F", "Sa", "Su"]
    
    public let rawValue: Int
    public static let Monday = Weekdays(rawValue: 1)
    public static let Tuesday = Weekdays(rawValue: 1 << 1)
    public static let Wednesday = Weekdays(rawValue: 1 << 2)
    public static let Thursday = Weekdays(rawValue: 1 << 3)
    public static let Friday = Weekdays(rawValue: 1 << 4)
    public static let Saturday = Weekdays(rawValue: 1 << 5)
    public static let Sunday = Weekdays(rawValue: 1 << 6)
    
    private func descriptionWithNames(names: [String], separator: String) -> String {
        return (0..<7).enumerate().flatMap { (index, value) -> [String] in
            if self.rawValue & value == 1 {
                return [names[index]]
            } else {
                return []
            }
        }.joinWithSeparator(separator)
    }
    
    public var description: String {
        return descriptionWithNames(Weekdays.dayNames, separator: ", ")
    }
    
    public var shortDescription: String {
        return descriptionWithNames(Weekdays.shortDayNames, separator: "")
    }
    
    public var indexSet: Set<Int> {
        return Set<Int>((0..<7).filter { self.rawValue & $0 == 1 })
    }
}

public enum Event: CustomStringConvertible {
    
    public enum MealType {
        case Breakfast
        case Lunch
        case Dinner
        case Snack
    }
    
    case Meal(Double, Double, MealType, Weekdays?)
    case Exercise(Double, Double, Weekdays?)
    case Sleep(Double, Double, Weekdays?)
    
    static func timestampWithHour(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) -> (start: Double, end: Double) {
        let endPoint: Double = Double(endHour * 3600 + endMinute * 60)
        let startPoint: Double = Double(startHour * 3600 + startMinute * 60)
        let end = endPoint > startPoint ? endPoint : endPoint + 3600 * 24
        return (start: startPoint, end: end)
    }
    
    public var description: String {
        switch self {
        case .Exercise(_, _, _):
            return "Exercise"
        case .Meal(_, _, let type, _):
            return "Meal: \(String(type))"
        case .Sleep(_, _, _):
            return "Sleep"
        }
    }
    
    public var detailDescription: String {
        func formattedTime(start: Double, _ end: Double, _ repeatInfo: Weekdays?) -> String {
            let repeatString = repeatInfo != nil ? " \(repeatInfo!.shortDescription)" : ""
            return "\(Int(start / 3600)):\(Int((start % 3600) / 60)) - \(Int(end / 3600)):\(Int((end % 3600) / 60))\(repeatString)"
        }
        switch self {
        case let .Exercise(start, end, repeatInfo):
            return formattedTime(start, end, repeatInfo)
        case let .Meal(start, end, _, repeatInfo):
            return formattedTime(start, end, repeatInfo)
        case let .Sleep(start, end, repeatInfo):
            return formattedTime(start, end, repeatInfo)
        }
    }
}
