{
Program: Rocket flight\nAuthor: M.M. Makarov\nCreated: November 2004\nIDE: Delphi 7
}
unit RocketBaseUnit;

interface

uses
  OpenGL;

type
  TRocketBase = class
  private
    x, z: Single;{coordinates}
    IsRun: Boolean;{whether it is falling}
  public
    Angle: Single;{angle}
    constructor Create;
    procedure Draw;
    procedure Turn;
  end;

implementation

procedure DrawQuadrangle(x1, y1, z1,
                         x2, y2, z2,
                         x3, y3, z3,
                         x4, y4, z4: Single);
{draw a polygon and compute its normals}
var
  wrki, vx1, vy1, vz1, vx2, vy2, vz2: Single;
begin
  vx1 := x1-x2;
  vy1 := y1-y2;
  vz1 := z1-z2;
  vx2 := x3-x2;
  vy2 := y3-y2;
  vz2 := z3-z2;

  wrki := sqrt(sqr(vy1 * vz2 - vz1 * vy2) +
               sqr(vz1 * vx2 - vx1 * vz2) +
               sqr(vx1 * vy2 - vy1 * vx2));

  glNormal3f((vy1 * vz2 - vz1 * vy2) / wrki,
             (vz1 * vx2 - vx1 * vz2) / wrki,
             (vx1 * vy2 - vy1 * vx2) / wrki);

  glTexCoord2f(0, 1);
  glVertex3f(x1, y1, z1);
  glTexCoord2f(0, 0);
  glVertex3f(x2, y2, z2);
  glTexCoord2f(1, 0);
  glVertex3f(x3, y3, z3);
  glTexCoord2f(1, 1);
  glVertex3f(x4, y4, z4);
end;

procedure DrawBox(x,y,z,xWidth,yWidth,zWidth:Single);
{draw a rectangular parallelepiped}
begin
  glBegin(GL_QUADS);

    DrawQuadrangle(x, y, z,
                   x, y, z + zWidth,
                   x, y + yWidth, z + zWidth,
                   x, y + yWidth, z);

    DrawQuadrangle(x + xWidth, y, z,
                   x + xWidth, y, z + zWidth,
                   x + xWidth, y + yWidth, z + zWidth,
                   x + xWidth, y + yWidth, z);

    DrawQuadrangle(x + xWidth, y, z,
                   x, y, z,
                   x, y + yWidth, z,
                   x + xWidth, y + yWidth, z);

    DrawQuadrangle(x + xWidth, y, z + zWidth,
                   x, y, z + zWidth,
                   x, y + yWidth, z + zWidth,
                   x + xWidth, y + yWidth, z + zWidth);

    DrawQuadrangle(x + xWidth, y, z,
                   x, y, z,
                   x, y, z + zWidth,
                   x + xWidth, y, z + zWidth);

    DrawQuadrangle(x + xWidth, y + yWidth, z,
                   x, y + yWidth, z,
                   x, y + yWidth, z + zWidth,
                   x + xWidth, y + yWidth, z + zWidth);

  glEnd;
end;

constructor TRocketBase.Create;
begin
  x := 0;
  z := 0;
  Angle := -20;
  IsRun := False;
end;

procedure TRocketBase.Turn;
{push the structure}
begin
  if Angle < 20 then IsRun := True;
end;

procedure TRocketBase.Draw;
{rendering}
begin
  if IsRun then
    Angle := Angle + 0.3;

  if Angle >= 20 then
    IsRun := False;

  glPushMatrix;
  glTranslatef(-13, 0, 0);
  glRotatef(Angle, 0, 0, 1);
  DrawBox(0, 0, -3, 0.99, 25, 1);
  DrawBox(0, 0, 2, 0.99, 25, 1);
  DrawBox(1, 24, 2, 3, 1, 1);
  DrawBox(1, 24, -3, 3, 1, 1);
  glLineWidth(5);
  glBegin(GL_LINE_STRIP);
  glVertex3f(0, 1 ,-2.5);
  glVertex3f(0, 5, 2.5);
  glVertex3f(0, 9, -2.5);
  glVertex3f(0, 13, 2.5);
  glVertex3f(0, 17, -2.5);
  glVertex3f(0, 21, 2.5);
  glVertex3f(0, 25, -2.5);
  glVertex3f(0, 25, 2.5);
  glVertex3f(0, 21, -2.5);
  glVertex3f(0, 17, 2.5);
  glVertex3f(0, 13, -2.5);
  glVertex3f(0, 9, 2.5);
  glVertex3f(0, 5, -2.5);
  glVertex3f(0, 1, 2.5);
  glEnd;
  glPopMatrix;

  glPushMatrix;
  glTranslatef(13, 0, 0);
  glRotatef(-Angle, 0, 0, 1);
  DrawBox(0, 0, -3, 0.99, 25, 1);
  DrawBox(0, 0, 2, 0.99, 25, 1);
  DrawBox(0, 24, 2, -3, 1, 1);
  DrawBox(0, 24, -3, -3, 1, 1);
  glLineWidth(5);
  glBegin(GL_LINE_STRIP);
  glVertex3f(0, 1, -2.5);
  glVertex3f(0, 5, 2.5);
  glVertex3f(0, 9,-2.5);
  glVertex3f(0, 13, 2.5);
  glVertex3f(0, 17, -2.5);
  glVertex3f(0, 21, 2.5);
  glVertex3f(0, 25, -2.5);
  glVertex3f(0, 25, 2.5);
  glVertex3f(0, 21, -2.5);
  glVertex3f(0, 17, 2.5);
  glVertex3f(0, 13, -2.5);
  glVertex3f(0, 9, 2.5);
  glVertex3f(0, 5, -2.5);
  glVertex3f(0, 1, 2.5);
  glEnd;
  glPopMatrix;
end;

end.
