#include "multiTex.h"
#include <iostream>
#include <cstdlib>
#include <cstring>

//FIXME: Replace this code with the SDL2 texture function using SDL Surfaces
multiTex::multiTex(int num, const char* texFile[]) {
  texArray = new GLuint [num];
  imgArray = new SDL_Surface* [num];
  transparency = new bool [num];
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
  delete[] transparency;
}

int multiTex::loadTextures(const char* texFile[]) {
  for(int i = 0; i < numTextures; i++) {
    imgArray[i] = IMG_Load(texFile[i]);
    if(imgArray[i] == NULL) {
      std::cerr << "Error in loading image file! " << IMG_GetError() << std::endl;
      exit(EXIT_FAILURE);
    }
    GLenum format = textureFormat(imgArray[i]->format, texFile[i]);
    if (format == GL_RGBA || format == GL_BGRA) transparency[i] = true; else transparency[i] = false;
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

GLenum multiTex::textureFormat(SDL_PixelFormat* format, const char* texFile) {
  char* formatText;
  Uint32 mask = format->Rmask;
  GLenum pixFormat;
  #if SDL_BYTEORDER == SDL_LIL_ENDIAN
    if(format->BitsPerPixel == 32) {
      switch(mask) { //Get the image format
        case 16711680:
          formatText = "BGRA";
          break;
        case 255:
          formatText = "RGBA";
          break;
        default:
          std::cerr << "ERROR!: Image " << texFile << " Has an unknown or incompatable pixel format!" << std::endl;
          exit(EXIT_FAILURE);
      }
    }
    else if(format->BitsPerPixel == 24) {
      switch(mask) { //Get the image format!
        case 16711680:
          formatText = "BGR";
          break;
        case 255:
          formatText = "RGB";
          break;
        default:
          std::cerr << "ERROR!: Image " << texFile << " Has an unknown or incompatable pixel format!" << std::endl;
          exit(EXIT_FAILURE);
      }
    }
    else {
      std::cerr << "ERROR: Image " << texFile << " is not a 24 or 32 bit image!" << std::endl;
      exit(EXIT_FAILURE);
    }
  #elif SDL_BYTEORDER == SDL_BIG_ENDIAN //support ARM devices in case we port to mobile ;)
    if(format->BitsPerPixel == 32) {
      switch(mask) { //Get the image format
        case 16711680:
          formatText = "RGBA";
          break;
        case 255:
          formatText = "BGRA";
          break;
        default:
          std::cerr << "ERROR!: Image " << texFile[ << " Has an unknown or incompatable pixel format!" << std::endl;
          exit(EXIT_FAILURE);
      }
    }
    else if(format->BitsPerPixel == 24) {
      switch(mask) { //Get the image format!
        case 16711680:
          formatText = "RGB";
          break;
        case 255:
          formatText = "BGR";
          break;
        default:
          std::cerr << "ERROR!: Image " << texFile << " Has an unknown or incompatable pixel format!" << std::endl;
          exit(EXIT_FAILURE);
      }
    }
    else {
      std::cerr << "ERROR: Image " << texFile << " is not a 24 or 32 bit image!" << std::endl;
      exit(EXIT_FAILURE);
    }
  #endif // SDL_BYTEORDER
    if(strcmp(formatText,"RGB") == 0) pixFormat = GL_RGB;
    else if(strcmp(formatText, "RGBA") == 0) pixFormat = GL_RGBA;
    else if(strcmp(formatText, "BGR") == 0) pixFormat = GL_BGR;
    else if(strcmp(formatText, "BGRA") == 0) pixFormat = GL_BGRA;
    else{
      std::cerr << "ERROR: Completely unknown pixel format for image " << texFile << std::endl;
      exit(EXIT_FAILURE);
    }
  return pixFormat;
}

bool multiTex::isTransparent(int imgID) {
  return transparency[imgID];
}
