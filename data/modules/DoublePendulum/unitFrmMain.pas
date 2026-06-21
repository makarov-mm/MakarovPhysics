unit unitFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, Math;

type
  vector=record{vector}
    x,y:Extended;
  end;

  Pendulum=record{pendulum}
    Len:Extended;{thread length}
    mass:Extended;{weight mass}
    Position:vector;{coordinates}
    FixedPos:vector;{attachment point coordinates}
    Angle:Extended;{deflection angle}
    Speed:Extended;{speed}
    Acceleration:Extended;{acceleration}
    preAngle:Extended;{previous angle}
    preSpeed:Extended;{previous speed}
    preAcceleration:Extended;{previous acceleration}
  end;

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
    nPixelFormat: Integer;
    pfd: TPixelFormatDescriptor;{pixel format}
    ps: TPaintStruct;
    quadObj1, quadObj2: GLUquadricObj;{quadric objects}
    ArrOfAngle,
    ArrOfSpeed,
    ArrOfAccel: Array[1..2,1..250] of Extended;
    infostep: Integer;{info output counter}
    procedure SetStandartWindowsPosition;
    procedure SetDCPixelFormat;
    procedure Render;
    procedure DrawGrid;
    procedure CalcPendulums;
    procedure Verlet;
    procedure Accel;
    procedure DrawGraphic;
    procedure DrawPhaseTraectory;
    procedure UpdateArrays;
  public
    Pendulums: Array[1..2] of Pendulum;{pendulums}
    IsRun,IsPaused: Boolean;
    procedure ClearArrays;
  end;

var
  frmLibMain: TfrmLibMain;

procedure InitLibrary(App, CallForm:THandle);

implementation

uses unitFrmTools, unitFrmResults, unitFrmGraphics, unitFormPhaseTraectory;

{$R *.dfm}

procedure InitLibrary(App,CallForm:THandle);
{Library initialization}
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;
  {create additional forms}
  frmTools := TfrmTools.Create(Application);
  frmResults := TfrmResults.Create(Application);
  frmGraphics := TfrmGraphics.Create(Application);
  frmPhaseTraectory := TfrmPhaseTraectory.Create(Application);
  frmLibMain.Show;
end;

procedure TfrmLibMain.UpdateArrays;
{array update}
var
  i, j: Integer;
begin
  for i := 1 to 2 do
  begin
    for j := 1 to 249 do
    begin
      ArrOfAngle[i, j] := ArrOfAngle[i, j + 1];
      ArrOfSpeed[i, j] := ArrOfSpeed[i, j + 1];
      ArrOfAccel[i, j] := ArrOfAccel[i, j + 1];
    end;
    ArrOfAngle[i, 250] := Pendulums[i].Angle;
    ArrOfSpeed[i, 250] := Pendulums[i].Speed;
    ArrOfAccel[i, 250] := Pendulums[i].Acceleration;
  end;
end;

procedure TfrmLibMain.ClearArrays;
{clear arrays}
var
  i, j: Integer;
begin
  for i:=1 to 2 do
    for j:=1 to 250 do
    begin
      ArrOfAngle[i,j] := 0;
      ArrOfSpeed[i,j] := 0;
      ArrOfAccel[i,j] := 0;
    end;
end;

procedure TfrmLibMain.DrawGraphic;
{graphs rendering}
var
  i:Integer;
begin
  frmGraphics.chartPendulum1.Series[0].Clear;
  frmGraphics.chartPendulum2.Series[0].Clear;
  case frmGraphics.tabs.TabIndex of
    0: begin
         frmGraphics.chartPendulum1.Title.Text.Text:='Angle (Pendulum 1) [deg]';
         frmGraphics.chartPendulum2.Title.Text.Text:='Angle (Pendulum 2) [deg]';
         for i:=1 to 250 do
         begin
           frmGraphics.chartPendulum1.Series[0].Add(ArrOfAngle[1,i]);
           frmGraphics.chartPendulum2.Series[0].Add(ArrOfAngle[2,i]);
         end;
       end;
    1: begin
         frmGraphics.chartPendulum1.Title.Text.Text:='Angular speed (Pendulum 1) [deg/s]';
         frmGraphics.chartPendulum2.Title.Text.Text:='Angular speed (Pendulum 2) [deg/s]';
         for i:=1 to 250 do
         begin
           frmGraphics.chartPendulum1.Series[0].Add(ArrOfSpeed[1,i]);
           frmGraphics.chartPendulum2.Series[0].Add(ArrOfSpeed[2,i]);
         end;
       end;
    2: begin
         frmGraphics.chartPendulum1.Title.Text.Text:='Angular acceleration (Pendulum 1) [deg/s^2]';
         frmGraphics.chartPendulum2.Title.Text.Text:='Angular acceleration (Pendulum 2) [deg/s^2]';
         for i:=1 to 250 do
         begin
           frmGraphics.chartPendulum1.Series[0].Add(ArrOfAccel[1,i]);
           frmGraphics.chartPendulum2.Series[0].Add(ArrOfAccel[2,i]);
         end;
       end;
  end;
