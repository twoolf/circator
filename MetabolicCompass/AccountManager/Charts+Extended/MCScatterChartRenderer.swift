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
            let animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        
        let entryCount = dataSet.entryCount

        var point = CGPoint()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
//        let shape = dataSet.scatterShape
 //       let shape = dataSet.scatterShapeSize
        let shape = dataSet.visible
        
        let shapeSize = dataSet.scatterShapeSize
        let shapeHalf = shapeSize / 2.0
        let shapeHoleSizeHalf = dataSet.scatterShapeHoleRadius
        let shapeHoleSize = shapeHoleSizeHalf * 2.0
        let shapeHoleColor = dataSet.scatterShapeHoleColor
        let shapeStrokeSize = (shapeSize - shapeHoleSize) / 2.0
        let shapeStrokeSizeHalf = shapeStrokeSize / 2.0
        
        context.saveGState()
        
        for j in 0 ..< Int(min(ceil(CGFloat(entryCount) * CGFloat(animator.phaseX)), CGFloat(entryCount)))
        {
            guard let e = dataSet.entryForIndex(j) else { continue }
            
            if e is BarChartDataEntry {
                let entry = e as! BarChartDataEntry
                if entry.yValues == nil {//we have only one value to draw
//                    point.x = CGFloat(e.xIndex)
                    point.x = CGFloat(e.x)
                    point.y = CGFloat(e.y) * CGFloat(phaseY)
                    point = point.applying(valueToPixelMatrix);
                    
                    if (!(viewPortHandler?.isInBoundsRight(point.x))!) {
                        break
                    }
                    
                    if (!(viewPortHandler?.isInBoundsLeft(point.x))! || !(viewPortHandler?.isInBoundsY(point.y))!) {
                        continue
                    }

//                    if (shape == .Circle) {//drawing circle
                    if (shape == true) {
                        if shapeHoleSize > 0.0 {
                            drawCircleShapeWithHole(context: context, //point: point, color: dataSet.colorAt(j).CGColor,
                                point: point, color: dataSet.color(atIndex: j).cgColor,
                                            shapeHoleSizeHalf: shapeStrokeSizeHalf, shapeStrokeSize: shapeStrokeSize,
                                            shapeStrokeSizeHalf: shapeStrokeSizeHalf, shapeHoleSize: shapeHoleSize, shapeHoleColor: shapeHoleColor)
                        } else {
                            drawCircleShapeWithoutHole(context: context, color: dataSet.color(atIndex: j).cgColor, point: point, shapeHalf: shapeHalf, shapeSize: shapeSize)
                        }
                    } else if (shape == false) {
                        context.setFillColor(dataSet.color(atIndex: j).cgColor)
//                        let customShape = dataSet.customScatterShape
//                        if customShape == nil {
//                            return
                        }
                        
                        drawCustomShape(context: context, point: point, customShape: drawCustomShape as! CGPath)
                    }
                } else {//we have more than one value to draw and we should connect them with a line
                    var prevPoint = CGPoint(-100, -100)
//                    for value in entry.values! {
                    for value in BarChartDataEntry.accessibilityElements()! {
//                        point.x = CGFloat(e.xIndex)
                        point.x = CGFloat(e.x)
                        point.y = CGFloat(e.y) * CGFloat(phaseY)
                        point = point.applying(valueToPixelMatrix);
                        
                        if (!(viewPortHandler?.isInBoundsRight(point.x))!) {
                            break
                        }
                        
                        if (!(viewPortHandler?.isInBoundsLeft(point.x))! || !(viewPortHandler?.isInBoundsY(point.y))!) {
                            continue
                        }

                        //context, point: point, color: dataSet.colorAt(j).CGColor  
                        if (shape == true) {
                            if shapeHoleSize > 0.0 {
                                drawCircleShapeWithHole(context: context, point: point, color: dataSet.color(atIndex: j).cgColor,
                                                        shapeHoleSizeHalf: shapeStrokeSizeHalf, shapeStrokeSize: shapeStrokeSize,
                                                        shapeStrokeSizeHalf: shapeStrokeSizeHalf, shapeHoleSize: shapeHoleSize, shapeHoleColor: shapeHoleColor)
                                
                                if (prevPoint.x > 0 && shouldDrawConnectionLines) {//driwing line that connects circle shapes
//                                    context.setStrokeColor(color: UIColor.whiteColor)
                                    context.setLineWidth(shapeHoleSize + shapeStrokeSize)
                                    prevPoint.x = prevPoint.x + 0.5
                                    prevPoint.y = prevPoint.y - 1.0
                                    context.move(to: prevPoint)
//                                    context.moveToPoint(context, prevPoint.x + 0.5, prevPoint.y - 1.0)
//                                    context.addLineToPoint(context, point.x + 0.5, point.y + 2.0)
                                    point.x = point.x + 0.5
                                    point.y = point.y + 2.0
                                    context.addLine(to: point)
                                    context.strokePath();
                                }
                            } else {
                                drawCircleShapeWithoutHole(context: context, color: dataSet.color(atIndex: j).cgColor, point: point, shapeHalf: shapeHalf, shapeSize: shapeSize)
                            }
                        } else if (shape == false) {
//                            context.setFillColorWithColor(context, dataSet.color(atIndex: j).CGColor)
//                            context.setFillColor(color: dataSet.color(atIndex: j).CGColor)
//                            let customShape = dataSet.customScatterShape
                            if drawCustomShape == nil {
                                return
                            }
                            let mcDataSet = dataSet as! MCScatterChartDataSet
                            // transform the provided custom path
                            context.saveGState()
                            if (prevPoint.x > 0) {//drawing line that connect custom shapes
//                                context.setStrokeColorWithColor(context, UIColor.whiteColor.withAlphaComponent(0.3).CGColor)
//                                context.setStrokeColor(color: whiteColor.withAlphaComponent(0.3).CGColor)
                                context.setLineWidth(7.0)
                                if mcDataSet.dataSetType == DataSetType.BloodPressureTop {
                                    context.move(to: point)
//                                    context.move(to: <#T##CGPoint#>)
                                    context.addLine(to: point)
//                                    context.addLine(to: <#T##CGPoint#>)
                                    context.strokePath()
                                } else {
                                    context.move(to: point)
//                                    context.addLine(context, point.x + 0.5, point.y + 2.0)
                                    context.addLine(to: point)
                                    context.strokePath()
                                }
                            }
                            
                            drawCustomShape(context: context, point: point, customShape: drawCustomShape as! CGPath)
                            context.restoreGState()
                        }
                        
                        prevPoint = point
                    }
                }
            }
        }
    
