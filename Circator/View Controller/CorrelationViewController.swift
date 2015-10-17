//
//  CorrelationViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/27/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class CorrelationViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet var collectionView : UICollectionView?
    
    var samples : Results<Sample> = try! Realm().objects(Sample)
    var screenWidth : CGFloat = 0.0
    var itemWidth : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        screenWidth = UIScreen.mainScreen().bounds.width - 20
        itemWidth = screenWidth / CGFloat(Sample.attributes().count + 1)
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.dataSource = self
        collectionView!.delegate = self
        
        collectionView!.registerClass(CollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        
        self.view.addSubview(collectionView!)
        let flow = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        setupFlowLayout(flow)
        setupNavigationBar()
    }
    
    func setupFlowLayout(flow:UICollectionViewFlowLayout) {
        flow.sectionInset = UIEdgeInsets(top: -20, left: 10, bottom: 0, right: 10)
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        flow.headerReferenceSize = CGSizeMake(50, 60)
        flow.itemSize = CGSize(width: itemWidth, height: 30)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.reloadData()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func setupNavigationBar() {
        navigationItem.title = "Correlations"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addButtonAction")
    }
    
    func addButtonAction() {
        let addViewController = AddViewController(nibName: nil, bundle: nil)
        let navController = UINavigationController(rootViewController: addViewController)
        presentViewController(navController, animated: true, completion: nil)
    }
    
    func plotButtonAction(sender: PlotButton!) {
        let plotViewController = PlotViewController(plotType: sender.plotType, nibName: nil, bundle: nil)
        navigationController?.pushViewController(plotViewController, animated: true)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let n = Sample.attributes().count + 1
        return section == 2 ? 2 : (samples.count > 0 ? n * n : 0)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        let n = Sample.attributes().count + 1
        let index = Int(indexPath.row)
        cell.backgroundColor = UIColor.whiteColor()
        cell.layer.borderWidth = 0.0
        cell.frame.size.width = itemWidth
        
        for view in cell.contentView.subviews {
            view.removeFromSuperview()
        }
        
        if ( indexPath.section < 2 ) {
            cell.asButton(5)
            if ( index == 0 ) {
                cell.setPlotType(0)
                cell.setText(indexPath.section == 0 ? "User" : "Pop")
                cell.backgroundColor = UIColor.redColor()
            } else if ( index < n ) {
                cell.setPlotType(index-1)
                cell.setText(Sample.attributes()[index-1])
            } else if ( index % n == 0 ) {
                cell.setPlotType((index / n)-1)
                cell.setText(Sample.attributes()[(index / n)-1])
            } else {
                // TODO: compute correlation between attribute pair.
                let row = Sample.attrnames()[(index / n)-1]
                let col = Sample.attrnames()[(index % n)-1]
                let realm = try! Realm()
                let rowavg : Double? = realm.objects(Sample).average(row)
                let colavg : Double? = realm.objects(Sample).average(col)
                cell.setText("\(rowavg!),\(colavg!)")
                cell.backgroundColor = UIColor.init(white: CGFloat(1 / rowavg!), alpha: 0.3)
            }
            cell.button.addTarget(self, action: "plotButtonAction:", forControlEvents: .TouchUpInside)
        } else {
            cell.asButton(index + 5)
            let t = index == 0 ? "Plot Scatter Graph" : "Plot Time Series"
            let cellWidth = screenWidth / 2
            cell.frame.size.width = cellWidth
            cell.button.setTitle(t, forState: .Normal)
            cell.button.addTarget(self, action: "plotButtonAction:", forControlEvents: .TouchUpInside)
        }
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

