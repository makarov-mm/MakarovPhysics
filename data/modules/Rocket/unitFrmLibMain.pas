{
Program: Rocket flight\nAuthor: M.M. Makarov\nCreated: November 2004\nIDE: Delphi 7
}
unit unitFrmLibMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, XPMan, ExtCtrls, RocketBaseUnit, RocketUnit, InfoUnit;

type
  TfrmLibMain = class(TForm)
    XPManifest1: TXPManifest;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    Image7: TImage;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    DC: HDC;{device context}
    HRC: HGLRC;{OpenGL rendering context}
    ps: TPaintStruct;
    nPixelFormat: Integer;
    pfd: TPixelFormatDescriptor;
    preX, preY: Integer;{previous mouse cursor position}
    MouseL: Boolean;{mouse button state}
    rotation: Single;{coordinate system rotation}
    Texture: Array[1..8, 0..127,0..127,0..3] of GLubyte;
    CallerForm: THandle;
    procedure SetDefaultWindowsPosition;
    procedure SetDCPixelFormat;
    procedure Render;
    procedure LoadTextures;
    procedure DrawQuadrangle(x1, y1, z1,
                             x2, y2, z2,
                             x3, y3, z3,
                             x4, y4, z4: Single);
    procedure DrawBox(x, y, z, xWidth, yWidth, zWidth: Single);
    procedure DrawHouse(x, z, t1, t2: Integer);
    procedure DrawHouses;
  public
    InfoThread: TMyThread;{thread for outputting rocket information}
    RotationSpeed: Single;{rotation speed}
    RocketBase: TRocketBase;{rocket stand}
    Rocket: TRocket;{rocket}
    Paused: Boolean;{pause}
  end;

procedure InitLibrary(App,CallForm:THandle);

var
  frmLibMain: TfrmLibMain;

implementation

uses unitFrmGraphics, unitFrmOptions, unitFrmResults;

{$R *.dfm}

procedure InitLibrary(App, CallForm: THandle);
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;
  frmOptions := TfrmOptions.Create(Application);
  frmResults := TfrmResults.Create(Application);
  frmGraphics := TfrmGraphics.Create(Application);

  frmLibMain.Show;
end;

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

procedure TfrmLibMain.DrawQuadrangle(x1, y1, z1,
                                     x2, y2, z2,
                                     x3, y3, z3,
                                     x4, y4, z4: Single);
{draw a polygon and compute its normals}
var
  wrki, vx1, vy1, vz1, vx2, vy2, vz2:Single;
begin
  vx1 := x1 - x2;
  vy1 := y1 - y2;
  vz1 := z1 - z2;
  vx2 := x3 - x2;
  vy2 := y3 - y2;
  vz2 := z3 - z2;

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

procedure TfrmLibMain.DrawBox(x, y, z, xWidth, yWidth, zWidth: Single);
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

procedure TfrmLibMain.LoadTextures;
{texture loading}
var
  i, j: Integer;
