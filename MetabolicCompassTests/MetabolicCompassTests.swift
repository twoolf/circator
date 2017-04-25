//
//  MetabolicCompassTests.swift
//  MetabolicCompassTests
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved. 
//

import XCTest
import Async
import SwiftyBeaver

let log = SwiftyBeaver.self

@testable import MetabolicCompassKit
@testable import MetabolicCompass

class MetabolicCompassTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        // Assume all tests need access to the calendar and HealthKit
        HealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else {
                log.error("Unable to access HealthKit")
                return
            }
            EventManager.sharedManager.checkCalendarAuthorizationStatus { _ in log.info("Accessed HKCal") }
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testFetchPreparationAndRecovery() {
        var passed = false
        HealthManager.sharedManager.fetchPreparationAndRecoveryWorkout(false) { (results, error) in
            log.info("FPRCB \(results) \(error)")
            passed = error == nil
        }
        sleep(5)
        XCTAssert(passed, "Pass preparation and recovery")
    }
}
