//
//  MCScatterChartRenderer.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/2/16.
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import UIKit
import Charts

class MCScatterChartRenderer: ScatterChartRenderer {
    
    var shouldDrawConnectionLines:Bool = true
    
    override func drawDataSet(context context: CGContext, dataSet: IScatterChartDataSet) {
        guard let
            dataProvider = dataProvider,
            animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer(dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        
        let entryCount = dataSet.entryCount

        var point = CGPoint()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let shape = dataSet.scatterShape
        
        let shapeSize = dataSet.scatterShapeSize
        let shapeHalf = shapeSize / 2.0
        let shapeHoleSizeHalf = dataSet.scatterShapeHoleRadius
        let shapeHoleSize = shapeHoleSizeHalf * 2.0
        let shapeHoleColor = dataSet.scatterShapeHoleColor
        let shapeStrokeSize = (shapeSize - shapeHoleSize) / 2.0
        let shapeStrokeSizeHalf = shapeStrokeSize / 2.0
        
        CGContextSaveGState(context)
        
        for j in 0 ..< Int(min(ceil(CGFloat(entryCount) * animator.phaseX), CGFloat(entryCount)))
        {
            guard let e = dataSet.entryForIndex(j) else { continue }
            
            if e is BarChartDataEntry {
                let entry = e as! BarChartDataEntry
                if entry.values == nil {//we have only one value to draw
                    point.x = CGFloat(e.xIndex)
                    point.y = CGFloat(e.value) * phaseY
                    point = CGPointApplyAffineTransform(point, valueToPixelMatrix);
                    
                    if (!viewPortHandler.isInBoundsRight(point.x)) {
                        break
                    }
                    
                    if (!viewPortHandler.isInBoundsLeft(point.x) || !viewPortHandler.isInBoundsY(point.y)) {
                        continue
                    }

                    if (shape == .Circle) {//drawing circle
                        if shapeHoleSize > 0.0 {
                            drawCircleShapeWithHole(context, point: point, color: dataSet.colorAt(j).CGColor,
                                            shapeHoleSizeHalf: shapeStrokeSizeHalf, shapeStrokeSize: shapeStrokeSize,
                                            shapeStrokeSizeHalf: shapeStrokeSizeHalf, shapeHoleSize: shapeHoleSize, shapeHoleColor: shapeHoleColor)
                        } else {
                            drawCircleShapeWithoutHole(context, color: dataSet.colorAt(j).CGColor, point: point, shapeHalf: shapeHalf, shapeSize: shapeSize)
                        }
                    } else if (shape == .Custom) {
                        CGContextSetFillColorWithColor(context, dataSet.colorAt(j).CGColor)
                        let customShape = dataSet.customScatterShape
                        if customShape == nil {
                            return
                        }
                        
                        drawCustomShape(context, point: point, customShape: customShape!)
                    }
                } else {//we have more than one value to draw and we should connect them wiht a line
                    var prevPoint = CGPointMake(-100, -100)
                    for value in entry.values! {
                        point.x = CGFloat(e.xIndex)
                        point.y = CGFloat(value) * phaseY
                        point = CGPointApplyAffineTransform(point, valueToPixelMatrix);
                        
                        if (!viewPortHandler.isInBoundsRight(point.x)) {
                            break
                        }
                        
                        if (!viewPortHandler.isInBoundsLeft(point.x) || !viewPortHandler.isInBoundsY(point.y)) {
                            continue
                        }

                        if (shape == .Circle) {
                            if shapeHoleSize > 0.0 {
                                drawCircleShapeWithHole(context, point: point, color: dataSet.colorAt(j).CGColor,
                                                        shapeHoleSizeHalf: shapeStrokeSizeHalf, shapeStrokeSize: shapeStrokeSize,
                                                        shapeStrokeSizeHalf: shapeStrokeSizeHalf, shapeHoleSize: shapeHoleSize, shapeHoleColor: shapeHoleColor)
                                
                                if (prevPoint.x > 0 && shouldDrawConnectionLines) {//driwing line that connects circle shapes
                                    CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().colorWithAlphaComponent(0.3).CGColor)
                                    CGContextSetLineWidth(context, shapeHoleSize + shapeStrokeSize)
                                    CGContextMoveToPoint(context, prevPoint.x + 0.5, prevPoint.y - 1.0)
                                    CGContextAddLineToPoint(context, point.x + 0.5, point.y + 2.0)
                                    CGContextStrokePath(context);
                                }
                            } else {
                                drawCircleShapeWithoutHole(context, color: dataSet.colorAt(j).CGColor, point: point, shapeHalf: shapeHalf, shapeSize: shapeSize)
                            }
                        } else if (shape == .Custom) {
                            CGContextSetFillColorWithColor(context, dataSet.colorAt(j).CGColor)
                            let customShape = dataSet.customScatterShape
                            if customShape == nil {
                                return
                            }
                            let mcDataSet = dataSet as! MCScatterChartDataSet
                            // transform the provided custom path
                            CGContextSaveGState(context)
                            if (prevPoint.x > 0) {//drawing line that connect custom shapes
                                CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().colorWithAlphaComponent(0.3).CGColor)
                                CGContextSetLineWidth(context, 7.0)
                                if mcDataSet.dataSetType == DataSetType.BloodPressureTop {
                                    CGContextMoveToPoint(context, prevPoint.x + 0.5, prevPoint.y)
                                    CGContextAddLineToPoint(context, point.x + 0.5, point.y)
                                    CGContextStrokePath(context)
                                } else {
                                    CGContextMoveToPoint(context, prevPoint.x + 0.5, prevPoint.y + 2.0)
                                    CGContextAddLineToPoint(context, point.x + 0.5, point.y + 2.0)
                                    CGContextStrokePath(context)
                                }
                            }
                            
                            drawCustomShape(context, point: point, customShape: customShape!)
                            CGContextRestoreGState(context)
                        }
                        
                        prevPoint = point
                    }
                }
            }
        }
        
