#include <cstdio>
#include <cstdlib>
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <GL/glu.h>
#include "glTest.h"
#ifdef __WIN32__
#include <windows.h>
#endif // __WIN32__

int main(int argc, char *argv[]) {
  if(init() == false) {
    return 1;
  }
  gameTick = SDL_AddTimer(30, runGameLoop, NULL);
  gameLoop();
  return 0;
}

bool init(void) {
  if( SDL_Init(SDL_INIT_EVERYTHING) != 0 ) {
    std::fprintf(stderr, "Something went wrong! SDL Error: %s\n", SDL_GetError());
    return false;
  }
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  mainWindow = SDL_CreateWindow("Hello, World!", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_X, SCREEN_Y, SDL_WINDOW_SHOWN|SDL_WINDOW_OPENGL);
  mainGLContext = SDL_GL_CreateContext(mainWindow);
  initGL();
  return true;
}

void initGL(void) { //TODO: Return code for when
  glShadeModel(GL_SMOOTH);
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_LIGHTING);
  glEnable(GL_NORMALIZE);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  const GLdouble screenAspect = (SCREEN_X / SCREEN_Y);
  gluPerspective(60, screenAspect, 1, 1000);
  glMatrixMode(GL_MODELVIEW);
  glEnable(GL_LIGHT0);
  //load textures
  cubeTex = new multiTex(17, cubeTexArr);
  shrubTex = new multiTex(7, shrubTexArr);
}

void gameLoop(void) {
  SDL_Event event;

  while((isRunning) && (SDL_WaitEvent(&event))) {
    switch(event.type) {
      case SDL_USEREVENT:
        drawScene();
        break;

      case SDL_KEYDOWN:
        handleKeyDown(&event.key);
        break;

      case SDL_KEYUP:
        handleKeyUp(&event.key);
        break;

      case SDL_QUIT:
        isRunning = false;
        cleanup();
        break;

      default:
        break;
    }
    if(shouldMoveCamera)
      moveCamera(camUpDown);
  }
}

void handleKeyDown(SDL_KeyboardEvent *event) {
  switch(event->keysym.sym) {
    case SDLK_DOWN:
      shouldMoveCamera = true;
      camUpDown = -1;
      break;

    case SDLK_UP:
      shouldMoveCamera = true;
      camUpDown = 1;
      break;

    case SDLK_LEFT:
      shouldRotCamera = true;
      camLeftRight = 1;
      break;

    case SDLK_RIGHT:
      shouldRotCamera = true;
      camLeftRight= -1;
      break;

    case SDLK_ESCAPE:
      isRunning = false;
      cleanup();
      break;

    case SDLK_TAB:
      if(renderType == GL_TRIANGLES) {
        glDisable(GL_LIGHT0);
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_LIGHTING);
        renderType = GL_LINE_STRIP;
      }
      else {
        glEnable(GL_LIGHTING);
        glEnable(GL_LIGHT0);
        glEnable(GL_TEXTURE_2D);
        renderType = GL_TRIANGLES;
      }
      break;

    case SDLK_LSHIFT:
      if(cubeTexMode == 16) cubeTexMode = 0; else cubeTexMode++;
      break;

    default:
      break;
  }
}

void handleKeyUp(SDL_KeyboardEvent *event) {
  switch(event->keysym.sym) {
    case SDLK_DOWN:
    case SDLK_UP:
      shouldMoveCamera = false;
      break;
    case SDLK_LEFT:
    case SDLK_RIGHT:
      shouldRotCamera = false;
      break;
    default:
      break;
  }
}

Uint32 runGameLoop(Uint32 interval, void* param) {
  SDL_Event event;

  event.type = SDL_USEREVENT;
  event.user.code = 1;
  event.user.data1 = 0;
  event.user.data2 = 0;
  SDL_PushEvent(&event);
  return interval;
}

