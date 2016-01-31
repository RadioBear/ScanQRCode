//
//  ScanCodeViewController.swift
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

import UIKit
import AVFoundation

class BRBScanCodeViewController: UIViewController {
    
    struct ZoomFactor {
        static let QRCode = ZoomFactor(zoomIn : 1.5)
        static let BarCode = ZoomFactor(zoomIn : 1)
        
        let zoomIn : CGFloat
        
        var affineTransformZoomInScale : CGAffineTransform  {
            return CGAffineTransformMakeScale(self.zoomIn, self.zoomIn)
        }
        
        var transform3DZoomInScale : CATransform3D  {
            return CATransform3DMakeScale(self.zoomIn, self.zoomIn, 1.0)
        }
    }
    
    struct ScanRegionSetting {
        static let InitRegion = ScanRegionSetting(sizeRatio: 0.1, widthHeightRatio: 1 / 1, centerInParentWidthRatio: 0.5, centerInParentHeightRatio: 0.5)
        static let QRCode = ScanRegionSetting(sizeRatio: 0.7, widthHeightRatio: 1 / 1, centerInParentWidthRatio: 0.5, centerInParentHeightRatio: 0.4)
        static let BarCode = ScanRegionSetting(sizeRatio: 0.85, widthHeightRatio: 16 / 9, centerInParentWidthRatio: 0.5, centerInParentHeightRatio: 0.4)
        
        let sizeRatio : CGFloat
        let widthHeightRatio : CGFloat
        let centerInParentWidthRatio : CGFloat
        let centerInParentHeightRatio : CGFloat
    }
    
    enum ScanType {
        case QRCode
        case BarCode
        
        var scanRegionSetting : ScanRegionSetting {
            switch self {
            case .QRCode:
                return ScanRegionSetting.QRCode
            case .BarCode:
                return ScanRegionSetting.BarCode
            }
        }
    }
    
    struct Setting {
        static let MaskAlpha : CGFloat = 0.5
        static let ChangeAnimationTime : CFTimeInterval = 0.25
    }
    
    
    var scanner : BRBNativeScanner!
    var scanType : ScanType = .QRCode
    var scanRectInDecoration : CGRect = CGRect.zero
    // show when wait to init capture device
    var initWaitView : UIActivityIndicatorView!
    var decorationLayer : BRBScaneCodeDectorationLayer!
    
