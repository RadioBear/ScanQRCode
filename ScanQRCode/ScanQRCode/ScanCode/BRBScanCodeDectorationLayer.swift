//
//  ScanCodeDectorationLayer.swift
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

class BRBScaneCodeDectorationLayer: CALayer {
    
    struct Setting {
        static let pathAnimationName = "PathAnimation"
        static let colorAnimationName = "ColorAnimation"
        
        static let frameBeginColor = UIColor.whiteColor().CGColor
        static let frameEndColor = CGColorCreateCopyWithAlpha(UIColor.whiteColor().CGColor, 0.5)
        static let frameLineWidth : CGFloat = 1
        
        static let connerSize : CGFloat = 20.0
        static let connerColor = UIColor.greenColor().CGColor
        static let connerLineWidth : CGFloat = 4
        
        static let baselineLineWidth : CGFloat = 3
        static let baselineBeginColor = CGColorCreateCopyWithAlpha(UIColor.redColor().CGColor, 0.5)
        static let baselineEndColor = CGColorCreateCopyWithAlpha(UIColor.redColor().CGColor, 0.1)
        static let baselineMargin : CGFloat = 30
    }
    
    enum LayerIndex : UInt32 {
        case Frame = 0
        case Conner = 1
        case Baseline = 2
    }
    
    enum InterfaceType {
        case FrameOnly
        case FrameAndLine
    }
    
    var interfaceType : InterfaceType = .FrameOnly {
        didSet {
            self.p_refreshInterfaceType()
        }
    }
    var connerLayer : CAShapeLayer!
    var frameLayer : CAShapeLayer!
    var baselineLayer : CAShapeLayer!
        
        
    func p_createFrameLayer() -> CAShapeLayer {
        
        let frameLayer = CAShapeLayer()
        frameLayer.lineWidth = Setting.frameLineWidth
        frameLayer.strokeColor = Setting.frameBeginColor
        frameLayer.fillColor = UIColor.clearColor().CGColor
        frameLayer.lineCap = kCALineCapRound
        frameLayer.lineJoin = kCALineJoinRound
        
        let animation = CABasicAnimation(keyPath: "strokeColor")
        animation.fromValue = Setting.frameBeginColor
        animation.toValue = Setting.frameEndColor
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
        animation.fillMode = kCAFillModeBoth
        animation.duration = 0.5
        animation.repeatCount = HUGE
        animation.autoreverses = true
        frameLayer.addAnimation(animation, forKey: Setting.colorAnimationName)
        
        return frameLayer
    }
    
    func p_createConnerLayer() -> CAShapeLayer {
        let connerLayer = CAShapeLayer()
        connerLayer.lineWidth = Setting.connerLineWidth
        connerLayer.strokeColor = Setting.connerColor
        connerLayer.fillColor = UIColor.clearColor().CGColor
        connerLayer.lineCap = kCALineCapRound
        connerLayer.lineJoin = kCALineJoinRound
        return connerLayer
    }
    
    func p_createBaselineLayer() -> CAShapeLayer {
        let baselineLayer = CAShapeLayer()
        baselineLayer.lineWidth = Setting.baselineLineWidth
        baselineLayer.strokeColor = Setting.baselineBeginColor
        baselineLayer.fillColor = UIColor.clearColor().CGColor
        baselineLayer.lineCap = kCALineCapRound
        baselineLayer.lineJoin = kCALineJoinRound
        
        let animation = CABasicAnimation(keyPath: "strokeColor")
        animation.fromValue = Setting.baselineBeginColor
        animation.toValue = Setting.baselineEndColor
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
        animation.fillMode = kCAFillModeBoth
        animation.duration = 0.5
        animation.repeatCount = HUGE
        animation.autoreverses = true
        baselineLayer.addAnimation(animation, forKey: Setting.colorAnimationName)
        
        return baselineLayer
    }
    
    func p_createFramePath(withRect rect : CGRect) -> CGPath {
        return CGPathCreateWithRect(rect, nil)
    }
    
