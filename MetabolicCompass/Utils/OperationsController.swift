//
//  OperationsController.swift
//  OperationsController.swift
//
//  Created by User on 9/3/18.
//  Copyright (c) 2018 Yanif Ahmad, Tom Woolf. All rights reserved.
//
//

import Foundation

final class OperationsController {
    
    private class WeakOperation {
        weak var operation: Operation?
        init(operation: Operation) {
            self.operation = operation
        }
    }
    
    private var operations = [String: WeakOperation]()
    private static let instance = OperationsController()
    
    class func add(_ operation: Operation, forKey key: String) {
        cancelOperation(for: key)
        OperationQueue.main.addOperation(operation)
        instance.operations[key] = WeakOperation(operation: operation)
    }
    
    class func cancelOperation(for key: String) {
        if let operation = instance.operations[key]?.operation, (!operation.isFinished || !operation.isCancelled) {
            operation.cancel()
        }
        _ = instance.operations.removeValue(forKey: key)
    }
}
