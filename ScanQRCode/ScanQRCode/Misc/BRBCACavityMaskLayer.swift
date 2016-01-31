//
//  BRBCAMaskRectLayer.swift
//  ScanQRCode
//
// Copyright (c) 2016 RadioBear
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//

import Foundation
import UIKit

class BRBCACavityMaskLayer : CALayer
{
    static let kPathAnimationName = "Path"
    
    lazy var shapeLayer : CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.blackColor().CGColor
        shapeLayer.fillRule = kCAFillRuleEvenOdd
        self.mask = shapeLayer
        return shapeLayer
    }()
    
    
    private func p_rectToFullBounds(rect : CGRect) -> CGRect {
        let selfBounds = self.bounds
        let fullBounds : CGRect
        if selfBounds.width > selfBounds.height {
            fullBounds = CGRectMake(0.0, (selfBounds.height - (selfBounds.width * 2)) * 0.5, selfBounds.width * 2.0, selfBounds.width * 2.0)
        } else {
            fullBounds = CGRectMake((selfBounds.width - (selfBounds.height * 2)) * 0.5, 0.0, selfBounds.height * 2.0, selfBounds.height * 2.0)
        }
        return fullBounds
    }
    
    func cavityWithRect(rect : CGRect) {
        let fullBounds = p_rectToFullBounds(bounds)
        let path = CGPathCreateMutable()
        CGPathAddRects(path, nil, [fullBounds, rect], 2)
        shapeLayer.path = path
    }
    
    func animationCavity(toRect newRect : CGRect, withDuration duration : CFTimeInterval) {
        var oldPath : CGPath?
        if shapeLayer.animationForKey(BRBCACavityMaskLayer.kPathAnimationName) != nil {
            if let presentLayer = shapeLayer.presentationLayer() {
                oldPath = presentLayer.path
            }
        }
        if oldPath == nil {
            oldPath = shapeLayer.path
        }
        
        let fullBounds = p_rectToFullBounds(bounds)
        let newPath = CGPathCreateMutable()
        CGPathAddRects(newPath, nil, [fullBounds, newRect], 2)
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = oldPath
        animation.toValue = newPath
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
        animation.fillMode = kCAFillModeBoth
        animation.removedOnCompletion = true

        shapeLayer.path = newPath
        shapeLayer.addAnimation(animation, forKey: BRBCACavityMaskLayer.kPathAnimationName)
    }
}