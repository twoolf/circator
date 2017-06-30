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
import Social

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
        self.view.layoutIfNeeded()

        setupBackground()

        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        let titleCellNib = UINib(nibName: "TitleCollectionViewCell", bundle: nil)
        collectionView?.register(titleCellNib, forCellWithReuseIdentifier: titleCellIdentifier)
        navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: ScreenManager.appTitleTextColor(), NSFontAttributeName: ScreenManager.appNavBarFont()]
        self.navigationController?.navigationBar.tintColor = ScreenManager.appNavigationBackColor()
    }

    func logoutAction()  {
        let alertController = UIAlertController(title: "", message: "Are you sure you wish to log out?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default) { (alertAction: UIAlertAction!) in
            AccountManager.shared.doLogout(completion: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UMDidLogoutNotification), object: nil)
                AccountManager.shared.loginOrRegister()
            })
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func setupBackground() {
        let backgroundImage = UIImageView(image: UIImage(named: "university_logo"))
        backgroundImage.contentMode = .center
        backgroundImage.layer.opacity = 0.02
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(backgroundImage, at: 0)

        let bgConstraints: [NSLayoutConstraint] = [
            backgroundImage.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            backgroundImage.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ]

        self.view.addConstraints(bgConstraints)
    }

    func socialAction() {
        let alertController = UIAlertController(title: nil, message: "Tell your friends about us!", preferredStyle: .actionSheet)

        let doShare : (String) -> Void = { serviceType in
            if let vc = SLComposeViewController(forServiceType: serviceType) {
                let msg = "Check out Metabolic Compass -- tracks your body clock for medical research on metabolic syndrome at Johns Hopkins."
                vc.setInitialText(msg)
                vc.add(NSURL(string: "https://www.metaboliccompass.com") as URL!)
                self.present(vc, animated: true, completion: nil)
            } else {
                let service = serviceType == SLServiceTypeTwitter ? "Twitter" : "Facebook"
                self.showAlert(withMessage: "Please log into your \(service) account from your iOS Settings")
            }
        }

        let withKeepAction = UIAlertAction(title: "Share on Twitter", style: .default) {
            (alertAction: UIAlertAction!) in
            doShare(SLServiceTypeTwitter)
        }

        let withDeleteAction = UIAlertAction(title: "Share on Facebook", style: .default) {
            (alertAction: UIAlertAction!) in
            doShare(SLServiceTypeFacebook)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(withKeepAction)
        alertController.addAction(withDeleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func webAction(asPrivacyPolicy: Bool) {
        let vc = SFSafariViewController(url: (asPrivacyPolicy ? MCRouter.privacyPolicyURL : MCRouter.aboutURL)!, entersReaderIfAvailable: false)
        present(vc, animated: true, completion: nil)
    }

    func withdrawAction() {
        let alertController = UIAlertController(title: nil, message: "Are you sure you wish to withdraw?", preferredStyle: .actionSheet)

        let doWithdraw = { keepData in
            AccountManager.shared.doWithdraw(keepData) { success in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UMDidLogoutNotification), object: nil)
                AccountManager.shared.loginOrRegister()
                if success {
                    let msg = "Thanks for using Metabolic Compass!"
                    UINotifications.genericMsg(vc: self.navigationController!, msg: msg, pop: true, asNav: true)
                } else {
                    let msg = "Failed to withdraw, please try again later"
                    UINotifications.genericError(vc: self.navigationController!, msg: msg, pop: false, asNav: true)
                }
            }
        }

        let withKeepAction = UIAlertAction(title: "Yes, and keep my data for research", style: .default) {
            (alertAction: UIAlertAction!) in
            doWithdraw(true)
        }

        let withDeleteAction = UIAlertAction(title: "Yes, but delete all of my data", style: .destructive) {
            (alertAction: UIAlertAction!) in
            doWithdraw(false)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(withKeepAction)
        alertController.addAction(withDeleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: - Data source
    
    private let segueProfileIdentifier       = "profileSegue"
    private let seguePhysiologicalIdentifier = "physiologicalSegue"
    private let segueNotificationsIdentifier = "notificationsSegue"
    private let segueHealthAccessIdentifier  = "healthAccessSegue"
    private let segueConsentViewerIdentifier = "consentViewerSegue"
    private let segueUserSettingsIdentifier  = "userSettingsSegue"

    private var consentPDFItemIndex    : Int = 0
    private var shareOurStoryIndex     : Int = 0
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

        settingsItems.append(SettingsItem(title: "Share Our Story".localized, iconImageName: "icon-bullhorn"))
        self.shareOurStoryIndex = settingsItems.count - 1

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
    
    private func itemAtIndexPath(indexPath: IndexPath) -> SettingsItem {
        return items[indexPath.row]
    }

    private func cellHasSubviewAtIndexPath(indexPath: IndexPath) -> Bool {
        return !( isCellShareOurStoryAtIndexPath(indexPath: indexPath)
                    || isCellAboutAtIndexPath(indexPath: indexPath)
                    || isCellPrivacyPolicyAtIndexPath(indexPath: indexPath)
                    || isCellLogoutAtIndexPath(indexPath: indexPath)
                    || isCellWithdrawAtIndexPath(indexPath: indexPath) )
    }

    private func isCellShareOurStoryAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.row == shareOurStoryIndex
    }

    private func isCellAboutAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.row == aboutItemIndex
    }

    private func isCellPrivacyPolicyAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.row == privacyPolicyItemIndex
    }

    private func isCellLogoutAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.row == logoutItemIndex
    }

    private func isCellWithdrawAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.row == withdrawItemIndex
    }

    // MARK: - UICollectionView DataSource & Delegate
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let item = itemAtIndexPath(indexPath: indexPath as IndexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: titleCellIdentifier, for: indexPath as IndexPath) as! TitleCollectionViewCell
        
        cell.titleLbl.text = item.title
        
        if let imageName = item.iconImageName {
            cell.cellImage?.image = UIImage(named: imageName)
        }
        
        if !cellHasSubviewAtIndexPath(indexPath: indexPath as IndexPath) {
            cell.hasAccessoryView = false
        }
        
        cell.titleLbl.textColor = ScreenManager.sharedInstance.appBrightTextColor()
        cell.titleLbl.font = cell.titleLbl.font.withSize(16.0)
        
        return cell
    }

    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        print("selected cell: \(indexPath)")
        let shareOurStoryCell = isCellShareOurStoryAtIndexPath(indexPath: indexPath as IndexPath)
        let asAboutCell = isCellAboutAtIndexPath(indexPath: indexPath as IndexPath)
        let asPrivacyPolicyCell = isCellPrivacyPolicyAtIndexPath(indexPath: indexPath as IndexPath)

        if shareOurStoryCell {
            socialAction()
        }
        else if asAboutCell || asPrivacyPolicyCell  {
            webAction(asPrivacyPolicy: asPrivacyPolicyCell)
        }
        else if isCellLogoutAtIndexPath(indexPath: indexPath as IndexPath) {
            logoutAction()
        }
        else if isCellWithdrawAtIndexPath(indexPath: indexPath as IndexPath) {
            withdrawAction()
        }
        else {
            let item = itemAtIndexPath(indexPath: indexPath as IndexPath)
            
            if let segueIdentifier = item.segueIdentifier {
//                self.performSegue(withIdentifier: segueIdentifier, sender: nil)
                OperationQueue.main.addOperation {
                    [weak self] in self?.performSegue(withIdentifier: segueIdentifier, sender: nil)
                    
                }
            }
        }
    }
    
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return defaultCellSize()
    }
    
    private let cellHeight: CGFloat = 65
    
    private func defaultCellSize() -> CGSize {
        let size = CGSize(self.collectionView!.bounds.width, cellHeight)
        return size
    }
}
