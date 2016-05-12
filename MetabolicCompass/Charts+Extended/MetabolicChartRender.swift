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
    
    var centerCircleColor = UIColor.colorWithHexString("#041F44")!
   
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
    
    override func drawExtras(context context: CGContext) {
        
        guard let
            chart = chart
            else { return }
        

        CGContextSaveGState(context)
        
        let center = chart.centerOffsets
        let radius = chart.radius * CGFloat(chart.chartYMax - chart.chartYMin)
        
        CGContextBeginPath(context)
        CGContextAddEllipseInRect(context, CGRectMake(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0))
        CGContextSetFillColorWithColor(context, self.centerCircleColor.CGColor)
        CGContextEOFillPath(context)
        
        CGContextRestoreGState(context)
    }
    
    func drawPoints(context context: CGContext)
    {
        guard let
            chart = self.chart,
            data = self.chart?.data as? RadarChartData,
            animator = self.animator
            else { return }
        
        guard let count = chart.data?.dataSetCount else {
            return
        }
        
        CGContextSaveGState(context)
        CGContextSetLineWidth(context, data.highlightLineWidth)
        
        for i in 0...count {
            guard let set = chart.data?.getDataSetByIndex(i) as? MetabolicChartDataSet else { continue }
            
            if (set.showPoints) {
                self.drawPoints(set, context: context, animator: animator, chart: chart)
            }
        }
        
        CGContextRestoreGState(context)
        
    }
    
    internal func drawPoints(set: MetabolicChartDataSet, context: CGContext, animator: ChartAnimator, chart: RadarChartView) {
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        let sliceangle = chart.sliceAngle
        let factor = chart.factor
        
        let center = chart.centerOffsets
        
        
        
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
            
            var fillColor = set.highlightCircleFillColor
            
            if let entry = e as? MetabolicDataEntry {
                fillColor = entry.pointColor
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
                    fillColor: fillColor,
                    strokeColor: set.highlightCircleStrokeColor,
                    strokeWidth: set.highlightCircleStrokeWidth)
            }
            
        }
        
        
        
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
