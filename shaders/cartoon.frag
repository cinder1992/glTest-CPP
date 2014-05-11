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
  float intensity2 = max((color.r + color.g + color.b)/2.5, 0.0);
  if (intensity2 > 0.95)
    color = vec4(1.0,1.0,1.0,1.0);
  else if (intensity2 > 0.8)
    color = vec4(0.7,0.7,0.7,1.0);
  else if (intensity2 > 0.5)
    color = vec4(0.5,0.5,0.5,1.0);
  else if (intensity2 > 0.25)
    color = vec4(0.25,0.25,0.25,1.0);
  else
    color = vec4(0.1,0.1,0.1,1.0);
    
  texel = texture2D(tex,gl_TexCoord[0].st);
    
  cf = color.rgb;
  af = color.a;
  ct = texel.rgb;
  at = texel.a;
  gl_FragColor = vec4(ct * cf, at * af);

}