begin
  glBindTexture(GL_TEXTURE_2D,1);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[1,i,j,0]:=GetRValue(Image1.Canvas.Pixels[i,j]);
      Texture[1,i,j,1]:=GetGValue(Image1.Canvas.Pixels[i,j]);
      Texture[1,i,j,2]:=GetBValue(Image1.Canvas.Pixels[i,j]);
      if (Texture[1,i,j,0]<5) and
         (Texture[1,i,j,1]<5) and
         (Texture[1,i,j,2]<5) then
        Texture[1,i,j,3]:=0
      else
        Texture[1,i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[1]);

  glBindTexture(GL_TEXTURE_2D,2);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[2,i,j,0]:=GetRValue(Image2.Canvas.Pixels[i,j]);
      Texture[2,i,j,1]:=GetGValue(Image2.Canvas.Pixels[i,j]);
      Texture[2,i,j,2]:=GetBValue(Image2.Canvas.Pixels[i,j]);
      if (Texture[2,i,j,0]<5) and
         (Texture[2,i,j,1]<5) and
         (Texture[2,i,j,2]<5) then
        Texture[2,i,j,3]:=0
      else
        Texture[2,i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[2]);

  glBindTexture(GL_TEXTURE_2D,3);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[3, i,j,0]:=GetRValue(Image3.Canvas.Pixels[i,j]);
      Texture[3, i,j,1]:=GetGValue(Image3.Canvas.Pixels[i,j]);
      Texture[3, i,j,2]:=GetBValue(Image3.Canvas.Pixels[i,j]);
      if (Texture[3, i,j,0]<5) and
         (Texture[3, i,j,1]<5) and
         (Texture[3, i,j,2]<5) then
        Texture[3, i,j,3]:=0
      else
        Texture[3, i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[3]);

  glBindTexture(GL_TEXTURE_2D,4);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[4, i,j,0]:=GetRValue(Image4.Canvas.Pixels[i,j]);
      Texture[4, i,j,1]:=GetGValue(Image4.Canvas.Pixels[i,j]);
      Texture[4, i,j,2]:=GetBValue(Image4.Canvas.Pixels[i,j]);
      if (Texture[4, i,j,0]<5) and
         (Texture[4, i,j,1]<5) and
         (Texture[4, i,j,2]<5) then
        Texture[4, i,j,3]:=0
      else
        Texture[4, i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[4]);

  glBindTexture(GL_TEXTURE_2D,5);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[5, i,j,0]:=GetRValue(Image5.Canvas.Pixels[i,j]);
      Texture[5, i,j,1]:=GetGValue(Image5.Canvas.Pixels[i,j]);
      Texture[5, i,j,2]:=GetBValue(Image5.Canvas.Pixels[i,j]);
      if (Texture[5, i,j,0]<5) and
         (Texture[5, i,j,1]<5) and
         (Texture[5, i,j,2]<5) then
        Texture[5, i,j,3]:=0
      else
        Texture[5, i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[5]);

  glBindTexture(GL_TEXTURE_2D,6);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[6, i,j,0]:=GetRValue(Image5.Canvas.Pixels[i,j]);
      Texture[6, i,j,1]:=GetGValue(Image5.Canvas.Pixels[i,j]);
      Texture[6, i,j,2]:=GetBValue(Image5.Canvas.Pixels[i,j]);
      Texture[6, i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[6]);

  glBindTexture(GL_TEXTURE_2D,7);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[7, i,j,0]:=GetRValue(Image6.Canvas.Pixels[i,j]);
      Texture[7, i,j,1]:=GetGValue(Image6.Canvas.Pixels[i,j]);
      Texture[7, i,j,2]:=GetBValue(Image6.Canvas.Pixels[i,j]);
      if (Texture[7, i,j,0]<5) and
         (Texture[7, i,j,1]<5) and
         (Texture[7, i,j,2]<5) then
        Texture[7, i,j,3]:=0
      else
        Texture[7, i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexGeni (GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexGeni (GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[7]);

  glBindTexture(GL_TEXTURE_2D,8);
  for i:=0 to 127 do
    for j:=0 to 127 do
    begin
      Texture[8, i,j,0]:=GetRValue(Image7.Canvas.Pixels[i,j]);
      Texture[8, i,j,1]:=GetGValue(Image7.Canvas.Pixels[i,j]);
      Texture[8, i,j,2]:=GetBValue(Image7.Canvas.Pixels[i,j]);
      if (Texture[8, i,j,0]<5) and
         (Texture[8, i,j,1]<5) and
         (Texture[8, i,j,2]<5) then
        Texture[8, i,j,3]:=0
      else
        Texture[8, i,j,3]:=255;
    end;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128,128,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Texture[8]);
end;

procedure TfrmLibMain.DrawHouse(x,z,t1,t2:Integer);
{draw a house}
const
  housewidth = 20;
  househeight = 30;
begin
  glBindTexture(GL_TEXTURE_2D,t1);
  DrawBox(x,0,z,housewidth,househeight,housewidth);
  glBindTexture(GL_TEXTURE_2D,t2);
  glBegin(GL_QUADS);
  DrawQuadrangle(x,            househeight+0.1, z+housewidth,
                 x+housewidth, househeight+0.1, z+housewidth,
                 x+housewidth, househeight+0.1, z,
                 x,            househeight+0.1, z);
  glEnd;
end;

procedure TfrmLibMain.DrawHouses;
var
  i:Integer;
begin
  glDeleteLists(1, 1);
  glNewList(1, GL_COMPILE);

  {draw houses}
  DrawHouse(20, 60, 2, 4);
  DrawHouse(20, 100, 2, 4);
  DrawHouse(70, 80, 2, 4);
  DrawHouse(90, 10, 3, 4);
  DrawHouse(120, 10, 3, 4);
  DrawHouse(90, -40, 2, 4);
  DrawHouse(130, -40, 2, 4);
  DrawHouse(-100, -150, 3, 4);
  DrawHouse(-70, -150, 3, 4);
  DrawHouse(-40, -150, 2, 4);
  DrawHouse(-150, 20, 3, 4);
  DrawHouse(-150, -70, 2, 4);
  DrawHouse(-100, 80, 3, 4);
  DrawHouse(-100, -90, 2, 4);
  DrawHouse(-70, -90, 3, 4);
  DrawHouse(-40, -90, 2, 4);
  DrawHouse(-10, -90, 3, 4);
  DrawHouse(-30, 130, 2, 4);
  DrawHouse(-70, 130, 3, 4);
  DrawHouse(-100, 130, 3, 4);

  {platform the rocket stands on}
  DrawBox(-15, -19, -15, 30, 20, 30);

  {draw roads}
  glBindTexture(GL_TEXTURE_2D, 6);
  glBegin(GL_QUADS);
  for i := 0 to 30 do
    DrawQuadrangle(45, 0.1, i*20+20,
                   65, 0.1, i*20+20,
                   65, 0.1, i*20,
                   45, 0.1, i*20);

  for i := -30 to 30 do
    DrawQuadrangle(-125, 0.13, i*20+20,
                   -105, 0.13, i*20+20,
                   -105, 0.13, i*20,
                   -125, 0.13, i*20);

  glEnd;
  glBindTexture(GL_TEXTURE_2D, 5);
  glBegin(GL_QUADS);
  for i := -30 to 30 do
    DrawQuadrangle(i * 20 + 20, 0.12, -125,
                   i * 20 + 20, 0.12, -105,
                   i * 20, 0.12, -105,
                   i * 20, 0.12, -125);
  for i := -30 to 30 do
    DrawQuadrangle(i * 20 + 20, 0.11, -15,
                   i * 20 + 20, 0.11, 5,
                   i * 20, 0.11, 5,
                   i * 20, 0.11, -15);
  glEnd;
  glEndList;
end;

procedure TfrmLibMain.Render;
{rendering}
const
  fieldkoef = 100;{texture stretch factor on the field}
var
  i, j: Integer;
begin
  if not Paused then
    if Rocket.IsRun then Rocket.Calc;
  glTranslatef(0, 18 - Rocket.H, -100);
  glRotatef(rotation, 0, 1, 0);

  rotation := rotation + RotationSpeed;
  if rotation > 360 then rotation := 0;

  {draw the field}
  glBindTexture(GL_TEXTURE_2D, 1);
  glBegin(GL_QUADS);
  for i := -5 to 5 do
    for j := -5 to 5 do
      DrawQuadrangle(i * fieldkoef, 0, j * fieldkoef + fieldkoef,
                     i * fieldkoef + fieldkoef, 0, j * fieldkoef + fieldkoef,
                     i * fieldkoef + fieldkoef, 0, j * fieldkoef,
                     i * fieldkoef, 0, j * fieldkoef);
  glEnd;

  {draw various structures}
  glCallList(1);

  {draw the rocket stand}
  glBindTexture(GL_TEXTURE_2D, 8);
  RocketBase.Draw;

  {draw the rocket}
  glBindTexture(GL_TEXTURE_2D, 7);
  if (RocketBase.Angle >= 20) and (not Rocket.IsRun) and (not Paused) then
    Rocket.CanStart(StrToFloat(frmOptions.txtMass.Text),
                    StrToFloat(frmOptions.txtSpeed.Text),
                    StrToFloat(frmOptions.txtFuelPerSec1.Text),
                    StrToFloat(frmOptions.txtFuelMass1.Text),
                    StrToFloat(frmOptions.txtFuelPerSec2.Text),
                    StrToFloat(frmOptions.txtFuelMass2.Text),
                    StrToFloat(frmOptions.txtFuelPerSec3.Text),
                    StrToFloat(frmOptions.txtFuelMass3.Text));
  Rocket.Draw(not Paused);
end;

procedure TimerTick(AHwnd: HWND; AMsg: UINT; AEvent: UINT_PTR; ATime: DWORD); stdcall;
{OnTimer event}
begin
  BeginPaint(frmLibMain.Handle, frmLibMain.ps);
  wglMakeCurrent(frmLibMain.DC, frmLibMain.HRC);
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  frmLibMain.Render;
  EndPaint(frmLibMain.Handle, frmLibMain.ps);
  SwapBuffers(frmLibMain.DC);
end;

procedure TfrmLibMain.SetDCPixelFormat;
{set the pixel format}
begin
  FillChar(pfd, SizeOf(pfd), 0);
  pfd.dwFlags := PFD_SUPPORT_OPENGL or
                 PFD_DRAW_TO_WINDOW or
                 PFD_DOUBLEBUFFER;
  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);