void drawScene(void) {
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  gluLookAt(0.0, camx, 8.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
  glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, Ambient);
  glMaterialfv(GL_FRONT, GL_SPECULAR, Specular);
  glMaterialf(GL_FRONT, GL_SHININESS, 128);
  glPushMatrix();
    glRotatef(camAngle, 0.0, 1.0, 0.0);
    glPushMatrix();
      glRotatef(lightAngle, 0.0, 1.0, 0.0);
      glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
      if (renderType == GL_LINE_STRIP) {
        glTranslatef(0, 0, 2);
        drawCube(0.3, renderType);
      }
    glPopMatrix();
    glColor4d(1, 1, 1, 1);
    drawCube(2, renderType);
  glPopMatrix();
  if (shouldRotCamera) camAngle += 10 * camLeftRight;
  camAngle = camAngle >= 360 ? (camAngle - 360) : camAngle;
  lightAngle += 5;
  lightAngle = lightAngle >= 360 ? (lightAngle - 360) : lightAngle;
  SDL_GL_SwapWindow(mainWindow);
}

void drawCube(GLfloat scale, GLenum mode) { //FIXME: Move to object?
  if(cubeTex->isTransparent(cubeTexMode)) {
    glEnable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.99);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  }
  cubeTex->bindTexture(cubeTexMode);
  GLfloat Verticies[8][3] = {{-0.5, -0.5, -0.5}, {0.5, -0.5, -0.5}, {0.5, -0.5, 0.5}, {-0.5, -0.5, 0.5},
                             {-0.5,  0.5, -0.5}, {0.5,  0.5, -0.5}, {0.5,  0.5, 0.5}, {-0.5,  0.5, 0.5}};
  //FIXME: UV Coordinates appear wrong when using non-TGA images.
  GLfloat uvMap[36][2] = {{0.75, 0.75}, {0.50, 0.75}, {0.50, 0.50}, {0.75, 0.75}, {0.75, 0.50}, {0.50, 0.50},
                          {0.50, 0.75}, {0.25, 0.75}, {0.25, 0.50}, {0.50, 0.75}, {0.50, 0.50}, {0.25, 0.50},
                          {0.25, 0.75}, {0.00, 0.75}, {0.00, 0.50}, {0.25, 0.75}, {0.25, 0.50}, {0.00, 0.50},
                          {1.00, 0.75}, {0.75, 0.75}, {0.75, 0.50}, {1.00, 0.75}, {1.00, 0.50}, {0.75, 0.50},
                          {0.50, 0.25}, {0.50, 0.50}, {0.25, 0.50}, {0.50, 0.25}, {0.25, 0.25}, {0.25, 0.50},
                          {0.25, 0.75}, {0.50, 0.75}, {0.50, 1.00}, {0.25, 0.75}, {0.25, 1.00}, {0.50, 1.00}};

  GLfloat Indicies[36] = {7, 4, 0,  7, 3, 0,
                          4, 5, 1,  4, 0, 1,
                          5, 6, 2,  5, 1, 2,
                          6, 7, 3,  6, 2, 3,
                          3, 0, 1,  3, 2, 1,
                          5, 4, 7,  5, 6, 7};

  glBegin(mode);
  #ifdef DEBUG
  fprintf(stdout, "glBegin\n");
  #endif
  for(int i = 0; i <= 11; i++) {
    for(int j = 0; j <= 2; j++) {
      int Index = Indicies[3 * i + j];
      if (mode != GL_TRIANGLES)
        glColor3f(1, 0, 0);
      else
        #ifdef DEBUG
        fprintf(stdout, "Index %i, Coordinates: %f, %f\n", Index, uvMap[3 * i + j][0], uvMap[3 * i + j][1]);
        #endif
        glTexCoord2f(uvMap[3 * i + j][0], 1.0 - uvMap[3 * i + j][1]); //TEST: SDL_Image loading TGA Upside down? T vector inverted for temp fix.
      glNormal3f(Verticies[Index][0] * 1.1, Verticies[Index][1] * 1.1, Verticies[Index][2] * 1.1);
      glVertex3f(Verticies[Index][0] * scale, Verticies[Index][1] * scale, Verticies[Index][2] * scale);
    }
  }
  glEnd();
  glBindTexture(GL_TEXTURE_2D, 0);
  if(cubeTex->isTransparent(cubeTexMode)) {
    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
  }
}

void moveCamera(int direction) {
  if(direction == 1)
    camx += 1;
  else if (direction == -1)
    camx -= 1;
}

void cleanup(void) {
  delete cubeTex;
  delete shrubTex;
  SDL_RemoveTimer(gameTick);
  SDL_GL_DeleteContext(mainGLContext);
  SDL_DestroyWindow(mainWindow);
  SDL_Quit();
}
