//
//  VariantViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Pages

/**
 Helping with Plot and Correlate views
 
 - note: used with VariantVC as alias
 */
class VariantViewController: UIViewController {

    var pages : [UIViewController]!
    var controller : PagesController!
    var startIndex : Int!
    var withNavigation : Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(!withNavigation, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func configureViews() {
        controller = PagesController(pages)
        controller.enableSwipe = false
        controller.showBottomLine = false
        controller.showPageControl = false

        let pageView = controller.view
        pageView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(controller)
        view.addSubview(pageView)
        let constraints: [NSLayoutConstraint] = [
            pageView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            pageView.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            pageView.rightAnchor.constraintEqualToAnchor(view.rightAnchor),
            pageView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        ]
        view.addConstraints(constraints)
        controller.didMoveToParentViewController(self)

        controller.goTo(startIndex)
    }

    func goTo(index: Int) { controller.goTo(index) }
}