end;

procedure TfrmLibMain.SetDefaultWindowsPosition;
{window layout setup}
const
  opwidth = 209;
  vdiv = 0.7;
begin
  with frmLibMain do
  begin
    Left := 0;
    Top := 0;
    Width := Screen.Width - opwidth;
    Height := Round(Screen.Height * vdiv);
  end;

  with frmGraphics do
  begin
    Left := 0;
    Top := frmLibMain.Height;
    Width := Round((Screen.Width - opwidth) / 2);
    Height := Screen.Height - frmLibMain.Height;
    Show;
  end;

  with frmOptions do
  begin
    Left := frmLibMain.Width;
    Top := 0;
    Height := Screen.Height;
    Width := Screen.Width - frmLibMain.Width;
    Show;
  end;

  with frmResults do
  begin
    Left := Round((Screen.Width-opwidth)/2);
    Top := frmLibMain.Height;
    Height := Screen.Height - frmLibMain.Height;
    Width := Round((Screen.Width - opwidth) / 2);
    Show;
  end;
end;

procedure TfrmLibMain.FormShow(Sender: TObject);
begin
  {set the default window layout}
  SetDefaultWindowsPosition;

  {start the extra thread that outputs information to frmResult.RichEdit1}
  InfoThread.Start;
end;

procedure TfrmLibMain.FormCreate(Sender: TObject);
const
  FogStart = 10;{fog start}
  FogEnd = 500;{fog end}
