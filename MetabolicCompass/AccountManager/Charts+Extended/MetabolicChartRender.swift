//
//  MetabolicChartRender.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved. 
//

import UIKit
import Charts
import MCCircadianQueries
import MetabolicCompassKit


extension CGRect{
    init(_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ height:CGFloat) {
        self.init(x:x,y:y,width:width,height:height)
    }
    
}
extension CGSize{
    init(_ width:CGFloat,_ height:CGFloat) {
        self.init(width:width,height:height)
    }
}
extension CGPoint{
    init(_ x:CGFloat,_ y:CGFloat) {
        self.init(x:x,y:y)
    }
}

class MetabolicChartRender: RadarChartRenderer {
    
    var centerCircleColor = UIColor.colorWithHex(hex6: 0x041F44)
    var imageIndent = CGFloat(5.0)
    var radiusMod   = CGFloat(1.0)

    internal struct Math {
        internal static let FDEG2RAD = CGFloat(Double.pi / 180.0)
        internal static let FRAD2DEG = CGFloat(180.0 / Double.pi)
        internal static let DEG2RAD = Double.pi / 180.0
        internal static let RAD2DEG = 180.0 / Double.pi
    }
    
    override func drawValues(context: CGContext) {
        super.drawValues(context: context)
        self.drawPoints(context: context)
    }
    
    
    func getPosition(center: CGPoint, dist: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(
            x: center.x + dist * cos(angle * Math.FDEG2RAD),
            y: center.y + dist * sin(angle * Math.FDEG2RAD)
        )
    }
    
    override func drawExtras(context: CGContext) {
        
        guard let
            chart = chart
            else { return }
        context.saveGState()
        
        let center = chart.centerOffsets
        let radius = chart.radius * radiusMod - CGFloat(chart.chartYMin) * CGFloat(chart.factor)
        
        context.beginPath()
        context.addEllipse(in: CGRect(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0))
        context.setFillColor(self.centerCircleColor.cgColor)
        context.fillPath()
        context.restoreGState()
        self.drawIcons(context: context)
        self.drawWeb(context: context)
    }
    
    override func drawWeb(context: CGContext) {
        guard let
            chart = chart as? MetabolicRadarChartView,
            let data = chart.data
            else { return }
        
        let sliceangle = chart.sliceAngle
        
        context.saveGState()
        
        // calculate the factor that is needed for transforming the value to
        // pixels
        let factor = chart.factor
        let radius = chart.radius * radiusMod - CGFloat(chart.chartYMin) * CGFloat(chart.factor)
        let rotationangle = chart.rotationAngle
        
        let center = chart.centerOffsets
        
        // draw the web lines that come from the center
        context.setLineWidth(chart.webLineWidth)
        context.setStrokeColor(chart.webColor.cgColor)
        context.setAlpha(chart.webAlpha)
        
        let xIncrements = 1 + chart.skipWebLineCount
        
        var _webLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)
        
        for i in stride(from: 0, to: data.entryCount, by: xIncrements) {
            let p = self.getPosition(
                center: center,
                dist: radius,
                angle: sliceangle * CGFloat(i) + rotationangle)
            
            _webLineSegmentsBuffer[0].x = center.x
            _webLineSegmentsBuffer[0].y = center.y
            _webLineSegmentsBuffer[1].x = p.x
            _webLineSegmentsBuffer[1].y = p.y
            context.strokeLineSegments(between: _webLineSegmentsBuffer)
        }
        
        // draw the inner-web  
        context.setLineWidth(chart.innerWebLineWidth)
        context.setStrokeColor(chart.webColor.cgColor)
        context.setAlpha(chart.webAlpha)
        
