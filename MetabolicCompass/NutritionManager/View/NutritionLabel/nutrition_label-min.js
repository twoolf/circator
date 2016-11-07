/*
 ******************************************************************************************************************+
 * NUTRITIONIX.com                                                                                                 |
 *                                                                                                                 |
 * This plugin allows you to create a fully customizable nutrition label                                           |
 *                                                                                                                 |
 * @authors             majin22 (js) and genesis23rd (css and html)                                                |
 * @copyright           Copyright (c) 2016 Nutritionix.                                                            |
 * @license             This Nutritionix jQuery Nutrition Label is dual licensed under the MIT and GPL licenses.   |
 * @link                http://www.nutritionix.com                                                                 |
 * @github              http://github.com/nutritionix/nutrition-label                                              |
 * @current version     6.0.16                                                                                     |
 * @stable version      6.0.15                                                                                     |
 * @supported browser   Firefox, Chrome, IE8+                                                                      |
 *                                                                                                                 |
 ******************************************************************************************************************+
 */

;(function ($) {
    $.fn.nutritionLabel = function (option, settings) {
        if (typeof option === "object") {
            settings = option;
            init(settings, $(this))
        } else {
            if (typeof option === "string" && option !== "") {
                if (option === "destroy") {
                    new NutritionLabel().destroy($(this))
                } else {
                    if (option === "hide") {
                        new NutritionLabel().hide($(this))
                    } else {
                        if (option === "show") {
                            new NutritionLabel().show($(this))
                        } else {
                            var values = [];
                            var elements = this.each(function () {
                                var data = $(this).data("_nutritionLabel");
                                if (data) {
                                    if ($.fn.nutritionLabel.defaultSettings[option] !== undefined) {
                                        if (settings !== undefined) {
                                            data.settings[option] = settings;
                                            init(data.settings, $(this))
                                        } else {
                                            values.push(data.settings[option])
                                        }
                                    }
                                } else {
                                    if ($.fn.nutritionLabel.defaultSettings[option] !== undefined) {
                                        if (settings !== undefined) {
                                            $.fn.nutritionLabel.defaultSettings[option] = settings;
                                            init(null, $(this))
                                        }
                                    }
                                }
                            });
                            if (values.length === 1) {
                                return values[0]
                            }
                            return values.length > 0 ? values : elements
                        }
                    }
                }
            } else {
                if (typeof option === "undefined" || option === "") {
                    init(settings, $(this))
                }
            }
        }
    };
    $.fn.nutritionLabel.defaultSettings = {
        width: 280,
        allowCustomWidth: true,
        widthCustom: "auto",
        allowNoBorder: true,
        allowFDARounding: true,
        allowGoogleAnalyticsEventLog: false,
        gooleAnalyticsFunctionName: "ga",
        userFunctionNameOnQuantityChange: null,
        hideNotApplicableValues: false,
        brandName: "Brand where this item belongs to",
        scrollLongIngredients: false,
        scrollHeightComparison: 100,
        scrollHeightPixel: 95,
        decimalPlacesForNutrition: 1,
        decimalPlacesForDailyValues: 0,
        decimalPlacesForQuantityTextbox: 1,
        scrollLongItemName: false,
        scrollLongItemNamePixel: 36,
        showBottomLink: false,
        urlBottomLink: "http://www.nutritionix.com",
        nameBottomLink: "Nutritionix",
        valueServingUnitQuantity: 1,
        valueServingSizeUnit: "",
        showServingUnitQuantityTextbox: false,
        itemName: "Item / Ingredient Name",
        showServingUnitQuantity: false,
        hideTextboxArrows: true,
        originalServingUnitQuantity: 0,
        nutritionValueMultiplier: 1,
        totalContainerQuantity: 1,
        calorieIntake: 2000,
        dailyValueTotalFat: 65,
        dailyValueSatFat: 20,
        dailyValueCholesterol: 300,
        dailyValueSodium: 2400,
        dailyValuePotassium: 3500,
        dailyValueCarb: 300,
        dailyValueFiber: 25,
        showCalories: false,
        showFatCalories: false,
        showTotalFat: false,
        showSatFat: false,
        showTransFat: false,
        showPolyFat: false,
        showMonoFat: false,
        showCholesterol: false,
        showSodium: false,
        showPotassium: false,
        showTotalCarb: false,
        showFibers: false,
        showSugars: false,
        showProteins: false,
        showVitaminA: false,
        showVitaminC: false,
        showCalcium: false,
        showIron: false,
        showAmountPerServing: true,
        showServingsPerContainer: false,
        showItemName: false,
        showBrandName: false,
        showIngredients: false,
        showCalorieDiet: false,
        showCustomFooter: false,
        showDisclaimer: false,
        scrollDisclaimerHeightComparison: 100,
        scrollDisclaimer: 95,
        valueDisclaimer: "Please note that these nutrition values are estimated based on our standard serving portions. As food servings may have a slight variance each time you visit, please expect these values to be with in 10% +/- of your actual meal. If you have any questions about our nutrition calculator, please contact Nutritionix.",
        ingredientLabel: "INGREDIENTS:",
        valueCustomFooter: "",
        naCalories: false,
        naFatCalories: false,
        naTotalFat: false,
        naSatFat: false,
        naTransFat: false,
        naPolyFat: false,
        naMonoFat: false,
        naCholesterol: false,
        naSodium: false,
        naPotassium: false,
        naTotalCarb: false,
        naFibers: false,
        naSugars: false,
        naProteins: false,
        naVitaminA: false,
        naVitaminC: false,
        naCalcium: false,
        naIron: false,
        valueServingWeightGrams: 0,
        valueServingPerContainer: 1,
        valueCalories: 0,
        valueFatCalories: 0,
        valueTotalFat: 0,
        valueSatFat: 0,
        valueTransFat: 0,
        valuePolyFat: 0,
        valueMonoFat: 0,
        valueCholesterol: 0,
        valueSodium: 0,
        valuePotassium: 0,
        valueTotalCarb: 0,
        valueFibers: 0,
        valueSugars: 0,
        valueProteins: 0,
        valueVitaminA: 0,
        valueVitaminC: 0,
        valueCalcium: 0,
        valueIron: 0,
        unitCalories: "",
        unitFatCalories: "",
        unitTotalFat: "g",
        unitSatFat: "g",
        unitTransFat: "g",
        unitPolyFat: "g",
        unitMonoFat: "g",
        unitCholesterol: "mg",
        unitSodium: "mg",
        unitPotassium: "mg",
        unitTotalCarb: "g",
        unitFibers: "g",
        unitSugars: "g",
        unitProteins: "g",
        unitVitaminA: "%",
        unitVitaminC: "%",
        unitCalcium: "%",
        unitIron: "%",
        valueCol1CalorieDiet: 2000,
        valueCol2CalorieDiet: 2500,
        valueCol1DietaryTotalFat: 0,
        valueCol2DietaryTotalFat: 0,
        valueCol1DietarySatFat: 0,
        valueCol2DietarySatFat: 0,
        valueCol1DietaryCholesterol: 0,
        valueCol2DietaryCholesterol: 0,
        valueCol1DietarySodium: 0,
        valueCol2DietarySodium: 0,
        valueCol1DietaryPotassium: 0,
        valueCol2DietaryPotassium: 0,
        valueCol1DietaryTotalCarb: 0,
        valueCol2DietaryTotalCarb: 0,
        valueCol1Dietary: 0,
        valueCol2Dietary: 0,
        textNutritionFacts: "Nutrition Facts",
        textDailyValues: "Daily Value",
        textServingSize: "Serving Size:",
        textServingsPerContainer: "Servings Per Container",
        textAmountPerServing: "Amount Per Serving",
        textCalories: "Calories",
        textFatCalories: "Calories from Fat",
        textTotalFat: "Total Fat",
        textSatFat: "Saturated Fat",
        textTransFat: "<i>Trans</i> Fat",
        textPolyFat: "Polyunsaturated Fat",
        textMonoFat: "Monounsaturated Fat",
        textCholesterol: "Cholesterol",
        textSodium: "Sodium",
        textPotassium: "Potassium",
        textTotalCarb: "Total Carbohydrates",
        textFibers: "Dietary Fiber",
        textSugars: "Sugars",
        textProteins: "Protein",
        textVitaminA: "Vitamin A",
        textVitaminC: "Vitamin C",
        textCalcium: "Calcium",
        textIron: "Iron",
        ingredientList: "None",
        textPercentDailyPart1: "Percent Daily Values are based on a",
        textPercentDailyPart2: "calorie diet",
        textGoogleAnalyticsEventCategory: "Nutrition Label",
        textGoogleAnalyticsEventActionUpArrow: "Quantity Up Arrow Clicked",
        textGoogleAnalyticsEventActionDownArrow: "Quantity Down Arrow Clicked",
        textGoogleAnalyticsEventActionTextbox: "Quantity Textbox Changed"
    };

    function NutritionLabel(settings, $elem) {
        this.nutritionLabel = null;
        this.settings = settings;
        this.$elem = $elem;
        return this
    }

    function cleanSettings(settings) {
        var numericIndex = ["width", "scrollHeightComparison", "scrollHeightPixel", "decimalPlacesForNutrition", "decimalPlacesForDailyValues", "calorieIntake", "dailyValueTotalFat", "dailyValueSatFat", "dailyValueCholesterol", "dailyValueSodium", "dailyValuePotassium", "dailyValueCarb", "dailyValueFiber", "valueServingSize", "valueServingWeightGrams", "valueServingPerContainer", "valueCalories", "valueFatCalories", "valueTotalFat", "valueSatFat", "valueTransFat", "valuePolyFat", "valueMonoFat", "valueCholesterol", "valueSodium", "valuePotassium", "valueTotalCarb", "valueFibers", "valueSugars", "valueProteins", "valueVitaminA", "valueVitaminC", "valueCalcium", "valueIron", "valueCol1CalorieDiet", "valueCol2CalorieDiet", "valueCol1DietaryTotalFat", "valueCol2DietaryTotalFat", "valueCol1DietarySatFat", "valueCol2DietarySatFat", "valueCol1DietaryCholesterol", "valueCol2DietaryCholesterol", "valueCol1DietarySodium", "valueCol2DietarySodium", "valueCol1DietaryPotassium", "valueCol2DietaryPotassium", "valueCol1DietaryTotalCarb", "valueCol2DietaryTotalCarb", "valueCol1Dietary", "valueCol2Dietary", "valueServingUnitQuantity", "scrollLongItemNamePixel", "decimalPlacesForQuantityTextbox"];
        $.each(settings, function (index, value) {
            if (jQuery.inArray(index, numericIndex) !== -1) {
                settings[index] = parseFloat(settings[index]);
                if (isNaN(settings[index]) || settings[index] === undefined) {
                    settings[index] = 0
                }
            }
        });
        if (settings.valueServingUnitQuantity < 0) {
            settings.valueServingUnitQuantity = 0
        }
        return settings
    }

    function UpdateNutritionValueWithMultiplier(settings) {
        var nutritionIndex = ["valueCalories", "valueFatCalories", "valueTotalFat", "valueSatFat", "valueTransFat", "valuePolyFat", "valueMonoFat", "valueCholesterol", "valueSodium", "valuePotassium", "valueTotalCarb", "valueFibers", "valueSugars", "valueProteins", "valueVitaminA", "valueVitaminC", "valueCalcium", "valueIron", "valueServingWeightGrams"];
        $.each(settings, function (index, value) {
            if (jQuery.inArray(index, nutritionIndex) !== -1) {
                settings[index] = parseFloat(settings[index]);
                if (isNaN(settings[index]) || settings[index] === undefined) {
                    settings[index] = 0
                }
                settings[index] = parseFloat(settings[index]) * parseFloat(settings.valueServingUnitQuantity) * parseFloat(settings.nutritionValueMultiplier)
            }
        });
        if (parseFloat(settings.valueServingUnitQuantity) == 0) {
            settings.valueServingPerContainer = 0
        } else {
            if (!isNaN(settings.valueServingPerContainer) && settings.valueServingPerContainer != undefined) {
                settings.valueServingPerContainer = parseFloat(settings.totalContainerQuantity) / parseFloat(settings.valueServingUnitQuantity)
            }
        }
        return settings
    }

    function init(settings, $elem) {
        var $settings = $.extend({}, $.fn.nutritionLabel.defaultSettings, settings || {});
        $settings.totalContainerQuantity = parseFloat($settings.valueServingPerContainer) * parseFloat($settings.valueServingUnitQuantity);
        var $originalCleanSettings = cleanSettings($.extend({}, $.fn.nutritionLabel.defaultSettings, settings || {}));
        $originalCleanSettings.totalContainerQuantity = parseFloat($originalCleanSettings.valueServingPerContainer) * parseFloat($originalCleanSettings.valueServingUnitQuantity);
        $settings = cleanSettings($settings);
        $originalCleanSettings = cleanSettings($originalCleanSettings);
        $settings.nutritionValueMultiplier = $settings.valueServingUnitQuantity <= 0 ? 1 : 1 / $settings.valueServingUnitQuantity;
        var $updatedsettings = UpdateNutritionValueWithMultiplier($settings);
        $settings.originalServingUnitQuantity = $updatedsettings.valueServingUnitQuantity;
        if ($updatedsettings.valueServingUnitQuantity <= 0) {
            $originalCleanSettings.valueServingUnitQuantity = 1;
            $updatedsettings = UpdateNutritionValueWithMultiplier($originalCleanSettings);
            $updatedsettings.valueServingUnitQuantity = 1
        }
        var nutritionLabel = new NutritionLabel($updatedsettings, $elem);
        $elem.html(nutritionLabel.generate());
        if ($settings.showIngredients && $settings.scrollLongIngredients) {
            updateScrollingFeature($elem, $settings)
        }
        if ($settings.showDisclaimer) {
            updateScrollingFeatureDisclaimer($elem, $settings)
        }
        notApplicableHover($elem);
        if ($settings.scrollLongItemName) {
            addScrollToItemDiv($elem, $settings)
        }
        if ($settings.showServingUnitQuantityTextbox) {
            $("#" + $elem.attr("id")).delegate(".unitQuantityUp", "click", function (e) {
                e.preventDefault();
                $settingsHolder = cleanSettings($.extend({}, $.fn.nutritionLabel.defaultSettings, settings || {}));
                $settingsHolder.totalContainerQuantity = $settings.totalContainerQuantity;
                $settingsHolder.originalServingUnitQuantity = $settings.originalServingUnitQuantity;
                $settingsHolder.nutritionValueMultiplier = $settingsHolder.valueServingUnitQuantity <= 0 ? 1 : 1 / $settingsHolder.valueServingUnitQuantity;
                changeQuantityByArrow($(this), 1, $settingsHolder, nutritionLabel, $elem)
            });
            $("#" + $elem.attr("id")).delegate(".unitQuantityDown", "click", function (e) {
                e.preventDefault();
                $settingsHolder = cleanSettings($.extend({}, $.fn.nutritionLabel.defaultSettings, settings || {}));
                $settingsHolder.originalServingUnitQuantity = $settings.originalServingUnitQuantity;
                $settingsHolder.totalContainerQuantity = $settings.totalContainerQuantity;
                $settingsHolder.nutritionValueMultiplier = $settingsHolder.valueServingUnitQuantity <= 0 ? 1 : 1 / $settingsHolder.valueServingUnitQuantity;
                changeQuantityByArrow($(this), -1, $settingsHolder, nutritionLabel, $elem)
            });
            $("#" + $elem.attr("id")).delegate(".unitQuantityBox", "change", function (e) {
                e.preventDefault();
                $settingsHolder = cleanSettings($.extend({}, $.fn.nutritionLabel.defaultSettings, settings || {}));
                $settingsHolder.originalServingUnitQuantity = $settings.originalServingUnitQuantity;
                $settingsHolder.totalContainerQuantity = $settings.totalContainerQuantity;
                $settingsHolder.nutritionValueMultiplier = $settingsHolder.valueServingUnitQuantity <= 0 ? 1 : 1 / $settingsHolder.valueServingUnitQuantity;
                changeQuantityTextbox($(this), $settingsHolder, nutritionLabel, $elem)
            });
            $("#" + $elem.attr("id")).delegate(".unitQuantityBox", "keydown", function (e) {
                if (e.keyCode == 13) {
                    e.preventDefault();
                    $settingsHolder = cleanSettings($.extend({}, $.fn.nutritionLabel.defaultSettings, settings || {}));
                    $settingsHolder.originalServingUnitQuantity = $settings.originalServingUnitQuantity;
                    $settingsHolder.totalContainerQuantity = $settings.totalContainerQuantity;
                    $settingsHolder.nutritionValueMultiplier = $settingsHolder.valueServingUnitQuantity <= 0 ? 1 : 1 / $settingsHolder.valueServingUnitQuantity;
                    changeQuantityTextbox($(this), $settingsHolder, nutritionLabel, $elem)
                }
            })
        }
        $elem.data("_nutritionLabel", nutritionLabel)
    }

    function addScrollToItemDiv($elem, $settings) {
        if ($("#" + $elem.attr("id") + " .name.inline").val() != undefined) {
            if ($("#" + $elem.attr("id") + " .name.inline").height() > (parseInt($settings.scrollLongItemNamePixel) + 1)) {
                $("#" + $elem.attr("id") + " .name.inline").css({
                    "margin-left": "3.90em",
                    height: parseInt($settings.scrollLongItemNamePixel) + "px",
                    "overflow-y": "auto"
                })
            }
        } else {
            if ($("#" + $elem.attr("id") + " .name").height() > (parseInt($settings.scrollLongItemNamePixel) + 1)) {
                $("#" + $elem.attr("id") + " .name").css({
                    height: parseInt($settings.scrollLongItemNamePixel) + "px",
                    "overflow-y": "auto"
                })
            }
        }
    }

    function notApplicableHover($elem) {
        if ($elem.attr("id") !== undefined && $elem.attr("id") !== "") {
            $("#" + $elem.attr("id") + " .notApplicable").hover(function () {
                $("#" + $elem.attr("id") + " .naTooltip").css({
                    top: $(this).position().top + "px",
                    left: $(this).position().left + 10 + "px"
                }).show()
            }, function () {
                $("#" + $elem.attr("id") + " .naTooltip").hide()
            })
        } else {
            $("#" + $elem.attr("id") + " .notApplicable").hover(function () {
                $(".naTooltip").css({
                    top: $(this).position().top + "px",
                    left: $(this).position().left + 10 + "px"
                }).show()
            }, function () {
                $(".naTooltip").hide()
            })
        }
    }

    function updateScrollingFeature($elem, $settings) {
        if ($elem.attr("id") !== undefined && $elem.attr("id") !== "") {
            $ingredientListParent = $("#" + $elem.attr("id") + " #ingredientList").parent()
        } else {
            $ingredientListParent = $("#ingredientList").parent()
        }
        if ($ingredientListParent.innerHeight() > $settings.scrollHeightComparison) {
            $ingredientListParent.addClass("scroll").css({height: $settings.scrollHeightPixel + "px"})
        }
    }

    function updateScrollingFeatureDisclaimer($elem, $settings) {
        if ($elem.attr("id") !== undefined && $elem.attr("id") !== "") {
            $disclaimerParent = $("#" + $elem.attr("id") + " #calcDisclaimerText").parent()
        } else {
            $disclaimerParent = $("#calcDisclaimerText").parent()
        }
        if ($disclaimerParent.innerHeight() > $settings.scrollDisclaimerHeightComparison) {
            $disclaimerParent.addClass("scroll").css({height: $settings.scrollDisclaimer + "px"})
        }
    }

    function changeQuantityTextbox($thisTextbox, $originalSettings, nutritionLabel, $elem) {
        var previousValue = parseFloat($("#" + $elem.attr("id") + " #nixLabelBeforeQuantity").val());
        textBoxValue = !regIsPosNumber($thisTextbox.val()) ? previousValue : parseFloat($thisTextbox.val());
        $thisTextbox.val(textBoxValue.toFixed($originalSettings.decimalPlacesForQuantityTextbox));
        $originalSettings.valueServingUnitQuantity = textBoxValue;
        $originalSettings = UpdateNutritionValueWithMultiplier($originalSettings);
        nutritionLabel = new NutritionLabel($originalSettings, $elem);
        $elem.html(nutritionLabel.generate());
        if ($originalSettings.showIngredients && $originalSettings.scrollLongIngredients) {
            updateScrollingFeature($elem, $originalSettings)
        }
        if ($originalSettings.showDisclaimer) {
            updateScrollingFeatureDisclaimer($elem, $originalSettings)
        }
        notApplicableHover($elem);
        if ($originalSettings.scrollLongItemName) {
            addScrollToItemDiv($elem, $originalSettings)
        }
        if ($originalSettings.allowGoogleAnalyticsEventLog) {
            window[$originalSettings.gooleAnalyticsFunctionName]("send", "event", $originalSettings.textGoogleAnalyticsEventCategory, $originalSettings.textGoogleAnalyticsEventActionTextbox)
        }
        if (typeof $originalSettings.userFunctionNameOnQuantityChange === "function") {
            $originalSettings.userFunctionNameOnQuantityChange("textbox", previousValue.toFixed($originalSettings.decimalPlacesForQuantityTextbox), textBoxValue.toFixed($originalSettings.decimalPlacesForQuantityTextbox))
        }
    }

    function changeQuantityByArrow($thisQuantity, changeValueBy, $settings, nutritionLabel, $elem) {
        var currentQuantity = parseFloat($thisQuantity.parent().parent().find("input.unitQuantityBox").val());
        if (isNaN(currentQuantity)) {
            currentQuantity = 1
        }
        var beforeCurrentQuantityWasChanged = currentQuantity;
        if (currentQuantity <= 1 && changeValueBy == -1) {
            changeValueBy = -0.5;
            currentQuantity += changeValueBy
        } else {
            if (currentQuantity < 1 && changeValueBy == 1) {
                changeValueBy = 0.5;
                currentQuantity += changeValueBy
            } else {
                if (currentQuantity <= 2 && currentQuantity > 1 && changeValueBy == -1) {
                    currentQuantity = 1
                } else {
                    currentQuantity += changeValueBy
                }
            }
        }
        if (currentQuantity < 0) {
            currentQuantity = 0
        }
        $thisQuantity.parent().parent().find("input.unitQuantityBox").val(currentQuantity.toFixed($settings.decimalPlacesForQuantityTextbox));
        $settings.valueServingUnitQuantity = currentQuantity;
        $settings = UpdateNutritionValueWithMultiplier($settings);
        nutritionLabel = new NutritionLabel($settings, $elem);
        $elem.html(nutritionLabel.generate());
        if ($settings.showIngredients && $settings.scrollLongIngredients) {
            updateScrollingFeature($elem, $settings)
        }
        if ($settings.showDisclaimer) {
            updateScrollingFeatureDisclaimer($elem, $settings)
        }
        notApplicableHover($elem);
        if ($settings.scrollLongItemName) {
            addScrollToItemDiv($elem, $settings)
        }
        if ($settings.allowGoogleAnalyticsEventLog) {
            if (changeValueBy > 0) {
                window[$settings.gooleAnalyticsFunctionName]("send", "event", $settings.textGoogleAnalyticsEventCategory, $settings.textGoogleAnalyticsEventActionUpArrow)
            } else {
                window[$settings.gooleAnalyticsFunctionName]("send", "event", $settings.textGoogleAnalyticsEventCategory, $settings.textGoogleAnalyticsEventActionDownArrow)
            }
        }
        if (typeof $settings.userFunctionNameOnQuantityChange === "function") {
            $settings.userFunctionNameOnQuantityChange(changeValueBy > 0 ? "up arrow" : "down arrow", beforeCurrentQuantityWasChanged, currentQuantity)
        }
    }

    function roundToNearestNum(input, nearest) {
        if (nearest < 0) {
            return Math.round(input * nearest) / nearest
        } else {
            return Math.round(input / nearest) * nearest
        }
    }

    function roundCalories(toRound, decimalPlace) {
        toRound = roundCaloriesRule(toRound);
        if (toRound > 0) {
            toRound = parseFloat(toRound.toFixed(decimalPlace))
        }
        return toRound
    }

    function roundFat(toRound, decimalPlace) {
        toRound = roundFatRule(toRound);
        if (toRound > 0) {
            toRound = parseFloat(toRound.toFixed(decimalPlace))
        }
        return toRound
    }

    function roundSodium(toRound, decimalPlace) {
        toRound = roundSodiumRule(toRound);
        if (toRound > 0) {
            toRound = parseFloat(toRound.toFixed(decimalPlace))
        }
        return toRound
    }

    function roundPotassium(toRound, decimalPlace) {
        toRound = roundPotassiumRule(toRound);
        if (toRound > 0) {
            toRound = parseFloat(toRound.toFixed(decimalPlace))
        }
        return toRound
    }

    function roundCholesterol(toRound, decimalPlace) {
        var normalVersion = true;
        var roundResult = roundCholesterolRule(toRound);
        if (roundResult === false) {
            normalVersion = false
        } else {
            toRound = roundResult
        }
        if (normalVersion) {
            if (toRound > 0) {
                toRound = parseFloat(toRound.toFixed(decimalPlace))
            }
        } else {
            toRound = "< 5"
        }
        return toRound
    }

    function roundCarbFiberSugarProtein(toRound, decimalPlace) {
        var normalVersion = true;
        var roundResult = roundCarbFiberSugarProteinRule(toRound);
        if (roundResult === false) {
            normalVersion = false
        } else {
            toRound = roundResult
        }
        if (normalVersion) {
            if (toRound > 0) {
                toRound = parseFloat(toRound.toFixed(decimalPlace))
            }
        } else {
            toRound = "< 1"
        }
        return toRound
    }

    function roundCaloriesRule(toRound) {
        if (toRound < 5) {
            return 0
        } else {
            if (toRound <= 50) {
                return roundToNearestNum(toRound, 5)
            } else {
                return roundToNearestNum(toRound, 10)
            }
        }
    }

    function roundFatRule(toRound) {
        if (toRound < 0.5) {
            return 0
        } else {
            if (toRound < 5) {
                return roundToNearestNum(toRound, 0.5)
            } else {
                return roundToNearestNum(toRound, 1)
            }
        }
    }

    function roundSodiumRule(toRound) {
        if (toRound < 5) {
            return 0
        } else {
            if (toRound <= 140) {
                return roundToNearestNum(toRound, 5)
            } else {
                return roundToNearestNum(toRound, 10)
            }
        }
    }

    function roundPotassiumRule(toRound) {
        if (toRound < 5) {
            return 0
        } else {
            if (toRound <= 140) {
                return roundToNearestNum(toRound, 5)
            } else {
                return roundToNearestNum(toRound, 10)
            }
        }
    }

    function roundCholesterolRule(toRound) {
        if (toRound < 2) {
            return 0
        } else {
            if (toRound <= 5) {
                return false
            } else {
                return roundToNearestNum(toRound, 5)
            }
        }
    }

    function roundCarbFiberSugarProteinRule(toRound) {
        if (toRound < 0.5) {
            return 0
        } else {
            if (toRound < 1) {
                return false
            } else {
                return roundToNearestNum(toRound, 1)
            }
        }
    }

    function roundVitaminsCalciumIron(toRound) {
        if (toRound > 0) {
            if (toRound < 10) {
                return roundToNearestNum(toRound, 2)
            } else {
                if (toRound < 50) {
                    return roundToNearestNum(toRound, 5)
                } else {
                    return roundToNearestNum(toRound, 10)
                }
            }
        } else {
            return 0
        }
    }

    function regIsPosNumber(fData) {
        return new RegExp("(^[0-9]+[.]?[0-9]+$)|(^[0-9]+$)").test(fData)
    }

    NutritionLabel.prototype = {
        generate: function () {
            var $this = this;
            if ($this.nutritionLabel) {
                return $this.nutritionLabel
            }
            if ($this.settings.hideNotApplicableValues) {
                $this.settings.showCalories = $this.settings.naCalories ? false : $this.settings.showCalories;
                $this.settings.showFatCalories = $this.settings.naFatCalories ? false : $this.settings.showFatCalories;
                $this.settings.showTotalFat = $this.settings.naTotalFat ? false : $this.settings.showTotalFat;
                $this.settings.showSatFat = $this.settings.naSatFat ? false : $this.settings.showSatFat;
                $this.settings.showTransFat = $this.settings.naTransFat ? false : $this.settings.showTransFat;
                $this.settings.showPolyFat = $this.settings.naPolyFat ? false : $this.settings.showPolyFat;
                $this.settings.showMonoFat = $this.settings.naMonoFat ? false : $this.settings.showMonoFat;
                $this.settings.showCholesterol = $this.settings.naCholesterol ? false : $this.settings.showCholesterol;
                $this.settings.showSodium = $this.settings.naSodium ? false : $this.settings.showSodium;
                $this.settings.showPotassium = $this.settings.naPotassium ? false : $this.settings.showPotassium;
                $this.settings.showTotalCarb = $this.settings.naTotalCarb ? false : $this.settings.showTotalCarb;
                $this.settings.showFibers = $this.settings.naFibers ? false : $this.settings.showFibers;
                $this.settings.showSugars = $this.settings.naSugars ? false : $this.settings.showSugars;
                $this.settings.showProteins = $this.settings.naProteins ? false : $this.settings.showProteins;
                $this.settings.showVitaminA = $this.settings.naVitaminA ? false : $this.settings.showVitaminA;
                $this.settings.showVitaminC = $this.settings.naVitaminC ? false : $this.settings.showVitaminC;
                $this.settings.showCalcium = $this.settings.naCalcium ? false : $this.settings.showCalcium;
                $this.settings.showIron = $this.settings.naIron ? false : $this.settings.showIron
            }
            for (x = 1; x < 9; x++) {
                var tab = "";
                for (y = 1; y <= x; y++) {
                    tab += "\t"
                }
                eval("var tab" + x + ' = "' + tab + '";')
            }
            var naValue = '<font class="notApplicable">-&nbsp;</font>';
            var calorieIntakeMod = (parseFloat($this.settings.calorieIntake) / 2000).toFixed(2);
            var borderCSS = "";
            if ($this.settings.allowNoBorder) {
                borderCSS = "border: 0;"
            }
            var nutritionLabel = "";
            if (!$this.settings.allowCustomWidth) {
                nutritionLabel += '<div itemscope itemtype="http://schema.org/NutritionInformation"';
                nutritionLabel += ' class="nutritionLabel" style="' + borderCSS + " width: " + $this.settings.width + 'px;">\n'
            } else {
                nutritionLabel += '<div itemscope itemtype="http://schema.org/NutritionInformation"';
                nutritionLabel += ' class="nutritionLabel" style="' + borderCSS + " width: " + $this.settings.widthCustom + ';">\n'
            }
            nutritionLabel += tab1 + '<div class="title">' + $this.settings.textNutritionFacts + "</div>\n";
            if ($this.settings.showItemName) {
                var tabTemp = tab1;
                var itemNameClass = "";
                if ($this.settings.showServingUnitQuantityTextbox) {
                    if (($this.settings.valueServingSizeUnit == null || $this.settings.valueServingSizeUnit == "") || ($this.settings.valueServingSizeUnit !== "" && $this.settings.valueServingSizeUnit !== null && $this.settings.originalServingUnitQuantity <= 0)) {
                        nutritionLabel += tab1 + '<div class="cf">\n';
                        nutritionLabel += tab2 + '<div class="rel servingSizeField">\n';
                        var textboxClass = "unitQuantityBox";
                        if (!$this.settings.hideTextboxArrows) {
                            nutritionLabel += tab3 + '<div class="setter">\n';
                            nutritionLabel += tab4 + '<a href="Increase the quantity" class="unitQuantityUp" rel="nofollow"></a>\n';
                            nutritionLabel += tab4 + '<a href="Decrease the quantity" class="unitQuantityDown" rel="nofollow"></a>\n';
                            nutritionLabel += tab3 + '</div><!-- closing class="setter" -->\n'
                        } else {
                            textboxClass = "unitQuantityBox arrowsAreHidden"
                        }
                        nutritionLabel += tab3 + '<input type="text" value="' + parseFloat($this.settings.valueServingUnitQuantity.toFixed($this.settings.decimalPlacesForQuantityTextbox)) + '" ';
                        nutritionLabel += 'class="' + textboxClass + '">\n';
                        nutritionLabel += tab3 + '<input type="hidden" value="' + parseFloat($this.settings.valueServingUnitQuantity.toFixed($this.settings.decimalPlacesForQuantityTextbox)) + '" ';
                        nutritionLabel += 'id="nixLabelBeforeQuantity">\n';
                        nutritionLabel += tab2 + '</div><!-- closing class="servingSizeField" -->\n';
                        tabTemp = tab2;
                        var itemNameClass = "inline"
                    }
                }
                nutritionLabel += tabTemp + '<div class="name ' + itemNameClass + '">';
                nutritionLabel += $this.settings.itemName;
                if ($this.settings.showBrandName && $this.settings.brandName != null && $this.settings.brandName != "") {
                    nutritionLabel += " - " + $this.settings.brandName
                }
                nutritionLabel += "</div>\n";
                if ($this.settings.showServingUnitQuantityTextbox) {
                    if (($this.settings.valueServingSizeUnit == null || $this.settings.valueServingSizeUnit == "") || ($this.settings.valueServingSizeUnit !== "" && $this.settings.valueServingSizeUnit !== null && $this.settings.originalServingUnitQuantity <= 0)) {
                        nutritionLabel += tab1 + '</div><!-- closing class="cf" -->\n'
                    }
                }
            }
            var servingSizeIsHidden = false;
            var servingContainerIsHidden = false;
            var servingSizeTextClass = "";
            if ($this.settings.showServingUnitQuantity) {
                nutritionLabel += tab1 + '<div class="serving">\n';
                if ($this.settings.originalServingUnitQuantity > 0) {
                    nutritionLabel += tab2 + '<div class="cf">\n';
                    nutritionLabel += tab3 + '<div class="servingSizeText fl">' + $this.settings.textServingSize + "</div>\n";
                    nutritionLabel += $this.settings.showServingUnitQuantityTextbox ? "" : tab3 + '<div class="servingUnitQuantity fl">' + parseFloat($this.settings.originalServingUnitQuantity.toFixed($this.settings.decimalPlacesForNutrition)) + "</div>\n";
                    var unitAddedClass = "";
                    var gramsAddedClass = "";
                    if ($this.settings.valueServingSizeUnit !== "" && $this.settings.valueServingSizeUnit !== null) {
                        if ($this.settings.showServingUnitQuantityTextbox && $this.settings.valueServingSizeUnit != null && $this.settings.valueServingSizeUnit != "") {
                            unitAddedClass = "unitHasTextbox";
                            gramsAddedClass = "gramsHasTextbox";
                            nutritionLabel += tab3 + '<div class="rel servingSizeField fl">\n';
                            var textboxClass = "unitQuantityBox";
                            if (!$this.settings.hideTextboxArrows) {
                                nutritionLabel += tab4 + '<div class="setter">\n';
                                nutritionLabel += tab5 + '<a href="Increase the quantity" class="unitQuantityUp" rel="nofollow"></a>\n';
                                nutritionLabel += tab5 + '<a href="Decrease the quantity" class="unitQuantityDown" rel="nofollow"></a>\n';
                                nutritionLabel += tab4 + '</div><!-- closing class="setter" -->\n'
                            } else {
                                textboxClass = "unitQuantityBox arrowsAreHidden"
                            }
                            nutritionLabel += tab4 + '<input type="text" value="' + parseFloat($this.settings.valueServingUnitQuantity.toFixed($this.settings.decimalPlacesForQuantityTextbox)) + '" ';
                            nutritionLabel += 'class="' + textboxClass + '">\n';
                            nutritionLabel += tab4 + '<input type="hidden" value="' + parseFloat($this.settings.valueServingUnitQuantity.toFixed($this.settings.decimalPlacesForQuantityTextbox)) + '" ';
                            nutritionLabel += 'id="nixLabelBeforeQuantity">\n';
                            nutritionLabel += tab3 + '</div><!-- closing class="servingSizeField" -->\n'
                        } else {
                            if ($this.settings.originalServingUnitQuantity > 0 && $this.settings.showServingUnitQuantityTextbox) {
                                nutritionLabel += tab3 + '<div class="servingUnitQuantity">' + parseFloat($this.settings.originalServingUnitQuantity.toFixed($this.settings.decimalPlacesForNutrition)) + "</div>\n"
                            }
                        }
                        nutritionLabel += tab3 + '<div class="servingUnit fl ' + unitAddedClass + '">' + $this.settings.valueServingSizeUnit + "</div>\n"
                    } else {
                        if ($this.settings.originalServingUnitQuantity > 0 && $this.settings.showServingUnitQuantityTextbox) {
                            nutritionLabel += tab3 + '<div class="servingUnitQuantity fl">' + parseFloat($this.settings.originalServingUnitQuantity.toFixed($this.settings.decimalPlacesForNutrition)) + "</div>\n"
                        }
                    }
                    if ($this.settings.valueServingWeightGrams > 0) {
                        nutritionLabel += tab3 + '<div class="servingWeightGrams fl ' + gramsAddedClass + '">(<span itemprop="servingSize">' + parseFloat($this.settings.valueServingWeightGrams.toFixed($this.settings.decimalPlacesForNutrition)) + "g</span>)</div>\n"
                    }
                    nutritionLabel += tab2 + '</div><!-- closing class="cf" -->\n'
                } else {
                    servingSizeIsHidden = true
                }
                if ($this.settings.showServingsPerContainer) {
                    if ($this.settings.valueServingPerContainer > 0) {
                        nutritionLabel += tab2 + "<div>" + $this.settings.textServingsPerContainer + " ";
                        nutritionLabel += parseFloat($this.settings.valueServingPerContainer.toFixed($this.settings.decimalPlacesForNutrition));
                        nutritionLabel += "</div>\n"
                    } else {
                        servingContainerIsHidden = true
                    }
                } else {
                    servingContainerIsHidden = true
                }
                nutritionLabel += tab1 + '</div><!-- closing class="serving" -->\n'
            }
            if ((!$this.settings.showItemName && !$this.settings.showServingUnitQuantity) || (!$this.settings.showItemName && servingSizeIsHidden && servingContainerIsHidden)) {
                nutritionLabel += tab1 + '<div class="headerSpacer"></div>\n'
            }
            nutritionLabel += tab1 + '<div class="bar1"></div>\n';
            if ($this.settings.showAmountPerServing) {
                nutritionLabel += tab1 + '<div class="line m">';
                nutritionLabel += "<b>" + $this.settings.textAmountPerServing + "</b>";
                nutritionLabel += "</div>\n"
            }
            nutritionLabel += tab1 + '<div class="line">\n';
            if ($this.settings.showFatCalories) {
                nutritionLabel += tab2 + '<div class="fr">';
                nutritionLabel += $this.settings.textFatCalories + " ";
                nutritionLabel += $this.settings.naFatCalories ? naValue : ($this.settings.allowFDARounding ? roundCalories($this.settings.valueFatCalories, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueFatCalories.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitFatCalories;
                nutritionLabel += "</div>\n"
            }
            if ($this.settings.showCalories) {
                nutritionLabel += tab2 + "<div>";
                nutritionLabel += "<b>" + $this.settings.textCalories + '</b> <span itemprop="calories">';
                nutritionLabel += $this.settings.naCalories ? naValue : ($this.settings.allowFDARounding ? roundCalories($this.settings.valueCalories, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueCalories.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitCalories;
                nutritionLabel += "</span></div>\n"
            } else {
                if ($this.settings.showFatCalories) {
                    nutritionLabel += tab2 + "<div>&nbsp;</div>\n"
                }
            }
            nutritionLabel += tab1 + "</div>\n";
            nutritionLabel += tab1 + '<div class="bar2"></div>\n';
            nutritionLabel += tab1 + '<div class="line ar">';
            nutritionLabel += "<b>% " + $this.settings.textDailyValues + "<sup>*</sup></b>";
            nutritionLabel += "</div>\n";
            if ($this.settings.showTotalFat) {
                nutritionLabel += tab1 + '<div class="line">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naTotalFat ? naValue : "<b>" + parseFloat(parseFloat((($this.settings.allowFDARounding ? roundFatRule($this.settings.valueTotalFat) : $this.settings.valueTotalFat) / ($this.settings.dailyValueTotalFat == 0 ? 1 : $this.settings.dailyValueTotalFat * calorieIntakeMod)) * 100).toFixed($this.settings.decimalPlacesForDailyValues)) + "</b>%";
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + "<b>" + $this.settings.textTotalFat + '</b> <span itemprop="fatContent">';
                nutritionLabel += ($this.settings.naTotalFat ? naValue : ($this.settings.allowFDARounding ? roundFat($this.settings.valueTotalFat, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueTotalFat.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitTotalFat) + "\n";
                nutritionLabel += tab1 + "</span></div>\n"
            }
            if ($this.settings.showSatFat) {
                nutritionLabel += tab1 + '<div class="line indent">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naSatFat ? naValue : "<b>" + parseFloat(parseFloat((($this.settings.allowFDARounding ? roundFatRule($this.settings.valueSatFat) : $this.settings.valueSatFat) / ($this.settings.dailyValueSatFat == 0 ? 1 : $this.settings.dailyValueSatFat * calorieIntakeMod)) * 100).toFixed($this.settings.decimalPlacesForDailyValues)) + "</b>%";
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + $this.settings.textSatFat + ' <span itemprop="saturatedFatContent">';
                nutritionLabel += ($this.settings.naSatFat ? naValue : ($this.settings.allowFDARounding ? roundFat($this.settings.valueSatFat, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueSatFat.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitSatFat) + "\n";
                nutritionLabel += tab1 + "</span></div>\n"
            }
            if ($this.settings.showTransFat) {
                nutritionLabel += tab1 + '<div class="line indent">\n';
                nutritionLabel += tab2 + $this.settings.textTransFat + ' <span itemprop="transFatContent">';
                nutritionLabel += ($this.settings.naTransFat ? naValue : ($this.settings.allowFDARounding ? roundFat($this.settings.valueTransFat, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueTransFat.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitTransFat) + "\n";
                nutritionLabel += tab1 + "</span></div>\n"
            }
            if ($this.settings.showPolyFat) {
                nutritionLabel += tab1 + '<div class="line indent">';
                nutritionLabel += $this.settings.textPolyFat + " ";
                nutritionLabel += $this.settings.naPolyFat ? naValue : ($this.settings.allowFDARounding ? roundFat($this.settings.valuePolyFat, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valuePolyFat.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitPolyFat;
                nutritionLabel += "</div>\n"
            }
            if ($this.settings.showMonoFat) {
                nutritionLabel += tab1 + '<div class="line indent">';
                nutritionLabel += $this.settings.textMonoFat + " ";
                nutritionLabel += $this.settings.naMonoFat ? naValue : ($this.settings.allowFDARounding ? roundFat($this.settings.valueMonoFat, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueMonoFat.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitMonoFat;
                nutritionLabel += tab1 + "</div>\n"
            }
            if ($this.settings.showCholesterol) {
                nutritionLabel += tab1 + '<div class="line">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naCholesterol ? naValue : "<b>" + parseFloat(parseFloat((($this.settings.allowFDARounding ? roundCholesterolRule($this.settings.valueCholesterol) : $this.settings.valueCholesterol) / ($this.settings.dailyValueCholesterol == 0 ? 1 : $this.settings.dailyValueCholesterol * calorieIntakeMod)) * 100).toFixed($this.settings.decimalPlacesForDailyValues)) + "</b>%";
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + "<b>" + $this.settings.textCholesterol + '</b> <span itemprop="cholesterolContent">';
                nutritionLabel += ($this.settings.naCholesterol ? naValue : ($this.settings.allowFDARounding ? roundCholesterol($this.settings.valueCholesterol, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueCholesterol.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitCholesterol) + "\n";
                nutritionLabel += tab1 + "</span></div>\n"
            }
            if ($this.settings.showSodium) {
                nutritionLabel += tab1 + '<div class="line">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naSodium ? naValue : "<b>" + parseFloat(parseFloat((($this.settings.allowFDARounding ? roundSodiumRule($this.settings.valueSodium) : $this.settings.valueSodium) / ($this.settings.dailyValueSodium == 0 ? 1 : $this.settings.dailyValueSodium * calorieIntakeMod)) * 100).toFixed($this.settings.decimalPlacesForDailyValues)) + "</b>%";
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + "<b>" + $this.settings.textSodium + '</b> <span itemprop="sodiumContent">';
                nutritionLabel += ($this.settings.naSodium ? naValue : ($this.settings.allowFDARounding ? roundSodium($this.settings.valueSodium, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueSodium.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitSodium) + "\n";
                nutritionLabel += tab1 + "</div>\n"
            }
            if ($this.settings.showPotassium) {
                nutritionLabel += tab1 + '<div class="line">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naPotassium ? naValue : "<b>" + parseFloat(parseFloat((($this.settings.allowFDARounding ? roundPotassiumRule($this.settings.valuePotassium) : $this.settings.valuePotassium) / ($this.settings.dailyValuePotassium == 0 ? 1 : $this.settings.dailyValuePotassium * calorieIntakeMod)) * 100).toFixed($this.settings.decimalPlacesForDailyValues)) + "</b>%";
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + "<b>" + $this.settings.textPotassium + '</b> <span itemprop="potassiumContent">';
                nutritionLabel += ($this.settings.naPotassium ? naValue : ($this.settings.allowFDARounding ? roundPotassium($this.settings.valuePotassium, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valuePotassium.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitPotassium) + "\n";
                nutritionLabel += tab1 + "</div>\n"
            }
            if ($this.settings.showTotalCarb) {
                nutritionLabel += tab1 + '<div class="line">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naTotalCarb ? naValue : "<b>" + parseFloat(parseFloat((($this.settings.allowFDARounding ? roundCarbFiberSugarProteinRule($this.settings.valueTotalCarb) : $this.settings.valueTotalCarb) / ($this.settings.dailyValueCarb == 0 ? 1 : $this.settings.dailyValueCarb * calorieIntakeMod)) * 100).toFixed($this.settings.decimalPlacesForDailyValues)) + "</b>%";
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + "<b>" + $this.settings.textTotalCarb + '</b> <span itemprop="carbohydrateContent">';
                nutritionLabel += ($this.settings.naTotalCarb ? naValue : ($this.settings.allowFDARounding ? roundCarbFiberSugarProtein($this.settings.valueTotalCarb, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueTotalCarb.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitTotalCarb) + "\n";
                nutritionLabel += tab1 + "</span></div>\n"
            }
            if ($this.settings.showFibers) {
                nutritionLabel += tab1 + '<div class="line indent">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naFibers ? naValue : "<b>" + parseFloat(parseFloat((($this.settings.allowFDARounding ? roundCarbFiberSugarProteinRule($this.settings.valueFibers) : $this.settings.valueFibers) / ($this.settings.dailyValueFiber * calorieIntakeMod)) * 100).toFixed($this.settings.decimalPlacesForDailyValues)) + "</b>%";
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + $this.settings.textFibers + ' <span itemprop="fiberContent">';
                nutritionLabel += ($this.settings.naFibers ? naValue : ($this.settings.allowFDARounding ? roundCarbFiberSugarProtein($this.settings.valueFibers, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueFibers.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitFibers) + "\n";
                nutritionLabel += tab1 + "</span></div>\n"
            }
            if ($this.settings.showSugars) {
                nutritionLabel += tab1 + '<div class="line indent">';
                nutritionLabel += $this.settings.textSugars + ' <span itemprop="sugarContent">';
                nutritionLabel += $this.settings.naSugars ? naValue : ($this.settings.allowFDARounding ? roundCarbFiberSugarProtein($this.settings.valueSugars, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueSugars.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitSugars;
                nutritionLabel += "</span></div>\n"
            }
            if ($this.settings.showProteins) {
                nutritionLabel += tab1 + '<div class="line">';
                nutritionLabel += "<b>" + $this.settings.textProteins + '</b> <span itemprop="proteinContent">';
                nutritionLabel += $this.settings.naProteins ? naValue : ($this.settings.allowFDARounding ? roundCarbFiberSugarProtein($this.settings.valueProteins, $this.settings.decimalPlacesForNutrition) : parseFloat($this.settings.valueProteins.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitProteins;
                nutritionLabel += "</span></div>\n"
            }
            nutritionLabel += tab1 + '<div class="bar1"></div>\n';
            if ($this.settings.showVitaminA) {
                nutritionLabel += tab1 + '<div class="line vitaminA">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naVitaminA ? naValue : ($this.settings.allowFDARounding ? roundVitaminsCalciumIron($this.settings.valueVitaminA) : parseFloat($this.settings.valueVitaminA.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitVitaminA;
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + $this.settings.textVitaminA + "\n";
                nutritionLabel += tab1 + "</div>\n"
            }
            if ($this.settings.showVitaminC) {
                nutritionLabel += tab1 + '<div class="line vitaminC">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naVitaminC ? naValue : ($this.settings.allowFDARounding ? roundVitaminsCalciumIron($this.settings.valueVitaminC) : parseFloat($this.settings.valueVitaminC.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitVitaminC;
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + $this.settings.textVitaminC + "\n";
                nutritionLabel += tab1 + "</div>\n"
            }
            if ($this.settings.showCalcium) {
                nutritionLabel += tab1 + '<div class="line calcium">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naCalcium ? naValue : ($this.settings.allowFDARounding ? roundVitaminsCalciumIron($this.settings.valueCalcium) : parseFloat($this.settings.valueCalcium.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitCalcium;
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + $this.settings.textCalcium + "\n";
                nutritionLabel += tab1 + "</div>\n"
            }
            if ($this.settings.showIron) {
                nutritionLabel += tab1 + '<div class="line iron">\n';
                nutritionLabel += tab2 + '<div class="dv">';
                nutritionLabel += $this.settings.naIron ? naValue : ($this.settings.allowFDARounding ? roundVitaminsCalciumIron($this.settings.valueIron) : parseFloat($this.settings.valueIron.toFixed($this.settings.decimalPlacesForNutrition))) + $this.settings.unitIron;
                nutritionLabel += "</div>\n";
                nutritionLabel += tab2 + $this.settings.textIron + "\n";
                nutritionLabel += tab1 + "</div>\n"
            }
            nutritionLabel += tab1 + '<div class="dvCalorieDiet line">\n';
            nutritionLabel += tab2 + '<div class="calorieNote">\n';
            nutritionLabel += tab3 + '<span class="star">*</span> ' + $this.settings.textPercentDailyPart1 + " " + $this.settings.calorieIntake + " " + $this.settings.textPercentDailyPart2 + ".\n";
            if ($this.settings.showIngredients) {
                nutritionLabel += tab3 + "<br />\n";
                nutritionLabel += tab3 + '<div class="ingredientListDiv">\n';
                nutritionLabel += tab4 + '<b class="active" id="ingredientList">' + $this.settings.ingredientLabel + "</b>\n";
                nutritionLabel += tab4 + $this.settings.ingredientList + "\n";
                nutritionLabel += tab3 + '</div><!-- closing class="ingredientListDiv" -->\n'
            }
            if ($this.settings.showDisclaimer) {
                nutritionLabel += tab3 + "<br/>";
                nutritionLabel += tab3 + '<div id="calcDisclaimer">\n';
                nutritionLabel += tab4 + '<span id="calcDisclaimerText">' + $this.settings.valueDisclaimer + "</span>\n";
                nutritionLabel += tab3 + "</div>\n";
                nutritionLabel += tab3 + "<br/>"
            }
            nutritionLabel += tab2 + '</div><!-- closing class="calorieNote" -->\n';
            if ($this.settings.showCalorieDiet) {
                nutritionLabel += tab2 + '<table class="tblCalorieDiet">\n';
                nutritionLabel += tab3 + "<thead>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<th>&nbsp;</th>\n";
                nutritionLabel += tab5 + "<th>Calories</th>\n";
                nutritionLabel += tab5 + "<th>" + $this.settings.valueCol1CalorieDiet + "</th>\n";
                nutritionLabel += tab5 + "<th>" + $this.settings.valueCol2CalorieDiet + "</th>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab3 + "</thead>\n";
                nutritionLabel += tab3 + "<tbody>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<td>Total Fat</td>\n";
                nutritionLabel += tab5 + "<td>Less than</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol1DietaryTotalFat + "g</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol2DietaryTotalFat + "g</td>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<td>&nbsp;&nbsp; Saturated Fat</td>\n";
                nutritionLabel += tab5 + "<td>Less than</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol1DietarySatFat + "g</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol2DietarySatFat + "g</td>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<td>Cholesterol</td>\n";
                nutritionLabel += tab5 + "<td>Less than</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol1DietaryCholesterol + "mg</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol2DietaryCholesterol + "mg</td>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<td>Sodium</td>\n";
                nutritionLabel += tab5 + "<td>Less than</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol1DietarySodium + "mg</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol2DietarySodium + "mg</td>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<td>Potassium</td>\n";
                nutritionLabel += tab5 + "<td>Less than</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol1DietaryPotassium + "mg</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol2DietaryPotassium + "mg</td>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<td>Total Carbohydrate</td>\n";
                nutritionLabel += tab5 + "<td>&nbsp;</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol1DietaryTotalCarb + "g</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol2DietaryTotalCarb + "g</td>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab4 + "<tr>\n";
                nutritionLabel += tab5 + "<td>&nbsp;&nbsp; Dietary</td>\n";
                nutritionLabel += tab5 + "<td>&nbsp;</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol1Dietary + "g</td>\n";
                nutritionLabel += tab5 + "<td>" + $this.settings.valueCol2Dietary + "g</td>\n";
                nutritionLabel += tab4 + "</tr>\n";
                nutritionLabel += tab3 + "</tbody>\n";
                nutritionLabel += tab2 + "</table>\n"
            }
            nutritionLabel += tab1 + '</div><!-- closing class="dvCalorieDiet line" -->\n';
            if ($this.settings.showBottomLink) {
                nutritionLabel += tab1 + '<div class="spaceAbove"></div>\n';
                nutritionLabel += tab1 + '<a href="' + $this.settings.urlBottomLink + '" target="_newSite" class="homeLinkPrint">' + $this.settings.nameBottomLink + "</a>\n";
                nutritionLabel += tab1 + '<div class="spaceBelow"></div>\n'
            }
            if ($this.settings.showCustomFooter) {
                nutritionLabel += tab1 + '<div class="customFooter">' + $this.settings.valueCustomFooter + "</div>\n"
            }
            nutritionLabel += '</div><!-- closing class="nutritionLabel" -->\n';
            nutritionLabel += '<div class="naTooltip">Data not available</div>\n';
            return nutritionLabel
        }
    }
})(jQuery);