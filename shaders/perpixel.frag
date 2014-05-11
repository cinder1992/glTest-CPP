varying vec4 diffuse,ambient;
varying vec3 lightDir,normal,halfVector;
uniform sampler2D tex;

void main(void) {
    vec4 color;
    vec3 ct,cf;
    vec4 texel;
    vec3 n,halfV;
    float NdotL,NdotHV;
    float intensity,at,af;
    n = normalize(normal);
    intensity = max(dot(lightDir,normalize(normal)),0.0);
    NdotL = max(dot(n,lightDir),0.0);
    color = ambient;
    if (NdotL > 0.0) {
      color += diffuse * NdotL;
      halfV = normalize(halfVector);
      NdotHV = max(dot(n,halfV),0.0);
      color += gl_FrontMaterial.specular *
               gl_LightSource[0].specular *
               pow(NdotHV, gl_FrontMaterial.shininess);
    }
    af = color.a + ambient.a;
    cf = (color.rgb * intensity) + ambient.rgb;
    texel = texture2D(tex,gl_TexCoord[0].st);

    ct = texel.rgb;
    at = texel.a;
    gl_FragColor = vec4(ct * cf, at * af);

}
