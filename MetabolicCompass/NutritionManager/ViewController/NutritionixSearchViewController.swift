//
//  NutritionixSearchViewController.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class NutritionixSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, ConfigurableStatusBar, FoodItemSelectionDelegate {
    
    let search = NutritionixSearch()
    let searchBar = UISearchBar()
    let tableView = UITableView()
    var didSelectFoodItem : (FoodItem->Void)?
    
    class SearchItemTableViewCell : UITableViewCell {
        
        static let CellID = "SearchItemTableViewCell"
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
            self.configureView()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        func configureView() {
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
    
        self.tableView.registerClass(SearchItemTableViewCell.self, forCellReuseIdentifier: SearchItemTableViewCell.CellID)
        self.configureView()
    }
    
    private func configureView() {
        
        self.search.searchResultsDidLoad = {
            self.updateUI()
        }
        
        self.searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.searchBar)
        
        let searchBarConstraints : [NSLayoutConstraint] = [
            self.searchBar.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            self.searchBar.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor),
            self.searchBar.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor)
        ]
        
        self.view.addConstraints(searchBarConstraints)
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.tableView)
        
        let tableViewConstraints : [NSLayoutConstraint] = [
            self.tableView.topAnchor.constraintEqualToAnchor(self.searchBar.bottomAnchor),
            self.tableView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor),
            self.tableView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor),
            self.tableView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor)
        ]
        
        self.view.addConstraints(tableViewConstraints)
        
    }
    
    func updateUI() {
        self.tableView.reloadData()
    }
    
    // MARK: UISearchBarDelegate
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        //TURN ON FOR DEMO
        self.search.filter = searchText
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.search.filter = searchBar.text
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.searchBar.resignFirstResponder()
        //TODO: move to detail view controller
        print("selected")
        self.didSelectFoodItem?(self.search.results[indexPath.row])
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.search.results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = self.tableView.dequeueReusableCellWithIdentifier(SearchItemTableViewCell.CellID) as? SearchItemTableViewCell else {
            preconditionFailure("failed to initialize table view cell")
        }
        
        cell.accessoryType = .DisclosureIndicator
        //print(self.search.results[indexPath.row].name)
        
        cell.textLabel?.text = self.search.results[indexPath.row].name
        cell.detailTextLabel?.text = "\(self.search.results[indexPath.row].brandName!), \(self.search.results[indexPath.row].servingQuantity) \(self.search.results[indexPath.row].servingSizeUnit!)"
        
        return cell
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
