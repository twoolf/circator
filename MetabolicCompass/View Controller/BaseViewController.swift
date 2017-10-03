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
//        let className = fullClassName.componentsSeparatedByString(".").last!
        let className = fullClassName.components(separatedBy: ".").last!

        return className
    }

    class func viewControllerFromStoryboard() -> BaseViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: self.storyboardId()) as! BaseViewController
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        hideKeyboard()
    }

    @objc func cancelKeyboard() {
        hideKeyboard()
    }


    private func configureNavBar() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.navigationItem.title = self.title?.localized.uppercased()

        _ = ScreenManager.sharedInstance.appNavBarTextColor()

//        self.navigationController?.navigationBar.tintColor = navBarTextColor
//        self.navigationController?.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName : navBarTextColor, NSFontAttributeName : ScreenManager.appNavBarFont() ]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func createBarButtonItem(_ title: String?, action: Selector) -> UIBarButtonItem{
        let bbItem = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.plain, target: self, action: action)
        bbItem.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: ScreenManager.appTitleTextColor()], for: UIControlState.normal)
        return bbItem
    }

    var alertControllerOkButtonHandler: ((Void) -> Void)? = nil

    func showAlert(withMessage message: String, title : String? = nil) {

        let vc = self.navigationController ?? self

        UINotifications.showError(vc: vc, msg: message, title: title)
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

    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let _ = touch.view as? UIButton {
            return false
        }
        return true
    }

    // MARK: - Keyboard actions
    private weak var scrollView: UIScrollView?

    func setupScrollViewForKeyboardsActions(view: UIScrollView) {
        scrollView = view

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification: )), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    @objc open func keyboardWillShow(notification:NSNotification){
        if let _scrollView = scrollView {
            var userInfo = notification.userInfo!
            var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            keyboardFrame = view.convert(keyboardFrame, from: nil)

            if keyboardFrame.size.height == 0 {
                keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
                keyboardFrame = view.convert(keyboardFrame, from: nil)
            }

            var contentInset:UIEdgeInsets = _scrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            _scrollView.contentInset = contentInset
        }
    }

    @objc func keyboardWillHide(notification:NSNotification) {
        switch scrollView {
        case is UICollectionView: break
//            log.info("CollectionView hiding keyboard")
        default:
            ()
        }

        if let _scrollView = scrollView {
            let contentInset:UIEdgeInsets = UIEdgeInsets.zero
            _scrollView.contentInset = contentInset
        }
    }

}
