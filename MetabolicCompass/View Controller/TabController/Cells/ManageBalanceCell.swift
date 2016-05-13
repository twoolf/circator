//
//  ManageBalanceCell.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class ManageBalanceCell: UITableViewCell {
    
        
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var leftImage: UIImageView!
    weak var data: DashboardMetricsConfigItem!
    
    override var inputView: UIView? {
        
        let storyboard = UIStoryboard(name: "TabScreens", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("BalanceSampleListController") as! BalanceSampleListController
        
        controller.selectdType = data.object
        controller.parentCell  = self
        
        return controller.view
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if (selected) {
            self.becomeFirstResponder()
        }
        
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        let tableView = self.superview!.superview as! UITableView
        tableView.deselectRowAtIndexPath(tableView.indexPathForCell(self)!, animated: true)
        return super.resignFirstResponder()
    }
}
