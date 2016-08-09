//
//  Array+Extended.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 8/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

extension Array where Element: NSOperation {
    func onFinish(block: () -> Void) {
        // This block will be executed after all operations from the array.
        let finishOperationBlock = NSBlockOperation(block: block)
        self.forEach { [unowned finishOperationBlock] in finishOperationBlock.addDependency($0) }
        NSOperationQueue().addOperation(finishOperationBlock)
    }
}