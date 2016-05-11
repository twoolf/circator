//
//  LoadImageCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import AVFoundation

class LoadImageCollectionViewCell: BaseCollectionViewCell, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var photoImg: UIImageView!
    
    weak var presentingViewController: UINavigationController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        photoImg.layer.cornerRadius = photoImg.frame.size.height / 2.0
        photoImg.layer.masksToBounds = true
        photoImg.layer.borderWidth = 0
    }

    @IBAction func loadPhotoAction(sender: UIButton) {
        if let navVC = presentingViewController {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            actionSheet.addAction(cancelAction)

            let showCameraAction = UIAlertAction(title: "Take a pic", style: .Default, handler: { (action) in
                let accessToCamera = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized //check if we have an access permissions to the camera
                if(!accessToCamera) {
                    self.showAlertActionForType(.Camera)
                } else {
                    self.showImagePickerWithSourceType(.Camera)
                }
            })
            actionSheet.addAction(showCameraAction)
            
            let showPhotoLibrary = UIAlertAction(title: "Choose from Album", style: .Default, handler: { (action) in
                let accessToPhoto = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) //check for access to the camera roll
                if(!accessToPhoto) {
                    self.showAlertActionForType(.PhotoLibrary)
                } else {
                    self.showImagePickerWithSourceType(.PhotoLibrary)
                }
                
            })
            actionSheet.addAction(showPhotoLibrary)
            navVC.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }

    private func showImagePickerWithSourceType(type: UIImagePickerControllerSourceType) {
        if let navVC = presentingViewController {
            let imagePicker = UIImagePickerController()
            //configure image picker
            imagePicker.sourceType = type
            imagePicker.delegate = self
            //calculate the height for nav bar. 
            //because we have an apperance with transparent nav bar we should update nav bar for image picker with white image
            let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
            let navBarSize = CGSizeMake(CGRectGetWidth(navVC.view.frame), CGRectGetHeight(navVC.navigationBar.frame) + statusBarHeight)
            navVC.presentViewController(imagePicker, animated: true, completion: {
                imagePicker.navigationBar.setBackgroundImage(UIImage().getImageWithColor(UIColor.whiteColor(), size: navBarSize), forBarMetrics: .Default)
            })
        }
    }
    
    private func showAlertActionForType(type: UIImagePickerControllerSourceType) {
        var message = "Please enable Camera access in Settings->Privacy->Camera->M-Compass"
        if(type == .PhotoLibrary) {
            message = "Please enable Photos access in Settings->Privacy->Photos->M-Compass"
        }
        let alertInfoController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertInfoController.addAction(UIAlertAction(title: "Cance", style: .Cancel, handler: nil))
        if let navVC = presentingViewController {
            navVC.presentViewController(alertInfoController, animated: true, completion: nil)
        }
    }
    
    // MARK: - ImagePicker Delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let photo = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        photoImg.image = photo
        
        valueChanged(photo)
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}
