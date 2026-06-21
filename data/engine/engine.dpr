library engine;
{
engine for the physics programs complex\nauthor: M.M. Makarov\ncreated: 20.II.2005\nupdated: 20.XI.2006
}

uses
  Windows, SysUtils, Classes, OpenGL;

type
  tex512 = array[0..511, 0..511, 0..2] of Byte;
  tex256 = array[0..255, 0..255, 0..2] of Byte;

const
  GL_CLAMP_TO_EDGE = $812F;

{$R *.res}

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

procedure SetDCPixelFormat(DC:HDC);
{pixel format setup}
var
  pfd: TPixelFormatDescriptor;
  nPixelFormat: Integer;
begin
  FillChar(pfd, Sizeof(pfd), 0);
  pfd.dwFlags := PFD_SUPPORT_OPENGL or
                 PFD_DOUBLEBUFFER or
                 PFD_DRAW_TO_WINDOW;
  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);
end;

procedure CalcNormal(x1, y1, z1, x2, y2, z2, x3, y3, z3: Extended;
  var nx, ny, nz: Extended);
var
  wrki: Double;
  vx1, vy1, vz1, vx2, vy2, vz2: Double;
begin
  vx1 := x1 - x2;
  vy1 := y1 - y2;
  vz1 := z1 - z2;
  vx2 := x2 - x3;
  vy2 := y2 - y3;
  vz2 := z2 - z3;

  wrki := sqrt(sqr(vy1 * vz2 - vz1 * vy2) +
               sqr(vz1 * vx2 - vx1 * vz2) +
               sqr(vx1 * vy2 - vy1 * vx2));

  nx := (vy1 * vz2 - vz1 * vy2) / wrki;
  ny := (vz1 * vx2 - vx1 * vz2) / wrki;
  nz := (vx1 * vy2 - vy1 * vx2) / wrki;
end;

function About: ShortString;
{about}
begin
  Result := 'Designed by Makarov M.M. @ 20.II.2005';
end;

procedure LoadTexture(PackFile: ShortString;
                      NumberInPack: Integer;
                      NumberInMemory: Integer);
{texture loading procedure}
var
  arr: tex256;
  f: file of tex256;
  i: Integer;
begin
  AssignFile(f, PackFile);
  Reset(f);
  for i := 1 to NumberInPack do
  begin
    Read(f, arr);
    if i = NumberInPack then
    begin
      glEnable(GL_TEXTURE_2D);
      glBindTexture(GL_TEXTURE_2D, NumberInMemory);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 256,
        0, GL_RGB, GL_UNSIGNED_BYTE, @arr);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
    end;
  end;
end;

procedure LoadTexture512(PackFile: ShortString;
                         NumberInPack: Integer;
                         NumberInMemory: Integer);
{texture loading procedure}
var
  arr: tex512;
  f: file of tex512;
  i: Integer;
begin
  AssignFile(f, PackFile);
  Reset(f);
  for i := 1 to NumberInPack do
  begin
    Read(f, arr);
    if i = NumberInPack then
    begin
      glEnable(GL_TEXTURE_2D);
      glBindTexture(GL_TEXTURE_2D, NumberInMemory);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 512, 512,
        0, GL_RGB, GL_UNSIGNED_BYTE, @arr);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
    end;
  end;
end;

procedure LoadTextureSphere(PackFile: ShortString;
                            NumberInPack: Integer;
                            NumberInMemory: Integer);
{texture loading procedure}
var
  arr: tex256;
  f: file of tex256;
  i: Integer;
begin
  AssignFile(f,PackFile);
  Reset(f);
  for i := 1 to NumberInPack do
  begin
    Read(f, arr);
    if i = NumberInPack then
    begin
      glEnable(GL_TEXTURE_2D);
      glBindTexture(GL_TEXTURE_2D, NumberInMemory);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 256,
        0, GL_RGB, GL_UNSIGNED_BYTE, @arr);
      glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
      glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
    end;
  end;
end;

