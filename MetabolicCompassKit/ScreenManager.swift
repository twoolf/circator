//
//  ScreenManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/19/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import Charts

/**
 We aim to support all Apple iPhone screen sizes. Towards that goal this class switches variables to reflect the user's particular phone. We use Apple's screen size from UIScreen to determine the appropriate values to set.

 */
public class ScreenManager {
    public static let sharedInstance = ScreenManager()

    func labelFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 14
        } else {
            return 16
        }
    }

    func inputFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 14
        } else {
            return 14
        }
    }

    public func dashboardRows() -> Int {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 4
        } else if (570 < screenHeight && screenHeight < 734) {
            return 6
        } else {
            return 7
        }
    }

    public func dashboardButtonHeight() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 28.0
        } else {
            return 35.0
        }
    }

    public func dashboardTitleLeading() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 60.0
        } else {
            return 80.0
        }
    }

    public func loginButtonFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 16.0
        } else {
            return 20.0
        }
    }

    public func settingsCellTrailing() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 15.0
        } else {
            return 20.0
        }
    }

    public func radarLegendPosition() -> ChartLegend.Position {
        return ChartLegend.Position.BelowChartCenter
    }

    public func eventTimeViewSummaryFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 18
        } else {
            return 24
        }
    }

    public func eventTimeViewPlotFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 10.5
        } else {
            return 12
        }
    }

    public func eventTimeViewHeight() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 60
        } else {
            return 100
        }
    }
    
    public func radarChartBottomIndent() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height
        
        if (screenHeight < 569) {
            return 20
        } else {
            return 50
        }
    }

    public func loginLabelFontSize() -> CGFloat {
        return labelFontSize()
    }

    public func loginInputFontSize() -> CGFloat {
        return inputFontSize()
    }

    public func profileLabelFontSize() -> CGFloat {
        return labelFontSize()
    }

    public func profileInputFontSize() -> CGFloat {
        return inputFontSize()
    }

    public func queryBuilderLabelFontSize() -> CGFloat {
        return labelFontSize()
    }

    public func queryBuilderInputFontSize() -> CGFloat {
        return inputFontSize()
    }
    
    // MARK: - colors
    
    public class func appTitleColor() -> UIColor {
        return UIColor(red: 0.58, green: 0.63, blue: 0.71, alpha: 1.0)
    }
    
    public class func appNavigationBackColor() -> UIColor {
        return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    public func appBgColor() -> UIColor {
        return UIColor(red: 0.047, green: 0.1412, blue: 0.318, alpha: 1.0)
    }
    
    public func appBrightBlueColor() -> UIColor {
        return UIColor(red: 0.298, green: 0.533, blue: 0.968, alpha: 1.0)
    }
    
    public func appGrayColor() -> UIColor {
        return UIColor(red: 0.325, green: 0.4, blue: 0.521, alpha: 1.0)
    }
    
    // MARK: - Fonts
    
    public func appFontOfSize(size: CGFloat) -> UIFont {
        return UIFont.systemFontOfSize(size)
    }
    
}
