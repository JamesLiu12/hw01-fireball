#version 300 es
precision highp float;

uniform float u_Time;
uniform vec3 u_SkyBottomColor;
uniform vec3 u_SkyTopColor;
uniform float u_StarDensity;

in vec2 fs_UV;

out vec4 out_Col;

float hash(vec2 p)
{
    vec3 q = fract(vec3(p.x, p.y, p.x) * 0.1031);
    q += dot(q, q.zyx + 31.32);
    return fract((q.x + q.y) * q.z);
}

void main()
{
    vec3 color = mix(u_SkyBottomColor, u_SkyTopColor, fs_UV.y);

    vec2 skyPos = gl_FragCoord.xy - vec2(10.0, 10.0) * u_Time;
    vec2 grid = floor(skyPos / 40.0);
    vec2 local = fract(skyPos / 40.0);
    vec2 starPos = vec2(hash(grid), hash(grid + vec2(17.0, 31.0)));
    float distanceToStar = length(local - starPos) * 40.0;
    float radius = mix(1.0, 2.0, hash(grid + vec2(13.0, 23.0)));
    float star = 1.0 - smoothstep(0.0, radius, distanceToStar);
    star *= step(1.0 - u_StarDensity, hash(grid + vec2(11.0, 17.0))) * mix(0.5, 1.0, hash(grid + vec2(29.0, 13.0)));

    color += vec3(star);
    out_Col = vec4(color, 1.0);
}
