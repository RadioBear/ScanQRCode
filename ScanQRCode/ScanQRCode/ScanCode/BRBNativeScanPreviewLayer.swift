//
//  BRBNativeScanPreviewLayer.swift
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

import AVFoundation


class BRBNativeScanPreviewLayer: AVCaptureVideoPreviewLayer, BRBScanPreviewLayer {
    
    struct Setting {
        static let AnimationName = "TransformAnimation"
    }
    
    var scaleTransform = CGAffineTransformIdentity
    var rotateTransform = CGAffineTransformIdentity
    
    
    var calayer : CALayer! {
        get {
            return self
        }
    }
    
    func scale(toFactor factor : CGFloat) {
        self.scaleTransform = CGAffineTransformMakeScale(factor, factor)
        self.updateTransform()
    }
    
    func animateScale(toFactor factor : CGFloat, withDuration duration : CFTimeInterval) {
        self.scaleTransform = CGAffineTransformMakeScale(factor, factor)
        self.updateTransform(withDuration : duration)
    }
    
    func rotate(toAngle angle : CGFloat) {
        self.rotateTransform = CGAffineTransformMakeRotation(angle)
        self.updateTransform()
    }
    
    func animateRotate(toAngle angle : CGFloat, withDuration duration : CFTimeInterval) {
        self.rotateTransform = CGAffineTransformMakeRotation(angle)
        self.updateTransform(withDuration : duration)
    }
    
    func rotate(withRotation rotation: CGAffineTransform) {
        self.rotateTransform = CGAffineTransformConcat(self.rotateTransform, rotation)
        self.updateTransform()
    }
    
    func animateRotate(withRotation rotation : CGAffineTransform, withDuration duration : CFTimeInterval) {
        self.rotateTransform = CGAffineTransformConcat(self.rotateTransform, rotation)
        self.updateTransform(withDuration : duration)
    }
    
    
    private func updateTransform() {
        CATransaction.disableActions()
        self.setAffineTransform(CGAffineTransformConcat(self.rotateTransform, self.scaleTransform))
        CATransaction.setDisableActions(false)
    }
    
    private func updateTransform(withDuration duration : CFTimeInterval) {
        var oldPath : CATransform3D!
        if self.animationForKey(Setting.AnimationName) != nil {
            if let presentLayer = self.presentationLayer() {
                oldPath = presentLayer.transform
            }
        }
        if oldPath == nil {
            oldPath = self.transform
        }
        
        let newValue = CATransform3DMakeAffineTransform(CGAffineTransformConcat(self.rotateTransform, self.scaleTransform))
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.duration = duration
        animation.fromValue = NSValue(CATransform3D: oldPath)
        animation.toValue = NSValue(CATransform3D: newValue)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
        animation.fillMode = kCAFillModeBoth
        animation.removedOnCompletion = true
        
        CATransaction.disableActions()
        self.transform = newValue
        CATransaction.setDisableActions(false)
        self.addAnimation(animation, forKey: Setting.AnimationName)
    }
}
