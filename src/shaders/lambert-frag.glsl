#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform float u_Time;
uniform vec3 u_CoolColor;
uniform vec3 u_MiddleColor;
uniform vec3 u_HotColor;
uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_Height;
in vec3 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float hash(vec3 p)
{
	p  = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

float noise3D(vec3 p)
{
    vec3 grid = floor(p);
    vec3 pos = fract(p);

    vec3 fade = pos * pos * pos * (pos * (pos * 6.0 - 15.0) + 10.0);

    float v000 = hash(grid + vec3(0.0, 0.0, 0.0));
    float v100 = hash(grid + vec3(1.0, 0.0, 0.0));
    float v010 = hash(grid + vec3(0.0, 1.0, 0.0));
    float v110 = hash(grid + vec3(1.0, 1.0, 0.0));
    float v001 = hash(grid + vec3(0.0, 0.0, 1.0));
    float v101 = hash(grid + vec3(1.0, 0.0, 1.0));
    float v011 = hash(grid + vec3(0.0, 1.0, 1.0));
    float v111 = hash(grid + vec3(1.0, 1.0, 1.0));

    float x00 = mix(v000, v100, fade.x);
    float x10 = mix(v010, v110, fade.x);
    float x01 = mix(v001, v101, fade.x);
    float x11 = mix(v011, v111, fade.x);

    float y0 = mix(x00, x10, fade.y);
    float y1 = mix(x01, x11, fade.y);

    return mix(y0, y1, fade.z);
}

void main()
{
    vec3 tailDirection = normalize(vec3(1.0, 1.0, 0.0));
    float along = dot(fs_Pos, tailDirection);
    float tail = smoothstep(0.0, 1.0, along);

    vec3 p = 5.0 * fs_Pos - 2.0 * tailDirection * u_Time;
    float patches = 0.75 * noise3D(p) + 0.25 * noise3D(3.0 * p);

    float erosion = noise3D(p);
    if (tail > 0.4 && erosion < mix(0.1, 0.7, tail)) {
        discard;
    }

    float heat = 0.56 - 0.43 * along + 0.65 * (patches - 0.5) - 0.35 * fs_Height;
    vec3 color = 
        heat < 0.4 ? u_CoolColor : 
        heat < 0.6 ? u_MiddleColor : 
        heat < 0.8 ? mix(u_MiddleColor, u_HotColor, 0.5) : u_HotColor;
    float hotSpot = smoothstep(0.7, 0.8, patches) * (1.0 - tail);
    color = mix(color, vec3(1.0, 1.0, 0.82), hotSpot);

    out_Col = vec4(color, u_Color.a);
}
