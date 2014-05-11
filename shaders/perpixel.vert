varying vec4 diffuse,ambient;
varying vec3 lightDir,normal,halfVector;

void main(void) {
    gl_Position = ftransform();
    lightDir = normalize(vec3(gl_LightSource[0].position));
    gl_TexCoord[0] = gl_MultiTexCoord0;
    halfVector = gl_LightSource[0].halfVector.xyz;
    normal = normalize(gl_NormalMatrix * gl_Normal);
    diffuse = gl_FrontMaterial.diffuse * gl_LightSource[0].diffuse;
    ambient = gl_FrontMaterial.ambient * gl_LightSource[0].ambient;
    ambient += gl_LightModel.ambient * gl_FrontMaterial.ambient;
}
