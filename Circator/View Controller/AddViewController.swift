//
//  AddViewController.swift
//  SimpleApp
//
//  Created by Yanif Ahmad on 9/18/15.
//  Copyright © 2015 Yanif Ahmad. All rights reserved.
//

import UIKit

class AddViewController: UIViewController, UITextFieldDelegate {
    var textFields : [(n: String, msg: String, tf: UITextField)] = []
    
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
        textFields = [("userID",        "#users",           UITextField(frame: CGRectZero)),
                      ("sampleID",      "samples per user", UITextField(frame: CGRectZero)),
                      ("sleep",          "sleep",            UITextField(frame: CGRectZero)),
                      ("weight",         "weight",           UITextField(frame: CGRectZero)),
                      ("heartRate",     "heart rate",       UITextField(frame: CGRectZero)),
                      ("totalCalories", "total calories",   UITextField(frame: CGRectZero)),
                      ("bloodPressure", "blood pressure",   UITextField(frame: CGRectZero))]

        for (_,msg,tf) in textFields {
            tf.placeholder = "Enter " + msg
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
        let valid = self.textFields.reduce(true, combine: {$0 && $1.tf.text!.utf16.count > 0})
        if valid {
            let num_users = (self.textFields[0].tf.text! as NSString).integerValue
            let user_samples = (self.textFields[1].tf.text! as NSString).floatValue
            var param_dict = [String:(Float, Float)]()
            
            for elem in self.textFields[2..<self.textFields.count] {
                if ( elem.tf.text != nil ) {
                    param_dict[elem.n] = ((elem.tf.text! as NSString).floatValue, 10.0)
                } else {
                    param_dict[elem.n] = (100.0, 0.0)
                }
            }
            
            let w = WorkloadGenerator()
            w.generate(num_users, samples_per_user: user_samples, param_dict: param_dict)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool { // [8]
        doneAction()
        textField.resignFirstResponder()
        return true
    }
}