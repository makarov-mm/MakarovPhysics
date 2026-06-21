unit unitFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, ExtCtrls, Math, MyEngine;

type
  TElectron = record
    x, y, z, t, h0, V: Extended;
    enabled: Boolean;
  end;

  TfrmLibMain = class(TForm)
    RenderTimer: TTimer;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure RenderTimerTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
  private
    CallerForm: THandle;
    DC: HDC;
    HRC: HGLRC;
    pfd: TPixelFormatDescriptor;
    nPixelFormat: Integer;
    ps: TPaintStruct;
    rotation: Extended;
    MouseDown: Boolean;
    preX: Integer;
    r: Extended;{distance between plates}
    el: Array[1..1000] of TElectron;
    procedure SetDefaultWindowsPosition;
    procedure SetDCPixelFormat;
    procedure Quadrangle(x1, y1, z1,
                         x2, y2, z2,
                         x3, y3, z3,
                         x4, y4, z4: Single);
    procedure DrawBox(x, y, z, xWidth, yWidth, zWidth: Single);
    procedure Calc;
  public
    IsRun: Boolean;
    StartSpeed: Extended;{initial electron speed}
    StartAngle: Extended;{electron launch angle}
    p1, p2: Extended;{potentials}
  end;

var
  frmLibMain: TfrmLibMain;

procedure InitLibrary(App,CallForm:THandle);

implementation

uses unitFrmOptions;

{$R *.dfm}

procedure InitLibrary(App,CallForm:THandle);
{Library initialization}
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;
  frmOptions := TfrmOptions.Create(Application);
  frmLibMain.Show;
end;

procedure TfrmLibMain.SetDCPixelFormat;
{pixel format setup}
begin
  FillChar(pfd,SizeOf(pfd),0);
  pfd.dwFlags := PFD_SUPPORT_OPENGL or
                 PFD_DRAW_TO_WINDOW or
                 PFD_DOUBLEBUFFER;
  nPixelFormat := ChoosePixelFormat(DC,@pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);
end;

procedure TfrmLibMain.SetDefaultWindowsPosition;
{window layout setup}
const
  w = 209;
begin
  with frmLibMain do
  begin
    Left := w;
    Top := 0;
    Width := Screen.Width - w;
    Height := Screen.Height;
  end;

  with frmOptions do
  begin
    Left := 0;
    Top := 0;
    Width := w;
    Height := Screen.Height;
    Show;
  end;
end;

procedure TfrmLibMain.Quadrangle(x1, y1, z1,
                                 x2, y2, z2,
                                 x3, y3, z3,
                                 x4, y4, z4: Single);
begin
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
{rectangular parallelepiped}
begin
  glBegin(GL_QUADS);
    glNormal3f(-1, 0, 0);
    Quadrangle(x, y, z + zWidth, x, y + yWidth, z + zWidth,
      x, y + yWidth, z, x, y, z);

    glNormal3f(1, 0, 0);
    Quadrangle(x + xWidth, y, z + zWidth,
      x + xWidth, y + yWidth, z + zWidth,
      x + xWidth, y + yWidth, z,
      x + xWidth, y, z);

    glNormal3f(0, 0, -1);
    Quadrangle(x, y, z,
      x, y + yWidth, z,
      x + xWidth, y + yWidth, z,
      x + xWidth, y, z);

    glNormal3f(0, 0, 1);
    Quadrangle(x, y, z + zWidth,
      x, y + yWidth, z + zWidth,
      x + xWidth, y + yWidth, z + zWidth,
      x + xWidth, y, z + zWidth);

    glNormal3f(0, -1, 0);
    Quadrangle(x, y, z,
      x, y, z + zWidth,
      x + xWidth, y, z + zWidth,
      x + xWidth, y, z);

    glNormal3f(0, 1, 0);
    Quadrangle(x, y + yWidth, z,
      x, y + yWidth, z + zWidth,
      x + xWidth, y + yWidth, z + zWidth,
      x + xWidth, y + yWidth, z);
  glEnd;
end;

procedure TfrmLibMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if frmOptions.Visible then Resize := False;
end;

procedure TfrmLibMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  RenderTimer.Enabled := False;
  MouseDown := False;

  {OpenGL shutdown}
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle, DC);
  DeleteDC(DC);

  {removing additional forms}
  frmOptions.Destroy;

  {module shutdown}
  SendMessage(CallerForm, WM_USER, 0, 0);
  Destroy;
end;

procedure TfrmLibMain.FormShow(Sender: TObject);
begin
  IsRun := False;

  {window layout setup}
  SetDefaultWindowsPosition;

  {OpenGL initialization}
  DC := GetDC(Handle);
  SetDCPixelFormat;
  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC, HRC);

  {OpenGL setup}
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_COLOR_MATERIAL);

  LoadTexture('data\textures\skybox_c.dat', 1, 1);
  LoadTexture('data\textures\skybox_c.dat', 2, 2);
  LoadTexture('data\textures\skybox_c.dat', 3, 3);
  LoadTexture('data\textures\skybox_c.dat', 4, 4);
  LoadTexture('data\textures\skybox_c.dat', 5, 5);
  LoadTexture('data\textures\skybox_c.dat', 6, 6);
  glDisable(GL_TEXTURE_2D);

  RenderTimer.Enabled := True;
