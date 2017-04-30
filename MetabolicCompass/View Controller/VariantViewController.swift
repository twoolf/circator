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
 This class let us handle the edge cases correctly for the Plot and the Correlate view controllers.  Without capturing the edge cases, the views supports for the plots and correlations are not seen correctly by the user.
 
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(!withNavigation, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func configureViews() {
        controller = PagesController(pages)
        controller.enableSwipe = false
        controller.showBottomLine = false
        controller.showPageControl = false

        let pageView = controller.view
        pageView?.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(controller)
        view.addSubview(pageView!)
        let constraints: [NSLayoutConstraint] = [
            pageView!.topAnchor.constraint(equalTo: view.topAnchor),
            pageView!.leftAnchor.constraint(equalTo: view.leftAnchor),
            pageView!.rightAnchor.constraint(equalTo: view.rightAnchor),
            pageView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        view.addConstraints(constraints)
        controller.didMove(toParentViewController: self)

        controller.goTo(startIndex)
    }

    func goTo(index: Int) { controller.goTo(index) }
}
