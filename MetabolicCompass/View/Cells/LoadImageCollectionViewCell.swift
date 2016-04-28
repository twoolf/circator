//
//  LoadImageCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

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
            let imagePicker = UIImagePickerController()
            
            imagePicker.sourceType = .PhotoLibrary
            imagePicker.delegate = self
            
            navVC.presentViewController(imagePicker, animated: true, completion: nil)

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
