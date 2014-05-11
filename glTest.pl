#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use SDL;
use SDLx::App;
use SDL::Event;
use SDL::Events;
use OpenGL qw(:all);
use OpenGL::Image;
use OpenGL::Shader;
use constant SCREEN_X => 1680;
use constant SCREEN_Y => 1050;
my $app = SDLx::App->new(w => SCREEN_X, h => SCREEN_Y, dt => 0.5, min_t => 1/60, gl =>1, exit_on_quit => 1);
$app->fullscreen();
my $angle = 0;
my $angle2 = 0;
my @diffuse = (0,0,0);
my @ambient = (1,1,1);
my @lightPos = (0, 0, 1, 0);
my $exiting = 0;
my $texID;
my $shrubID;
my $skybox;
my $skyboxImg = 'skybox.tga';
my $frameCounter = 0;
$shrubID = 0;
$texID = 0;
my @tex;
my @shrub;
my $camx;
my $moveCam;
my $rotCam;
my $renderMode;
my $lightOverride;
my $curShader = 0;
my $curTextShader = 0;
my $fps;
my $timerTime = 90;
my ($time, $prevTime);
$time = SDL::get_ticks;
$moveCam = 0;
$rotCam = 0;
$camx = 0;
$renderMode = GL_TRIANGLES;
$lightOverride = 0;



my @images = (["img/stone.tga"      ,0],
              ["img/grass.tga"      ,0],
              ["img/snow.tga"       ,0],
              ["img/woodLog.tga"    ,0],
              ["img/woodPlank.tga"  ,0],
              ["img/crafting.tga"   ,0],
              ["img/furnace.tga"    ,0],
              ["img/furnace_lit.tga",0],
              ["img/coal.tga"       ,0],
              ["img/iron.tga"       ,0],
              ["img/redstone.tga"   ,0],
              ["img/gold.tga"       ,0],
              ["img/diamond.tga"    ,0],
              ["img/chest.tga"      ,0],
              ["img/glass.tga"      ,1],
              ["img/bookcase.tga"   ,0],
              ["img/tnt.tga"        ,0]
            );

my @shrubs = (["img/shrub/shrub.tga",      0],
              ["img/shrub/rose.tga",       0],
              ["img/shrub/dandelion.tga",  0],
              ["img/shrub/brownShroom.tga",0],
              ["img/shrub/redShroom.tga"  ,0],
              ["img/shrub/cobweb.tga"     ,0],
              ["img/shrub/reed.tga"       ,0]);

my @shaders = (["OpenGL Default (Per-Vertex Lighting)"],
               ["Per-Pixel Lighting", "shaders/perpixel.frag", "shaders/perpixel.vert", 0],
               ["Cartoon Lighting", "shaders/cartoon.frag", "shaders/cartoon.vert", 0]);

my @textShaders = (["OpenGL Default"],
                   ["Flag", "shaders/text/flag.frag", "shaders/text/flag.vert", 0],
                   ["Breeze", "shaders/text/breeze.frag", "shaders/text/breeze.vert", 0],
                   ["Ripple", "shaders/text/ripple.frag", "shaders/text/ripple.vert", 0],
                   ["HUD", "shaders/text/hud.frag", "shaders/text/hud.vert", 0]);

my $textTex =    ["img/font.tga",0];
my $text;

init();
$app->add_event_handler(\&handleEvents);
$app->add_move_handler(\&moveCamera);
$app->add_show_handler(\&display);
$app->run();