end;

procedure TfrmLibMain.DrawPhaseTraectory;
{phase trajectories rendering}
var
  i: Integer;
begin
  frmPhaseTraectory.chartPhase1.Series[0].Clear;
  frmPhaseTraectory.chartPhase2.Series[0].Clear;
  for i := 1 to 250 do
  begin
    frmPhaseTraectory.chartPhase1.Series[0].AddXY(ArrOfAngle[1, i],ArrOfSpeed[1, i]);
    frmPhaseTraectory.chartPhase2.Series[0].AddXY(ArrOfAngle[2, i],ArrOfSpeed[2, i]);
  end;
end;


procedure TfrmLibMain.Verlet;
var
  tf: Array[1..2] of Extended;
  i,k: Integer;
  dt: Double;

  procedure put;
  var
    j: Integer;
  begin
    for j := 1 to 2 do
    begin
      Pendulums[j].preSpeed := Pendulums[j].Speed;
      Pendulums[j].preAngle := Pendulums[j].Angle;
    end;
  end;

begin
  dt := 1 / 4000;
  for k := 1 to 160 do
  begin
    put;
    Accel;

    for i := 1 to 2 do
      tf[i] := Pendulums[i].preAcceleration;

    for i := 1 to 2 do
    begin
      Pendulums[i].Angle :=
        Pendulums[i].preAngle +
        Pendulums[i].preSpeed * dt+
        Pendulums[i].Acceleration * sqr(dt) / 2;
      Pendulums[i].Speed :=
        Pendulums[i].preSpeed +
        Pendulums[i].Acceleration * dt;
    end;

    put;
    Accel;

    for i := 1 to 2 do
    begin
      tf[i] := (tf[i] + Pendulums[i].Acceleration) / 2;
      Pendulums[i].Speed :=
        Pendulums[i].Speed +
        tf[i] * dt;
      Pendulums[i].Angle :=
        Pendulums[i].Angle +
        Pendulums[i].Speed * dt +
        tf[i] * sqr(dt) / 2;
      if Pendulums[i].Angle > 360 then
        Pendulums[i].Angle :=
          Frac(Pendulums[i].Angle / 360) * 360;
      if Pendulums[i].Angle < -360 then
        Pendulums[i].Angle :=
          Frac(Pendulums[i].Angle / (-360)) * (-360);
    end;
  end;

  {array update}
  UpdateArrays;
end;

procedure TfrmLibMain.Accel;
const
  g = 9.81;
var
  t, ts, t2: Extended;
begin
  t := cos(DegToRad(Pendulums[1].preAngle) -
    DegToRad(Pendulums[2].preAngle));
  ts := sin(DegToRad(Pendulums[1].preAngle) -
    DegToRad(Pendulums[2].preAngle));
  t2 := sin(DegToRad(Pendulums[2].preAngle) -
    DegToRad(Pendulums[1].preAngle));

  Pendulums[1].Acceleration := RadToDeg(
    -(Pendulums[2].mass / Pendulums[1].mass) * t *
    (Pendulums[2].Len / Pendulums[1].Len) *
    DegToRad(Pendulums[2].preAcceleration) -
    (Pendulums[2].mass / Pendulums[1].mass) *
    sqr(DegToRad(Pendulums[2].preSpeed)) *
    (Pendulums[2].Len/Pendulums[1].Len) * ts-
    (g/Pendulums[1].Len) * sin(DegToRad(Pendulums[1].preAngle)) );

  Pendulums[2].Acceleration := RadToDeg(
    -(Pendulums[1].Len / Pendulums[2].Len) *
    DegToRad(Pendulums[1].preAcceleration) * t -
    sqr(DegToRad(Pendulums[1].preSpeed)) *
    (Pendulums[1].Len/Pendulums[2].Len) * t2-
    (g/Pendulums[2].Len) * sin(DegToRad(Pendulums[2].preAngle)) );
