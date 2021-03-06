//
//  ChartPointViewBarGreyOut.swift
//  Examples
//
//  Created by ischuetz on 15/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public class ChartPointViewBarGreyOut: ChartPointViewBar {

    private let greyOut: Bool
    private let greyOutDelay: Float
    private let greyOutAnimDuration: Float
    
    init(chartPoint: ChartPoint, p1: CGPoint, p2: CGPoint, width: CGFloat, color: UIColor, animDuration: Float = 0.5, greyOut: Bool = false, greyOutDelay: Float = 1, greyOutAnimDuration: Float = 0.5) {
        
        self.greyOut = greyOut
        self.greyOutDelay = greyOutDelay
        self.greyOutAnimDuration = greyOutAnimDuration
        
        super.init(p1: p1, p2: p2, width: width, bgColor: color, animDuration: animDuration)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func didMoveToSuperview() {
        
        super.didMoveToSuperview()
        
        if self.greyOut {
            UIView.animateWithDuration(CFTimeInterval(self.greyOutAnimDuration), delay: CFTimeInterval(self.greyOutDelay), options: UIViewAnimationOptions.CurveEaseOut, animations: {() -> Void in
                self.backgroundColor = UIColor.grayColor()
            }, completion: nil)
        }
    }
}
