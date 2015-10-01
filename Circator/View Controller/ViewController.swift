//
//  ViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class ViewController: UIViewController {

    var appName = "Circator"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = try! Realm()
        let labels = [appName] + Sample.attributes()

        for (i,ltxt) in labels.enumerate() {
            var labeltxt = ""
            if i > 0 {
                let attr = Sample.attrnames()[i-1]
                let statistic : Double? = realm.objects(Sample).average(attr)
                labeltxt = statistic == nil ? ltxt : ltxt + ": " + statistic!.description
            } else {
                labeltxt = ltxt
            }

            let lbl = UILabel()
            lbl.text = labeltxt
            lbl.textColor = UIColor.blackColor()
            lbl.textAlignment = .Center
            lbl.font = i == 0 ? UIFont.systemFontOfSize(64) : UIFont.systemFontOfSize(20)
            lbl.frame = i == 0 ? CGRectMake(0, 100, 300, 100) : CGRectMake(0, 200+CGFloat(i-1)*30, 300, 30)
            self.view.addSubview(lbl)
        }
        
        let analyzeButton = UIButton()
        analyzeButton.setTitle("Analyze", forState: .Normal)
        analyzeButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        let buttonWidth = (UIScreen.mainScreen().bounds.width - 80) / 2
        analyzeButton.frame = CGRectMake(35, 230+(CGFloat(labels.count-1) * 30), buttonWidth, 50)
        analyzeButton.titleLabel!.textAlignment = .Center
        analyzeButton.addTarget(self, action: "analyzePressed", forControlEvents: .TouchUpInside)
        analyzeButton.layer.cornerRadius = 7.0
        analyzeButton.backgroundColor = UIColor(red: 67/255.0, green: 114/255.0, blue: 170/255.0, alpha: 1.0)
        
        let settingsButton = UIButton()
        settingsButton.setTitle("Settings", forState: .Normal)
        settingsButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)

        settingsButton.frame = CGRectMake(45+buttonWidth, 230+(CGFloat(labels.count-1) * 30), buttonWidth, 50)
        settingsButton.titleLabel!.textAlignment = .Center
        settingsButton.addTarget(self, action: "settingsPressed", forControlEvents: .TouchUpInside)
        settingsButton.layer.cornerRadius = 7.0
        settingsButton.backgroundColor = UIColor(red: 69/255.0, green: 139/255.0, blue: 0.0, alpha: 1.0)
        
        self.view.addSubview(analyzeButton)
        self.view.addSubview(settingsButton)
    }

    func analyzePressed() {
        let correlationViewController = CorrelationViewController()
        navigationController?.pushViewController(correlationViewController, animated: true)
    }

    func settingsPressed() {
        let settingsViewController = SettingsViewController()
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

