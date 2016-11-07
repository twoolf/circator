//
//  BarcodeScannerViewController.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/28/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import AVFoundation
import UIKit

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, ConfigurableStatusBar, FoodItemSelectionDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var isSearchingView : SearchingForBarcodeView!
    var search = NutritionixSearch()
    var didSelectFoodItem : (FoodItem->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.search.searchResultsDidLoad = {
            self.hasReceivedBarcodeResult()
        }
        
        self.view.backgroundColor = UIColor.blackColor()
        self.captureSession = AVCaptureSession()
        
        let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            self.alertFailure()
            return
        }
        
        if (self.captureSession.canAddInput(videoInput)) {
            self.captureSession.addInput(videoInput)
        } else {
            self.alertFailure()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (self.captureSession.canAddOutput(metadataOutput)) {
            self.captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeUPCECode]
            
        } else {
            self.alertFailure()
            return
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer.frame = view.layer.bounds
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(previewLayer)
        
        self.configureView()
        
        captureSession.startRunning()
        self.isSearchingView.startSearching()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.captureSession?.running == false {
            self.captureSession.startRunning()
            self.isSearchingView.startSearching()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.captureSession?.running == true {
            self.captureSession.stopRunning()

        }
    }
    
    func configureView() {
        
        self.isSearchingView = SearchingForBarcodeView()
        self.isSearchingView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.isSearchingView)
        
        let isSearchingViewConstraints : [NSLayoutConstraint] = [
            self.isSearchingView.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor),
            self.isSearchingView.centerYAnchor.constraintEqualToAnchor(self.view.centerYAnchor),
            self.isSearchingView.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor, multiplier: 0.666),
            self.isSearchingView.heightAnchor.constraintEqualToAnchor(self.view.widthAnchor, multiplier: 0.666)
        ]
        
        self.view.addConstraints(isSearchingViewConstraints)
        
    }
    
    func alertFailure() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(ac, animated: true, completion: nil)
        self.captureSession = nil
        self.navigationController?.popViewControllerAnimated(true)
    }
    

    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        self.captureSession.stopRunning()
        
        if let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            NSOperationQueue.mainQueue().addOperationWithBlock({self.isSearchingView.foundBarcode()})
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            self.search.filter = metadata.stringValue
            
        }
    }
    
    func hasReceivedBarcodeResult() {
        
        if let foodItem = self.search.results.first {
            
            self.didSelectFoodItem?(foodItem)
        }
        
    }
    
    //status bar animation add-on
    var showStatusBar = true
    
    override func prefersStatusBarHidden() -> Bool {
        
        return !self.showStatusBar
        
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    func showStatusBar(enabled: Bool) {
        self.showStatusBar = enabled
        UIView.animateWithDuration(0.5, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
}

class SearchingForBarcodeView : UIView {
    
    var statusView : UIImageView!
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.configureView()
    }
    
    func configureView() {
        
        self.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.25)
        self.clipsToBounds = true
        self.layer.cornerRadius = 15
        
        self.statusView = UIImageView(image: UIImage(named: "barcode_icon_white"))
        self.statusView.translatesAutoresizingMaskIntoConstraints = false
        self.statusView.alpha = 0.5
        
        self.addSubview(self.statusView)
        
        let barcodeViewConstraints : [NSLayoutConstraint] = [
            self.statusView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor),
            self.statusView.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor),
            self.statusView.widthAnchor.constraintEqualToAnchor(self.widthAnchor, multiplier: 0.75),
            self.statusView.heightAnchor.constraintEqualToAnchor(self.heightAnchor, multiplier: 0.75)
        ]
        
        self.addConstraints(barcodeViewConstraints)

    }
    
    func startSearching(sender: AnyObject? = nil)  {
        
        self.alpha = 1
        self.statusView.alpha = 1
        self.statusView.image = UIImage(named: "barcode_icon_white")
        UIView.animateWithDuration(0.5, delay: 0, options: [.CurveEaseInOut, .Repeat, .Autoreverse], animations: {
            self.alpha = self.alpha == 1 ? 0 : 1
        }, completion: nil)
    }
    
    func foundBarcode(sender: AnyObject? = nil)  {
        
        self.layer.removeAllAnimations()
        self.alpha = 1
        self.statusView.alpha = 1
        self.statusView.image = UIImage(named: "checkmark_white")

        UIView.animateWithDuration(1, delay: 0.5, options: [.CurveEaseInOut], animations: {
            self.alpha = 0
            self.statusView.alpha = 0
        }, completion: nil)
        
    }
    
    override func didMoveToSuperview() {
        self.startSearching()
    }
}

