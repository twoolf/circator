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

class DashboardComparisonCell: UITableViewCell {

    @IBOutlet weak var sampleName: UILabel!
    @IBOutlet weak var sampleIcon: UIImageView!
    @IBOutlet weak var localSampleValueTextField: UILabel!
    @IBOutlet weak var populationSampleValueTextField: UILabel!
    
    static let healthFormatter = SampleFormatter()
    
    
    var sampleType: HKSampleType? {
        didSet {
            guard sampleType != nil else {
                sampleIcon.image = nil
                return
            }
            
            sampleIcon.image = PreviewManager.iconForSampleType(sampleType!)
            sampleName.attributedText = self.sampleNameForSampleType(self.sampleType!)
        }
    }
    
    func sampleNameForSampleType(sampleType: HKSampleType) -> NSAttributedString {
        
        switch sampleType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return NSAttributedString(string: NSLocalizedString("Weight", comment: "body mass"),
                                      attributes: [NSForegroundColorAttributeName: UIColor(red: 41/255.0, green: 113.0/255.0, blue: 1.0, alpha: 1.0)])
            
        case HKQuantityTypeIdentifierHeartRate:
            return NSAttributedString(string: NSLocalizedString("Heart rate", comment: "user heart rate"),
                                      attributes: [NSForegroundColorAttributeName: UIColor(red: 225/255.0, green: 53.0/255.0, blue: 34.0/255.0, alpha: 1.0)])
            
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSAttributedString(string: NSLocalizedString("Sleep", comment: "user sleep time"),
                                      attributes: [NSForegroundColorAttributeName: UIColor(red: 184.0/255.0, green: 144.0/255.0, blue: 21.0/255.0, alpha: 1.0)])
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return NSAttributedString(string: NSLocalizedString("Caffeine", comment: "Caffeine level"),
                                      attributes: [NSForegroundColorAttributeName: UIColor(red: 115.0/255.0, green: 0.0/255.0, blue: 170.0/255.0, alpha: 1.0)])
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSAttributedString(string: NSLocalizedString("BMI", comment: "Body mass index"),
                                      attributes: [NSForegroundColorAttributeName: UIColor(red: 148.0/255.0, green: 106.0/255.0, blue: 66.0/255.0, alpha: 1.0)])
            
        default:
            return NSAttributedString(string: "\(sampleType.identifier)")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    /// loading both User and Population samples
    func setUserData(userData: [MCSample], populationAverageData: [MCSample], stalePopulation: Bool = false) {
        loadUserSamples(userData)
        loadPopSamples(populationAverageData, stale: stalePopulation)
    }
    
    private func loadUserSamples( results: [MCSample]) {
        localSampleValueTextField.text = IntroCompareDataTableViewCell.healthFormatter.stringFromSamples(results)
    }
    
    /// note setUserData above that uses this call
    private func loadPopSamples(results: [MCSample], stale: Bool) {
        populationSampleValueTextField.text = IntroCompareDataTableViewCell.healthFormatter.stringFromSamples(results)
    }
}
