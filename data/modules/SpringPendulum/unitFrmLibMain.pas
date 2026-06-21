unit unitFrmLibMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, OpenGL, Spring;

type
  TfrmLibMain = class(TForm)
    RenderTimer: TTimer;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RenderTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    CallerForm: THandle;
    DC: HDC;
    HRC: HGLRC;
    pfd: TPixelFormatDescriptor;
    ps: TPaintStruct;
    nPixelFormat: Integer;
    quadobj: GLUQuadricObj;
    procedure DrawGraphics;
    procedure Calc;
    procedure SetDCPixelFormat;
    procedure SetDefaultWindowsPosition;
    procedure Render;
    procedure DrawBox(x, y, z, dx, dy, dz: Single);
  public
    g,{free-fall acceleration}
    m,{weight mass}
    defaultLen,{spring length}
    k,{stiffness coefficient}
    S,{displacement}
    Period,{oscillation period}
    currPeriod,
    Freq,{Oscillation frequency}
    preSpeed, Speed,{speed}
    Acceleration: Extended;{acceleration}
    SArray,{displacement}
    VArray,{speed}
    AArray: Array[1..200] of Single;{acceleration}
    IsRun: Boolean;
    MySpring: TSpring;
  end;

var
  frmLibMain: TfrmLibMain;

procedure InitLibrary(App, CallForm: THandle);

implementation

uses unitFrmOptions, unitFrmGraphics;

{$R *.dfm}

procedure InitLibrary(App,CallForm:THandle);
{Library initialization}
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;
  frmOptions := TfrmOptions.Create(Application);
  frmGraphics := TfrmGraphics.Create(Application);
  frmLibMain.Show;
end;

procedure TfrmLibMain.DrawBox(x, y, z, dx, dy, dz: Single);
{rectangular parallelepiped}
begin
  glBegin(GL_QUADS);

  glNormal3f(-1, 0, 0);
  glVertex3f(x, y, z);
  glVertex3f(x, y + dy, z);
  glVertex3f(x, y + dy, z + dz);
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
  glVertex3f(x + dx,y + dy, z);
  glVertex3f(x, y + dy, z);

  glNormal3f(0, 0, 1);
  glVertex3f(x, y, z + dz);
  glVertex3f(x + dx, y, z + dz);
  glVertex3f(x + dx, y + dy,z + dz);
  glVertex3f(x, y + dy, z + dz);

  glEnd;
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

procedure TfrmLibMain.SetDefaultWindowsPosition;
{window layout setup}
const
  w = 209;
begin
  with frmGraphics do
  begin
    Top := 0;
    Left := 0;
    Height := Screen.Height;
    Width := Round(Screen.Width / 4);
    Show;
  end;

  with frmLibMain do
  begin
    Top := 0;
    Left := frmGraphics.Width;
    Height := frmGraphics.Height;
    Width := Screen.Width - frmGraphics.Width - w;
  end;

  with frmOptions do
  begin
    Top := 0;
    Left := frmLibMain.Left + frmLibMain.Width;
    Height := frmLibMain.Height;
    Width := w;
    Show;
  end;
end;

procedure TfrmLibMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if frmOptions.Visible then Resize := False;
end;

procedure TfrmLibMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MySpring.Destroy;

  {removing additional forms}
  frmOptions.Destroy;
  frmGraphics.Destroy;

  {OpenGL shutdown}
  gluDeleteQuadric(quadObj);
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle, DC);
  DeleteDC(DC);

  {module shutdown}
  SendMessage(CallerForm, WM_USER, 0, 0);
  Destroy;
end;

procedure TfrmLibMain.FormShow(Sender: TObject);
begin
  SetDefaultWindowsPosition;

  {OpenGL initialization}
  DC := GetDC(Handle);
  SetDCPixelFormat;
  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC, HRC);

  {OpenGL setup}
  glEnable(GL_DEPTH_TEST);
  quadObj := gluNewQuadric;
  gluQuadricDrawStyle(quadObj, GLU_FILL);
  gluQuadricOrientation(quadObj, GLU_OUTSIDE);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_COLOR_MATERIAL);
  RenderTimer.Enabled := True;
