//
//  AddViewController.swift
//  SimpleApp
//
//  Created by Yanif Ahmad on 9/18/15.
//  Copyright © 2015 Yanif Ahmad. All rights reserved.
//

import UIKit
import RealmSwift

class AddViewController: UIViewController, UITextFieldDelegate {
    var textFields : [(n: String, tf: UITextField)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        setupTextField()
        setupNavigationBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupTextField() {
        textFields = [("user_id",        UITextField(frame: CGRectZero)),
                      ("sample_id",      UITextField(frame: CGRectZero)),
                      ("sleep",          UITextField(frame: CGRectZero)),
                      ("weight",         UITextField(frame: CGRectZero)),
                      ("heart_rate",     UITextField(frame: CGRectZero)),
                      ("total_calories", UITextField(frame: CGRectZero)),
                      ("blood_pressure", UITextField(frame: CGRectZero))]

        for (n,tf) in textFields {
            tf.placeholder = "Enter " + n
            tf.delegate = self
            view.addSubview(tf)
        }
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneAction")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let padding = CGFloat(11)
        for (i,elem) in textFields.enumerate() {
            elem.tf.frame = CGRectMake(padding, self.topLayoutGuide.length + CGFloat(i * 50 + 20), view.frame.size.width - padding * 2, 50)
        }
    }
    
    func doneAction() {
        let realm = try! Realm()
        let (uid, sid) = (self.textFields[0], self.textFields[1])
        if uid.tf.text!.utf16.count > 0 && sid.tf.text!.utf16.count > 0 {
            var argdict : Dictionary<String, AnyObject> =
                ["user_id": (uid.tf.text! as NSString).integerValue, "sample_id": (sid.tf.text! as NSString).integerValue]

            for elem in self.textFields[2..<self.textFields.count] {
                if ( elem.tf.text != nil ) {
                    argdict[elem.n] = (elem.tf.text! as NSString).doubleValue
                } else {
                    argdict[elem.n] = 0.0
                }
            }

            let sample = Sample(value: argdict)
            sample.refreshKey()
            try! realm.write { realm.add(sample) }
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool { // [8]
        doneAction()
        textField.resignFirstResponder()
        return true
    }
}