//
//  LoadImageCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Async

class LoadImageCollectionViewCell: CircleImageCollectionViewCell, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    weak var presentingViewController: UINavigationController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    @IBAction func loadPhotoAction(sender: UIButton) {
        if let navVC = presentingViewController {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            actionSheet.addAction(cancelAction)

            let showCameraAction = UIAlertAction(title: "Take a pic", style: .Default, handler: { (action) in
                self.checkCamera()
            })
            actionSheet.addAction(showCameraAction)
            
            let showPhotoLibrary = UIAlertAction(title: "Choose from Album", style: .Default, handler: { (action) in
                self.checkCameraRoll()
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
        alertInfoController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        if let navVC = presentingViewController {
            navVC.presentViewController(alertInfoController, animated: true, completion: nil)
        }
    }
    
    func checkCameraRoll (){
        PHPhotoLibrary.requestAuthorization { status in
            Async.main{
                switch status {
                case .Authorized:
                    self.showImagePickerWithSourceType(.PhotoLibrary)
                case .Restricted:
                    self.showAlertActionForType(.PhotoLibrary)
                case .Denied:
                    self.showAlertActionForType(.PhotoLibrary)
                default:
                    break
                }
            }
        }
    }
    
    func checkCamera() {
        let authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch authStatus {
            case .Authorized: self.showImagePickerWithSourceType(.Camera)
            case .Denied: showAlertActionForType(.Camera)
            case .NotDetermined: alertPromptToAllowCameraAccessViaSetting()
            default: showAlertActionForType(.Camera)
        }
    }
    
    func alertPromptToAllowCameraAccessViaSetting() {
        if AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count > 0 {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { granted in
                Async.main{
                    self.checkCamera()
                }
            }
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
