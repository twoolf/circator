# Code Efficiency Report - MetabolicCompass (Circator)

Date: October 7, 2025
Repository: twoolf/circator

This report documents inefficiency patterns identified in the MetabolicCompass codebase that could be optimized for better performance, reduced memory usage, or improved code maintainability.

## Summary

Found 5 significant inefficiency patterns across the Swift codebase:
1. **Sequential dictionary key checks in FoodItem.swift** (HIGH IMPACT) - FIXED IN THIS PR
2. **Repeated NSPredicate creation in String+Extended.swift** (MEDIUM IMPACT)
3. **New NSOperationQueue creation per call in Array+Extended.swift** (MEDIUM IMPACT)
4. **String concatenation in reduce function** (LOW-MEDIUM IMPACT)
5. **Inefficient reduce pattern in Meal.swift** (LOW IMPACT - appears unimplemented)

## Detailed Findings

### 1. FoodItem.swift - Sequential Dictionary Key Checks (HIGH IMPACT) ⚠️ FIXED

**Location:** `/MetabolicCompass/NutritionManager/Model/FoodItem.swift` lines 31-170

**Problem:**
The `init(nutritionixData:)` method uses sequential `if key == "..."` checks to parse a dictionary with 25+ possible keys. Each iteration of the for loop checks every if statement, resulting in O(n) string comparisons per iteration.

**Current Code Pattern:**
```swift
for (key, value) in nutritionixData {
    if key == "item_name" {
        if let name = value as? String {
            self.name = name
        }
    }
    if key == "brand_name" {
        self.brandName = String(value) != "<null>" ? String(value) : nil
    }
    if key == "item_description" {
        self.statement = String(value) != "<null>" ? String(value) : nil
    }
    // ... 22+ more if checks
}
```

**Impact:**
- Worst-case: 25+ string comparisons per dictionary entry
- Executes on every API response when creating FoodItems from nutritionix data
- High-frequency code path in the nutrition tracking feature

**Solution Applied:**
Replaced with a `switch` statement which Swift optimizes with jump tables for O(1) dispatch:

```swift
for (key, value) in nutritionixData {
    switch key {
    case "item_name":
        if let name = value as? String {
            self.name = name
        }
    case "brand_name":
        self.brandName = String(value) != "<null>" ? String(value) : nil
    case "item_description":
        self.statement = String(value) != "<null>" ? String(value) : nil
    // ... all other cases
    default:
        break
    }
}
```

**Estimated Improvement:** 
- Reduces from O(n) to O(1) key matching
- Should provide measurable performance improvement when parsing API responses

---

### 2. String+Extended.swift - Repeated NSPredicate Creation (MEDIUM IMPACT)

**Location:** `/MetabolicCompass/Extensions/String+Extended.swift` lines 27-33

**Problem:**
The `mathesToRegEx` helper method creates a new `NSPredicate` instance every time it's called for regex validation.

**Current Code:**
```swift
private func mathesToRegEx(regEx: String) -> Bool {
    let predicate = NSPredicate(format:"SELF MATCHES %@", regEx)
    let isValid = predicate.evaluateWithObject(self)
    return isValid
}
```

**Impact:**
- Unnecessary object allocation on every validation
- Called from `isValidAsEmail()` and `containsOnlyLetters()` which may be called frequently during form validation

**Recommendation:**
Option 1: Cache predicates for common patterns (email, letters)
```swift
private static let emailPredicate = NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
private static let lettersPredicate = NSPredicate(format:"SELF MATCHES %@", "[A-Za-z]{1,}")
```

Option 2: Use `NSRegularExpression` which can be cached and reused more efficiently

**Estimated Improvement:**
- Eliminates repeated object allocation
- Reduces memory churn during form validation

---

### 3. Array+Extended.swift - New NSOperationQueue Per Call (MEDIUM IMPACT)

**Location:** `/MetabolicCompass/Extensions/Array+Extended.swift` line 16

**Problem:**
The `onFinish` extension method creates a new `NSOperationQueue` instance every time it's called.

**Current Code:**
```swift
func onFinish(block: () -> Void) {
    let finishOperationBlock = NSBlockOperation(block: block)
    self.forEach { [unowned finishOperationBlock] in finishOperationBlock.addDependency($0) }
    NSOperationQueue().addOperation(finishOperationBlock)  // Creates new queue!
}
```

