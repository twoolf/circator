//
//  MainSettingsViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import SafariServices
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

        setupBackground()

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

    func setupBackground() {
        let backgroundImage = UIImageView(image: UIImage(named: "university_logo"))
        backgroundImage.contentMode = .Center
        backgroundImage.layer.opacity = 0.02
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(backgroundImage, atIndex: 0)

        let bgConstraints: [NSLayoutConstraint] = [
            backgroundImage.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor),
            backgroundImage.centerYAnchor.constraintEqualToAnchor(self.view.centerYAnchor)
        ]

        self.view.addConstraints(bgConstraints)
    }

    func webAction(asPrivacyPolicy: Bool) {
        let vc = SFSafariViewController(URL: asPrivacyPolicy ? privacyPolicyURL : aboutURL, entersReaderIfAvailable: false)
        presentViewController(vc, animated: true, completion: nil)
    }

    func withdrawAction() {
        let alertController = UIAlertController(title: nil, message: "Are you sure you wish to withdraw?", preferredStyle: .ActionSheet)

        let doWithdraw = { keepData in
            AccountManager.shared.doWithdraw(keepData) { success in
                NSNotificationCenter.defaultCenter().postNotificationName(UMDidLogoutNotification, object: nil)
                AccountManager.shared.loginOrRegister()
                if success {
                    let msg = "Thanks for using Metabolic Compass!"
                    UINotifications.genericMsg(self.navigationController!, msg: msg, pop: true, asNav: true)
                } else {
                    let msg = "Failed to withdraw, please try again later"
                    UINotifications.genericError(self.navigationController!, msg: msg, pop: false, asNav: true)
                }
            }
        }

        let withKeepAction = UIAlertAction(title: "Yes, and keep my data for research", style: .Default) {
            (alertAction: UIAlertAction!) in
            doWithdraw(true)
        }

        let withDeleteAction = UIAlertAction(title: "Yes, but delete all of my data", style: .Destructive) {
            (alertAction: UIAlertAction!) in
            doWithdraw(false)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(withKeepAction)
        alertController.addAction(withDeleteAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: - Data source
    
    private let segueProfileIdentifier       = "profileSegue"
    private let seguePhysiologicalIdentifier = "physiologicalSegue"
    private let segueNotificationsIdentifier = "notificationsSegue"
    private let segueHealthAccessIdentifier  = "healthAccessSegue"
    private let segueConsentViewerIdentifier = "consentViewerSegue"
    private let segueUserSettingsIdentifier  = "userSettingsSegue"

    private var consentPDFItemIndex    : Int = 0
    private var aboutItemIndex         : Int = 0
    private var privacyPolicyItemIndex : Int = 0
    private var logoutItemIndex        : Int = 0
    private var withdrawItemIndex      : Int = 0

    private lazy var items : [SettingsItem] = {
       var settingsItems = [SettingsItem]()
        
        settingsItems.append(SettingsItem(title: "Profile".localized, iconImageName: "icon-settings-profile", segueIdentifier: self.segueProfileIdentifier))

        settingsItems.append(SettingsItem(title: "Physiological Profile".localized, iconImageName: "icon-settings-physiological", segueIdentifier: self.seguePhysiologicalIdentifier))

        // settingsItems.append(SettingsItem(title: "Notifications".localized, iconImageName: "icon-settings-notifications", segueIdentifier: self.segueNotificationsIdentifier))

        // settingsItems.append(SettingsItem(title: "Health Access".localized, iconImageName: "icon-settings-health", segueIdentifier: self.segueHealthAccessIdentifier))

        settingsItems.append(SettingsItem(title: "User Settings".localized, iconImageName: "icon-settings-gear", segueIdentifier: self.segueUserSettingsIdentifier))

        settingsItems.append(SettingsItem(title: "Consent PDF".localized, iconImageName: "icon-consent-document", segueIdentifier: self.segueConsentViewerIdentifier))

        settingsItems.append(SettingsItem(title: "About Us".localized, iconImageName: "icon-settings-health"))
        self.aboutItemIndex = settingsItems.count - 1

        settingsItems.append(SettingsItem(title: "Privacy Policy".localized, iconImageName: "icon-privacy-shield"))
        self.privacyPolicyItemIndex = settingsItems.count - 1

        settingsItems.append(SettingsItem(title: "Log Out".localized, iconImageName: "icon-settings-logout"))
        self.logoutItemIndex = settingsItems.count - 1

        settingsItems.append(SettingsItem(title: "Withdraw From This Study".localized, iconImageName: "icon-settings-logout"))
        self.withdrawItemIndex = settingsItems.count - 1

        return settingsItems
    }()
    
    private func itemAtIndexPath(indexPath: NSIndexPath) -> SettingsItem {
        return items[indexPath.row]
    }

    private func cellHasSubviewAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return !( isCellAboutAtIndexPath(indexPath)
                    || isCellPrivacyPolicyAtIndexPath(indexPath)
                    || isCellLogoutAtIndexPath(indexPath)
                    || isCellWithdrawAtIndexPath(indexPath) )
    }

    private func isCellAboutAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == aboutItemIndex
    }

    private func isCellPrivacyPolicyAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == privacyPolicyItemIndex
    }

    private func isCellLogoutAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == logoutItemIndex
    }

    private func isCellWithdrawAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == withdrawItemIndex
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
        
        if !cellHasSubviewAtIndexPath(indexPath) {
            cell.hasAccessoryView = false
        }
        
        cell.titleLbl.textColor = ScreenManager.sharedInstance.appBrightTextColor()
        cell.titleLbl.font = cell.titleLbl.font.fontWithSize(16.0)
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let asAboutCell = isCellAboutAtIndexPath(indexPath)
        let asPrivacyPolicyCell = isCellPrivacyPolicyAtIndexPath(indexPath)

        if asAboutCell || asPrivacyPolicyCell  {
            webAction(asPrivacyPolicyCell)
        }
        else if isCellLogoutAtIndexPath(indexPath) {
            logoutAction()
        }
        else if isCellWithdrawAtIndexPath(indexPath) {
            withdrawAction()
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
