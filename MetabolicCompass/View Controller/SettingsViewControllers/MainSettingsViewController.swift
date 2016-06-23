//
//  MainSettingsViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class SettingsItem : NSObject {
    
    private(set) var title: String!
    private(set) var segueIdentifier: String?
    private(set) var iconImageName: String?
    
    init(title itemTitle: String, iconImageName itemIconImageName: String? = nil, segueIdentifier itemSegueIdentifier: String? = nil) {
        super.init()
        
        title = itemTitle
        segueIdentifier = itemSegueIdentifier
        iconImageName = itemIconImageName
    }
}


class MainSettingsViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let titleCellIdentifier = "titleCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        let titleCellNib = UINib(nibName: "TitleCollectionViewCell", bundle: nil)
        collectionView?.registerNib(titleCellNib, forCellWithReuseIdentifier: titleCellIdentifier)
//        navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: ScreenManager.appTitleTextColor(), NSFontAttributeName: ScreenManager.appNavBarFont()]
//        self.navigationController?.navigationBar.tintColor = ScreenManager.appNavigationBackColor()
    }

    func logoutAction()  {
        let alertController = UIAlertController(title: "", message: "Are you sure you wish to log out?", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .Default) { (alertAction: UIAlertAction!) in
            AccountManager.shared.doLogout({
                NSNotificationCenter.defaultCenter().postNotificationName(UMDidLogoutNotification, object: nil)
                AccountManager.shared.loginOrRegister()
            })
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Data source
    
    private let segueProfileIdentifier = "profileSegue"
    private let seguePhysiologicalIdentifier = "physiologicalSegue"
    private let segueNotificationsIdentifier = "notificationsSegue"
    private let segueHealthAccessIdentifier = "healthAccessSegue"
    
    private var logoutItemIndex : Int = 0
    
    private lazy var items : [SettingsItem] = {
       var settingsItems = [SettingsItem]()
        
        settingsItems.append(SettingsItem(title: "Profile".localized, iconImageName: "icon-settings-profile", segueIdentifier: self.segueProfileIdentifier))
        settingsItems.append(SettingsItem(title: "Physiological Profile".localized, iconImageName: "icon-settings-physiological", segueIdentifier: self.seguePhysiologicalIdentifier))
//        settingsItems.append(SettingsItem(title: "Notifications".localized, iconImageName: "icon-settings-notifications", segueIdentifier: self.segueNotificationsIdentifier))
        settingsItems.append(SettingsItem(title: "Health Access".localized, iconImageName: "icon-settings-health", segueIdentifier: self.segueHealthAccessIdentifier))
    
        settingsItems.append(SettingsItem(title: "Log out".localized, iconImageName: "icon-settings-logout"))
        self.logoutItemIndex = settingsItems.count - 1
        
        return settingsItems
    }()
    
    private func itemAtIndexPath(indexPath: NSIndexPath) -> SettingsItem {
        return items[indexPath.row]
    }
    
    private func isCellLogoutAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == logoutItemIndex
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let item = itemAtIndexPath(indexPath)
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(titleCellIdentifier, forIndexPath: indexPath) as! TitleCollectionViewCell
        
        cell.titleLbl.text = item.title
        
        if let imageName = item.iconImageName {
            cell.cellImage?.image = UIImage(named: imageName)
        }
        
        if isCellLogoutAtIndexPath(indexPath) {
            cell.hasAccessoryView = false
        }
        
        cell.titleLbl.textColor = ScreenManager.sharedInstance.appUnBrightTextColor()
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if isCellLogoutAtIndexPath(indexPath) {
            logoutAction()
        }
        else {
            let item = itemAtIndexPath(indexPath)
            
            if let segueIdentifier = item.segueIdentifier {
                self.performSegueWithIdentifier(segueIdentifier, sender: nil)
            }
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return defaultCellSize()
    }
    
    private let cellHeight: CGFloat = 65
    
    private func defaultCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHeight)
        return size
    }
}
