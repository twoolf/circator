//
//  CycleChartRenderer.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 11/22/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import CoreGraphics
import Charts

class CycleChartRender: PieChartRenderer {

    internal struct Math
    {
        internal static let FDEG2RAD = CGFloat(Double.pi / 180.0)
        internal static let FRAD2DEG = CGFloat(180.0 / Double.pi)
        internal static let DEG2RAD = Double.pi / 180.0
        internal static let RAD2DEG = 180.0 / Double.pi
    }

    override func drawValues(context: CGContext)
    {
        guard let
            chart = chart,
            let data = chart.data,
            let animator = animator
            else { return }

        let center = chart.centerCircleBox

        // get whole the radius
        let radius = chart.radius
        let rotationAngle = chart.rotationAngle
        var drawAngles = chart.drawAngles
        var absoluteAngles = chart.absoluteAngles

        let phaseX = animator.phaseX
        let phaseY = animator.phaseY

        var labelRadiusOffset = radius / 10.0 * 3.0

        if chart.drawHoleEnabled
        {
            labelRadiusOffset = (radius - (radius * chart.holeRadiusPercent)) / 2.0
        }

        let labelRadius = radius - labelRadiusOffset

        var dataSets = data.dataSets

        let yValueSum = (data as! PieChartData).yValueSum

//        let drawXVals = chart.isDrawSliceTextEnabled
//        let drawXVals = chart.isdrawEntryLabelsEnabled
        let usePercentValuesEnabled = chart.usePercentValuesEnabled

        var angle: CGFloat = 0.0
        var xIndex = 0

        context.saveGState()
        defer { context.restoreGState() }

        for i in 0 ..< dataSets.count
        {
            guard let dataSet = dataSets[i] as? IPieChartDataSet else { continue }

            let drawYVals = dataSet.isDrawValuesEnabled

            if (!drawYVals)
            {
                continue
            }

            let xValuePosition = dataSet.xValuePosition
            let yValuePosition = dataSet.yValuePosition

            let valueFont = dataSet.valueFont
            let lineHeight = valueFont.lineHeight

            guard let formatter = dataSet.valueFormatter else { continue }

            for j in 0 ..< dataSet.entryCount
            {
                if (drawYVals && !drawYVals && (j >= data.dataSetCount || data.getDataSetByIndex(j) == nil))
                {
                    xIndex += 1
                    continue
                }

                guard let e = dataSet.entryForIndex(j) else { continue }

                if (xIndex == 0)
                {
                    angle = 0.0
                }
                else
                {
                    angle = absoluteAngles[xIndex - 1] * (phaseX as! CGFloat)
                }

                let sliceAngle = drawAngles[xIndex]
                let sliceSpace = dataSet.sliceSpace
                let sliceSpaceMiddleAngle = sliceSpace / (Math.FDEG2RAD * labelRadius)

                // offset needed to center the drawn text in the slice 
                let angleOffset = (sliceAngle - sliceSpaceMiddleAngle / 2.0) / 2.0

                angle = angle + angleOffset

                let transformedAngle = rotationAngle + angle * (phaseY as! CGFloat)

            
                let value = usePercentValuesEnabled ? e.x / yValueSum * 100.0 : e.x
//                let valueText = formatter.stringFromNumber(value)!
//                let valueText = formatter.stringForValue(value)!
                let valueText = formatter.description

                let sliceXBase = cos(transformedAngle * Math.FDEG2RAD)
                let sliceYBase = sin(transformedAngle * Math.FDEG2RAD)

//                let drawXOutside = drawXVals && xValuePosition == .OutsideSlice
                let drawXOutside = drawYVals && xValuePosition == .outsideSlice
                let drawYOutside = drawYVals && yValuePosition == .outsideSlice
                let drawXInside = drawYVals && xValuePosition == .insideSlice
                let drawYInside = drawYVals && yValuePosition == .insideSlice

                if drawYOutside || drawYOutside
                {
                    let valueLineLength1 = dataSet.valueLinePart1Length
                    let valueLineLength2 = dataSet.valueLinePart2Length
                    let valueLinePart1OffsetPercentage = dataSet.valueLinePart1OffsetPercentage

                    var pt2: CGPoint
                    var labelPoint: CGPoint
                    var align: NSTextAlignment

                    var line1Radius: CGFloat

                    if chart.drawHoleEnabled
                    {
                        line1Radius = (radius - (radius * chart.holeRadiusPercent)) * valueLinePart1OffsetPercentage + (radius * chart.holeRadiusPercent)
                    }
                    else
                    {
                        line1Radius = radius * valueLinePart1OffsetPercentage
                    }

                    let polyline2Length = dataSet.valueLineVariableLength
                        ? labelRadius * valueLineLength2 * abs(sin(transformedAngle * Math.FDEG2RAD))
                        : labelRadius * valueLineLength2;

                    let pt0 = CGPoint(
                        x: line1Radius * sliceXBase + center.x,
                        y: line1Radius * sliceYBase + center.y)

                    let pt1 = CGPoint(
                        x: labelRadius * (1 + valueLineLength1) * sliceXBase + center.x,
                        y: labelRadius * (1 + valueLineLength1) * sliceYBase + center.y)

                    if transformedAngle .truncatingRemainder(dividingBy: 360.0) >= 90.0 && transformedAngle .truncatingRemainder(dividingBy: 360.0) <= 270.0
                    {
                        pt2 = CGPoint(x: pt1.x - polyline2Length, y: pt1.y)
                        align = .right
                        labelPoint = CGPoint(x: pt2.x - 5, y: pt2.y - lineHeight)
                    }
                    else
                    {
                        pt2 = CGPoint(x: pt1.x + polyline2Length, y: pt1.y)
                        align = .left
                        labelPoint = CGPoint(x: pt2.x + 5, y: pt2.y - lineHeight)
                    }

                    if dataSet.valueLineColor != nil
                    {
                        context.setStrokeColor(dataSet.valueLineColor!.cgColor)
                        context.setLineWidth(dataSet.valueLineWidth);


                        context.move(to: pt0)
                        context.addLine(to: pt0)
                        context.addLine(to: pt1)
//                        CGContextmoveToPoint(context, pt0.x, pt0.y)
//                        CGContextAddLine(context, pt1.x, pt1.y)
//                        CGContextAddLine(context, pt2.x, pt2.y)

                        context.drawPath(using: CGPathDrawingMode.stroke);
                    }

                    if drawXOutside && drawYOutside
                    {
                        ChartUtils.drawText(
                            context: context,
                            text: valueText,
                            point: labelPoint,
                            align: align,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                        )

                        if (j < data.dataSetCount && data.getDataSetByIndex(j) != nil)
                        {
                            ChartUtils.drawText(
                                context: context,
//                                text: data.xVals[j]!,
                                text: data.getDataSetByIndex(j)! as! String,
                                point: CGPoint(x: labelPoint.x, y: labelPoint.y + lineHeight),
                                align: align,
                                attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                            )
                        }
                    }
                    else if drawXOutside
                    {
                        ChartUtils.drawText(
                            context: context,
                            text: data.getDataSetByIndex(j)! as! String,
                            point: CGPoint(x: labelPoint.x, y: labelPoint.y + lineHeight / 2.0),
                            align: align,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                        )
                    }
                    else if drawYOutside
                    {
                        ChartUtils.drawText(
                            context: context,
                            text: valueText,
                            point: CGPoint(x: labelPoint.x, y: labelPoint.y + lineHeight / 2.0),
                            align: align,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                        )
                    }
                }

                if drawXInside || drawYInside
                {
                    // calculate the text position
                    let x = labelRadius * sliceXBase + center.x
                    let y = labelRadius * sliceYBase + center.y - lineHeight

                    if drawXInside && drawYInside
                    {
                        ChartUtils.drawText(
                            context: context,
                            text: valueText,
                            point: CGPoint(x: x, y: y),
                            align: .center,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                        )

                        if j < data.dataSetCount && data.getDataSetByIndex(j) != nil
                        {
                            ChartUtils.drawText(
                                context: context,
                                text: data.getDataSetByIndex(j)! as! String,
                                point: CGPoint(x: x, y: y + lineHeight),
                                align: .center,
                                attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                            )
                        }
                    }
                    else if drawXInside
                    {
                        ChartUtils.drawText(
                            context: context,
                            text: data.getDataSetByIndex(j)! as! String,
                            point: CGPoint(x: x, y: y + lineHeight / 2.0),
                            align: .center,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                        )
                    }
                    else if drawYInside
                    {
                        ChartUtils.drawText(
                            context: context,
                            text: valueText,
                            point: CGPoint(x: x, y: y + lineHeight / 2.0),
                            align: .center,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)]
                        )
                    }
                }

                xIndex += 1
            }
        }
    }
}
