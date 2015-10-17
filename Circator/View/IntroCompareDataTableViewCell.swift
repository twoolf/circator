//
//  IntroCompareDataTableViewCell.swift
//  Circator
//
//  Created by Sihao Lu on 10/2/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit

class IntroCompareDataTableViewCell: UITableViewCell {
    
    lazy var healthParameterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        imageView.tintColor = Theme.universityDarkTheme.foregroundColor
        return imageView
    }()
    
    lazy var userDataLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.universityDarkTheme.bodyTextColor
        label.backgroundColor = UIColor.clearColor()
        label.text = "75 kg"
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(20)
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var populationAverageLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.universityDarkTheme.bodyTextColor
        label.backgroundColor = UIColor.clearColor()
        label.text = "123"
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(20)
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var labelContainerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.userDataLabel, self.populationAverageLabel])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 10
        return stackView
    }()
    
    var sampleType: HKSampleType? {
        didSet {
            let image: UIImage
            guard sampleType != nil else {
                healthParameterImageView.image = nil
                return
            }
            switch sampleType!.identifier {
            case HKQuantityTypeIdentifierBodyMass:
                image = UIImage(named: "icon_weight")!
            case HKQuantityTypeIdentifierHeartRate:
                image = UIImage(named: "icon_heart_rate")!
            case HKCategoryTypeIdentifierSleepAnalysis:
                image = UIImage(named: "icon_sleep")!
            case HKQuantityTypeIdentifierDietaryEnergyConsumed:
                image = UIImage(named: "icon_food")!
            case HKCorrelationTypeIdentifierBloodPressure:
                image = UIImage(named: "icon_blood_pressure")!
            default:
                image = UIImage()
            }
            healthParameterImageView.image = image
        }
    }
    
    static let healthFormatter = SampleFormatter()
    
    func setUserData(userData: [HKSample], populationAverageData: [HKSample]) {
        loadSamples(userData, toLabel: userDataLabel)
        loadSamples(populationAverageData, toLabel: populationAverageLabel)
    }
    
    private func loadSamples(samples: [HKSample], toLabel label: UILabel) {
        label.text = "\(IntroCompareDataTableViewCell.healthFormatter.stringFromSamples(samples))"
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    private func configureView() {
        backgroundColor = UIColor.clearColor()
        contentView.addSubview(healthParameterImageView)
        healthParameterImageView.translatesAutoresizingMaskIntoConstraints = false
        let imageViewConstraints: [NSLayoutConstraint] = [
            healthParameterImageView.leadingAnchor.constraintEqualToAnchor(contentView.layoutMarginsGuide.leadingAnchor, constant: 10),
            healthParameterImageView.widthAnchor.constraintEqualToAnchor(healthParameterImageView.heightAnchor),
            healthParameterImageView.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant: 8),
            healthParameterImageView.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor, constant: -8),
            healthParameterImageView.heightAnchor.constraintEqualToConstant(37)
        ]
        contentView.addConstraints(imageViewConstraints)
        labelContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelContainerView)
        let labelConstraints: [NSLayoutConstraint] = [
            labelContainerView.leadingAnchor.constraintEqualToAnchor(healthParameterImageView.trailingAnchor, constant: 15),
            labelContainerView.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor),
            labelContainerView.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant: 0),
            labelContainerView.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor)
        ]
        contentView.addConstraints(labelConstraints)

    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}