var
  fogColor: Array[0..3] of GLFloat;{Fog color}
begin
  {set variables to initial values}
  preX := 0;
  preY := 0;
  MouseL := False;
  rotation := 0;
  RotationSpeed := 0.3;
  Paused := False;

  {create Rocket and Rocket Base objects}
  RocketBase := TRocketBase.Create;
  Rocket := TRocket.Create;

  {OpenGL initialization}
  DC := GetDC(Handle);
  SetDCPixelFormat;
  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC, HRC);
  glClearColor(0, 0, 0, 1);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LINE_SMOOTH);
  glEnable(GL_POINT_SMOOTH);
  glEnable(GL_POLYGON_SMOOTH);
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  {fog setup}
  fogColor[0] := 0;
  fogColor[1] := 0;
  fogColor[2] := 0;
  glEnable(GL_FOG);
  glFogi(GL_FOG_MODE, GL_LINEAR);
  glHint(GL_FOG_HINT, GL_NICEST);
  glFogf(GL_FOG_START, FogStart);
  glFogf(GL_FOG_END, FogEnd);
  glFogfv(GL_FOG_COLOR, @fogColor);

  {texture loading}
  LoadTextures;

  {create a display list for various houses, roads, etc.}
  DrawHouses;

  {extra thread}
  InfoThread:=TMyThread.Create(true);

  //InfoThread.Priority:=tpIdle;
  InfoThread.MyRocket:=Rocket;

  {set the rendering timer}
  SetTimer(Handle, 1, 40, @TimerTick);
end;

procedure TfrmLibMain.FormResize(Sender: TObject);
{adjust OpenGL output when the window is resized}
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientWidth / ClientHeight, 40, 1000);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TfrmLibMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    MouseL := True
  else
    MouseL := False;

  preX := X;
  preY := Y;
end;

procedure TfrmLibMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    MouseL := False;
end;

procedure TfrmLibMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
const
  sens = 0.1;{mouse sensitivity}
begin
  {rotate the coordinate system when the mouse moves with the left button pressed}
  if MouseL then
  begin
    rotation := rotation + (X - preX) * sens;
    preX := X;
  end;
end;

procedure TfrmLibMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if frmOptions.Visible then Resize := False;
end;

procedure TfrmLibMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  frmOptions.Free;
  frmResults.Free;
  frmGraphics.Free;

  {removing classes}
  InfoThread.Destroy;
  InfoThread := nil;
  Rocket.Destroy;
  Rocket := nil;
  RocketBase.Destroy;
  RocketBase := nil;

  {removing timer}
  KillTimer(Handle, 1);

  {OpenGL shutdown}
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle, DC);
  DeleteDC(DC);

  SendMessage(CallerForm, WM_USER, 0, 0);
end;

end.
 