**Impact:**
- Operation queue creation is a relatively expensive operation
- May be called multiple times in the application
- Unnecessary resource overhead

**Recommendation:**
Option 1: Reuse a shared background queue:
```swift
private static let finishQueue = NSOperationQueue()

func onFinish(block: () -> Void) {
    let finishOperationBlock = NSBlockOperation(block: block)
    self.forEach { [unowned finishOperationBlock] in finishOperationBlock.addDependency($0) }
    Array.finishQueue.addOperation(finishOperationBlock)
}
```

Option 2: Use the operations' existing queue if available, or a main queue

**Estimated Improvement:**
- Reduces resource allocation overhead
- Better queue management

---

### 4. NutritionManagerBackEnd.swift - String Concatenation in Reduce (LOW-MEDIUM IMPACT)

**Location:** `/MetabolicCompass/NutritionManager/NutritionManagerBackEnd.swift` lines 47-54

**Problem:**
The `encodeDictionary` method uses string concatenation within a reduce function, creating intermediate string objects.

**Current Code:**
```swift
func encodeDictionary(vals: [String: AnyObject]) -> String {
    let result = Array(vals.keys).reduce("") {
        (accumulator, key) in
        let prefix = (accumulator == "") ? "?" : "&"
        return "\(accumulator)\(prefix)\(encodeKeyOrVal(key))=\(encodeKeyOrVal(vals[key]!))"
    }
    return result
}
```

**Impact:**
- Creates intermediate string for each key-value pair
- Memory churn, especially for dictionaries with many keys
- Called when building URL query strings

**Recommendation:**
Use a string builder approach or `joined()`:
```swift
func encodeDictionary(vals: [String: AnyObject]) -> String {
    var components = vals.map { key, value in
        "\(encodeKeyOrVal(key))=\(encodeKeyOrVal(value))"
    }
    return components.isEmpty ? "" : "?" + components.joined(separator: "&")
}
```

**Estimated Improvement:**
- Reduces intermediate string allocations
- Cleaner, more idiomatic Swift code

---

### 5. Meal.swift - Inefficient Reduce Pattern (LOW IMPACT - UNIMPLEMENTED)

**Location:** `/MetabolicCompass/NutritionManager/Model/Meal.swift` lines 25-29

**Problem:**
The `nutrition` computed property uses a reduce with a combiner that just returns the first item, appearing unimplemented.

**Current Code:**
```swift
var nutrition : NutritionalContent {
    get {
        return self.items.reduce(FoodItem(), combine: FoodItem.combiner).nutrition
    }
}

// In FoodItem.swift:
static var combiner : ((FoodItem, FoodItem) -> FoodItem) = { (thisFood, thatFood) in
    return thisFood  // Just returns first item!
}
```

**Impact:**
- Wasteful computation - iterates through all items but doesn't aggregate
- The nutrition calculation appears broken or incomplete
- May return incorrect nutrition totals

**Recommendation:**
Either:
1. Implement proper nutrition aggregation in the combiner
2. Or use a more efficient approach:
```swift
var nutrition : NutritionalContent {
    get {
        let combined = NutritionalContent()
        for item in items {
            // Add item.nutrition values to combined
        }
        return combined
    }
}
```

**Estimated Improvement:**
- Fixes potentially broken functionality
- More efficient if proper aggregation is implemented

---

## Priority Recommendations

1. **IMMEDIATE:** Fix FoodItem.swift dictionary parsing (highest performance impact) - ✅ COMPLETED
2. **HIGH:** Review and fix Meal.swift nutrition calculation (appears broken)
3. **MEDIUM:** Cache NSPredicate instances in String+Extended.swift
4. **MEDIUM:** Optimize NSOperationQueue usage in Array+Extended.swift
5. **LOW:** Refactor string building in NutritionManagerBackEnd.swift

## Testing Notes

- All changes should be pure refactorings with equivalent logic
- Test nutrition data parsing after FoodItem.swift changes
- Verify form validation still works after String+Extended.swift changes
- Check that operation completion callbacks work after Array+Extended.swift changes

---

**Report Generated:** October 7, 2025
**Author:** Devin AI
**Session:** https://app.devin.ai/sessions/52c564ddd8fa4fa4bf28bad43bac718b
