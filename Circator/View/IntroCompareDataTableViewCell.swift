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
    
    func setUserData(userData: DataSample, populationAverageData: DataSample) {
        let image: UIImage
        switch userData.type {
        case .BloodPressure:
            image = UIImage(named: "icon_blood_pressure")!
        case .BodyMass:
            image = UIImage(named: "icon_weight")!
        case .EnergyIntake:
            image = UIImage(named: "icon_food")!
        case .HeartRate:
            image = UIImage(named: "icon_heart_rate")!
        case .Sleep:
            image = UIImage(named: "icon_sleep")!
        }
        healthParameterImageView.image = image
        userDataLabel.text = "\(userData)"
        populationAverageLabel.text = "\(populationAverageData)"
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