end;

procedure TfrmLibMain.RenderTimerTimer(Sender: TObject);
var
  lp: Extended;{plate length}
  i: Integer;
begin
  wglMakeCurrent(DC, HRC);
  BeginPaint(Handle, ps);
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;

  if MouseDown then
  begin
    rotation := rotation + (Mouse.CursorPos.X - preX);
    preX := Mouse.CursorPos.X;
  end;
  glTranslatef(0, 0, -frmOptions.tbDist.Position);
  glRotatef(rotation, 0, 1, 0);

  glEnable(GL_TEXTURE_2D);
  DrawSkyBox(-250, -250, -250, 500, 500, 500, 1, 2, 3, 4, 5, 6);
  glDisable(GL_TEXTURE_2D);

  r := frmOptions.tbDistance.Position / 10;
  lp := frmOptions.tbLength.Position / 10;

  glColor3f(1, 1, 1);
  DrawBox(-lp / 2, r / 2 -0.5, -3, lp, 0.5, 6);
  DrawBox(-lp / 2, -r / 2, -3, lp, 0.5, 6);

  glColor3f(0.5, 0.5, 0.5);
  DrawBox(-lp / 2 - 0.7, -r / 2 + 0.2, -0.2, 0.2, r * 0.7, 0.4);
  DrawBox(-lp / 2 - 0.7, -r / 2 + 0.2, -0.2, lp / 2, 0.2, 0.4);

  glColor3f(0, 0, 1);
  DrawBox(-lp / 2 - 0.5, -r / 2 + 0.8, -2, 0.2, r - 1.6, 4);

  glDisable(GL_LIGHTING);
  glColor3f(0.5, 0.5, 0.5);
  glBegin(GL_LINES);
    glVertex3f(-lp / 2 + 0.1, -r / 2, -2.9);
    glVertex3f(-lp / 2 + 0.1, r / 2, -2.9);
    glVertex3f(lp / 2 - 0.1, -r / 2, -2.9);
    glVertex3f(lp / 2 - 0.1, r / 2, -2.9);
    glVertex3f(-lp / 2 + 0.1, -r / 2, 2.9);
    glVertex3f(-lp / 2 + 0.1, r / 2, 2.9);
    glVertex3f(lp / 2 - 0.1, -r / 2, 2.9);
    glVertex3f(lp / 2 - 0.1, r / 2, 2.9);
  glEnd;
  glEnable(GL_LIGHTING);

  if IsRun then
    for i := 1 to 40 do
      Calc;
  
  EndPaint(Handle, ps);
  SwapBuffers(DC);
end;

procedure TfrmLibMain.Calc;
{calculations}
const
  em = -1.7588E11;
var
  found: Boolean;
  i, j: Integer;
  maxx, minx, maxy, miny, U, d, a: Extended;
begin
  for j := 1 to 20 do
  begin

    found := False;
    i := 0;
    while (not found) and (i < 1000) do
    begin
      inc(i);
      if not el[i].enabled then
      begin
        found := True;
        with el[i] do
        begin
          y := (Random(Round((r - 2) * 10000)) - (r - 2) * 5000) / 10000;
          if Random(2) = 1 then
            y := -y;
          x := -(frmOptions.tbLength.Position / 20) - 0.5;
          el[i].z := Random(400) / 100 - 2;
          el[i].V := 0;
          t := 0;
          h0 := y;
          enabled := True;
        end;
      end;
    end;
  end;

  maxx := frmOptions.tbLength.Position / 20;
  minx := -frmOptions.tbLength.Position / 20;
  maxy := frmOptions.tbDistance.Position / 20;
  miny := -frmOptions.tbDistance.Position / 20;
  U := (p2 - p1) * 10E-14;
  d := frmOptions.tbDistance.Position / 10;

  glDisable(GL_LIGHTING);
  glColor3f(0, 0, 1);
  glPointSize(2);
  glBegin(GL_POINTS);
  for i := 1 to 1000 do
  begin
    if el[i].enabled then
      if (el[i].x > maxx) or (el[i].x < minx - 0.6) or
         (el[i].y > maxy) or (el[i].y < miny) then
      begin
        el[i].enabled := False;
      end else begin
        el[i].t := el[i].t + 1;
        el[i].x := el[i].x + StartSpeed * (1 / 1000) * cos(DegToRad(StartAngle));
        a := U * em / d;
        el[i].V := el[i].V + a * (1 / 1000);
        el[i].y := el[i].y + StartSpeed * (1 / 1000) * sin(DegToRad(StartAngle)) + el[i].V;
        glVertex3f(el[i].x, el[i].y, el[i].z);
      end;
  end;
  glEnd;
  glEnable(GL_LIGHTING);
end;

procedure TfrmLibMain.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientWidth / ClientHeight, 1, 1000);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TfrmLibMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseDown := True;
  preX := Mouse.CursorPos.X;
end;

procedure TfrmLibMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseDown := False;
end;

procedure TfrmLibMain.FormCreate(Sender: TObject);
begin
  rotation := -20;
end;

end.
 