    func p_createConnerPath(withRect rect : CGRect) -> CGPath {
        let connerPath = CGPathCreateMutable()
        // left top
        CGPathMoveToPoint(connerPath, nil, rect.minX, rect.minY + Setting.connerSize)
        CGPathAddLineToPoint(connerPath, nil, rect.minX, rect.minY)
        CGPathAddLineToPoint(connerPath, nil, rect.minX + Setting.connerSize, rect.minY)
        // left bottom
        CGPathMoveToPoint(connerPath, nil, rect.minX, rect.maxY - Setting.connerSize)
        CGPathAddLineToPoint(connerPath, nil, rect.minX, rect.maxY)
        CGPathAddLineToPoint(connerPath, nil, rect.minX + Setting.connerSize, rect.maxY)
        // right top
        CGPathMoveToPoint(connerPath, nil, rect.maxX, rect.minY + Setting.connerSize)
        CGPathAddLineToPoint(connerPath, nil, rect.maxX, rect.minY)
        CGPathAddLineToPoint(connerPath, nil, rect.maxX - Setting.connerSize, rect.minY)
        // righ bottom
        CGPathMoveToPoint(connerPath, nil, rect.maxX, rect.maxY - Setting.connerSize)
        CGPathAddLineToPoint(connerPath, nil, rect.maxX, rect.maxY)
        CGPathAddLineToPoint(connerPath, nil, rect.maxX - Setting.connerSize, rect.maxY)
        return connerPath
    }
    
    func p_createBaselinePath(withRect rect : CGRect) -> CGPath {
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, rect.minX + Setting.baselineMargin, rect.midY)
        CGPathAddLineToPoint(path, nil, rect.maxX - Setting.baselineMargin, rect.midY)
        return path
    }

    func frameWithRect(rect : CGRect) {
        
        self.p_makeInit()
        
        self.frameLayer?.path = p_createFramePath(withRect: rect)
        self.connerLayer?.path = p_createConnerPath(withRect: rect)
        
        if interfaceType == .FrameAndLine {
            self.baselineLayer?.path = p_createBaselinePath(withRect: rect)
        }
    }
    
    func animationFrame(toRect newRect : CGRect, withDuration duration : CFTimeInterval) {
        
        self.p_makeInit()

        if let frameLayer = self.frameLayer {
            var oldPath : CGPath?
            if frameLayer.animationForKey(Setting.pathAnimationName) != nil {
                if let presentLayer = frameLayer.presentationLayer() {
                    oldPath = presentLayer.path
                }
            }
            if oldPath == nil {
                oldPath = frameLayer.path
            }
            
            let newPath = p_createFramePath(withRect: newRect)
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = oldPath
            animation.toValue = newPath
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
            animation.fillMode = kCAFillModeBoth
            animation.removedOnCompletion = true
            
            CATransaction.disableActions()
            frameLayer.path = newPath
            CATransaction.setDisableActions(false)
            frameLayer.addAnimation(animation, forKey: Setting.pathAnimationName)
        }
        
        if let connerLayer = self.connerLayer {
            var oldPath : CGPath?
            if connerLayer.animationForKey(Setting.pathAnimationName) != nil {
                if let presentLayer = connerLayer.presentationLayer() {
                    oldPath = presentLayer.path
                }
            }
            if oldPath == nil {
                oldPath = connerLayer.path
            }
            
            let newPath = p_createConnerPath(withRect: newRect)
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = oldPath
            animation.toValue = newPath
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
            animation.fillMode = kCAFillModeBoth
            animation.removedOnCompletion = true
            
            CATransaction.disableActions()
            connerLayer.path = newPath
            CATransaction.setDisableActions(false)
            connerLayer.addAnimation(animation, forKey: Setting.pathAnimationName)
        }
        if interfaceType == .FrameAndLine {
            if let baselineLayer = self.baselineLayer {
                let newPath = p_createBaselinePath(withRect: newRect)
                
                let animation = CABasicAnimation(keyPath: "path")
                animation.fromValue = CGPathCreateMutable()
                animation.toValue = newPath
                animation.duration = duration
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
                animation.fillMode = kCAFillModeBoth
                animation.removedOnCompletion = true
                
                CATransaction.disableActions()
                baselineLayer.path = newPath
                CATransaction.setDisableActions(false)
                baselineLayer.addAnimation(animation, forKey: Setting.pathAnimationName)
            }
        }
    }

    private func p_makeInit() {
        
        if self.connerLayer == nil {
            self.connerLayer = p_createConnerLayer()
            self.insertSublayer(connerLayer, atIndex: LayerIndex.Conner.rawValue)
        }
        if self.frameLayer == nil {
            self.frameLayer = p_createFrameLayer()
            self.insertSublayer(frameLayer, atIndex: LayerIndex.Frame.rawValue)
        }
        
        if interfaceType == .FrameAndLine {
            if self.baselineLayer == nil {
                self.baselineLayer = p_createBaselineLayer()
                self.insertSublayer(baselineLayer, atIndex: LayerIndex.Baseline.rawValue)
            }
        }
        
        self.p_refreshInterfaceType()
    }
    
    private func p_refreshInterfaceType() {
        if interfaceType == .FrameAndLine {
            self.baselineLayer?.hidden = false
        } else {
            self.baselineLayer?.hidden = true
        }
    }
}