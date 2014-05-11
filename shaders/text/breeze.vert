uniform float time;
void main() {
    vec4 v = vec4(gl_Vertex);
    float vx = (v.x/4.0) + (time / 2.0);
    v.z = ((pow(sin(vx),3.0)+cos(vx) / 2.0) + pow(cos(vx),7.0)) * v.x/4.0;
    v.z -= (v.z/2.0);
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    gl_Position = gl_ModelViewProjectionMatrix * v;
}
