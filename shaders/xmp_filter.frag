#version 460 core

#include <flutter/runtime_effect.glsl>

// Packed uniform vectors (Impeller allows max 31 bindings, so group related floats)
uniform vec4 u_basicAdjust1;     // x: exposure, y: contrast, z: highlights, w: shadows
uniform vec4 u_basicAdjust2;     // x: unused,  y: unused,   z: vibrance,   w: saturation
uniform vec4 u_whiteBalance;     // x: temperature, y: tint, z/w reserved
uniform vec4 u_saturationAdjust1; // x: red, y: orange, z: yellow, w: green
uniform vec4 u_saturationAdjust2; // x: aqua, y: blue, z: purple, w: magenta
uniform vec4 u_luminanceAdjust1;  // x: red, y: orange, z: yellow, w: green
uniform vec4 u_luminanceAdjust2;  // x: aqua, y: blue, z: purple, w: magenta
uniform vec4 u_splitToning;       // x: shadow hue, y: shadow saturation, z: highlight hue, w: highlight saturation

#define U_EXPOSURE            u_basicAdjust1.x
#define U_CONTRAST            u_basicAdjust1.y
#define U_HIGHLIGHTS          u_basicAdjust1.z
#define U_SHADOWS             u_basicAdjust1.w
#define U_VIBRANCE            u_basicAdjust2.z
#define U_SATURATION          u_basicAdjust2.w
#define U_TEMPERATURE         u_whiteBalance.x
#define U_TINT                u_whiteBalance.y

#define U_SAT_RED             u_saturationAdjust1.x
#define U_SAT_ORANGE          u_saturationAdjust1.y
#define U_SAT_YELLOW          u_saturationAdjust1.z
#define U_SAT_GREEN           u_saturationAdjust1.w
#define U_SAT_AQUA            u_saturationAdjust2.x
#define U_SAT_BLUE            u_saturationAdjust2.y
#define U_SAT_PURPLE          u_saturationAdjust2.z
#define U_SAT_MAGENTA         u_saturationAdjust2.w

#define U_LUM_RED             u_luminanceAdjust1.x
#define U_LUM_ORANGE          u_luminanceAdjust1.y
#define U_LUM_YELLOW          u_luminanceAdjust1.z
#define U_LUM_GREEN           u_luminanceAdjust1.w
#define U_LUM_AQUA            u_luminanceAdjust2.x
#define U_LUM_BLUE            u_luminanceAdjust2.y
#define U_LUM_PURPLE          u_luminanceAdjust2.z
#define U_LUM_MAGENTA         u_luminanceAdjust2.w

#define U_SPLIT_SHADOW_HUE    u_splitToning.x
#define U_SPLIT_SHADOW_SAT    u_splitToning.y
#define U_SPLIT_HIGHLIGHT_HUE u_splitToning.z
#define U_SPLIT_HIGHLIGHT_SAT u_splitToning.w

// ToneCurve 데이터 (텍스처로 전달)
uniform sampler2D u_toneCurveTexture;

// 입력
uniform vec2 u_resolution;
uniform sampler2D u_texture;

out vec4 fragColor;

// sRGB ↔ Linear 변환
vec3 srgbToLinear(vec3 srgb) {
    return pow(srgb, vec3(2.2));
}

vec3 linearToSrgb(vec3 linear) {
    return pow(linear, vec3(1.0 / 2.2));
}

// RGB → HSV 변환
vec3 rgbToHsv(vec3 rgb) {
    float maxVal = max(rgb.r, max(rgb.g, rgb.b));
    float minVal = min(rgb.r, min(rgb.g, rgb.b));
    float delta = maxVal - minVal;

    vec3 hsv;

    // Hue 계산
    if (delta == 0.0) {
        hsv.x = 0.0;
    } else if (maxVal == rgb.r) {
        hsv.x = mod((rgb.g - rgb.b) / delta, 6.0);
    } else if (maxVal == rgb.g) {
        hsv.x = (rgb.b - rgb.r) / delta + 2.0;
    } else {
        hsv.x = (rgb.r - rgb.g) / delta + 4.0;
    }
    hsv.x /= 6.0;

    // Saturation 계산
    hsv.y = (maxVal == 0.0) ? 0.0 : delta / maxVal;

    // Value 계산
    hsv.z = maxVal;

    return hsv;
}

