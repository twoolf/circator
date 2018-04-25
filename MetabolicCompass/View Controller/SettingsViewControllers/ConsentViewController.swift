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
        
        UserManager.sharedManager.getConsentData {[weak self] (data) in
            DispatchQueue.main.async {
                guard let strongSelf = self else {return}
                if let pdfdata = data
                {
                    let url = NSURL.fileURL(withPath: Bundle.main.bundlePath)
                    strongSelf.webView.load(pdfdata, mimeType: "application/pdf", textEncodingName: "UTF-8", baseURL: url)
                } else {
                    
                    let label = UILabel()
                    label.font = UIFont(name: "GothamBook", size: 20)!
                    label.textColor = .black
                    label.textAlignment = .center
                    label.text = "Unable to show consent PDF"
                    
                    label.translatesAutoresizingMaskIntoConstraints = false
                    strongSelf.view.addSubview(label)
                    strongSelf.view.addConstraints([
                        label.centerXAnchor.constraint(equalTo: strongSelf.view.layoutMarginsGuide.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: strongSelf.view.layoutMarginsGuide.centerYAnchor),
                        label.heightAnchor.constraint(equalToConstant: 100)
                        ])
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
