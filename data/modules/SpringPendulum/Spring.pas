unit Spring;

interface

uses
  Windows, OpenGL, SysUtils;

type
  {spring class}
  TSpring = class
  public
    x1,{start coordinate}
    x2,{end coordinate}
    deflen:Extended;{initial length (without stretching or compression)}
    procedure Render;
  end;

implementation

procedure TSpring.Render;
const
  width=1;
  parts=4;
var
  step:Extended;
  xsize:Extended;
  i:Word;
begin
  xsize:=width/2;
  glDisable(GL_LIGHTING);
  glColor3f(1,0,0);
  glBegin(GL_LINE_STRIP);

  step:=(x2-x1)/Round(parts*deflen);

  glVertex3f(xsize,x1-0.2,xsize);
  for i:=1 to Round(parts*deflen) do
  begin
    glVertex3f(xsize,x1+step*((i-1)*4+0)/4,xsize);
    glVertex3f(xsize,x1+step*((i-1)*4+1)/4,-xsize);
    glVertex3f(-xsize,x1+step*((i-1)*4+2)/4,-xsize);
    glVertex3f(-xsize,x1+step*((i-1)*4+3)/4,xsize);
  end;
  glVertex3f(-xsize,x1+step*((Round(parts*deflen)-1)*4+4)/4+0.2,xsize);

  glEnd;
  glEnable(GL_LIGHTING);
end;

begin
end.