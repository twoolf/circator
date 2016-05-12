//
//  MetabolicChartRender.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts


class MetabolicChartRender: RadarChartRenderer {
    
   
    internal struct Math
    {
        internal static let FDEG2RAD = CGFloat(M_PI / 180.0)
        internal static let FRAD2DEG = CGFloat(180.0 / M_PI)
        internal static let DEG2RAD = M_PI / 180.0
        internal static let RAD2DEG = 180.0 / M_PI
    }
    
    override func drawValues(context context: CGContext) {
        super.drawValues(context: context)
        self.drawPoints(context: context)
    }
    
    func getPosition(center center: CGPoint, dist: CGFloat, angle: CGFloat) -> CGPoint
    {
        return CGPoint(
            x: center.x + dist * cos(angle * Math.FDEG2RAD),
            y: center.y + dist * sin(angle * Math.FDEG2RAD)
        )
    }
    
    func drawPoints(context context: CGContext)
    {
        guard let
            chart = self.chart,
            data = self.chart?.data as? RadarChartData,
            animator = self.animator
            else { return }
        
        CGContextSaveGState(context)
        CGContextSetLineWidth(context, data.highlightLineWidth)
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        let sliceangle = chart.sliceAngle
        let factor = chart.factor
        
        let center = chart.centerOffsets
        
        guard let set = chart.data?.getDataSetByIndex(1) as? IRadarChartDataSet else { return }
        
        CGContextSetStrokeColorWithColor(context, set.highlightColor.CGColor)
        
        for i in 0...set.entryCount {
            
            let e = set.entryForXIndex(i)
            if e?.xIndex != i
            {
                continue
            }
            
            let j = set.entryIndex(entry: e!)
            let y = (e!.value - chart.chartYMin)
            
            if (y.isNaN)
            {
                continue
            }
            
            let _highlightPointBuffer = self.getPosition(
                center: center,
                dist: CGFloat(y) * factor * phaseY,
                angle: sliceangle * CGFloat(j) * phaseX + chart.rotationAngle)
            
            
            if (!_highlightPointBuffer.x.isNaN && !_highlightPointBuffer.y.isNaN)
            {
                drawHighlightCircle2(
                    context: context,
                    atPoint: _highlightPointBuffer,
                    outerRadius: set.highlightCircleOuterRadius,
                    fillColor: set.highlightCircleFillColor,
                    strokeColor: set.highlightCircleStrokeColor,
                    strokeWidth: set.highlightCircleStrokeWidth)
            }
            
        }
        
        
        CGContextRestoreGState(context)
    }
   
    internal func drawHighlightCircle2(
        context context: CGContext,
                atPoint point: CGPoint,
                        outerRadius: CGFloat,
                        fillColor: NSUIColor?,
                        strokeColor: NSUIColor?,
                        strokeWidth: CGFloat)
    {
        CGContextSaveGState(context)
        
        if let fillColor = fillColor
        {
            CGContextBeginPath(context)
            CGContextAddEllipseInRect(context, CGRectMake(point.x - outerRadius, point.y - outerRadius, outerRadius * 2.0, outerRadius * 2.0))
            CGContextSetFillColorWithColor(context, fillColor.CGColor)
            CGContextEOFillPath(context)
        }
        
        if let strokeColor = strokeColor
        {
            CGContextBeginPath(context)
            CGContextAddEllipseInRect(context, CGRectMake(point.x - outerRadius, point.y - outerRadius, outerRadius * 2.0, outerRadius * 2.0))
            CGContextSetStrokeColorWithColor(context, strokeColor.CGColor)
            CGContextSetLineWidth(context, strokeWidth)
            CGContextStrokePath(context)
        }
        
        CGContextRestoreGState(context)
    }
}
