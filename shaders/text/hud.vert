uniform vec2 Resolution;

void main() {
    vec4 v = vec4((gl_Vertex.x * 32.0) / Resolution.x, ((gl_Vertex.y - 1.0) * 32.0) / Resolution.y, 0, 1);
    v -= vec4(1,-1,0,0);
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    gl_Position = v;
}