sub handleEvents {
  my ($type, $key);
  my ($event, $app) = @_;
  $type = $event->type(); #get the event type
  if ($type == SDL_QUIT) {$app->stop()} #Kill the app if we're quitting
  if ($type == SDL_KEYDOWN) {
    $key = $event->key_sym;
    if ($key == SDLK_DOWN) { #Rotate down
      $moveCam = -1;
    }
    elsif ($key == SDLK_UP) { #Rotate up
      $moveCam = 1;
    }
    if ($key == SDLK_LEFT) { #Rotate
      $rotCam = 1;
    }
    if ($key == SDLK_RIGHT) { #rotate
      $rotCam = -1
    }
    if ($key == SDLK_TAB) { #Change to wireframe and  back
      if($renderMode == GL_TRIANGLES) {
        glDisable(GL_LIGHT0);
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_LIGHTING);
        $renderMode = GL_LINE_STRIP;
        $lightOverride = 1;
      }
      else {
        glEnable(GL_LIGHT0);
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_LIGHTING);
        $renderMode = GL_TRIANGLES;
        $lightOverride = 0;
      }
    }
    if ($key == SDLK_LSHIFT) { #Increment the block texture
      if ($texID < $#images) {
        $texID++;
      }
      else {
        $texID = 0;
      }
    }
    if ($key == SDLK_LCTRL) { #Increment the shrub texture
      if ($shrubID < $#shrubs) {
        $shrubID++
      }
      else {
        $shrubID = 0;
      }
    }
    if ($key == SDLK_ESCAPE) { #Kill the app if we press escape
      $app->stop(); 
    }
    if ($key == SDLK_SPACE) {
      if ($curShader == $#shaders) {
        @{$shaders[$#shaders]}[3]->Disable();
        $curShader = 0;
      }
      else {
        @{$shaders[$curShader]}[3]->Disable() unless $curShader == 0;
        $curShader++;
        @{$shaders[$curShader]}[3]->Enable;
      }
    }
    if ($key == SDLK_LALT) {
      if ($curTextShader == $#textShaders) {
        @{$textShaders[$#textShaders]}[3]->Disable();
        $curTextShader = 0;
      }
      else {
        @{$textShaders[$curTextShader]}[3]->Disable() unless $curTextShader == 0;
        $curTextShader++;
        @{$textShaders[$curTextShader]}[3]->Enable;
      }
    }
  }
  if ($type == SDL_KEYUP) {
    $key = $event->key_sym;
    if ($key == SDLK_DOWN || $key == SDLK_UP) { #Stop rotating
      $moveCam = 0;
    }
    if ($key == SDLK_LEFT || $key == SDLK_RIGHT) { #Stop rotating
      $rotCam = 0;
    }
  }
}

sub moveCamera {
  my $count = $_[0];
  if ($moveCam == 1) {
    $camx += 2 * $count;
  }
  elsif ($moveCam == -1) {
    $camx -= 2 * $count;
  }
}

sub init {
  glutInit();                              #Enable GLUT in case we ever need it
  glShadeModel(GL_SMOOTH);                 #using SMOOTH shade model
  glEnable(GL_TEXTURE_2D);                 #Enable textures
  glEnable(GL_DEPTH_TEST);                 #Enable depth testing
  glDepthFunc(GL_LEQUAL);                  #Objects are culled if they're less or equal to the depth buffer
  glEnable(GL_LIGHTING);                   #enable lighting
  glEnable(GL_NORMALIZE);                  #I was lazy so lets let OpenGL automatically normalise everything
  glMatrixMode(GL_PROJECTION);             #Go to the PROJECTION matrix
  glLoadIdentity();                        #reset the matrix
  gluPerspective( 60, SCREEN_X/SCREEN_Y, 1, 1000); #Set our perspective veiwport
  glMatrixMode(GL_MODELVIEW);              #Go back to the model matrix
  glEnable(GL_LIGHT0);                     #Enable Light0

  ##INITIALISE TEXTURES##
  print "Loading Textures, please wait...\n";
  @tex = glGenTextures_p($#images+1); #Generate a texture
  @shrub = glGenTextures_p($#shrubs); #Generate more textures
  foreach my $i (0.. $#images) {
    loadTexture($images[$i], \$tex[$i]); #Load an image
  }
  foreach my $i (0.. $#shrubs) {
    loadTexture($shrubs[$i], \$shrub[$i]);
  }
  loadTexture($textTex, $text);
  loadSkybox($skyboxImg, \$skybox); #Load THE skybox
  foreach my $i (1 .. $#shaders) {
    loadShaders($shaders[$i], $shaders[$i]);
  }
  foreach my $i (1 .. $#textShaders) {
    loadShaders($textShaders[$i], $textShaders[$i]);
  }
}

sub display {
  my ($delta, $app) = @_;
  if ($frameCounter >= 10) {
    $frameCounter = 0;
  }
  $prevTime = $time;
  $time = SDL::get_ticks;
  $time = $time / 1000;
  $timerTime += $time - $prevTime;
  $fps = sprintf("%.3f", 1/($time - $prevTime)) if $frameCounter == 0;
  my $timer = sprintf("%.2d:%.2d:%.2d", $timerTime/(60*60), $timerTime/60, ($timerTime % (60*60)) % 60);
  $frameCounter++;
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); #Clear the screen
  glLoadIdentity(); #Reset the matrix
  gluLookAt (0.0, $camx, 8.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0); #Look at this point
  glMaterialfv_p(GL_FRONT_AND_BACK, GL_AMBIENT, 0.3,0.3,0.3,0);
  glMaterialfv_p(GL_FRONT, GL_SPECULAR, 0.5,0.5,0.5,0); #Set our materials
  glMaterialfv_p(GL_FRONT, GL_SHININESS, 128);
  glPushMatrix(); #Push the matrix state to the matrix stack
    glRotatef($angle, 0, 1, 0); #Do our transformations
    glPushMatrix();
      glRotatef($angle2, 0, 1, 0);
      glLightfv_p(GL_LIGHT0, GL_POSITION, 0,0,2,0);
      if ($renderMode == GL_LINE_STRIP) {
        glTranslatef(0,0,2);
        draw_cube(0.3, $renderMode, \@tex, $texID, $images[$texID][1]);
      }
    glPopMatrix();
    glColor4d(1,1,1,1);
    ##Draw our things##
    glPushMatrix();
      glRotatef(180, 0, 1, 0);
      draw_skybox(1000, $renderMode, $skybox);
    glPopMatrix();
    draw_cube(2, $renderMode, \@tex, $texID, $images[$texID][1]);
    glTranslatef(0,2,0);
    draw_shrub(2, $renderMode, \@shrub, $shrubID);
    #glutSolidSphere(1, 10, 10);
    glTranslatef(1.1,1,0);
    glScalef(0.2,0.2,0.2);
    glColor3d(1,1,1);
    my $renModeText;
    $renModeText = "Triangles" if $renderMode == GL_TRIANGLES;
    $renModeText = "Wireframe" if $renderMode == GL_LINE_STRIP;
    renderText("Hello, World!\n\nText Engine Loaded\nControls:\nLeft SHIFT: Change Block texture\nLeft CTRL: Change Shrub texture\nSPACE: Change Block shader\n\303\304\304\304\304\304\304\304\304\264\nCurrent Shader: $shaders[$curShader][0]\nCurrent Text Shader: $textShaders[$curTextShader][0]\nFPS: $fps\nTimer: $timer\nRender Mode: $renModeText", $text);
  glPopMatrix(); #pop the matrix state
  $angle += ($delta * 220 * $rotCam); #Rotate the camera
  $angle = $angle >= 360 ? ($angle - 360) : $angle; #do more things
  $angle2 = $angle2 >= 360 ? ($angle2 - 360) : $angle2;
  $angle2 += ($time - $prevTime) * $fps;
  $app->sync(); #Sync the app
}

sub draw_cube {
  my $mul = shift;
  my $type = shift;
  my $tex = shift;
  my $texID = shift;
  my $transparent = shift;
  $shaders[$curShader][3]->Disable() unless $type == GL_TRIANGLES || $curShader == 0;
  if ($transparent) { #Enable alpha blending
    glEnable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.99);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  }
  if ($type == GL_LINE_STRIP) { #Are we rendering wireframe?
    glColor3d(1,0,0)
  }
  glBindTexture(GL_TEXTURE_2D, $$tex[$texID]);
  ##INDECIES##
  my @indices = qw( 7 4 0  7 3 0
                    4 5 1  4 0 1
                    5 6 2  5 1 2
                    6 7 3  6 2 3
                    3 0 1  3 2 1
                    5 4 7  5 6 7);
  ##VERTECIES##                  
  my @vertices = ([-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                  [-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]);
  ##UV TEXTURE MAP##
  my @uvMap = ([0.75, 0.75], [0.50, 0.75], [0.50, 0.50], [0.75, 0.75], [0.75, 0.50], [0.50, 0.50],
               [0.50, 0.75], [0.25, 0.75], [0.25, 0.50], [0.50, 0.75], [0.50, 0.50], [0.25, 0.50],
               [0.25, 0.75], [0.00, 0.75], [0.00, 0.50], [0.25, 0.75], [0.25, 0.50], [0.00, 0.50],
               [1.00, 0.75], [0.75, 0.75], [0.75, 0.50], [1.00, 0.75], [1.00, 0.50], [0.75, 0.50],
               [0.50, 0.25], [0.50, 0.50], [0.25, 0.50], [0.50, 0.25], [0.25, 0.25], [0.25, 0.50],
               [0.25, 0.75], [0.50, 0.75], [0.50, 1.00], [0.25, 0.75], [0.25, 1.00], [0.50, 1.00]);
               
  glBegin($type); #Begin our object#
  foreach my $triangle (0 .. 11) { #Calculate for each triangle
    foreach my $vertex (0 .. 2) {
      my $index  = $indices[3 * $triangle + $vertex]; #get our index
      my $coords = $vertices[$index]; #Get our vertex
      my $uv = $uvMap[3 * $triangle + $vertex]; #Get our UV coordinate
      #my $colour = $color[$index];
      #glColor3d(@$colour);
      #print "@$uv\n";
      my @coord = ($$coords[0] * $mul, $$coords[1] * $mul, $$coords[2] * $mul);
      glTexCoord2f($$uv[0], $$uv[1]); #Set the Texture coordinate to the UV coordinate
      glNormal3f($coord[0] * $mul * 1.1, $coord[1] * $mul * 1.1, $coord[2] * $mul * 1.1); #Set our NORMAL for our lighting
      glVertex3f(@coord); #Set our vertex
    }
  }
  glEnd; #End the object
  if ($transparent) { #Disable alpha blending and alpha testing if we're using transparency
    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
  }
  $shaders[$curShader][3]->Enable() unless $type == GL_TRIANGLES || $curShader == 0;
}

sub draw_shrub {
  my $mul = shift;
  my $type = shift;
  my $tex = shift;
  my $texID = shift;
  $shaders[$curShader][3]->Disable() unless $curShader == 0;
  glEnable(GL_BLEND);
  glDisable(GL_LIGHTING) if not $lightOverride;
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.99);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glBindTexture(GL_TEXTURE_2D, $$tex[$texID]);
  if ($type == GL_LINE_STRIP) {
    glColor3d(0,1,0)
  }
  my @indices = qw( 0 4 6  0 2 6
                    3 7 5  3 1 5);

  my @vertices = ([-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                  [-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]);

  my @uvMap = ([0,0], [0,1], [1,1], [0,0],[1,0],[1,1],
               [0,0], [0,1], [1,1], [0,0],[1,0],[1,1]);
  glBegin($type);
  foreach my $triangle (0..3) {
    foreach my $vertex (0..2) {
      my $index = $indices[3* $triangle + $vertex];
      my $coords = $vertices[$index];
      my $uv = $uvMap[3 * $triangle + $vertex];

      glTexCoord2f($$uv[0], $$uv[1]);
      glNormal3f($$coords[0] * $mul * 1.1, $$coords[1] * $mul * 1.1, $$coords[2] * $mul * 1.1);
      glVertex3f($$coords[0] * $mul, $$coords[1] * $mul, $$coords[2] * $mul);
    }
  }
  glEnd();
  glDepthMask(GL_TRUE);
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glEnable(GL_LIGHTING) if not $lightOverride;
  $shaders[$curShader][3]->Enable() unless $curShader == 0;
}

sub draw_skybox {
  my $mul = shift;
  my $type = shift;
  my $tex = shift;
  $shaders[$curShader][3]->Disable() unless $curShader == 0;
  glDisable(GL_LIGHTING) if not $lightOverride; #Prevent the subroutine from resetting the lighting if we're in wireframe
  glBindTexture(GL_TEXTURE_2D, $tex);
  if ($type == GL_LINE_STRIP) {
    glColor3d(0,0,0.5)
  }
  my @indices = qw( 7 4 0  7 3 0
                    4 5 1  4 0 1
                    5 6 2  5 1 2
                    6 7 3  6 2 3
                    3 0 1  3 2 1
                    5 4 7  5 6 7);
  my @vertices = ([-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                  [-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]);

  my @uvMap = ([0.75, 0.75], [0.50, 0.75], [0.50, 0.50], [0.75, 0.75], [0.75, 0.50], [0.50, 0.50],
               [0.50, 0.75], [0.25, 0.75], [0.25, 0.50], [0.50, 0.75], [0.50, 0.50], [0.25, 0.50],
               [0.25, 0.75], [0.00, 0.75], [0.00, 0.50], [0.25, 0.75], [0.25, 0.50], [0.00, 0.50],
               [1.00, 0.75], [0.75, 0.75], [0.75, 0.50], [1.00, 0.75], [1.00, 0.50], [0.75, 0.50],
               [0.50, 0.25], [0.50, 0.50], [0.25, 0.50], [0.50, 0.25], [0.25, 0.25], [0.25, 0.50],
               [0.25, 0.75], [0.50, 0.75], [0.50, 1.00], [0.25, 0.75], [0.25, 1.00], [0.50, 1.00]);
  glBegin($type);
  foreach my $triangle (0 .. 11) {
    foreach my $vertex (0 .. 2) {
      my $index  = $indices[3 * $triangle + $vertex];
      my $coords = $vertices[$index];
      my $uv = $uvMap[3 * $triangle + $vertex];
      #my $colour = $color[$index];
      #glColor3d(@$colour);
      #print "@$uv\n";
      glTexCoord2f($$uv[0], $$uv[1]);
      glVertex3f($$coords[0] * $mul, $$coords[1] * $mul, $$coords[2] * $mul);
    }
  }
  glEnd;
  glEnable(GL_LIGHTING) if not $lightOverride;
  $shaders[$curShader][3]->Enable() unless $curShader == 0;
}

sub loadTexture {
  my $image = shift;
  my $tex = shift;
  print "Loading texture: $$image[0]\n";
  my $img = new OpenGL::Image(source=>$$image[0]) or die "could not load image: $$image[0]";
  my ($Tex_Type,$Tex_Format,$Tex_Size) = $img->Get('gl_internalformat','gl_format','gl_type');
  my ($Tex_Width,$Tex_Height) = $img->Get('width','height');
  my $pixels = $img->GetArray();
  glBindTexture(GL_TEXTURE_2D, $$tex);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexImage2D_c(GL_TEXTURE_2D, 0, $Tex_Type, $Tex_Width, $Tex_Height, 0, $Tex_Format, $Tex_Size, $pixels->ptr());
  print "Successfully loaded texture: $$image[0]\n";
}

sub loadSkybox {
  my $sboxImg = shift;
  my $texture = shift;
  print "Loading Skybox: $sboxImg\n";
  $$texture = glGenTextures_p(1);
  my $img = new OpenGL::Image(source=>$sboxImg) or die "Could not load skybox image";
  my ($Tex_Type,$Tex_Format,$Tex_Size) = $img->Get('gl_internalformat','gl_format','gl_type');
  my ($Tex_Width,$Tex_Height) = $img->Get('width','height');
  my $pixels = $img->GetArray();
  glBindTexture(GL_TEXTURE_2D, $$texture);
  glTexImage2D_c(GL_TEXTURE_2D, 0, $Tex_Type, $Tex_Width, $Tex_Height, 0, $Tex_Format, $Tex_Size, $pixels->ptr());
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
  print "Successfully loaded Skybox: $sboxImg\n";
}

sub toUV {
  my $coord = shift;
  my $res = shift;
  my @return = ($$coord[0] / $$res[0], -(($$coord[1]-$$res[1]) / $$res[1]));
  return \@return;
}

sub renderText {
  my $string = shift;
  my $texture = shift;
  $shaders[$curShader][3]->Disable() unless $curShader == 0;
  $textShaders[$curTextShader][3]->Enable() unless $curTextShader == 0;
  my $varID;
  if ($curTextShader == 4) {
    $varID = $textShaders[$curTextShader][3]->Map("Resolution");
    glUniform2fARB($varID, SCREEN_X, SCREEN_Y);
  }
  else {
   $varID = $textShaders[$curTextShader][3]->Map("time") if $curTextShader != 0;
    glUniform1fARB($varID, $timerTime) if $curTextShader != 0;
  }
  glDisable(GL_LIGHTING) if not $lightOverride;
  glEnable(GL_TEXTURE_2D) if $lightOverride;
  my @strArray = split("", $string); #create the array of characters
  my @pos = (0,0);
  foreach my $i (0 .. $#strArray) {

    glBindTexture(GL_TEXTURE_2D, $texture);
    my $char = ord($strArray[$i]);
    my @coords = (0,0);
    if ($strArray[$i] eq "\n") {
      @pos = (0,$pos[1]+1);
      next;
    }
    if($char >= 256) {
      carp "wide character in print\n";
      $char = 255
    }
    while($char > 15) {
      $char -= 16;
      $coords[1]++;
    }
    $coords[0] = $char; #@coords now holds the text's position in the file (colom, row)
    @coords = ($coords[0] * 8, $coords[1] * 16); #and now it contains the actual pixel-position
    
    @coords = (toUV(\@coords, [128,256]),
               toUV([$coords[0] + 8, $coords[1]], [128,256]),
               toUV([$coords[0], $coords[1] + 16], [128,256]),
               toUV([$coords[0] + 8, $coords[1] + 16], [128,256]));

    glBegin(GL_TRIANGLES);
      glTexCoord2f(@{$coords[2]});
      glVertex3f(0 + (0.5*$pos[0]),0 - (1*$pos[1]),0);
      glTexCoord2f(@{$coords[3]});
      glVertex3f(0.5 + (0.5*$pos[0]),0 - (1*$pos[1]),0);
      for (0 .. 1) {
        glTexCoord2f(@{$coords[0]});
        glVertex3f(0 + (0.5*$pos[0]),1 - (1*$pos[1]),0);
      }
      glTexCoord2f(@{$coords[1]});
      glVertex3f(0.5 + (0.5*$pos[0]),1 - (1*$pos[1]),0);
      glTexCoord2f(@{$coords[3]});
      glVertex3f(0.5 + (0.5*$pos[0]),0 - (1*$pos[1]),0);
    glEnd();
    $pos[0] += 1;
  }
  glEnable(GL_LIGHTING) if not $lightOverride;
  glDisable(GL_TEXTURE_2D) if $lightOverride;
  $textShaders[$curTextShader][3]->Disable() unless $curTextShader == 0;
  $shaders[$curShader][3]->Enable() unless $curShader == 0;
}

sub loadShaders {
  my $shadeData = shift;
  my $shader = shift;
  print "Loading shader: $$shadeData[0]\n";
  $$shader[3] = new OpenGL::Shader('GLSL') or die "There was a problem initalising GLSL shaders!";
  my $info = $$shader[3]->LoadFiles($$shadeData[1], $$shadeData[2]);
  print $info . "\n" if $info;
  print "Sucessfully loaded shader\n";
}
