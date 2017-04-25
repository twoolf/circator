//
//  PathMenuItem.swift
//  PathMenu
//
//  Created by pixyzehn on 12/27/14. 
//  Copyright (c) 2014 pixyzehn. All rights reserved.
//

import Foundation
import UIKit

public protocol PathMenuItemDelegate: class {
    func pathMenuItemTouchesBegin(item: PathMenuItem)
    func pathMenuItemTouchesEnd(item: PathMenuItem)
}

public class PathMenuItem: UIImageView {
    
    public var contentImageView: UIImageView?
    public var contentLabel: UILabel!

    public var startPoint: CGPoint?
    public var endPoint: CGPoint?
    public var nearPoint: CGPoint?
    public var farPoint: CGPoint?
    
    public weak var delegate: PathMenuItemDelegate?
    
    override public var isHighlighted: Bool {
        didSet {
            contentImageView?.isHighlighted = isHighlighted
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
    convenience public init(image: UIImage,
            highlightedImage himg: UIImage? = nil,
                contentImage cimg: UIImage? = nil,
    highlightedContentImage hcimg: UIImage? = nil,
                 contentText text: String?  = nil)
    {

        self.init(frame: CGRect.zero)
        self.image = image
        self.highlightedImage = himg

        self.contentImageView = UIImageView(image: cimg)
        self.contentImageView?.highlightedImage = hcimg

        self.contentLabel = UILabel(frame: CGRect.zero)
        self.contentLabel.text = text
        self.contentLabel.font = UIFont(name: "GothamBook", size: 14.0)
        self.contentLabel.textColor = .lightGray

        self.isUserInteractionEnabled = true
        self.addSubview(contentImageView!)

        self.contentLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentLabel)
        let constraints: [NSLayoutConstraint] = [
            contentLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 10.0),
            //contentLabel.heightAnchor.constraintEqualToConstant(25.0),
            contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]

        self.addConstraints(constraints)
    }

    private func ScaleRect(rect: CGRect, n: CGFloat) -> CGRect {
        let width  = rect.size.width
        let height = rect.size.height
        return CGRect((width - width * n)/2, (height - height * n)/2, width * n, height * n)
    }

    //MARK: UIView's methods
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if let image = image {
            bounds = CGRect(0, 0, image.size.width, image.size.height)
        }
        
        if let imageView = contentImageView,
                let width = imageView.image?.size.width,
                    let height = imageView.image?.size.height {

            imageView.frame = CGRect(bounds.size.width/2 - width/2, bounds.size.height/2 - height/2, width, height)
        }
    }
    
    public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isHighlighted = true
        delegate?.pathMenuItemTouchesBegin(item: self)
    }
    
    public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            if !ScaleRect(rect: bounds, n: 2.0).contains(location) {
                isHighlighted = false
            }
        }
    }

    public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isHighlighted = false
        if let location = touches.first?.location(in: self) {
            if ScaleRect(rect: bounds, n: 2.0).contains(location) {
                delegate?.pathMenuItemTouchesEnd(item: self)
            }
        }
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        isHighlighted = false
    }
}
