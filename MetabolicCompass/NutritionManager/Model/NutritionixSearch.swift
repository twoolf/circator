//
//  NutritionixSearch.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/27/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import Foundation
import HealthKit

class Nutritionix {
    static let AppID = "a81d19cd"
    static let AppKey = "b045070df4b393eac5160fbb53262b1d"
}

class NutritionixSearch : JSONBackEnd {
    
    var rangeSize = 20
    lazy var hitRangeToLoad : (Int, Int) = (0, self.rangeSize)
    var hitsForSearch : (String, Int) = ("", 0)
    var parameters : [String: AnyObject] = [:]
    var results : [FoodItem] = []
    var filter : String? {
        didSet {
            if let filter = self.filter {
                if let barcode = Int(filter) {
                    self.searchRequest(searchBarcode: barcode)
                } else {
                    self.searchRequest(searchPhrase: filter)
                }
                
            }
        }
    }
    var searchResultsDidLoad : (Void->Void)?
    
    override init() {
        super.init()
    }
    
    func configurePhraseSearchParameters() {
        
        self.parameters = [
            "results" : "\(self.hitRangeToLoad.0):\(self.hitRangeToLoad.1)",
            "fields" : "*",
            "appId" : Nutritionix.AppID,
            "appKey" : Nutritionix.AppKey
        ]
    }
    
    func searchRequest(searchPhrase phrase : String) {
        
        self.configurePhraseSearchParameters()
        self.results.removeAll()
        
        
        if let url = NSURL(string: "https://api.nutritionix.com/v1_1/search/" + self.encodeKeyOrVal(phrase)) {
            self.ajaxRequest(url, parameters: self.parameters, jsonDataDidArrive: { (data, error) in
                if let json = data {
                    //filter is force unwrapped because this method is only called when filter is not nil
                    /*
                    if self.hitsForSearch.0 != self.filter! {
                        if let totalHits = json["total_hits"] as? NSNumber {
                            self.hitsForSearch = (self.filter!, Int(totalHits))
                        }
                    } else {
                        //todo:
                    }*/
                    
                    
                    if let resultsToAppend = json["hits"] as? NSArray {
                        self.appendResults(JSONData: resultsToAppend)
                    }
                    
                    if let block = self.searchResultsDidLoad {
                        NSOperationQueue.mainQueue().addOperationWithBlock(block)
                    }
                }
                
            })
        }
    }
    
    func configureBarcodeSearchParameters(forBarcode barcode : Int) {
        
        self.parameters = [
            "upc" : barcode,
            "appId" : Nutritionix.AppID,
            "appKey" : Nutritionix.AppKey
        ]
    }
    
    func searchRequest(searchBarcode barcode : Int) {
        
        self.configureBarcodeSearchParameters(forBarcode: barcode)
        self.results.removeAll()
        
        if let url = NSURL(string: "https://api.nutritionix.com/v1_1/item") {
            self.ajaxRequest(url, parameters: self.parameters, jsonDataDidArrive: { (data, error) in
                if let itemFields = data as? [String : AnyObject] {
                                        
                    self.results.append(FoodItem(nutritionixData: itemFields))
                    
                    if let block = self.searchResultsDidLoad {
                        NSOperationQueue.mainQueue().addOperationWithBlock(block)
                    }
                }
                

                
            })
        }
    }
    
    func appendResults(JSONData data : NSArray) {
        
        for item in data {
            
            if let keyValuePairs = item["fields"] as? [String : AnyObject] {
                self.results.append(FoodItem(nutritionixData: keyValuePairs))
            }
            

        }
        
    }

}
