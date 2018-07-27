//
//  AppActivityIndicator.swift
//  AppActivityIndicator.swift
//
//  Created by User on 7/27/18.
//  Copyright (c) 2018 Yanif Ahmad, Tom Woolf. All rights reserved.
//
//

import UIKit
import NVActivityIndicatorView

protocol AppActivityIndicatorContainer: class {
    var activityIndicator: AppActivityIndicator? { get }
    func isInProgress() -> Bool
    func showActivity()
    func hideActivity()
}

extension AppActivityIndicatorContainer {
    func isInProgress() -> Bool {
        return activityIndicator?.isAnimating ?? false
    }
    
    func showActivity() {
        activityIndicator?.startAnimating()
    }
    
    func hideActivity() {
        activityIndicator?.stopAnimating()
    }
}

final class AppActivityIndicator: UIView {
    @IBOutlet private weak var indicator: NVActivityIndicatorView?
    
    var isAnimating: Bool {
        return indicator?.isAnimating ?? false
    }
    
    static func forView(container: UIView) -> AppActivityIndicator {
        let view = AppActivityIndicator(frame: container.bounds)
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let sz: CGFloat = 30
        
        let activityFrame = CGRect(0.0, 0.0, sz, sz)
        let activityIndicator = NVActivityIndicatorView(frame: activityFrame, type: .lineScale, color: UIColor.lightGray)
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(activityIndicator)
        view.indicator = activityIndicator
        container.addSubview(view)
        return view
    }
    
    func startAnimating() {
        isUserInteractionEnabled = true
        indicator?.startAnimating()
    }
    
    func stopAnimating() {
        isUserInteractionEnabled = false
        indicator?.stopAnimating()
    }
}