end;

procedure TfrmLibMain.DrawGrid;
{grid rendering}
var
  i: Integer;
begin
  glDisable(GL_LIGHTING);
  glColor3f(0.3, 0.3, 0.3);
  glBegin(GL_LINES);
  for i := -50 to 50 do
    if i <> 0 then
    begin
      glVertex3f(i / 2, -50, 0);
      glVertex3f(i / 2, 50, 0);
      glVertex3f(-50, i / 2, 0);
      glVertex3f(50, i / 2, 0);
    end;
  glColor3f(0.3, 1, 0.3);
  glVertex3f(0, -50, 0);
  glVertex3f(0, 50, 0);
  glColor3f(1, 0.3, 0.3);
  glVertex3f(-50, 0, 0);
  glVertex3f(50, 0, 0);
  glEnd;
  glEnable(GL_LIGHTING);
end;

procedure TfrmLibMain.SetStandartWindowsPosition;
{window layout setup}
const
  dw = 209;
  dh1 = 0.25;
  dh2 = 0.25;
begin
  with frmLibMain do
  begin
    Left := dw;
    Top := 0;
    Height := Round(Screen.Height * (1 - (dh1 + dh2)));
    Width := Screen.Width - dw;
  end;

  with frmTools do
  begin
    Left := 0;
    Top := 0;
    Height := Screen.Height;
    Width := dw;
    Show;
  end;

  with frmGraphics do
  begin
    Left := frmTools.Width;
    Top := frmLibMain.Height;
    Width := frmLibMain.Width;
    Height := Round(Screen.Height*dh1);
    Show;
  end;

  with frmResults do
  begin
    Left := dw;
    Top := frmGraphics.Height + frmLibMain.Height;
    Width := Round((Screen.Width - dw) / 2);
    Height := Screen.Height - frmLibMain.Height - frmGraphics.Height;
    Show;
  end;

  with frmPhaseTraectory do
  begin
    Left := dw + frmResults.Width;
    Top := frmResults.Top;
    Width := Screen.Width - dw - frmResults.Width;
    Height := frmResults.Height;
    Show;
  end;
end;

procedure TfrmLibMain.SetDCPixelFormat;
{pixel format setup}
begin
  FillChar(pfd,SizeOf(pfd), 0);
  pfd.dwFlags := PFD_SUPPORT_OPENGL or
                 PFD_DRAW_TO_WINDOW or
                 PFD_DOUBLEBUFFER;
  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);
end;

procedure TfrmLibMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if frmResults.Visible then Resize := False;
end;

procedure TfrmLibMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {removing rendering timer}
  KillTimer(Handle, 456);

  {removing Quadric objects}
  gluDeleteQuadric(quadObj1);
  gluDeleteQuadric(quadObj2);

  {OpenGL shutdown}
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle,DC);
  DeleteDC(DC);

  {removing windows}
  frmTools.Destroy;
  frmResults.Destroy;
  frmGraphics.Destroy;
  frmPhaseTraectory.Destroy;

  {module shutdown}
  SendMessage(CallerForm, WM_USER, 0, 0);
  Destroy;
end;

procedure TfrmLibMain.CalcPendulums;
{coordinate calculation from deflection angles}
begin
  if IsRun and not IsPaused then Verlet;
  with Pendulums[1] do
  begin
    Position.x := Len * sin(DegToRad(Angle));
    Position.y := Len * cos(DegToRad(Angle));
  end;
  Pendulums[2].FixedPos.x := Pendulums[1].Position.x;
  Pendulums[2].FixedPos.y := Pendulums[1].Position.y;
  with Pendulums[2] do
  begin
    Position.x := FixedPos.x + Len * sin(DegToRad(Angle));
    Position.y := FixedPos.y + Len * cos(DegToRad(Angle));
  end;
end;

procedure TfrmLibMain.Render;
const
  qw = 5;{displacement along the Y axis}
  infolimit = 5;{info output moment}