//        context.restoreGState()
//    context.
    }
    
    func drawCircleShapeWithHole (context: CGContext, point: CGPoint, color: CGColor, shapeHoleSizeHalf: CGFloat,
                          shapeStrokeSize: CGFloat, shapeStrokeSizeHalf: CGFloat, shapeHoleSize: CGFloat, shapeHoleColor: UIColor?) {
        context.setStrokeColor(color)
        context.setLineWidth(shapeStrokeSize)
        var rect = CGRect()
        rect.origin.x = point.x - shapeHoleSizeHalf - shapeStrokeSizeHalf
        rect.origin.y = point.y - shapeHoleSizeHalf - shapeStrokeSizeHalf
        rect.size.width = shapeHoleSize + shapeStrokeSize
        rect.size.height = shapeHoleSize + shapeStrokeSize
        context.strokeEllipse(in: rect)
        
        if let _shapeHoleColor = shapeHoleColor
        {
            context.setFillColor(_shapeHoleColor.cgColor)
            rect.origin.x = point.x - shapeHoleSizeHalf
            rect.origin.y = point.y - shapeHoleSizeHalf
            rect.size.width = shapeHoleSize
            rect.size.height = shapeHoleSize
            context.fillEllipse(in: rect)
        }
    }
    
    func drawCircleShapeWithoutHole (context: CGContext, color: CGColor, point: CGPoint, shapeHalf: CGFloat, shapeSize: CGFloat) {
        context.setFillColor(color)
        var rect = CGRect()
        rect.origin.x = point.x - shapeHalf
        rect.origin.y = point.y - shapeHalf
        rect.size.width = shapeSize
        rect.size.height = shapeSize
        context.fillEllipse(in: rect)
    }
    
    func drawCustomShape (context: CGContext, point: CGPoint, customShape: CGPath) {
        context.translateBy(x: point.x-3.0, y: point.y)
        context.beginPath()
        context.addPath(customShape)
        context.fillPath()
    }

