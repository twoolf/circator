//
//  NutritionLabelView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/27/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import HealthKit
import UIKit
import WebKit

class NutritionLabelView : WKWebView, WKNavigationDelegate {
    
    var scalesToFixedDimensions : Bool = true
    var content : NutritionalContent!
    
    var incomplete : Bool {
        get {
            if self.content.containsNutritionOfType(typeOfNutrition: .VitaminB6) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .VitaminB12) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .VitaminD) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .VitaminE) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .VitaminK) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .VitaminE) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Thiamin) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Riboflavin) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Niacin) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Folate) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Biotin) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .PantothenicAcid) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Phosphorus) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Iodine) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Magnesium) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Zinc) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Selenium) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Copper) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Manganese) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Chromium) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Molybdenum) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Chloride) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Caffeine) {
                return true
            }
            if self.content.containsNutritionOfType(typeOfNutrition: .Water) {
                return true
            }
            return false
        }
    }
    
    convenience init(nutritionalContent content : NutritionalContent) {
        self.init(frame: CGRect.zero)
        self.content = content
        self.navigationDelegate = self
        self.configureView()
    }
    
    private func configureView() {
       
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.scrollView.scrollEnabled = false
        self.userInteractionEnabled = false

    }
    
    private func displayConfiguration() -> String {
        
        var configuration = ""
        
        if let calories = self.content.EnergyConsumed {
            print("calories!")
            configuration += "'valueCalories' : \(calories.doubleValueForUnit(NutritionQuantityType.EnergyConsumed.unit)), 'showCalories' : true,"
        }
        
        //TODO: add calories from fat by calculation
        
        if let fatTotal = self.content.FatTotal {
            configuration += "'valueTotalFat' : \(fatTotal.doubleValueForUnit(NutritionQuantityType.FatTotal.unit)), 'showTotalFat' : true,"
        }
        
        if let fatSaturated = self.content.FatSaturated {
            configuration += "'valueSatFat' : \(fatSaturated.doubleValueForUnit(NutritionQuantityType.FatSaturated.unit)), 'showSatFat' : true,"
        }
        
        //TODO: add trans fat, calculation?
        
        if let fatPolyunsat = self.content.FatPolyunsaturated {
            configuration += "'valuePolyFat' : \(fatPolyunsat.doubleValueForUnit(NutritionQuantityType.FatPolyunsaturated.unit)), 'showPolyFat' : true,"
        }
        
        if let fatMonounsat = self.content.FatMonounsaturated {
            configuration += "'valueMonoFat' : \(fatMonounsat.doubleValueForUnit(NutritionQuantityType.FatMonounsaturated.unit)), 'showMonoFat' : true,"
        }
        
        if let cholesterol = self.content.Cholesterol {
            configuration += "'valueCholesterol' : \(cholesterol.doubleValueForUnit(NutritionQuantityType.Cholesterol.unit)), 'showCholesterol' : true,"
        }
        
        if let sodium = self.content.Sodium {
            configuration += "'valueSodium' : \(sodium.doubleValueForUnit(NutritionQuantityType.Sodium.unit)), 'showSodium' : true,"
        }
        
        if let potassium = self.content.Potassium {
            configuration += "'valuePotassium' : \(potassium.doubleValueForUnit(NutritionQuantityType.Potassium.unit)), 'showPotassium' : true,"
        }
        
        if let carbs = self.content.Carbohydrates {
            configuration += "'valueTotalCarb' : \(carbs.doubleValueForUnit(NutritionQuantityType.Carbohydrates.unit)), 'showTotalCarb' : true,"
        }
        
        if let fiber = self.content.Fiber {
            configuration += "'valueFibers' : \(fiber.doubleValueForUnit(NutritionQuantityType.Fiber.unit)), 'showFibers' : true,"
        }
        
        if let sugar = self.content.Sugar {
            configuration += "'valueSugars' : \(sugar.doubleValueForUnit(NutritionQuantityType.Sugar.unit)), 'showSugars' : true,"
        }
        
        if let protein = self.content.Protein {
            configuration += "'valueProteins' : \(protein.doubleValueForUnit(NutritionQuantityType.Protein.unit)), 'showProteins' : true,"
        }
        
        /*
         
        TODO: daily value percentage calculation needed
         
        if let vitaminA = self.content.VitaminA {
            configuration += "'valueVitaminA' : \(vitaminA), 'showVitaminA' : true,"
        }
        
        if let vitaminC = self.content.VitaminC {
            configuration += "'valueVitaminC' : \(vitaminC), 'showVitaminC' : true,"
        }
        
        if let calcium = self.content.Calcium {
            configuration += "'valueCalcium' : \(calcium), 'showCalcium' : true,"
        }
        
        if let iron = self.content.Iron {
            configuration += "'valueIron' : \(iron), 'showIron' : true,"
        }
         
        */
        
        return configuration
    }
    
    private func inject() -> String {
        
        print(self.displayConfiguration())
                
        return "$(document).ready(function(){$('#label').nutritionLabel({ " + self.displayConfiguration() + " }); });"
    }
 
    
    //inject javascript configuration of nutritional content and configures height of view based on content size of loaded webview
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        
        webView.evaluateJavaScript(self.inject(), completionHandler: { (result, error) in
            
            if self.scalesToFixedDimensions {
                //webView.evaluateJavaScript("document.getElementById(\"meta\").setAttribute(\"content\", \"initial-scale=1.0\");", completionHandler: nil)
                webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (result, error) in
                    
                    if let contentHeight = result as? NSNumber {
                        
                        webView.superview?.addConstraint(webView.heightAnchor.constraintEqualToConstant(CGFloat(contentHeight) - 15))
                    }
                })
            }

            webView.superview?.layoutIfNeeded()
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let filePath = NSBundle.mainBundle().URLForResource("nutrition_label", withExtension: "html") {
            let request = NSURLRequest(URL: filePath)
            self.loadRequest(request)
        }
    }
    
}