// HSV → RGB 변환
vec3 hsvToRgb(vec3 hsv) {
    float c = hsv.z * hsv.y;
    float x = c * (1.0 - abs(mod(hsv.x * 6.0, 2.0) - 1.0));
    float m = hsv.z - c;

    vec3 rgb;
    if (hsv.x < 1.0/6.0) {
        rgb = vec3(c, x, 0.0);
    } else if (hsv.x < 2.0/6.0) {
        rgb = vec3(x, c, 0.0);
    } else if (hsv.x < 3.0/6.0) {
        rgb = vec3(0.0, c, x);
    } else if (hsv.x < 4.0/6.0) {
        rgb = vec3(0.0, x, c);
    } else if (hsv.x < 5.0/6.0) {
        rgb = vec3(x, 0.0, c);
    } else {
        rgb = vec3(c, 0.0, x);
    }

    return rgb + m;
}

// ToneCurve 적용 (텍스처에서 룩업)
vec3 applyToneCurve(vec3 color) {
    // Main curve (y=0.25), Red curve (y=0.5), Green curve (y=0.75), Blue curve (y=1.0)
    float mainValue = texture(u_toneCurveTexture, vec2(dot(color, vec3(0.299, 0.587, 0.114)), 0.25)).r;
    vec3 curvedColor = vec3(
        texture(u_toneCurveTexture, vec2(color.r, 0.5)).r,
        texture(u_toneCurveTexture, vec2(color.g, 0.75)).g,
        texture(u_toneCurveTexture, vec2(color.b, 1.0)).b
    );

    // Main curve와 개별 커브를 혼합
    return mix(color, curvedColor, 0.7) * (0.3 + mainValue * 0.7);
}

// 화이트 밸런스 적용
vec3 applyWhiteBalance(vec3 color) {
    // Temperature: 5500K 기준으로 조정
    float tempFactor = (U_TEMPERATURE - 5500.0) / 1000.0;
    float tintFactor = U_TINT / 100.0;

    // 간단한 화이트 밸런스 매트릭스
    mat3 wbMatrix = mat3(
        1.0 + tempFactor * 0.1, 0.0, -tempFactor * 0.05,
        -tintFactor * 0.02, 1.0 + tintFactor * 0.05, 0.0,
        -tempFactor * 0.05, 0.0, 1.0 - tempFactor * 0.1
    );

    return wbMatrix * color;
}

// Exposure 적용
vec3 applyExposure(vec3 color) {
    return color * pow(2.0, U_EXPOSURE);
}

// Contrast 적용
vec3 applyContrast(vec3 color) {
    float contrastFactor = 1.0 + (U_CONTRAST / 100.0);
    return (color - 0.5) * contrastFactor + 0.5;
}

// Highlights/Shadows 적용
vec3 applyHighlightsShadows(vec3 color) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));

    // 하이라이트 마스크 (밝은 영역)
    float highlightMask = smoothstep(0.5, 1.0, luma);
    // 섀도우 마스크 (어두운 영역)
    float shadowMask = smoothstep(0.5, 0.0, luma);

    vec3 highlightAdjust = color * (1.0 + U_HIGHLIGHTS / 100.0 * highlightMask);
    vec3 shadowAdjust = highlightAdjust * (1.0 + U_SHADOWS / 100.0 * shadowMask);

    return shadowAdjust;
}

