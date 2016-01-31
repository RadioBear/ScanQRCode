//
//  BRBNativeScanner.swift
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


class BRBNativeScanner: NSObject, BRBScanner, AVCaptureMetadataOutputObjectsDelegate {
    
    struct Setting {
        static let ScanSessionQueueName = "ScanSessionQueue"
        static let ScanResultQueueName = "ScanResultQueue"
    }
    
    struct MetadataObject {
        static let QRCode = [AVMetadataObjectTypeQRCode]
        static let BarCode = [AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode93Code]
        
        static func types(fromCodeType codeType : BRBScannerCodeType) -> [String] {
            switch codeType {
            case .QRCode:
                return QRCode
            case .BarCode:
                return BarCode
            }
        }
    }
    
    var sessionQueue : dispatch_queue_t!
    var resultQueue : dispatch_queue_t!
    var captureDevice : AVCaptureDevice!
    var captureInput : AVCaptureDeviceInput!
    var captureOutput : AVCaptureMetadataOutput!
    var captureSession : AVCaptureSession!
    var capturePreviewLayer : BRBNativeScanPreviewLayer!
    var internalCodeType : BRBScannerCodeType = .QRCode
    
    var codeType: BRBScannerCodeType {
        get {
            return self.internalCodeType
        }
        set(newValue) {
            
            if self.internalCodeType != newValue {
                self.internalCodeType = newValue
                
                // update
                dispatch_async(self.sessionQueue) {
                    if self.captureOutput != nil {
                        self.captureOutput.metadataObjectTypes = MetadataObject.types(fromCodeType: self.internalCodeType)
                    }
                }
            }
        }
    }
    
    var previewLayer : BRBScanPreviewLayer! {
        get {
            return self.capturePreviewLayer
        }
    }
    
    var running: Bool {
        get {
            if self.captureSession != nil {
                return self.captureSession.running
            }
            return false
        }
    }
    
    func startRunning(completion : (()->())? = nil) {
        dispatch_async(self.sessionQueue) {
            if self.captureSession != nil {
                if !self.captureSession.running {
                    self.captureSession.startRunning()
                }
            }
            completion?()
        }
    }
    
    func stopRunning() {
        dispatch_async(self.sessionQueue) {
            if self.captureSession != nil {
                if self.captureSession.running {
                    self.captureSession.stopRunning()
                }
            }
        }
    }
    
    func rectForScan(fromLayer layer: CALayer!, withRect rectInLayer: CGRect) {
        if let capturePreviewLayer = self.capturePreviewLayer, layer = layer {
            let rectInPreview = capturePreviewLayer.convertRect(rectInLayer, fromLayer: layer)
            let rectInMetadataOutput = capturePreviewLayer.metadataOutputRectOfInterestForRect(rectInPreview)
            
            dispatch_async(self.sessionQueue) {
                self.captureOutput.rectOfInterest = rectInMetadataOutput
            }
        }
    }
    
