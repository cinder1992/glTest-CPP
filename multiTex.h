#ifndef _MULTITEX_H
#define _MULIITEX_H

#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <SDL2/SDL_image.h>

class multiTex {
  private:
    SDL_Surface** imgArray;
    GLuint* texArray;
    int numTextures;
    bool* transparency;
    GLenum textureFormat(SDL_PixelFormat*, const char*);
  public:
    multiTex(int, const char*[]);
    ~multiTex();
    int loadTextures(const char*[]);
    void bindTexture(int);
    bool isTransparent(int);
};
#endif