    // for mask
    var maskLayer : BRBCACavityMaskLayer!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        p_setupCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.scanner?.startRunning()

    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.scanner?.stopRunning()
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return .Portrait
    }
    
    @available(iOS 8.0, *)
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // self.view.layer.bounds is berfore change value
        // size is new
    
        coordinator.animateAlongsideTransition({
            (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            // but in here self.view.layer.bounds is the new value
            self.p_refreshWhenRotationOrientation(context)

        }) {
            (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            
                
        }

    }
    
    @available(iOS, introduced=2.0, deprecated=8.0)
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        // self.view.layer.bounds is after change value
        
        self.p_refreshWhenRotationOrientation(toInterfaceOrientation, duration: duration)
    }
    
    @available(iOS, introduced=2.0, deprecated=8.0)
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        // self.view.layer.bounds is berfore change value
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    
    @IBAction func changeTypeToQRCode(sender: UIButton) {
        self.p_dispatchInitScanQRCode()
    }
    
    
    @IBAction func changeTypeToBarCode(sender: UIButton) {
        self.p_dispatchInitScanBarCode()
    }
    
    private func p_backToTopView() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func foundCode(code: String) {
        print(code)
    }
    
    private func p_showInitWaitView() {
        if initWaitView == nil {
            initWaitView = UIActivityIndicatorView(activityIndicatorStyle : .WhiteLarge)
            initWaitView.center = self.view.center
            initWaitView.startAnimating() //开始动画
            self.view.addSubview(initWaitView);
        } else {
            initWaitView.hidden = false
            initWaitView.startAnimating()
        }
    }
    
    private func p_hideInitWaitView() {
        if initWaitView != nil {
            initWaitView.stopAnimating()
            initWaitView.hidden = true
            initWaitView.removeFromSuperview()
            initWaitView = nil
        }
    }

    
    private func p_showFailToBack(titleKey : String, messageKey : String) {

        let alert = BRBAlert(viewController: self, title: titleKey.brb_localized("The title displayed"), message: messageKey.brb_localized("contain"))
        alert.addButton(BRBAlertButton(title: "Common.Button.OK".brb_localized(), type: .Cancel, handler: {(_)->Void in self.p_backToTopView() }))
        alert.show()
        
    }
    
    

    private func p_setupCamera() {
        
        self.p_showInitWaitView()
      
        // Let's go
        self.scanner = BRBNativeScanner()
        self.scanner.setup { (result) -> () in
            switch result {
            case .Succeed:
                self.p_dispatchInitLayer() {
                        
                    self.p_dispatchInitScanQRCode() {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.p_hideInitWaitView()
                        }
                    }
                    
                }
                break
            case .Fail(.NoDevice):
                dispatch_async(dispatch_get_main_queue()) {
                    self.scanner = nil
                    self.p_hideInitWaitView()
                    self.p_showFailToBack("ScanCode.NotSupported.Title", messageKey: "ScanCode.NotSupported.Contain")
                }
            case .Fail(.UserDenied):
                dispatch_async(dispatch_get_main_queue()) {
                    self.scanner = nil
                    self.p_hideInitWaitView()
                    self.p_showFailToBack("ScanCode.UserDenied.Title", messageKey: "ScanCode.UserDenied.Contain")
                }
            default:
                dispatch_async(dispatch_get_main_queue()) {
                    self.scanner = nil
                    self.p_hideInitWaitView()
                    self.p_showFailToBack("ScanCode.InitFail.Title", messageKey: "ScanCode.InitFail.Contain")
                }
            }
        }
    }
    
    private func p_dispatchInitLayer(completion : ()->()) {
        dispatch_async(dispatch_get_main_queue()) {

            let parentLayer = self.view.layer
            let parentBounds = parentLayer.bounds
            do{
                let fixBounds : CGRect
                if #available(iOS 8.0, *) {
                    fixBounds = UIScreen.mainScreen().fixedCoordinateSpace.bounds
                } else {
                    fixBounds = UIScreen.mainScreen().bounds
                }
                if let previewLayer = self.scanner?.previewLayer {
                    let previewCALayer = previewLayer.calayer
                    previewCALayer.bounds = fixBounds
                    previewCALayer.anchorPoint = CGPointMake(0.5, 0.5)
                    previewCALayer.position = parentBounds.brb_center
             
                    let curOrientation = UIDevice.currentDevice().orientation
                    switch curOrientation {
                    case .Portrait:
                        break
                    case .PortraitUpsideDown:
                        previewLayer.rotate(toAngle: CGFloat(M_PI))
                    case .LandscapeLeft:
                        previewLayer.rotate(toAngle: -CGFloat(M_PI_2))
                    case .LandscapeRight:
                        previewLayer.rotate(toAngle: CGFloat(M_PI_2))
                    default:
                        break
                    }
                    
                    // because previewLayer should scale so if no clip to bound it will over the parent layer
                    parentLayer.masksToBounds = true
                    
                    // 这个操作只能在主线程做，否则在iOS7.0上会更新很慢的现象
                    parentLayer.insertSublayer(previewCALayer, atIndex: 0)
                }
            }
            do{
                let maskLayer = BRBCACavityMaskLayer()
                let parentRect = parentLayer.bounds
                maskLayer.bounds = parentRect
                maskLayer.anchorPoint = CGPointMake(0.5, 0.5)
                maskLayer.position = parentRect.brb_center
                maskLayer.backgroundColor = CGColorCreateCopyWithAlpha(UIColor.blackColor().CGColor, Setting.MaskAlpha)
                maskLayer.hidden = true
                
                
                if let initRect = self.p_calcScanRect(inLayer: maskLayer, withRegionSetting: .InitRegion) {
                    maskLayer.cavityWithRect(initRect)
                }
                
                parentLayer.addSublayer(maskLayer)
                
                self.maskLayer = maskLayer
            }
            do{
                let decorationLayer = BRBScaneCodeDectorationLayer()
                let parentRect = parentLayer.bounds
                decorationLayer.bounds = parentRect
                decorationLayer.anchorPoint = CGPointMake(0.5, 0.5)
                decorationLayer.position = parentRect.brb_center
                decorationLayer.hidden = true
                
                if let initRect = self.p_calcScanRect(inLayer: decorationLayer, withRegionSetting: .InitRegion) {
                    decorationLayer.frameWithRect(initRect)
                }
                
                parentLayer.addSublayer(decorationLayer)
                
                self.decorationLayer = decorationLayer
            }
            
            return completion()
        }
    }
    
    private func p_dispatchInitScanQRCode(completion : (()->())? = nil) {
        
        //p_showInitWaitView()
        
        dispatch_async(dispatch_get_main_queue()) {
            if let previewLayer = self.scanner?.previewLayer, maskLayer = self.maskLayer, decorationLayer = self.decorationLayer {
                
                //放大
                /*dispatch_async(self.sessionQueue) {
                self.p_setDeviceScale(withDevice: self.captureDevice, withZoomFactor: .QRCode)
                }*/
                
                // zoom in view
                previewLayer.animateScale(toFactor: ZoomFactor.QRCode.zoomIn, withDuration: Setting.ChangeAnimationTime)
                
                decorationLayer.interfaceType = .FrameOnly
                
                // scan region
                if let scanRect = self.p_calcScanRect(inLayer: decorationLayer, withRegionSetting: .QRCode) {
                    
                    maskLayer.animationCavity(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                    decorationLayer.animationFrame(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                    self.scanRectInDecoration = scanRect
                }
                
                maskLayer.hidden = false
                decorationLayer.hidden = false
                self.scanType = .QRCode
                
                self.scanner.codeType = .QRCode
                self.scanner.rectForScan(fromLayer: self.decorationLayer, withRect: self.scanRectInDecoration)
                self.scanner.startRunning(completion)
            }
        }
    }
    
    private func p_dispatchInitScanBarCode() {
        
        //p_showInitWaitView()
        
        dispatch_async(dispatch_get_main_queue()) {
            if let previewLayer = self.scanner?.previewLayer, maskLayer = self.maskLayer, decorationLayer = self.decorationLayer {
                
                //放大
                /*dispatch_async(self.sessionQueue) {
                self.p_setDeviceScale(withDevice: self.captureDevice, withZoomFactor: .BarCode)
                }*/
                
                // zoom in view
                previewLayer.animateScale(toFactor: ZoomFactor.BarCode.zoomIn, withDuration: Setting.ChangeAnimationTime)
                
                decorationLayer.interfaceType = .FrameAndLine
                
                // scan region
                if let scanRect = self.p_calcScanRect(inLayer: decorationLayer, withRegionSetting: .BarCode) {
                    
                    maskLayer.animationCavity(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                    decorationLayer.animationFrame(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                    self.scanRectInDecoration = scanRect
                }
                
                maskLayer.hidden = false
                decorationLayer.hidden = false
                self.scanType = .BarCode
                
                self.scanner.codeType = .BarCode
                self.scanner.rectForScan(fromLayer: self.decorationLayer, withRect: self.scanRectInDecoration)
                self.scanner.startRunning()
            }
        }
    }
    
    @available(iOS, introduced=2.0, deprecated=8.0)
    private func p_refreshWhenRotationOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        // videoPreviewLayer
        if let previewLayer = self.scanner?.previewLayer, parentLayer = previewLayer.calayer?.superlayer {
            let parentBounds = parentLayer.bounds
            previewLayer.calayer.position = parentBounds.brb_center
            
            switch toInterfaceOrientation {
            case .Portrait:
                previewLayer.animateRotate(toAngle: 0.0, withDuration: duration)
            case .PortraitUpsideDown:
                previewLayer.animateRotate(toAngle: CGFloat(M_PI), withDuration: duration)
            case .LandscapeLeft:
                previewLayer.animateRotate(toAngle: CGFloat(M_PI_2), withDuration: duration)
            case .LandscapeRight:
                previewLayer.animateRotate(toAngle: -CGFloat(M_PI_2), withDuration: duration)
            default:
                previewLayer.animateRotate(toAngle: 0.0, withDuration: duration)
            }
        }
        
        // maskLayer
        if let maskLayer = self.maskLayer, parentLayer = maskLayer.superlayer {
            let parentBounds = parentLayer.bounds
            maskLayer.bounds = parentBounds
            maskLayer.position = parentBounds.brb_center
        }
        
        // decorationLayer
        if let decorationLayer = self.decorationLayer, parentLayer = decorationLayer.superlayer {
            let parentBounds = parentLayer.bounds
            decorationLayer.bounds = parentBounds
            decorationLayer.position = parentBounds.brb_center
        }
        
        // scan region
        if let maskLayer = self.maskLayer, decorationLayer = self.decorationLayer {
            if let scanRect = self.p_calcScanRect(inLayer: decorationLayer, withRegionSetting: self.scanType.scanRegionSetting) {
                
                maskLayer.animationCavity(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                decorationLayer.animationFrame(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                self.scanRectInDecoration = scanRect
            }
        }
        
        self.scanner?.rectForScan(fromLayer: self.decorationLayer, withRect: self.scanRectInDecoration)
    }
    
    @available(iOS 8.0, *)
    private func p_refreshWhenRotationOrientation(context: UIViewControllerTransitionCoordinatorContext) {
        
        // videoPreviewLayer
        if let previewLayer = self.scanner?.previewLayer, parentLayer = previewLayer.calayer?.superlayer {
            let parentBounds = parentLayer.bounds
            previewLayer.calayer.position = parentBounds.brb_center
            
            previewLayer.animateRotate(withRotation: CGAffineTransformInvert(context.targetTransform()), withDuration: context.transitionDuration())
        }

        // maskLayer
        if let maskLayer = self.maskLayer, parentLayer = maskLayer.superlayer {
            let parentBounds = parentLayer.bounds
            maskLayer.bounds = parentBounds
            maskLayer.position = parentBounds.brb_center
        }
        
        // decorationLayer
        if let decorationLayer = self.decorationLayer, parentLayer = decorationLayer.superlayer {
            let parentBounds = parentLayer.bounds
            decorationLayer.bounds = parentBounds
            decorationLayer.position = parentBounds.brb_center
        }
        
        // scan region
        if let maskLayer = self.maskLayer, decorationLayer = self.decorationLayer {
            if let scanRect = self.p_calcScanRect(inLayer: decorationLayer, withRegionSetting: self.scanType.scanRegionSetting) {
                
                maskLayer.animationCavity(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                decorationLayer.animationFrame(toRect: scanRect, withDuration: Setting.ChangeAnimationTime)
                self.scanRectInDecoration = scanRect
            }
        }
        
        self.scanner?.rectForScan(fromLayer: self.decorationLayer, withRect: self.scanRectInDecoration)
    }
    
    
    private func p_calcScanRect(inLayer layer : CALayer?, withRegionSetting setting : ScanRegionSetting) -> CGRect? {
        if let layer = layer {
            let navigationBarHight = (self.navigationController?.navigationBar.bounds.size.height) ?? 0
            var layerRect = layer.bounds
            layerRect.origin.y += navigationBarHight
            layerRect.size.height -= navigationBarHight
            let scanWidth = min(layerRect.width, layerRect.height) * setting.sizeRatio
            let scanHeight = scanWidth / setting.widthHeightRatio
            let x = (layerRect.width * setting.centerInParentWidthRatio) - (scanWidth * 0.5) + layerRect.origin.x
            let y = (layerRect.height * setting.centerInParentHeightRatio) - (scanHeight * 0.5) + layerRect.origin.y
            let scanRectInLayer = CGRectMake(x, y, scanWidth, scanHeight)
            return scanRectInLayer
        }
        return nil
    }
    
    
    /*
    func CGAffineTransformFromRectToRect(fromRect : CGRect, _ toRect : CGRect) -> CGAffineTransform {
        let trans1 = CGAffineTransformMakeTranslation(-fromRect.origin.x, -fromRect.origin.y)
        let scale = CGAffineTransformMakeScale(toRect.size.width/fromRect.size.width, toRect.size.height/fromRect.size.height)
        let trans2 = CGAffineTransformMakeTranslation(toRect.origin.x, toRect.origin.y)
        return CGAffineTransformConcat(CGAffineTransformConcat(trans1, scale), trans2);
    }
    */
}
