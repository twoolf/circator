//
//  LoadImageCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import AVFoundation
import Async

class LoadImageCollectionViewCell: CircleImageCollectionViewCell, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    weak var presentingViewController: UINavigationController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    @IBAction func loadPhotoAction(_ sender: UIButton) {
        
    }
    
    /*
    @IBAction func loadPhotoAction(_ sender: UIButton) {
        if let navVC = presentingViewController {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(cancelAction)

            let showCameraAction = UIAlertAction(title: "Take a pic", style: .default, handler: { (action) in
                self.checkCamera()
            })
            actionSheet.addAction(showCameraAction)
            
            let showPhotoLibrary = UIAlertAction(title: "Choose from Album", style: .default, handler: { (action) in
                self.checkCameraRoll()
            })
            actionSheet.addAction(showPhotoLibrary)
            navVC.present(actionSheet, animated: true, completion: nil)
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
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            let navBarSize = CGSize(navVC.view.frame.width, navVC.navigationBar.frame.height + statusBarHeight)
            navVC.present(imagePicker, animated: true, completion: {
                imagePicker.navigationBar.setBackgroundImage(UIImage().getImageWithColor(color: UIColor.white, size: navBarSize), for: .default)
            })
        }
    }
    
    private func showAlertActionForType(type: UIImagePickerControllerSourceType) {
        var message = "Please enable Camera access in Settings->Privacy->Camera->M-Compass"
        if(type == .photoLibrary) {
            message = "Please enable Photos access in Settings->Privacy->Photos->M-Compass"
        }
        let alertInfoController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertInfoController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        if let navVC = presentingViewController {
            navVC.present(alertInfoController, animated: true, completion: nil)
        }
    }
    
    func checkCameraRoll (){
        PHPhotoLibrary.requestAuthorization { status in
            Async.main{
                switch status {
                case .authorized:
                    self.showImagePickerWithSourceType(type: .photoLibrary)
                case .restricted:
                    self.showAlertActionForType(type: .photoLibrary)
                case .denied:
                    self.showAlertActionForType(type: .photoLibrary)
                default:
                    break
                }
            }
        }
    }
    
    func checkCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
            case .authorized: showImagePickerWithSourceType(type: .camera)
            case .denied: showAlertActionForType(type: .camera)
            case .notDetermined: alertPromptToAllowCameraAccessViaSetting()
            default: showAlertActionForType(type: .camera)
        }
    }
    
    func alertPromptToAllowCameraAccessViaSetting() {
        if AVCaptureDevice.devices(for: AVMediaType.video).count > 0 {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                Async.main{
                    self.checkCamera()
                }
            }
        }
    }
    
    // MARK: - ImagePicker Delegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let photo = info[UIImagePickerControllerOriginalImage] as? UIImage
        photoImg.image = photo
        valueChanged(newValue: photo)
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    */
}
