//
//  VariantViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Pages

class VariantViewController: UIViewController {

    var pages : [UIViewController]!
    var controller : PagesController!
    var startIndex : Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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

    func addViews(views: [UIView]) {
        pages.appendContentsOf(views.map { cview in
            let vc = UIViewController()
            let vcview = vc.view

            cview.translatesAutoresizingMaskIntoConstraints = false
            vcview.addSubview(cview)
            let constraints: [NSLayoutConstraint] = [
                cview.topAnchor.constraintEqualToAnchor(vcview.topAnchor),
                cview.leftAnchor.constraintEqualToAnchor(vcview.leftAnchor),
                cview.rightAnchor.constraintEqualToAnchor(vcview.rightAnchor),
                cview.bottomAnchor.constraintEqualToAnchor(vcview.bottomAnchor)
            ]
            vcview.addConstraints(constraints)
            return vc
        })
        configureViews()
    }
}
