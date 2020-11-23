//
//  SecondViewController.swift
//  kinemic-gesture-sdk-example-ios-storyboard
//
//  Created by Fabian on 10.06.20.
//  Copyright © 2020 kinemic. All rights reserved.
//

import UIKit
import KinemicGesture

class AirmouseViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var engine: SingleBandModel!
    var colorDraw = UIColor.red.cgColor
    var colorHover = UIColor.green.cgColor
    
    let maxAngle = 20.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        engine = SingleBandModel(from: AppDelegate.engine)
        AppDelegate.engine.register(airmouseListener: self)
        engine.startAirmouse()
    }

    func drawPointer(x: Float, y: Float, draw: Bool) {
        let width = Double(view.frame.width)
        let height = Double(view.frame.height)
        let size = max(width, height) / 4.0
        
        let fixedY = asin(Double(y)/90.0) / .pi * 180.0
        
        let x1 = sin((Double(x) / maxAngle)) * size + 0.5*width
        let y1 = sin((Double(fixedY) / -maxAngle)) * size + 0.5*height
        
        let x2 = (Double(x) / maxAngle) * size + 0.5*width
        let y2 = (Double(fixedY) / -maxAngle) * size + 0.5*height
        
        let x3 = (Double(x) / maxAngle) * size + 0.5*width
        let y3 = (Double(y) / -maxAngle) * size + 0.5*height
        
        UIGraphicsBeginImageContext(view.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        imageView.image?.draw(in: view.bounds)
        let color = draw ? colorDraw : colorHover
        
        context.clear(view.bounds)
        context.beginPath()
        context.addArc(center: CGPoint(x: x1, y: y1), radius: 10, startAngle: 0, endAngle: CGFloat(.pi*2.0), clockwise: true)
        context.closePath()
        context.setFillColor(color)
        context.fillPath()
        
        context.beginPath()
        context.addArc(center: CGPoint(x: x2, y: y2), radius: 10, startAngle: 0, endAngle: CGFloat(.pi*2.0), clockwise: true)
        context.closePath()
        context.setFillColor(color.copy(alpha: 0.5)!)
        context.fillPath()
        
        context.beginPath()
        context.addArc(center: CGPoint(x: x3, y: y3), radius: 10, startAngle: 0, endAngle: CGFloat(.pi*2.0), clockwise: true)
        context.closePath()
        context.setFillColor(color.copy(alpha: 0.25)!)
        context.fillPath()
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}

extension AirmouseViewController: AirmouseListener {
    func engine(_ engine: Engine, didDetectAirmouseMoveFrom band: String, x: Float, y: Float, wristAngle: Float, facing: AirmousePalmDirection) {
        drawPointer(x: x, y: y, draw: facing == .facingDownwards)
    }
}
