//
//  PresentationView.swift
//  RodionovEgorTestovoeArkit
//
//  Created by Егор Родионов on 25.10.22.
//

import Foundation

import UIKit
import Vision

class PresentationView: UIView {
    private var coordinates : [VNVector]
    init(coordinates: [VNVector]) {
        self.coordinates = coordinates
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    override func draw(_ rect: CGRect) {
        if coordinates.count > 0{
            guard let context = UIGraphicsGetCurrentContext() else { return }
            
          
            
            context.setFillColor(UIColor.systemRed.cgColor)
            context.setStrokeColor(UIColor.systemGreen.cgColor)
            context.setLineWidth(2)
            
            context.move(to: CGPoint(x: coordinates[0].x, y: coordinates[0].y))
            for i in 1...(coordinates.count - 1){
                
                
                context.addLine(to: CGPoint(x: coordinates[i].x, y: coordinates[i].y))
                context.move(to: CGPoint(x: coordinates[i].x, y: coordinates[i].y))
                
            }
            
            
           
            context.drawPath(using: .fillStroke)
        }
    
       
        
     
        
    }
    
}

