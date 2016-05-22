//
//  BaseViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class BaseViewController: UIViewController, UIGestureRecognizerDelegate {

    let selectedTextColor = ScreenManager.sharedInstance.appBrightTextColor()
    let unselectedTextColor = ScreenManager.sharedInstance.appUnBrightTextColor()

    class var storyboardName : String {
        // Override It
        return ""
    }

    class func storyboardId() -> String {
        let fullClassName = NSStringFromClass(self) as String
        let className = fullClassName.componentsSeparatedByString(".").last!

        return className
    }

    class func viewControllerFromStoryboard() -> BaseViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: NSBundle.mainBundle())
        return storyboard.instantiateViewControllerWithIdentifier(self.storyboardId()) as! BaseViewController
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavBar()

        self.automaticallyAdjustsScrollViewInsets = false

        self.view.backgroundColor = ScreenManager.sharedInstance.appBgColor()

        // add recogizer for closing keyboard by clicking on empty space
        let gr = UITapGestureRecognizer(target: self, action: #selector(BaseViewController.cancelKeyboard))
        gr.cancelsTouchesInView = false
        gr.delegate = self
        self.view.addGestureRecognizer(gr)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        hideKeyboard()
    }

    func cancelKeyboard() {
        hideKeyboard()
    }


    private func configureNavBar() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        self.navigationItem.title = self.title?.localized.uppercaseString

        let navBarTextColor = ScreenManager.sharedInstance.appNavBarTextColor()

        self.navigationController?.navigationBar.tintColor = navBarTextColor
        self.navigationController?.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName : navBarTextColor, NSFontAttributeName : ScreenManager.appNavBarFont() ]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    var alertControllerOkButtonHandler: ((Void) -> Void)? = nil

    func showAlert(withMessage message: String, title : String? = nil) {

        let vc = self.navigationController ?? self

        UINotifications.showError(vc, msg: message, title: title)
//
//        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: {(alert: UIAlertAction!) in
//            if let completionHadler = self.alertControllerOkButtonHandler {
//                completionHadler()
//            }
//        }))
//
//        self.presentViewController(alert, animated: true, completion: nil)
    }

    func startAction() {
        hideKeyboard()
    }

    func hideKeyboard() {
        self.view.endEditing(true)
    }

    // MARK: - UIGestureRecognizer Delegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if let _ = touch.view as? UIButton {
            return false
        }
        return true
    }

    // MARK: - Keyboard actions
    private weak var scrollView: UIScrollView?

    func setupScrollViewForKeyboardsActions(view: UIScrollView) {
        scrollView = view

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
    }

    func keyboardWillShow(notification:NSNotification){
        if let _scrollView = scrollView {
            var userInfo = notification.userInfo!
            var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
            keyboardFrame = view.convertRect(keyboardFrame, fromView: nil)

            var contentInset:UIEdgeInsets = _scrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            _scrollView.contentInset = contentInset
        }
    }

    func keyboardWillHide(notification:NSNotification) {
        if let _scrollView = scrollView {
            let contentInset:UIEdgeInsets = UIEdgeInsetsZero
            _scrollView.contentInset = contentInset
        }
    }

}
