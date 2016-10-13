//
//  NavigationViewController.swift
//  TGUIKit
//
//  Created by keepcoder on 15/09/16.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import SwiftSignalKitMac
public enum ViewControllerStyle {
    case push;
    case pop;
    case none;
}

public class NavigationViewController: ViewController, CALayerDelegate,CAAnimationDelegate {

    var stack:[ViewController] = [ViewController]()
    
    var empty:ViewController
    
    public private(set) var controller:ViewController
    
    private var navigationBar:NavigationBarView = NavigationBarView()
    
    var pushDisposable:MetaDisposable = MetaDisposable()
    var popDisposable:MetaDisposable = MetaDisposable()
    
    public override func loadView() {
        super.loadView();
        self.view.autoresizesSubviews = true
        self.stack.append(controller)
        
        controller.navigationController = self
        
        self.view.addSubview(navigationBar)
        
        self.view.addSubview(controller.view)
        
    }
    
    public init(_ empty:ViewController) {
        self.empty = empty
        self.controller = empty
        super.init()
    }
    
    public var stackCount:Int {
        return stack.count
    }
    
    deinit {
        self.popDisposable.dispose()
        self.pushDisposable.dispose()
    }
    
    public func push(_ controller:ViewController, _ animated:Bool = true) -> Void {
        
        controller.navigationController = self
        controller.loadViewIfNeeded(self.bounds)
        
        self.pushDisposable.set((controller.ready.get() |> take(1)).start(next: {[weak self] _ in
            if let strongSelf = self {
                controller.navigationController = strongSelf
                
                if let index = strongSelf.stack.index(of: controller) {
                    strongSelf.stack.remove(at: index)
                }
                
                strongSelf.stack.append(controller)
                
                strongSelf.show(controller, animated && strongSelf.stack.count > 1 ? .push : .none)
            }
        }))
    }
    
    
    func show(_ controller:ViewController,_ style:ViewControllerStyle) -> Void {
        
        var previous:ViewController = self.controller;
        self.controller = controller

        
        if(previous == controller) {
            previous.viewWillDisappear(false);
            previous.viewDidDisappear(false);
            
            controller.viewWillAppear(false);
            controller.viewDidAppear(false);
            controller.becomeFirstResponder();
            
            return;
        }
        
        self.navigationBar.frame = NSMakeRect(0, 0, NSWidth(self.frame), controller.bar.height)
        
        controller.view.removeFromSuperview()
        controller.view.frame = NSMakeRect(0, controller.bar.height - 1, NSWidth(self.frame), NSHeight(self.frame) - controller.bar.height + 1)
        
        if style == .pop {
            stack.remove(at: stack.index(of: previous)!)
        }
        
        var pfrom:CGFloat = 0, pto:CGFloat = 0, nto:CGFloat = 0, nfrom:CGFloat = 0;
        
        switch style {
        case .push:
            nfrom = NSWidth(self.frame) 
            nto = 0
            pfrom = 0
            pto = -100//round(NSWidth(self.frame)/3.0)
            self.view.addSubview(controller.view, positioned: .above, relativeTo: previous.view)
        case .pop:
            nfrom = -round(NSWidth(self.frame)/3.0)
            nto = 0
            pfrom = 0
            pto = NSWidth(self.frame)
            previous.view.setFrameOrigin(NSMakePoint(pto, previous.frame.minY))
            self.view.addSubview(controller.view, positioned: .below, relativeTo: previous.view)
        case .none:
            previous.view.removeFromSuperview()
            self.view.addSubview(controller.view)
            previous.viewWillDisappear(false);
            controller.viewWillAppear(false);
            previous.viewDidDisappear(false);
            controller.viewDidAppear(false);
            controller.becomeFirstResponder();
            
            self.navigationBar.switchViews(left: controller.leftBarView, center: controller.centerBarView, right: controller.rightBarView, style: style, animationStyle: controller.animationStyle)

            
            return // without animations
        }
        
        
        previous.viewWillDisappear(true);
        controller.viewWillAppear(true);
        
        
        
        
        CATransaction.begin()

        
        self.navigationBar.switchViews(left: controller.leftBarView, center: controller.centerBarView, right: controller.rightBarView, style: style, animationStyle: controller.animationStyle)
        
        
         
        previous.view.layer?.animate(from: pfrom as NSNumber, to: pto as NSNumber, keyPath: "position.x", timingFunction: kCAMediaTimingFunctionSpring, duration: previous.animationStyle.duration, removeOnCompletion: true, additive: false, completion: { (completed) in
            
            previous.viewDidDisappear(true);
            previous.view.removeFromSuperview()
            
        });
        

        controller.view.layer?.animate(from: nfrom as NSNumber, to: nto as NSNumber, keyPath: "position.x", timingFunction: kCAMediaTimingFunctionSpring, duration: controller.animationStyle.duration, removeOnCompletion: true, additive: false, completion: { (completed) in
            
            controller.viewDidAppear(true);
            controller.becomeFirstResponder()
        });
        
        
        CATransaction.commit()
        
    }
    
    
    public func back(_ index:Int = -1) -> Void {
        if stackCount > 1 {
            show(stack[stackCount - 2], .pop)
        }
    }
    
    
}