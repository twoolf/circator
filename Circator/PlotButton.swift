//
//  PlotButton.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class PlotButton : UIButton {

    dynamic var plotType = 0

    init(plot : Int, frame : CGRect) {
        super.init(frame : frame)
        self.plotType = plot
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
