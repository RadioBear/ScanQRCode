//
//  BRBAlert.swift
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

private var UIAlertViewWrapperPropertyKey : UInt8 = 0


enum BRBAlertButtonStyle : Int {
    case Default
    case Cancel
    case Destructive
    
    @available(iOS 8.0, *)
    var alertActionStyle : UIAlertActionStyle {
        switch self {
        case .Default:
            return .Default
        case .Cancel:
            return .Cancel
        case .Destructive:
            return .Destructive
        }
    }
}

struct BRBAlertButton {
    var title : String?
    var type : BRBAlertButtonStyle = .Default
    var handler : ((BRBAlertButton) -> Void)?
}

class BRBAlert {

    // Private class that handles delegation and completion handler (do not instantiate)
    final class UIAlertViewWrapper : NSObject, UIAlertViewDelegate
    {
        // MARK: - all button with Handlers
        var buttons : [BRBAlertButton]!

        // MARK: - Initializers
        init(buttons: [BRBAlertButton]!)
        {
            self.buttons = buttons
        }
        
        // MARK: - UIAlertView Delegate
        func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
            
            if buttonIndex >= 0 && buttonIndex < self.buttons.count {
                let button = self.buttons[buttonIndex]
                button.handler?(button)
            }
        }
    }

    
    var viewController : UIViewController?
    var title: String?
    var message: String?
    var buttons = [BRBAlertButton]()
    
    init(viewController : UIViewController?, title: String?, message: String?) {
        self.viewController = viewController
        self.title = title
        self.message = message
    }
    
    func addButton(button: BRBAlertButton) {
        buttons.append(button)
    }
    
    func show() {
        if #available(iOS 8.0, *) {
            let ac = UIAlertController(title: self.title, message: self.message, preferredStyle: .Alert)
            for button in self.buttons {
                ac.addAction(UIAlertAction(title: button.title, style: button.type.alertActionStyle, handler: (button.handler == nil) ? nil : { (UIAlertAction) -> Void in
                        button.handler?(button)
                    }))
            }
            viewController?.presentViewController(ac, animated: true, completion: nil)
        } else {
            let wrapper = UIAlertViewWrapper(buttons: self.buttons)
            let at = UIAlertView(title: self.title, message: self.message, delegate: wrapper, cancelButtonTitle: nil)
            
            for button in self.buttons {
                at.addButtonWithTitle(button.title)
            }
            
            // 如果不保持self的话就会被回收，不能调用回调了
            objc_setAssociatedObject(at, &UIAlertViewWrapperPropertyKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            at.show()
        }
    }
    
    class func showWith(viewController : UIViewController?, title : String, withMessage message : String, withButton button : String) {
        if #available(iOS 8.0, *) {
            let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: button, style: .Default, handler: nil))
            viewController?.presentViewController(ac, animated: true, completion: nil)

        } else {
            // Fallback on earlier versions
            let at = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: button)
            at.show()
        }
    }
}