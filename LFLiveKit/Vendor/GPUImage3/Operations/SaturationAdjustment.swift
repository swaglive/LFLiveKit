public class SaturationAdjustment: BasicOperation {
    public var saturation:Float = 0.5 { didSet { uniformSettings["saturation"] = saturation } }
    
    public init() {
        super.init(fragmentFunctionName:"saturationFragment", numberOfInputs:1)
        
        ({saturation = 0.5})()
    }
}
