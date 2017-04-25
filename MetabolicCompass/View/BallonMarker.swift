//
//  BalloonMarker.swift
//  ChartsDemo
//
//  Created by Artem Usachov on 29/5/16.
//
//

import Foundation
import Charts

//public class BalloonMarker: ChartMarker
public class BalloonMarker: MarkerImage
{
    public var font: UIFont?
    public var insets = UIEdgeInsets()
    public var minimumSize = CGSize()

    private var labelns: NSString?
    private var _labelSize: CGSize = CGSize()
    private var _size: CGSize = CGSize()
    private var _paragraphStyle: NSMutableParagraphStyle?
    private var _drawAttributes = [String : AnyObject]()

    public var scatterChartMarker = false
    public var yMax = 1.0
    public var yMin = 0.0
    public var yPixelRange = 0.0

    public var yActual = 0.0

    public init(color: UIColor, font: UIFont, insets: UIEdgeInsets)
    {
//        super.init()

        self.font = font
        self.insets = insets
        
        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = .center
    }
    
//    var size: Size { return _size; }
    
    open override func draw(context: CGContext, point: CGPoint)
    {
        if (labelns == nil)
        {
            return
        }
        
        let offset = self.offsetForDrawing(atPoint: point)

        var rect = CGRect(
            origin: CGPoint(
                x: point.x + offset.x,
                y: point.y + offset.y),
            size: _size)

        if scatterChartMarker {
            let actualYPos = (yMax - yActual) * (yPixelRange / (yMax - yMin))

            rect = CGRect(
                origin: CGPoint(
                    x: point.x + offset.x,
                    y: CGFloat(actualYPos) + offset.y),
                size: _size)
        }

        rect.origin.x -= (_size.width + 1.0) / 2.0
        rect.origin.y -= _size.height + 1.0

        let bezierPath = getBallonPathForRect(rect: rect)

        UIGraphicsPushContext(context);
        context.saveGState();
        bezierPath.stroke()

        rect.origin.y += self.insets.top
        rect.size.height -= self.insets.top + self.insets.bottom

        labelns?.draw(in: rect, withAttributes: _drawAttributes)
        context.restoreGState();
        UIGraphicsPopContext();
    }
    
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        yActual = entry.y
        
        var _: [BarChartDataEntry]
/*        for i in bentry {
            labelns = NSString(format: "%.5g", vals[vals.count-1])
            yActual = vals[vals.count-1]
        } else {
            labelns = NSString(format: "%.5g", entry.y)
        } */

        _drawAttributes.removeAll()
        _drawAttributes[NSFontAttributeName] = self.font
        _drawAttributes[NSParagraphStyleAttributeName] = _paragraphStyle
        _drawAttributes[NSForegroundColorAttributeName] = UIColor.white
        
        _labelSize = labelns?.size(attributes: _drawAttributes) ?? .zero
        _size.width = _labelSize.width + self.insets.left + self.insets.right
        _size.height = _labelSize.height + self.insets.top + self.insets.bottom
        _size.width = max(minimumSize.width, _size.width)
        _size.height = max(minimumSize.height, _size.height)
    }

    func getBallonPathForRect (rect: CGRect) -> UIBezierPath {
        let color2 = UIColor(red: 0.008, green: 0.145, blue: 0.329, alpha: 1.000)
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(rect.origin.x + 7.64, rect.origin.y + 0))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 29.36, rect.origin.y + 0))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 33.65,rect.origin.y + 0.33),
                                    controlPoint1: CGPoint(rect.origin.x + 31.56, rect.origin.y + 0),
                                    controlPoint2: CGPoint(rect.origin.x + 32.66, rect.origin.y + 0))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 33.84, rect.origin.y + 0.37))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 36.63, rect.origin.y + 3.16),
                                    controlPoint1: CGPoint(rect.origin.x + 35.14, rect.origin.y + 0.85),
                                    controlPoint2: CGPoint(rect.origin.x + 36.15, rect.origin.y + 1.86))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 37, rect.origin.y + 7.64),
                                    controlPoint1: CGPoint(rect.origin.x + 37, rect.origin.y + 4.34),
                                    controlPoint2: CGPoint(rect.origin.x + 37, rect.origin.y + 5.44))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 37, rect.origin.y + 16.36))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 36.67, rect.origin.y + 20.65),
                                    controlPoint1: CGPoint(rect.origin.x + 37, rect.origin.y + 18.56),
                                    controlPoint2: CGPoint(rect.origin.x + 37, rect.origin.y + 19.66))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 36.63, rect.origin.y + 20.84))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 33.84, rect.origin.y + 23.63),
                                    controlPoint1: CGPoint(rect.origin.x + 36.15, rect.origin.y + 22.14),
                                    controlPoint2: CGPoint(rect.origin.x + 35.14, rect.origin.y + 23.15))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 29.36, rect.origin.y + 24),
                                    controlPoint1: CGPoint(rect.origin.x + 32.66, rect.origin.y + 24),
                                    controlPoint2: CGPoint(rect.origin.x + 31.56, rect.origin.y + 24))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 7.64, rect.origin.y + 24))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 3.35, rect.origin.y + 23.67),
                                    controlPoint1: CGPoint(rect.origin.x + 5.44, rect.origin.y + 24),
                                    controlPoint2: CGPoint(rect.origin.x + 4.34, rect.origin.y + 24))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 3.16, rect.origin.y + 23.63))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 0.37, rect.origin.y + 20.84),
                                    controlPoint1: CGPoint(rect.origin.x + 1.86, rect.origin.y + 23.15),
                                    controlPoint2: CGPoint(rect.origin.x + 0.85, rect.origin.y + 22.14))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 0, rect.origin.y + 16.36),
                                    controlPoint1: CGPoint(rect.origin.x + 0, rect.origin.y + 19.66),
                                    controlPoint2: CGPoint(rect.origin.x + 0, rect.origin.y + 18.56))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 0, rect.origin.y + 7.64))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 0.33, rect.origin.y + 3.35),
                                    controlPoint1: CGPoint(rect.origin.x + 0, rect.origin.y + 5.44),
                                    controlPoint2: CGPoint(rect.origin.x + 0, rect.origin.y + 4.34))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 0.37, rect.origin.y + 3.16))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 3.16, rect.origin.y + 0.37),
                                    controlPoint1: CGPoint(rect.origin.x + 0.85, rect.origin.y + 1.86),
                                    controlPoint2: CGPoint(rect.origin.x + 1.86, rect.origin.y + 0.85))
        bezier3Path.addCurve(to: CGPoint(rect.origin.x + 7.64, rect.origin.y + 0),
                                    controlPoint1: CGPoint(rect.origin.x + 4.34, rect.origin.y + 0),
                                    controlPoint2: CGPoint(rect.origin.x + 5.44, rect.origin.y + 0))
        bezier3Path.close()
        bezier3Path.move(to: CGPoint(rect.origin.x + 14, rect.origin.y + 24))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 24, rect.origin.y + 24))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 19, rect.origin.y + 29))
        bezier3Path.addLine(to: CGPoint(rect.origin.x + 14, rect.origin.y + 24))
        bezier3Path.close()
        color2.setFill()
        bezier3Path.fill()
        color2.setStroke()
        bezier3Path.lineWidth = 1
        bezier3Path.stroke()

        return bezier3Path
    }
}
