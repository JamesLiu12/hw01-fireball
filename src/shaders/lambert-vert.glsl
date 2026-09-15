#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec3 fs_Pos;
out float fs_Height;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 hash(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}

vec3 gradient(vec3 p) {
    vec3 result = hash(p) * 2.0 - 1.0;
    float len = max(length(result), 0.00001);
    return result / len;
}

float noise3D(vec3 p) {
    vec3 grid = floor(p);
    vec3 pos = fract(p);

    vec3 fade = pos * pos * pos * (pos * (pos * 6.0 - 15.0) + 10.0);

    vec3 p000 = vec3(0.0, 0.0, 0.0);
    vec3 p100 = vec3(1.0, 0.0, 0.0);
    vec3 p010 = vec3(0.0, 1.0, 0.0);
    vec3 p110 = vec3(1.0, 1.0, 0.0);
    vec3 p001 = vec3(0.0, 0.0, 1.0);
    vec3 p101 = vec3(1.0, 0.0, 1.0);
    vec3 p011 = vec3(0.0, 1.0, 1.0);
    vec3 p111 = vec3(1.0, 1.0, 1.0);

    float v000 = dot(gradient(grid + p000), pos - p000);
    float v100 = dot(gradient(grid + p100), pos - p100);
    float v010 = dot(gradient(grid + p010), pos - p010);
    float v110 = dot(gradient(grid + p110), pos - p110);
    float v001 = dot(gradient(grid + p001), pos - p001);
    float v101 = dot(gradient(grid + p101), pos - p101);
    float v011 = dot(gradient(grid + p011), pos - p011);
    float v111 = dot(gradient(grid + p111), pos - p111);

    float x00 = mix(v000, v100, fade.x);
    float x10 = mix(v010, v110, fade.x);
    float x01 = mix(v001, v101, fade.x);
    float x11 = mix(v011, v111, fade.x);

    float y0 = mix(x00, x10, fade.y);
    float y1 = mix(x01, x11, fade.y);

    return mix(y0, y1, fade.z);
}

float fbm(vec3 p)
{
    float persistence = 0.5;
    float result = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;

    for (int i = 0; i < 6; i++)
    {
        result += amplitude * noise3D(p * frequency);
        amplitude *= persistence;
        frequency *= 2.0;
    }
    return result;
}

float largeShape(vec3 p)
{
    return (
          sin(6.0 * p.x + 1.2 * u_Time)
        + cos(7.0 * p.y - 1.6 * u_Time)
        + sin(8.0 * p.z + 1.4 * u_Time)
    ) * 0.05;
}

float fineShape(vec3 p)
{
    vec3 q = 5.0 * p - vec3(1.5, 1.5, 0.0) * u_Time;
    return 0.15 * fbm(q);
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.    
    
    vec3 tailDirection = normalize(vec3(1.0, 1.0, 0.0));
    
    float along = dot(normalize(vs_Pos.xyz), tailDirection);
    float waveStrength = mix(0.3, 1.5, smoothstep(-1.0, 1.0, along));
    float height = (largeShape(vs_Pos.xyz) + fineShape(vs_Pos.xyz)) * waveStrength;
    
    fs_Pos = vs_Pos.xyz;
    fs_Height = height;

    vec3 normal = normalize(vs_Nor.xyz);
    vec3 displacedPos = vs_Pos.xyz + height * normal;
    
    float tail = smoothstep(0.0, 1.0, along);
    float flicker = 0.1 * sin(2.0 * u_Time + 10.0 * vs_Pos.z);
    displacedPos += tailDirection * tail * tail * (1.0 + flicker);
    displacedPos -= tailDirection * 0.5;

    vec4 modelposition = u_Model * vec4(displacedPos, 1.0);   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
