//
//  Beauty.swift
//  GPUImage
//
//  Created by finn on 2021/9/28.
//  Copyright © 2021 Red Queen Coder, LLC. All rights reserved.
//

import Foundation

public class Beauty: BasicOperation {
    public var beautyLevel: Float = 0.5 {
        didSet {
            uniformSettings["isBeauty"] = beautyLevel
            uniformSettings["paramColor"] = Color(red: 1.0 - 0.6 * beautyLevel,
                                                  green: 1.0 - 0.3 * beautyLevel,
                                                  blue: 0.1 + 0.3 * beautyLevel,
                                                  alpha: 0.1 + 0.3 * beautyLevel)
        }
    }

//    public var beautyLevel: Float = 0.0 {
//        didSet {
//            uniformSettings["isBeauty"] = beautyLevel
//        }
//    }
    public var paramColor: Color = Color(red: 0.33, green: 0.63, blue: 0.4, alpha: 0.35) {
        didSet {
            uniformSettings["paramColor"] = paramColor
        }
    }

    public var singleStepOffset: Position = Position.center { didSet { uniformSettings["singleStepOffset"] = singleStepOffset } }

    public init() {
        super.init(fragmentFunctionName: "beautyFragment", numberOfInputs: 1)

        ({ beautyLevel = 0.0 })()
        ({ paramColor = Color(red: 0.33, green: 0.63, blue: 0.4, alpha: 0.35) })()
        ({ singleStepOffset = Position.center })()
    }
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex)
        
        singleStepOffset = Position(2.0 / Float(texture.texture.width), 2.0 / Float(texture.texture.height))
    }
}
