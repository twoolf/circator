//
//  DashboardComparisonCell.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import MCCircadianQueries

class DashboardComparisonCell: UITableViewCell {

    @IBOutlet weak var sampleName: UILabel!
    @IBOutlet weak var sampleIcon: UIImageView!
    @IBOutlet weak var groupIcon: UIImageView!
    @IBOutlet weak var localSampleValueTextField: UILabel!
    @IBOutlet weak var populationSampleValueTextField: UILabel!

    static let groupFilterImage = UIImage(named: "icon-group-results-filtered")
    static let groupNormalImage = UIImage(named: "icon-group-results")

    static let healthFormatter = SampleFormatter()
    
    var sampleType: HKSampleType? {
        didSet {
            guard sampleType != nil else {
                sampleIcon.image = nil
                return
            }
            
            sampleIcon.image = appearanceProvider.imageForSampleType(sampleType!.identifier, active: true)
            sampleName.attributedText = appearanceProvider.titleForSampleType(sampleType!.identifier, active: true)
        }
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    /// updates the group icon based on whether this cell's type is used as a population filter.
    func setPopulationFiltering(active: Bool) {
        groupIcon?.image = active ? DashboardComparisonCell.groupFilterImage : DashboardComparisonCell.groupNormalImage
    }

    /// loading both User and Population samples
    func setUserData(_ userData: [MCSample], populationAverageData: [MCSample], stalePopulation: Bool = false) {
//    func setUserData(userData: [MCSample], populationAverageData: [MCSample], stalePopulation: Bool = true) {
        loadUserSamples(results: userData)
        loadPopSamples(results: populationAverageData, stale: stalePopulation)
    }
    
    private let defaultTextColor  = UIColor(red: 62.0/255.0, green: 84.0/255.0, blue: 117.0/255.0, alpha: 1.0)
    private let defaultDigitColor = UIColor.white
    private let staleDigitColor   = UIColor.yellow

    private func loadUserSamples(results: [MCSample]) {
        
        if let staleDateStart = results.last?.startDate {
//            let stale = (staleDateStart < Date().addDays(daysToAdd: -1))
            let stale = true
            var text = DashboardComparisonCell.healthFormatter.stringFromSamples(samples: results)
            if stale { text = text + "**" }
        }
        
 //       if let stale = (results.last?.startDate)  { stale.
 //       {  if stale < 1.days.ago) ?? false }

 //       _ = DashboardComparisonCell.healthFormatter.stringFromSamples(samples: results)
 //       if stale { text = text + "**" }
        let stale = true
        var text = DashboardComparisonCell.healthFormatter.stringFromSamples(samples: results)

        let formatAttrs = [NSAttributedStringKey.foregroundColor: stale ? staleDigitColor : defaultDigitColor,
                           NSAttributedStringKey.font : ScreenManager.appFontOfSize(size: 16)]

        let defaultFormatAttrs = [NSAttributedStringKey.foregroundColor: defaultTextColor,
                                  NSAttributedStringKey.font : ScreenManager.appFontOfSize(size: 16)]

        localSampleValueTextField.attributedText =
            text.formatTextWithRegex(regex: "[-+]?(\\d*[.,/])?\\d+", format: formatAttrs, defaultFormat: defaultFormatAttrs)
//        print("local sample \(String(describing: localSampleValueTextField.attributedText))")
    }
    
    /// note setUserData above that uses this call
    private func loadPopSamples(results: [MCSample], stale: Bool) {
        
        var text = DashboardComparisonCell.healthFormatter.stringFromSamples(samples: results)
        if stale { text = text + "**" }
//        print("stale or not in population \(stale)")

        let formatAttrs = [NSAttributedStringKey.foregroundColor: stale ? staleDigitColor : defaultDigitColor,
                           NSAttributedStringKey.font : ScreenManager.appFontOfSize(size: 16)]

        let defaultFormatAttrs = [NSAttributedStringKey.foregroundColor: defaultTextColor,
                                  NSAttributedStringKey.font : ScreenManager.appFontOfSize(size: 16)]

        populationSampleValueTextField.attributedText =
            text.formatTextWithRegex(regex: "[-+]?(\\d*[.,/])?\\d+", format: formatAttrs, defaultFormat: defaultFormatAttrs)
//        print("population sample \(String(describing: populationSampleValueTextField.attributedText))")
    }
    
    
}
