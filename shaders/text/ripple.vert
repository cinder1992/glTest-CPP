uniform float time;
void main() {
    vec4 v = vec4(gl_Vertex);
    v.z = sin(1.0*(v.x+v.y) + time * 2.0)/4.0;
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    gl_Position = gl_ModelViewProjectionMatrix * v;
}