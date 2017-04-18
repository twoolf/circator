//
//  ConsentViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 8/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit

class ConsentViewController: BaseViewController {

    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let consentDict = UserManager.sharedManager.getConsent()
        if let pdfstr = consentDict["consent"] as? String,
            let pdfdata = NSData(base64Encoded: pdfstr, options: NSData.Base64DecodingOptions())
        {
            let url = NSURL.fileURLWithPath(Bundle.main.bundlePath)
            webView.loadData(pdfdata as Data, MIMEType: "application/pdf", textEncodingName: "UTF-8", baseURL: url)
        } else {
            let label = UILabel()
            label.font = UIFont(name: "GothamBook", size: 20)!
            label.textColor = .blackColor
            label.textAlignment = .center
            label.text = "Unable to show consent PDF"

            label.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(label)
            self.view.addConstraints([
                label.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
                label.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
