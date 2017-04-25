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
 This class further helps us with controlling the plot and correlate views. By understanding and capturing the errors associated with the data coming into the views we support a better experience for the participants.
 
 - note: used with errorVC as alias
 */
class ErrorViewController : UIViewController {
    var image : UIImage!
    var msg : String!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func configureViews() {
        view.backgroundColor = Theme.universityDarkTheme.backgroundColor

        let iview = UIImageView()
        iview.image = image
        iview.contentMode = .scaleAspectFit
        iview.tintColor = Theme.universityDarkTheme.foregroundColor

        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.lineBreakMode = .byWordWrapping
        lbl.numberOfLines = 0
        lbl.text = msg
        lbl.textColor = Theme.universityDarkTheme.foregroundColor

        iview.translatesAutoresizingMaskIntoConstraints = false
        lbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iview)
        view.addSubview(lbl)

        let constraints: [NSLayoutConstraint] = [
            iview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iview.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            lbl.topAnchor.constraint(equalTo: iview.bottomAnchor),
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iview.widthAnchor.constraint(equalToConstant: 100),
            iview.heightAnchor.constraint(equalToConstant: 100),
            lbl.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50)
        ]
        view.addConstraints(constraints)
    }
}
