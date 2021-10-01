#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

constant half3 weighting = half3(0.299, 0.587, 0.114);
constant half3x3 saturateMatrix = half3x3(
{1.1102, -0.0598, -0.061},
{-0.0774, 1.0826, -0.1186},
{-0.0228, -0.0228, 1.1772});
//

typedef struct {
    float isBeauty;
    float2 singleStepOffset;
    float4 paramColor;
} BeautyUniform;

float hardLight(float color) {
    if (color <= 0.5)
        color = color * color * 2.0;
    else
        color = 1.0 - ((1.0 - color)*(1.0 - color) * 2.0);
    return color;
}

fragment half4 beautyFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant BeautyUniform& uniform [[buffer(1)]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    if (uniform.isBeauty == 0.0) return color;
    float2 blurCoordinates[24];
    float2 textureCoordinate = fragmentInput.textureCoordinate.xy;
    float2 singleStepOffset = uniform.singleStepOffset;
    blurCoordinates[0] = textureCoordinate.xy + singleStepOffset * float2(0.0, -10.0);
    blurCoordinates[1] = textureCoordinate.xy + singleStepOffset * float2(0.0, 10.0);
    blurCoordinates[2] = textureCoordinate.xy + singleStepOffset * float2(-10.0, 0.0);
    blurCoordinates[3] = textureCoordinate.xy + singleStepOffset * float2(10.0, 0.0);
    blurCoordinates[4] = textureCoordinate.xy + singleStepOffset * float2(5.0, -8.0);
    blurCoordinates[5] = textureCoordinate.xy + singleStepOffset * float2(5.0, 8.0);
    blurCoordinates[6] = textureCoordinate.xy + singleStepOffset * float2(-5.0, 8.0);
    blurCoordinates[7] = textureCoordinate.xy + singleStepOffset * float2(-5.0, -8.0);
    blurCoordinates[8] = textureCoordinate.xy + singleStepOffset * float2(8.0, -5.0);
    blurCoordinates[9] = textureCoordinate.xy + singleStepOffset * float2(8.0, 5.0);
    blurCoordinates[10] = textureCoordinate.xy + singleStepOffset * float2(-8.0, 5.0);
    blurCoordinates[11] = textureCoordinate.xy + singleStepOffset * float2(-8.0, -5.0);
    blurCoordinates[12] = textureCoordinate.xy + singleStepOffset * float2(0.0, -6.0);
    blurCoordinates[13] = textureCoordinate.xy + singleStepOffset * float2(0.0, 6.0);
    blurCoordinates[14] = textureCoordinate.xy + singleStepOffset * float2(6.0, 0.0);
    blurCoordinates[15] = textureCoordinate.xy + singleStepOffset * float2(-6.0, 0.0);
    blurCoordinates[16] = textureCoordinate.xy + singleStepOffset * float2(-4.0, -4.0);
    blurCoordinates[17] = textureCoordinate.xy + singleStepOffset * float2(-4.0, 4.0);
    blurCoordinates[18] = textureCoordinate.xy + singleStepOffset * float2(4.0, -4.0);
    blurCoordinates[19] = textureCoordinate.xy + singleStepOffset * float2(4.0, 4.0);
    blurCoordinates[20] = textureCoordinate.xy + singleStepOffset * float2(-2.0, -2.0);
    blurCoordinates[21] = textureCoordinate.xy + singleStepOffset * float2(-2.0, 2.0);
    blurCoordinates[22] = textureCoordinate.xy + singleStepOffset * float2(2.0, -2.0);
    blurCoordinates[23] = textureCoordinate.xy + singleStepOffset * float2(2.0, 2.0);
    
    float sampleColor = color.g * 22.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[0]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[1]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[2]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[3]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[4]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[5]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[6]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[7]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[8]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[9]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[10]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[11]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[12]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[13]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[14]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[15]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[16]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[17]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[18]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[19]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[20]).g * 3.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[21]).g * 3.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[22]).g * 3.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[23]).g * 3.0;
    
    sampleColor = sampleColor / 62.0;
    float highPass = color.g - sampleColor + 0.5;

    for (int i = 0; i < 5; i++) {
        highPass = hardLight(highPass);
    }
    half4 paramColor = half4(uniform.paramColor);
    
    half luminance = dot(color.rgb, weighting);
    half alpha = pow(luminance, paramColor.r);
    
    half3 smoothColor = color.rgb + (color.rgb - half3(highPass)) * alpha * 0.1;
    smoothColor.r = clamp(pow(smoothColor.r, paramColor.g), 0.0h, 1.0h);
    smoothColor.g = clamp(pow(smoothColor.g, paramColor.g), 0.0h, 1.0h);
    smoothColor.b = clamp(pow(smoothColor.b, paramColor.g), 0.0h, 1.0h);
    
    half3 screen = half3(1.0) - (half3(1.0) - smoothColor) * (half3(1.0) - color.rgb);
    half3 lighten = max(smoothColor, color.rgb);
    half3 softlight =
    2.0 * color.rgb * smoothColor +
    color.rgb * color.rgb -
    2.0 * color.rgb * color.rgb * smoothColor;
    
    half4 finalColor = half4(mix(color.rgb, screen, alpha), 1.0);
    finalColor.rgb = mix(finalColor.rgb, lighten, alpha);
    finalColor.rgb = mix(finalColor.rgb, softlight, paramColor.b);

    half3 satcolor = finalColor.rgb * saturateMatrix;
    finalColor.rgb = mix(finalColor.rgb, satcolor, paramColor.a);

    return finalColor;
}
