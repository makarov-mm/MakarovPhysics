unit unitFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, Math;

const
  segsCount = 800;

type
  TfrmLibMain = class(TForm)
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    CallerForm: THandle;{calling form}
    DC: HDC;{device context}
    HRC: HGLRC;{OpenGL rendering context}
    ps: TPaintStruct;
    pfd: TPixelFormatDescriptor;
    nPixelFormat: Integer;
    RenderTimerID: Integer;{rendering timer identifier}
    QuadObj: GLUquadricObj;{quadric object}
    graphdelay: Integer;{graph output delay}
    procedure UpdateArrays;
    procedure DrawGraphics;
    procedure DrawTraectory;
    procedure Render;
    procedure SetDCPixelFormat;
    procedure SetDefaultWindowsPosition;
    procedure Calculate;
  public
    ArrX, ArrY, ArrSX, ArrSY: Array[1..segsCount] of Extended;{arrays}
    PlanetMass,{planet mass}
    SatelliteMass,{object mass}
    PlanetRadius,{planet radius}
    cX, cY,{object coordinates}
    speedX, speedY,{object speed}
    accelX, accelY: Extended;{object acceleration}
    IsRun: Boolean;
  end;

var
  frmLibMain: TfrmLibMain;

procedure InitLibrary(App,CallForm:THandle);

implementation

uses unitFrmOptions, unitFrmResult, unitFrmGraphics;

{$R *.dfm}

procedure InitLibrary(App, CallForm: THandle);
{Library initialization}
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;

  {create additional windows}
  frmOptions := TfrmOptions.Create(Application);
  frmResults := TfrmResults.Create(Application);
  frmGraphics := TfrmGraphics.Create(Application);
  frmLibMain.Show;
end;

procedure TfrmLibMain.UpdateArrays;
var
  i: Integer;
begin
  for i := 1 to segsCount - 1 do
  begin
    ArrX[i] := ArrX[i + 1];
    ArrY[i] := ArrY[i + 1];
    ArrSX[i] := ArrSX[i + 1];
    ArrSY[i] := ArrSY[i + 1];
  end;
  
  ArrX[segsCount] := cX;
  ArrY[segsCount] := cY;
  ArrSX[segsCount] := speedX;
  ArrSY[segsCount] := speedY;
end;

procedure TfrmLibMain.DrawGraphics;
var
  i: Integer;
begin
  frmGraphics.chartPhase1.Series[0].Clear;
  frmGraphics.chartPhase2.Series[0].Clear;

  for i := 1 to segsCount do
  begin
    frmGraphics.chartPhase1.Series[0].AddXY(ArrX[i],ArrSX[i]);
    frmGraphics.chartPhase2.Series[0].AddXY(ArrY[i],ArrSY[i]);
  end;
end;

procedure TfrmLibMain.Calculate;
{calculations}
const
  gamma = 6.6720 * 0.00000000001;
  dt = 1 / 250000;
var
  i: Integer;
  taccel: Extended;
begin
  taccel := frmOptions.tbTime.Position;
  for i := 1 to 10000 do
  begin
    accelX := -(gamma * PlanetMass * SatelliteMass / (sqr(cX) + sqr(cY))) * (cX / sqrt(sqr(cX) + sqr(cY)));
    accelY := -(gamma * PlanetMass * SatelliteMass / (sqr(cX) + sqr(cY))) * (cY / sqrt(sqr(cX) + sqr(cY)));
    speedX := speedX + accelX * dt * taccel;
    speedY := speedY + accelY * dt * taccel;
    cX := cX + speedX * dt * taccel;
    cY := cY + speedY * dt * taccel;
  end;
end;

procedure TfrmLibMain.SetDefaultWindowsPosition;
const
  dw = 209;
  dh = 0.7;
