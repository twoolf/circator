//
//  IntroCompareDataTableViewCell.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/2/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit

/**
 enables tables in first page view of dashboard to have properties set
 
 - note: setUserData, loadUserSamples, loadPopSamples to populate rows
 */
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
            guard sampleType != nil else {
                healthParameterImageView.image = nil
                return
            }
            healthParameterImageView.image = PreviewManager.iconForSampleType(sampleType!)
        }
    }

    static let healthFormatter = SampleFormatter()

    /// loading both User and Population samples
    func setUserData(userData: [MCSample], populationAverageData: [MCSample], stalePopulation: Bool = false) {
        loadUserSamples(userData, toLabel: userDataLabel)
        loadPopSamples(populationAverageData, toLabel: populationAverageLabel, stale: stalePopulation)
    }

    /// note setUserData above that uses this call
    private func loadUserSamples( results: [MCSample], toLabel label: UILabel) {
        label.text = IntroCompareDataTableViewCell.healthFormatter.stringFromSamples(results)
    }

    /// note setUserData above that uses this call
    private func loadPopSamples(results: [MCSample], toLabel label: UILabel, stale: Bool) {
        label.text = IntroCompareDataTableViewCell.healthFormatter.stringFromSamples(results)
        if stale { label.textColor = UIColor.yellowColor() }
        else { label.textColor = Theme.universityDarkTheme.bodyTextColor }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }

    /// constraints and styles
    private func configureView() {
        backgroundColor = UIColor.clearColor()
        contentView.addSubview(healthParameterImageView)
        healthParameterImageView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = healthParameterImageView.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant: 8)
        topConstraint.priority = 999
        let imageViewConstraints: [NSLayoutConstraint] = [
            healthParameterImageView.leadingAnchor.constraintEqualToAnchor(contentView.layoutMarginsGuide.leadingAnchor, constant: 10),
            healthParameterImageView.widthAnchor.constraintEqualToAnchor(healthParameterImageView.heightAnchor),
            topConstraint,
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

    }

}