end;

procedure TfrmLibMain.FormResize(Sender: TObject);
begin
  glViewPort(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientWidth / ClientHeight, 1, 100);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TfrmLibMain.Calc;
{calculations}
const
  dt = 1 / 4000;
var
  i: Integer;
  preAccel: Extended;
begin
  preSpeed := Speed;

  for i := 1 to RenderTimer.Interval * 4 do
  begin
    preAccel := Acceleration;
    if m <> 0 then
      Acceleration := (m * g - k * S) / m;
    S := S + Speed * dt + preAccel * sqr(dt) / 2;
    Speed := Speed + (Acceleration + preAccel) * dt / 2;
    currPeriod := currPeriod + 1 / 4000;
  end;

  if (preSpeed < 0) and (Speed>=0) then
  begin
    Period := currPeriod;
    currPeriod := 0;
    Freq := 1 / Period;
  end;

  frmOptions.txtDX.Text := FloatToStr(S);
  frmOptions.txtResult.Text := 'Displacement (m): ' + FloatToStrF(S, ffFixed, 10, 5) + #13#10 +
                               'Speed (m/s): ' + FloatToStrF(Speed, ffFixed, 10, 5) + #13#10 +
                               'Acceleration (m/s^2): ' + FloatToStrF(Acceleration, ffFixed, 10, 5) + #13#10 +
                               'Period (s): ' + FloatToStrF(Period, ffFixed, 10, 5) + #13#10 +
                               'Frequency (Hz): ' + FloatToStrF(Freq, ffFixed, 10, 5);
end;

procedure TfrmLibMain.DrawGraphics;
{graphs rendering}
var
  i: Integer;
begin
  {array values shift}
  for i := 1 to 199 do
  begin
    SArray[i] := SArray[i + 1];
    VArray[i] := VArray[i + 1];
    AArray[i] := AArray[i + 1];
  end;

  {adding new values}
  SArray[200] := S;
  VArray[200] := Speed;
  AArray[200] := Acceleration;

  {rendering}
  with frmGraphics do
  begin
    chartDX.Series[0].Clear;
    chartSpeed.Series[0].Clear;
    chartAccel.Series[0].Clear;
    chartDX.Title.Text.Text:='Displacement (m): ' + FloatToStr(S);
    chartSpeed.Title.Text.Text:='Speed (m/s): ' + FloatToStr(Speed);
    chartAccel.Title.Text.Text:='Acceleration (m/s^2): ' + FloatToStr(Acceleration);

    for i := 1 to 200 do
    begin
      chartDX.Series[0].Add(SArray[i]);
      chartSpeed.Series[0].Add(VArray[i]);
      chartAccel.Series[0].Add(AArray[i]);
    end;
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
  glTranslate(0, 0, -70);

  if IsRun then
  begin
    with MySpring do
    begin
      x1 := 15;
      x2 := 15 - defaultLen - S;
      deflen := defaultLen;
      Render;
    end;

    glColor3f(1, 1, 1);
    glPushMatrix;
    glTranslatef(0, 15 - defaultLen - S - 0.5, 0);
    gluSphere(quadObj, 1, 15, 15);
    glPopMatrix;

    DrawBox(-5, 15, -2, 10, 1, 4);
  end;

  EndPaint(Handle, ps);
  SwapBuffers(DC);
end;

procedure TfrmLibMain.RenderTimerTimer(Sender: TObject);
begin
  if IsRun then
  begin
    Calc;
    DrawGraphics;
  end;
  Render;
end;

procedure TfrmLibMain.FormCreate(Sender: TObject);
begin
  IsRun := False;
  MySpring := TSpring.Create;
end;

end.
 