begin
  wglMakeCurrent(DC, HRC);
  BeginPaint(Handle, ps);
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glTranslatef(0, -3, -frmTools.tbDistance.Position);

  {pendulum calculation}
  CalcPendulums;

  {graphs rendering}
  DrawGraphic;

  {phase trajectories rendering}
  DrawPhaseTraectory;

  {grid rendering}
  if frmTools.cbGrid.Checked then
    DrawGrid;

  {information output}
  inc(infostep);
  if infostep > infolimit then
  begin
    infostep := 0;
    frmResults.txtResults.Text := 'Pendulum 1' + #13#10 +
      'Angle: ' + FloatToStr(Pendulums[1].Angle) + ' (deg)' + #13#10 +
      'Angular speed: ' + FloatToStr(Pendulums[1].Speed) + ' (deg/s)' + #13#10+
      'Angular acceleration: ' + FloatToStr(Pendulums[1].Acceleration) + ' (deg/s^2)'
      + #13#10#13#10 +
      'Pendulum 2' + #13#10 +
      'Angle: ' + FloatToStr(Pendulums[2].Angle) + ' (deg)' + #13#10 +
      'Angular speed: ' + FloatToStr(Pendulums[2].Speed) + ' (deg/s)' + #13#10 +
      'Angular acceleration: ' + FloatToStr(Pendulums[2].Acceleration) + ' (deg/s^2)';
  end;

  {rendering of pendulum suspension threads}
  glColor3f(1, 1, 1);
  if frmTools.cbViewPend.Checked then
  begin
    glDisable(GL_LIGHTING);
    glBegin(GL_LINES);
      glVertex3f(0, 0 + qw, 0.1);
      glVertex3f(Pendulums[1].Position.x,
                 -Pendulums[1].Position.y + qw,
                 0.2);
      glVertex3f(Pendulums[2].FixedPos.x,
                 -Pendulums[2].FixedPos.y + qw,
                 0.2);
      glVertex3f(Pendulums[2].Position.x,
                 -Pendulums[2].Position.y + qw,
                 0.2);
    glEnd;
    glEnable(GL_LIGHTING);
  end;

  {weights rendering}
  if frmTools.cbViewMass.Checked then
  begin
    glPushMatrix;
    glTranslatef(Pendulums[1].FixedPos.x,
                 -Pendulums[1].FixedPos.y + qw,
                 0.1);
    gluSphere(quadObj1,frmTools.tbMassSize.Position/50, 25, 25);
    glPopMatrix;
    glPushMatrix;
    glTranslatef(Pendulums[1].Position.x,
                 -Pendulums[1].Position.y+qw,
                 0.1);
    gluSphere(quadObj1,frmTools.tbMassSize.Position / 40, 25, 25);
    glPopMatrix;
    glPushMatrix;
    glTranslatef(Pendulums[2].Position.x,
                 -Pendulums[2].Position.y + qw,
                 0.1);
    gluSphere(quadObj2,frmTools.tbMassSize.Position / 40, 25, 25);
    glPopMatrix;
  end;


  EndPaint(Handle,ps);
  SwapBuffers(DC);
end;

procedure RenderTimerTick(AHwnd: HWND; AMsg: UINT; AEvent: UINT_PTR; ATime: DWORD); stdcall;
begin
  frmLibMain.Render;
end;

procedure TfrmLibMain.FormShow(Sender: TObject);
var
  material: Array[0..3] of GLfloat;
  i: Integer;
begin
  IsRun := False;
  IsPaused := False;
  for i := 1 to 2 do
    with Pendulums[i] do
    begin
      Len := 2;
      mass := 1;
      Angle := 30;
      Speed := 0;
    end;
  Pendulums[2].Angle := 75;

  {OpenGL initialization}
  DC := GetDC(Handle);
  SetDCPixelFormat;
  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC,HRC);
  {OpenGL setup}

  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  material[0] := 0.1;
  material[1] := 0.1;
  material[2] := 0.1;
  material[3] := 1;
  glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, @material);

  {creating Quadric objects}
  quadObj1:=gluNewQuadric;
  gluQuadricDrawStyle(quadObj1, GLU_FILL);
  gluQuadricOrientation(quadObj1, GLU_OUTSIDE);
  quadObj2:=gluNewQuadric;
  gluQuadricDrawStyle(quadObj2, GLU_FILL);
  gluQuadricOrientation(quadObj2, GLU_OUTSIDE);

  {window layout setup}
  SetStandartWindowsPosition;

  {rendering timer initialization}
  SetTimer(Handle, 456, 40, @RenderTimerTick);
end;

procedure TfrmLibMain.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientWidth / ClientHeight, 1, 100);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

end.
 