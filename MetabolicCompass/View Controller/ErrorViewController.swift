//
//  ErrorViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit

/**
 Helping with Plot and Correlate views
 
 - note: used with errorVC as alias
 */
class ErrorViewController : UIViewController {
    var image : UIImage!
    var msg : String!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func configureViews() {
        view.backgroundColor = Theme.universityDarkTheme.backgroundColor

        let iview = UIImageView()
        iview.image = image
        iview.contentMode = .ScaleAspectFit
        iview.tintColor = Theme.universityDarkTheme.foregroundColor

        let lbl = UILabel()
        lbl.textAlignment = .Center
        lbl.lineBreakMode = .ByWordWrapping
        lbl.numberOfLines = 0
        lbl.text = msg
        lbl.textColor = Theme.universityDarkTheme.foregroundColor

        iview.translatesAutoresizingMaskIntoConstraints = false
        lbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iview)
        view.addSubview(lbl)

        let constraints: [NSLayoutConstraint] = [
            iview.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            iview.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor, constant: -50),
            lbl.topAnchor.constraintEqualToAnchor(iview.bottomAnchor),
            lbl.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            iview.widthAnchor.constraintEqualToConstant(100),
            iview.heightAnchor.constraintEqualToConstant(100),
            lbl.widthAnchor.constraintEqualToAnchor(view.widthAnchor, constant: -50)
        ]
        view.addConstraints(constraints)
    }
}