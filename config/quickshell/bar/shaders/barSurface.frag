#version 440

// Bar background surface: the full-width strip and the pills are rendered as a
// single signed-distance field, smooth-unioned together so the points where a
// pill meets the strip become soft concave fillets instead of hard corners.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;     // surface size in px
    vec4 stripRect;      // x, y, w, h  (square-cornered band)
    vec4 pill0;          // x, y, w, h  (w <= 0 disables)
    vec4 pill1;
    vec4 pill2;
    vec4 pill3;
    vec4 fillColor;      // straight rgba
    float pillRadius;
    float smoothing;     // fillet size, px
    float softness;      // edge feather, px
};

float sdRoundRect(vec2 p, vec2 c, vec2 hs, float r) {
    r = min(r, min(hs.x, hs.y));
    vec2 d = abs(p - c) - hs + vec2(r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

float smin(float a, float b, float k) {
    if (k <= 0.0) return min(a, b);
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float rectSdf(vec4 r, vec2 p, float rad) {
    vec2 hs = r.zw * 0.5;
    return sdRoundRect(p, r.xy + hs, hs, rad);
}

float scene(vec2 p) {
    vec2 sHs = stripRect.zw * 0.5;
    float d = sdRoundRect(p, stripRect.xy + sHs, sHs, 0.0);
    if (pill0.z > 0.0) d = smin(d, rectSdf(pill0, p, pillRadius), smoothing);
    if (pill1.z > 0.0) d = smin(d, rectSdf(pill1, p, pillRadius), smoothing);
    if (pill2.z > 0.0) d = smin(d, rectSdf(pill2, p, pillRadius), smoothing);
    if (pill3.z > 0.0) d = smin(d, rectSdf(pill3, p, pillRadius), smoothing);
    return d;
}

void main() {
    vec2 p = qt_TexCoord0 * resolution;

    float d = scene(p);
    float edge = max(fwidth(d), 1e-4) + softness;
    float cov = 1.0 - smoothstep(-edge, edge, d);

    vec3 fillPM = fillColor.rgb * (fillColor.a * cov);
    float fillA = fillColor.a * cov;

    fragColor = vec4(fillPM, fillA) * qt_Opacity;
}