        let labelCount = chart.yAxis.entryCount
        for j in 0 ..< labelCount - chart.skipWebCircleCount {
            let r = CGFloat(chart.yAxis.entries[j] - chart.chartYMin) * factor            
            context.beginPath()
            context.addEllipse(in: CGRect(center.x - r, center.y - r, r * 2.0, r * 2.0))
            context.strokePath()
        }
        context.restoreGState()
    }
    
    func drawIcons(context: CGContext) {
        guard let
            chart = chart,
            let data = chart.data
            else { return }
        
        let sliceangle = chart.sliceAngle
        context.saveGState()
        
        // calculate the factor that is needed for transforming the value to
        // pixels
        let factor = chart.factor
        let rotationangle = chart.rotationAngle
        
        let center = chart.centerOffsets
        var dataSet: MetabolicChartDataSet? = nil
        
        guard let count = chart.data?.dataSetCount else {
            return
        }
        
        for i in 0...count {
            guard let set = chart.data?.getDataSetByIndex(i) as? MetabolicChartDataSet else { continue }
            
            if (set.showPoints) {
                dataSet = set
                break
            }
        }
        
        if dataSet != nil {
            for (index, type) in PreviewManager.balanceSampleTypes.enumerated() {
                let provider = DashboardMetricsAppearanceProvider()
                let image = provider.imageForSampleType(type.identifier, active: true)
                let p = self.getPosition(
                    center: center,
                    dist: CGFloat(chart.yRange) * factor + self.imageIndent,
                    angle: sliceangle * CGFloat(index) + rotationangle)
                image?.draw(in: CGRect(p.x - (image?.size.width)!/2, p.y - (image?.size.height)!/2, (image?.size.width)!, (image?.size.height)!))
            }
        }
        context.restoreGState()
    }
    
    func drawPoints(context: CGContext) {
        guard let
            chart = self.chart,
            let data = self.chart?.data as? RadarChartData,
            let animator = self.animator
            else { return }
        
        guard let count = chart.data?.dataSetCount else {
            return
        }
        
        context.saveGState()
        context.setLineWidth(data.highlightLineWidth)
        
        for i in 0...count {
            guard let set = chart.data?.getDataSetByIndex(i) as? MetabolicChartDataSet else { continue }
            
            if (set.showPoints) {
                self.drawPoints(set: set, context: context, animator: animator, chart: chart)
            }
        }
        context.restoreGState()
    }
    
    internal func drawPoints(set: MetabolicChartDataSet, context: CGContext, animator: Animator, chart: RadarChartView) {
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        let sliceangle = chart.sliceAngle
        let factor = chart.factor
        
        let center = chart.centerOffsets
        

        for (index, type) in PreviewManager.balanceSampleTypes.enumerated() {
            let provider = DashboardMetricsAppearanceProvider()
            let pointColor = provider.colorForSampleType(type.identifier, active: true)
            let e = set.entryForIndex(index)
            let j = set.entryIndex(entry: e!)
            let y = (e!.y - chart.chartYMin)
    
            let _highlightPointBuffer = self.getPosition(
                center: center,
                dist: CGFloat(y) * factor * CGFloat(phaseY),
                angle: sliceangle * CGFloat(j) * CGFloat(phaseX) + chart.rotationAngle)

            if (!_highlightPointBuffer.x.isNaN && !_highlightPointBuffer.y.isNaN) {
                drawHighlightCircle2(
                    context: context,
                    atPoint: _highlightPointBuffer,
                    outerRadius: set.highlightCircleOuterRadius,
                    fillColor: pointColor,
                    strokeColor: set.highlightCircleStrokeColor,
                    strokeWidth: set.highlightCircleStrokeWidth)
            }
            
        }
    }
   
    internal func drawHighlightCircle2(
        context: CGContext,
                atPoint point: CGPoint,
                        outerRadius: CGFloat,
                        fillColor: NSUIColor?,
                        strokeColor: NSUIColor?,
                        strokeWidth: CGFloat)
    {
        context.saveGState()
        
        if let fillColor = fillColor
        {
            context.beginPath()
            context.addEllipse(in: CGRect(point.x - outerRadius, point.y - outerRadius, outerRadius * 2.0, outerRadius * 2.0))
            context.setFillColor(fillColor.cgColor)
//            context.setFillPath(context)
            context.fillPath()
//            CGContextEOFillPath(context)
        }
        
        if let strokeColor = strokeColor
        {
            context.beginPath()
            context.addEllipse(in: CGRect(point.x - outerRadius, point.y - outerRadius, outerRadius * 2.0, outerRadius * 2.0))
            context.setStrokeColor(strokeColor.cgColor)
            context.setLineWidth(strokeWidth)
            context.strokePath()
        }
        
        context.restoreGState()
    }
    

}
