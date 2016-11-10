//
//  CGSize+Additions.swift
//  PrimaryFlightDisplay
//
//  Created by Michael Koukoullis on 27/02/2016.
//  Copyright © 2016 Michael Koukoullis. All rights reserved.
//

import SpriteKit

extension CGSize {
    
    var pointsPerDegree: CGFloat {
        return (height / 2) / CGFloat(90)
    }
    
    var pointsPerRadian: CGFloat {
        return CGFloat.degreesPerRadian * pointsPerDegree
    }
}