procedure DrawOneSideTexturedBox(x, y, z, dx, dy, dz: Extended);
{box for the menu in the main program}
begin
  glDisable(GL_TEXTURE_2D);

  glBegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glVertex3f(x, y, z);
  glVertex3f(x, y + dy, z);
  glVertex3f(x, y + dy,z + dz);
  glVertex3f(x, y, z + dz);

  glNormal3f(1, 0, 0);
  glVertex3f(x + dx, y, z);
  glVertex3f(x + dx, y + dy, z);
  glVertex3f(x + dx, y + dy, z + dz);
  glVertex3f(x + dx, y, z + dz);

  glNormal3f(0, -1, 0);
  glVertex3f(x, y, z);
  glVertex3f(x + dx, y, z);
  glVertex3f(x + dx, y, z + dz);
  glVertex3f(x, y, z + dz);

  glNormal3f(0, 1, 0);
  glVertex3f(x, y + dy, z);
  glVertex3f(x + dx, y + dy, z);
  glVertex3f(x + dx, y + dy, z + dz);
  glVertex3f(x, y + dy, z + dz);

  glNormal3f(0, 0, -1);
  glVertex3f(x, y, z);
  glVertex3f(x + dx, y, z);
  glVertex3f(x + dx, y + dy,z);
  glVertex3f(x, y + dy, z);
  glEnd;

  glEnable(GL_TEXTURE_2D);
  glBegin(GL_QUADS);
  glNormal3f(0, 0, 1);
  glTexCoord2d(1, 1);
  glVertex3f(x, y, z + dz);
  glTexCoord2d(0, 1);
  glVertex3f(x + dx, y, z + dz);
  glTexCoord2d(0, 0);
  glVertex3f(x + dx,y + dy, z + dz);
  glTexCoord2d(1, 0);
  glVertex3f(x, y + dy, z + dz);

  glEnd;
end;

procedure DrawSkyBox(x, y, z, dx, dy, dz: Extended;
                     tex1, tex2, tex3, tex4, tex5, tex6: Integer);
{skybox}
const
  d = 1;
begin
  x := x + d;
  y := y + d;
  z := z + d;
  dx := dx - d * 2;
  dy := dy - d * 2;
  dz := dz - d * 2;

  //up
  glBindTexture(GL_TEXTURE_2D, tex1);
  glBegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glTexCoord2d(1, 0);
  glVertex3f(x + dx,y + dy,z + dz);
  glTexCoord2d(0, 0);
  glVertex3f(x + dx,y + dy, z);
  glTexCoord2d(0, 1);
  glVertex3f(x, y + dy, z);
  glTexCoord2d(1, 1);
  glVertex3f(x, y + dy, z + dz);
  glEnd;

  //down
  glBindTexture(GL_TEXTURE_2D, tex2);
  glBegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glTexCoord2d(1, 1);
  glVertex3f(x + dx, y, z + dz);
  glTexCoord2d(0, 1);
  glVertex3f(x + dx, y, z);
  glTexCoord2d(0, 0);
  glVertex3f(x, y, z);
  glTexCoord2d(1, 0);
  glVertex3f(x, y, z + dz);
  glEnd;

  //left
  glBindTexture(GL_TEXTURE_2D,tex3);
  glBegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glTexCoord2d(0, 1);
  glVertex3f(x + dx, y, z + dz);
  glTexCoord2d(0, 0);
  glVertex3f(x + dx,y + dy, z + dz);
  glTexCoord2d(1, 0);
  glVertex3f(x + dx, y + dy, z);
  glTexCoord2d(1, 1);
  glVertex3f(x + dx, y, z);
  glEnd;

  //right
  glBindTexture(GL_TEXTURE_2D, tex4);
  glBegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glTexCoord2d(1, 1);
  glVertex3f(x, y, z + dz);
  glTexCoord2d(1, 0);
  glVertex3f(x, y + dy, z + dz);
  glTexCoord2d(0, 0);
  glVertex3f(x, y + dy, z);
  glTexCoord2d(0, 1);
  glVertex3f(x, y, z);
  glEnd;

  //forward
  glBindTexture(GL_TEXTURE_2D, tex5);
  glBegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glTexCoord2d(0, 1);
  glVertex3f(x + dx, y, z);
  glTexCoord2d(0, 0);
  glVertex3f(x + dx, y + dy, z);
  glTexCoord2d(1, 0);
  glVertex3f(x, y + dy, z);
  glTexCoord2d(1, 1);
  glVertex3f(x, y, z);
  glEnd;

  //backward
  glBindTexture(GL_TEXTURE_2D, tex6);
  glBegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glTexCoord2d(1, 1);
  glVertex3f(x + dx, y, z + dz);
  glTexCoord2d(1, 0);
  glVertex3f(x + dx, y + dy, z + dz);
  glTexCoord2d(0, 0);
  glVertex3f(x, y + dy, z + dz);
  glTexCoord2d(0, 1);
  glVertex3f(x, y, z + dz);
  glEnd;
end;




exports
  SetDCPixelFormat,
  About,
  LoadTexture,
  LoadTexture512,
  LoadTextureSphere,
  DrawOneSideTexturedBox,
  DrawSkyBox,
  CalcNormal;

begin
end.
 