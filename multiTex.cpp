#include "multiTex.h"
#include <iostream>

multiTex::multiTex(int num, const char* texFile[]) {
  texArray = new GLuint [num];
  imgArray = new SDL_Surface* [num];
  glGenTextures(num, texArray);
  numTextures = num;
  loadTextures(texFile);
}

multiTex::~multiTex(void) {
  glDeleteTextures(numTextures, texArray);
  for(int i = 0; i < numTextures; i++) {
    if(imgArray[i] != NULL) {
      SDL_FreeSurface(imgArray[i]);
    }
  }
  delete[] texArray;
  delete[] imgArray;
}

int multiTex::loadTextures(const char* texFile[]) {
  for(int i = 0; i < numTextures; i++) {
    imgArray[i] = IMG_Load(texFile[i]);
    GLenum format;
    switch(imgArray[i]->format->BitsPerPixel) {
      case 24:
        format = GL_BGR;
        break;
      case 32:
        format = GL_BGRA;
        break;
      default:
        format = GL_BGR;
        break;
    }

    if(imgArray[i] == NULL) {
      std::cout << "Error in loading image file! " << IMG_GetError() << std::endl;
      exit(1);
    }
    glBindTexture(GL_TEXTURE_2D, texArray[i]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, imgArray[i]->format->BytesPerPixel, imgArray[i]->w, imgArray[i]->h, 0, format, GL_UNSIGNED_BYTE, imgArray[i]->pixels);
  }
  return 0;
}

void multiTex::bindTexture(int texId) {
  glBindTexture(GL_TEXTURE_2D, texArray[texId]);
}