// HSL 개별 색상 조정
vec3 applyHSLAdjustments(vec3 color) {
    vec3 hsv = rgbToHsv(color);
    float hue = hsv.x * 360.0; // 0-360도로 변환

    // 색상 영역별 조정
    float satAdjust = 1.0;
    float lumAdjust = 0.0;

    if (hue >= 345.0 || hue < 15.0) { // Red
        satAdjust += U_SAT_RED / 100.0;
        lumAdjust += U_LUM_RED / 100.0;
    } else if (hue < 45.0) { // Orange
        satAdjust += U_SAT_ORANGE / 100.0;
        lumAdjust += U_LUM_ORANGE / 100.0;
    } else if (hue < 75.0) { // Yellow
        satAdjust += U_SAT_YELLOW / 100.0;
        lumAdjust += U_LUM_YELLOW / 100.0;
    } else if (hue < 135.0) { // Green
        satAdjust += U_SAT_GREEN / 100.0;
        lumAdjust += U_LUM_GREEN / 100.0;
    } else if (hue < 195.0) { // Aqua
        satAdjust += U_SAT_AQUA / 100.0;
        lumAdjust += U_LUM_AQUA / 100.0;
    } else if (hue < 255.0) { // Blue
        satAdjust += U_SAT_BLUE / 100.0;
        lumAdjust += U_LUM_BLUE / 100.0;
    } else if (hue < 285.0) { // Purple
        satAdjust += U_SAT_PURPLE / 100.0;
        lumAdjust += U_LUM_PURPLE / 100.0;
    } else { // Magenta
        satAdjust += U_SAT_MAGENTA / 100.0;
        lumAdjust += U_LUM_MAGENTA / 100.0;
    }

    hsv.y *= satAdjust;
    hsv.z += lumAdjust * 0.1;

    return hsvToRgb(hsv);
}

// Split Toning 적용
vec3 applySplitToning(vec3 color) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));

    // 섀도우와 하이라이트 마스크
    float shadowMask = smoothstep(0.3, 0.0, luma);
    float highlightMask = smoothstep(0.7, 1.0, luma);

    // 섀도우 톤
    if (U_SPLIT_SHADOW_SAT > 0.0) {
        float shadowHue = U_SPLIT_SHADOW_HUE / 360.0;
        vec3 shadowTone = hsvToRgb(vec3(shadowHue, U_SPLIT_SHADOW_SAT / 100.0, 1.0));
        color = mix(color, color * shadowTone, shadowMask * 0.3);
    }

    // 하이라이트 톤
    if (U_SPLIT_HIGHLIGHT_SAT > 0.0) {
        float highlightHue = U_SPLIT_HIGHLIGHT_HUE / 360.0;
        vec3 highlightTone = hsvToRgb(vec3(highlightHue, U_SPLIT_HIGHLIGHT_SAT / 100.0, 1.0));
        color = mix(color, color * highlightTone, highlightMask * 0.3);
    }

    return color;
}

// 전역 채도/비브란스 적용
vec3 applySaturationVibrance(vec3 color) {
    vec3 hsv = rgbToHsv(color);

    // 채도 조정
    hsv.y *= (1.0 + U_SATURATION / 100.0);

    // 비브란스 조정 (낮은 채도 영역에 더 강하게 적용)
    float vibranceMask = 1.0 - hsv.y;
    hsv.y += U_VIBRANCE / 100.0 * vibranceMask;

    return hsvToRgb(hsv);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / u_resolution;
    vec3 color = texture(u_texture, uv).rgb;

    // sRGB를 Linear로 변환
    color = srgbToLinear(color);

    // XMP 처리 순서 (Adobe Camera Raw와 동일)
    // 1. Exposure
    color = applyExposure(color);

    // 2. White Balance
    color = applyWhiteBalance(color);

    // 3. ToneCurve (가장 중요)
    color = applyToneCurve(color);

    // 4. Contrast
    color = applyContrast(color);

    // 5. Highlights/Shadows
    color = applyHighlightsShadows(color);

    // 6. HSL 개별 색상 조정
    color = applyHSLAdjustments(color);

    // 7. Split Toning
    color = applySplitToning(color);

    // 8. 전역 채도/비브란스
    color = applySaturationVibrance(color);

    // Linear를 sRGB로 변환
    color = linearToSrgb(color);

    // 결과 출력
    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
