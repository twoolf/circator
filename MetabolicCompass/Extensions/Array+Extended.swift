//
//  Array+Extended.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 8/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

extension Array where Element: Operation {
    func onFinish(block: @escaping () -> Void) {
        // This block will be executed after all operations from the array.
        let finishOperationBlock = BlockOperation(block: block)
        self.forEach { [unowned finishOperationBlock] in finishOperationBlock.addDependency($0) }
        OperationQueue().addOperation(finishOperationBlock)
    }
}