    func setDeviceScale(withZoomFactor zoomFactor : CGFloat) {
        if let device = self.captureDevice {
            if device.videoZoomFactor == zoomFactor {
                return
            }
            let maxZoom = device.activeFormat.videoMaxZoomFactor;
            let targetZoom : CGFloat
            if zoomFactor <= maxZoom {
                targetZoom = zoomFactor
            } else if maxZoom > 1.0 {
                targetZoom = maxZoom
            } else {
                targetZoom = 1.0
            }
            
            if(targetZoom != device.videoZoomFactor) {
                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = targetZoom
                    device.unlockForConfiguration()
                } catch _ {
                }
            }
        }
    }
    
    func setup(completion : BRBScannerInitCompletion) {
        p_Init(completion)
    }
    
    // result will callback at sessionQueue
    private func p_Init(completion : BRBScannerInitCompletion) {
        
        // Communicate with the session and other session objects on this queue.
        if self.sessionQueue == nil {
            self.sessionQueue = dispatch_queue_create( Setting.ScanSessionQueueName, DISPATCH_QUEUE_SERIAL)
        }
        if self.resultQueue == nil {
            self.resultQueue = dispatch_queue_create(Setting.ScanResultQueueName, DISPATCH_QUEUE_SERIAL)
        }
        
        // Check video authorization status. Video access is required .
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == .NotDetermined {
            dispatch_suspend(self.sessionQueue)
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) {
                (Bool) -> () in
                dispatch_resume(self.sessionQueue)
            }
        }
        
        // Setup the capture session.
        // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
        // so that the main queue isn't blocked, which keeps the UI responsive.
        dispatch_async(self.sessionQueue) {
            // 1 device
            // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
            // as the media type parameter.
            let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo, preferringPosition: .Back)
            if captureDevice == nil {
                // return fail
                return completion(result: .Fail(.NoDevice))
            }
            do {
                try captureDevice.lockForConfiguration()
                if captureDevice.lowLightBoostSupported {
                    captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                if captureDevice.isWhiteBalanceModeSupported(.ContinuousAutoWhiteBalance) {
                    captureDevice.whiteBalanceMode = .ContinuousAutoWhiteBalance
                }
                if captureDevice.isExposureModeSupported(.ContinuousAutoExposure) {
                    captureDevice.exposureMode = .ContinuousAutoExposure
                }
                if captureDevice.isFocusModeSupported(.ContinuousAutoFocus) {
                    captureDevice.focusMode = .ContinuousAutoFocus
                }
                captureDevice.unlockForConfiguration()
            } catch {
                if let error = error as NSError?
                {
                    print( "<error>", error.code, error.domain, error.localizedDescription )
                }
            }
            
            // 2 input
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let deviceInput : AVCaptureDeviceInput!
            do {
                deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            } catch {
                if let error = error as NSError?
                {
                    print( "<error>", error.code, error.domain, error.localizedDescription )
                }
                // check if no right to use camera
                if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) != .Authorized {
                    // user denied
                    // return fail
                    return completion(result: .Fail(.UserDenied))
                } else {
                    // return fail
                    return completion(result: .Fail(.CantConfigSession))
                }
            }
            
            // 3
            // Create capture session and add input
            let captureSession = AVCaptureSession()
            
            var configSessionSucceed = true
            captureSession.beginConfiguration()
            
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            } else {
                // can not add input
                configSessionSucceed = false
            }
            
            // 4
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(captureMetadataOutput) {
                captureSession.addOutput(captureMetadataOutput)
                // Set delegate and use the default dispatch queue to execute the call back(must do after addOutput)
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: self.resultQueue)
                
                captureMetadataOutput.metadataObjectTypes = MetadataObject.types(fromCodeType: self.internalCodeType)
            } else {
                // can not add output
                configSessionSucceed = false
            }
            
            // 这个设置变动后会闪一下黑色，所以不宜改变
            if captureSession.canSetSessionPreset(AVCaptureSessionPresetHigh) {
                captureSession.sessionPreset = AVCaptureSessionPresetHigh
            }
            
            captureSession.commitConfiguration()
            
            if !configSessionSucceed {
                return completion(result: .Fail(.CantConfigSession))
            }
            
            let capturePreviewLayer = BRBNativeScanPreviewLayer(session: captureSession)
            if capturePreviewLayer != nil {
                capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                if let previewLayerConnection = capturePreviewLayer.connection {
                    if previewLayerConnection.supportsVideoOrientation {
                        previewLayerConnection.videoOrientation = .Portrait
                    }
                }
            } else {
                return completion(result: .Fail(.CantConfigSession))
            }
    
            // succeed
            self.captureSession = captureSession
            self.captureDevice = captureDevice
            self.captureInput = deviceInput
            self.captureOutput = captureMetadataOutput
            self.capturePreviewLayer = capturePreviewLayer
            return completion(result: .Succeed)
        }
    }
    
    
    // >>> Begin AVCaptureMetadataOutputObjectsDelegate <<<
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            //qrCodeFrameView?.frame = CGRectZero
            //messageLabel.text = "No QR code is detected"
            return
        }
        
        self.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            print(readableObject.stringValue);
        }
        
    }
    // >>> End AVCaptureMetadataOutputObjectsDelegate <<<
    
}