begin
  with frmLibMain do
  begin
    Left := dw;
    Top := 0;
    Width := Screen.Width - dw;
    Height := Floor(Screen.Height * dh);
  end;

  with frmResults do
  begin
    Left := dw;
    Top := frmLibMain.Height;
    Width := Floor((Screen.Width - dw) / 2);
    Height := Screen.Height - frmLibMain.Height;
    Show;
  end;

  with frmGraphics do
  begin
    Left := frmResults.Left + frmResults.Width;
    Top := frmLibMain.Height;
    Width := Screen.Width - frmResults.Width - dw;
    Height := frmResults.Height;
    Show;
  end;

  with frmOptions do
  begin
    Left := 0;
    Top := 0;
    Width := dw;
    Height := Screen.Height;
    Show;
  end;
end;

procedure TfrmLibMain.DrawTraectory;
var
  i: Integer;
begin
  if IsRun then
  begin
    glBegin(GL_LINE_STRIP);
    for i := 1 to segsCount do
      glVertex3f(ArrX[i] / 500000, ArrY[i] / 500000, 0);
    glEnd;
  end;
end;

procedure TfrmLibMain.Render;
{rendering}
begin
  wglMakeCurrent(DC, HRC);
  BeginPaint(Handle, ps);
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glTranslatef(0, 0, -frmOptions.tbDistance.Position * 5);

  if IsRun then
    Calculate;

  if frmOptions.cbTraectory.Checked  then
    DrawTraectory;

  glColor3f(1, 1, 1);
  gluSphere(quadObj, PlanetRadius / 500000, 30, 30);

  glTranslatef(cX / 500000 , cY / 500000, 0);
  gluSphere(quadObj, frmOptions.tbObjRadius.Position, 30, 30);

  inc(graphdelay);
  if graphdelay > 3 then
  begin
    UpdateArrays;
    DrawGraphics;
    graphdelay := 0;
    frmResults.txtResult.Text :=
      'X: ' + FloatToStr(cX) + ' m' + #13#10 +
      'Y: ' + FloatToStr(cY) + ' m' + #13#10 +
      'Speed X: ' + FloatToStr(speedX) + ' m/s' + #13#10 +
      'Speed Y: ' + FloatToStr(speedY) + ' m/s';
  end;

  EndPaint(Handle, ps);
  SwapBuffers(DC);
end;

procedure TfrmLibMain.SetDCPixelFormat;
begin
  FillChar(pfd, SizeOf(pfd), 0);
  pfd.dwFlags := PFD_SUPPORT_OPENGL or
                 PFD_DRAW_TO_WINDOW or
                 PFD_DOUBLEBUFFER;
  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);
end;

procedure TfrmLibMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if frmOptions.Visible then Resize := False;
end;

procedure TfrmLibMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {destroying timers}
  KillTimer(Handle, RenderTimerID);

  {removing a quadric object}
  gluDeleteQuadric(QuadObj);

  {OpenGL shutdown}
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle, DC);
  DeleteDC(DC);

  {removing additional forms}
  frmOptions.Destroy;
  frmResults.Destroy;
  frmGraphics.Destroy;

  {module shutdown}
  SendMessage(CallerForm, WM_USER, 0, 0);
  Destroy;
end;

procedure RenderTimerTick(AHwnd: HWND; AMsg: UINT; AEvent: UINT_PTR; ATime: DWORD); stdcall;
begin
  frmLibMain.Render;
end;

procedure TfrmLibMain.FormShow(Sender: TObject);
begin
  IsRun := False;
  PlanetMass := 59760 * 100000000000000000000.0;
  PlanetRadius := 3600000;
  cX := 13600000;

  speedY := 6500;
  SatelliteMass := 1;

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
  glEnable(GL_POLYGON_SMOOTH);
  glClearColor(0, 0, 0, 1);

  {creating a quadric object}
  quadObj := gluNewQuadric;
  gluQuadricDrawStyle(quadObj, GLU_FILL);
  gluQuadricOrientation(quadObj, GLU_OUTSIDE);

  SetDefaultWindowsPosition;
  {timer initialization}
  Randomize;
  RenderTimerID := Random(10000);
  SetTimer(Handle, RenderTimerID, 40, @RenderTimerTick);
end;

procedure TfrmLibMain.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientWidth / ClientHeight, 1, 10000);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

end.
 