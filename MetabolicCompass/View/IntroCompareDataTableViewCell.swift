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
import MCCircadianQueries

/**
 This class supports our tables in the first view of dashboard.  The goals is to have properties set by the user and to keep a consistent theme.  The in-code constraints let us view immediately what has been defined.
 
 - note: setUserData, loadUserSamples, loadPopSamples to populate rows
 */
class IntroCompareDataTableViewCell: UITableViewCell {

    lazy var healthParameterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Theme.universityDarkTheme.foregroundColor
        return imageView
    }()

    lazy var userDataLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.universityDarkTheme.bodyTextColor
        label.backgroundColor = UIColor.clear
        label.text = "75 kg"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    lazy var populationAverageLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.universityDarkTheme.bodyTextColor
        label.backgroundColor = UIColor.clear
        label.text = "123"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    lazy var labelContainerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.userDataLabel, self.populationAverageLabel])
        stackView.axis = .horizontal
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.fill
        stackView.spacing = 10
        return stackView
    }()

    var sampleType: HKSampleType? {
        didSet {
            guard sampleType != nil else {
                healthParameterImageView.image = nil
                return
            }
            healthParameterImageView.image = PreviewManager.iconForSampleType(sampleType: sampleType!)
        }
    }

    static let healthFormatter = SampleFormatter()

    /// loading both User and Population samples
//    func setUserData(userData: [MCSample], populationAverageData: [MCSample], stalePopulation: Bool = false) {
    func setUserData(userData: [MCSample], populationAverageData: [MCSample], stalePopulation: Bool = true) {
        loadUserSamples(results: userData, toLabel: userDataLabel)
        loadPopSamples(results: populationAverageData, toLabel: populationAverageLabel, stale: stalePopulation)
    }

    /// note setUserData above that uses this call
    private func loadUserSamples( results: [MCSample], toLabel label: UILabel) {
        label.text = IntroCompareDataTableViewCell.healthFormatter.stringFromSamples(samples: results)
    }

    /// note setUserData above that uses this call
    private func loadPopSamples(results: [MCSample], toLabel label: UILabel, stale: Bool) {
        label.text = IntroCompareDataTableViewCell.healthFormatter.stringFromSamples(samples: results)
        if stale { label.textColor = UIColor.yellow }
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
        backgroundColor = UIColor.clear
        contentView.addSubview(healthParameterImageView)
        healthParameterImageView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = healthParameterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        topConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.defaultHigh.rawValue - 1)
        let imageViewConstraints: [NSLayoutConstraint] = [
            healthParameterImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: 10),
            healthParameterImageView.widthAnchor.constraint(equalTo: healthParameterImageView.heightAnchor),
            topConstraint,
            healthParameterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            healthParameterImageView.heightAnchor.constraint(equalToConstant: 37)
        ]
        contentView.addConstraints(imageViewConstraints)
        labelContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelContainerView)
        let labelConstraints: [NSLayoutConstraint] = [
            labelContainerView.leadingAnchor.constraint(equalTo: healthParameterImageView.trailingAnchor, constant: 15),
            labelContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            labelContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            labelContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        contentView.addConstraints(labelConstraints)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