        CGContextRestoreGState(context)
    }
    
    func drawCircleShapeWithHole (context: CGContext, point: CGPoint, color: CGColor, shapeHoleSizeHalf: CGFloat,
                          shapeStrokeSize: CGFloat, shapeStrokeSizeHalf: CGFloat, shapeHoleSize: CGFloat, shapeHoleColor: UIColor?) {
        CGContextSetStrokeColorWithColor(context, color)
        CGContextSetLineWidth(context, shapeStrokeSize)
        var rect = CGRect()
        rect.origin.x = point.x - shapeHoleSizeHalf - shapeStrokeSizeHalf
        rect.origin.y = point.y - shapeHoleSizeHalf - shapeStrokeSizeHalf
        rect.size.width = shapeHoleSize + shapeStrokeSize
        rect.size.height = shapeHoleSize + shapeStrokeSize
        CGContextStrokeEllipseInRect(context, rect)
        
        if let _shapeHoleColor = shapeHoleColor
        {
            CGContextSetFillColorWithColor(context, _shapeHoleColor.CGColor)
            rect.origin.x = point.x - shapeHoleSizeHalf
            rect.origin.y = point.y - shapeHoleSizeHalf
            rect.size.width = shapeHoleSize
            rect.size.height = shapeHoleSize
            CGContextFillEllipseInRect(context, rect)
        }
    }
    
    func drawCircleShapeWithoutHole (context: CGContext, color: CGColor, point: CGPoint, shapeHalf: CGFloat, shapeSize: CGFloat) {
        CGContextSetFillColorWithColor(context, color)
        var rect = CGRect()
        rect.origin.x = point.x - shapeHalf
        rect.origin.y = point.y - shapeHalf
        rect.size.width = shapeSize
        rect.size.height = shapeSize
        CGContextFillEllipseInRect(context, rect)
    }
    
    func drawCustomShape (context: CGContext, point: CGPoint, customShape: CGPath) {
        CGContextTranslateCTM(context, point.x-3.0, point.y)
        CGContextBeginPath(context)
        CGContextAddPath(context, customShape)
        CGContextFillPath(context)
    }
}
