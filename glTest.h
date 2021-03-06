#ifndef _GLTEST_H
#define _GL_TEST_H
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include "multiTex.h"
//I know global vars are horrible and bad, but this code is C style, so I'll use them
SDL_Window* mainWindow;
SDL_GLContext mainGLContext;
SDL_TimerID gameTick;
bool isRunning = true;
const GLdouble SCREEN_X = 1440.0, SCREEN_Y = 900.0;
GLfloat camx = 0;
bool shouldMoveCamera = false;
bool shouldRotCamera = false;
int camUpDown;
int camLeftRight;
GLfloat camAngle = 0;
GLfloat lightAngle = 0;
bool lightOverride = false;
int cubeTexMode = 0;
int shrubTexMode = 0;
GLenum renderType = GL_TRIANGLES;

GLfloat Ambient[] = {3.0, 3.0, 3.0, 0.0};
GLfloat Specular[] = {5.0, 5.0, 5.0, 0.0};
GLfloat lightPos[] = {0.0, 0.0, 2.0, 0.0};


const char * cubeTexArr[] = {"img/stone.tga", "img/grass.tga", "img/snow.tga", "img/woodLog.tga",
                          "img/woodPlank.tga", "img/crafting.tga", "img/furnace.tga", "img/furnace_lit.tga",
                          "img/coal.tga", "img/iron.tga", "img/redstone.tga", "img/gold.tga",
                          "img/diamond.tga", "img/chest.tga", "img/glass.tga", "img/bookcase.tga", "img/tnt.tga"};

const char * shrubTexArr[] = {"img/shrub/shrub.tga", "img/shrub/rose.tga", "img/shrub/dandelion.tga", "img/shrub/brownShroom.tga",
                              "img/shrub/redShroom.tga", "img/shrub/cobweb.tga", "img/shrub/reed.tga"};
multiTex* cubeTex;
multiTex* shrubTex;
//function defs
bool init(void);
void initGL(void);
void gameLoop(void);
void handleKeyDown(SDL_KeyboardEvent*);
void handleKeyUp(SDL_KeyboardEvent*);
Uint32 runGameLoop(Uint32, void*);
void drawScene(void);
void drawCube(GLfloat, GLenum);
void moveCamera(int);
void cleanup(void);
#endif
