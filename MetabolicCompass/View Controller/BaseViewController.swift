//
//  BaseViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class BaseViewController: UIViewController {
    
    
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
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.view.backgroundColor = ScreenManager.sharedInstance.appBgColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func showAlert(withMessage message: String, title : String = "Alert") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard actions
    private weak var scrollView: UIScrollView?
    
    func setupScroolViewForKeyboardsActions(view: UIScrollView) {
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
