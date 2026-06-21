unit unitFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, unitFrmOptions, unitFrmGraphics, OpenGL, OscillSystem;

type
  TfrmLibMain = class(TForm)
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    CallerForm: THandle;{calling form}
    DC: HDC;
    HRC: HGLRC;
    ps: TPaintStruct;
    pfd: TPixelFormatDescriptor;
    nPixelFormat: Integer;
    RenderTimerID: Integer;
    preX: Integer;{previous mouse position}
    IsLMouseKeyDown: Boolean;{whether the left mouse button is pressed}
    rotation: Extended;{coordinate system rotation angle around the Y axis}
    IsRun: Boolean;{whether calculations are running}
    procedure SetDCPixelFormat;
    procedure Render;
    procedure SetDefaultWindowsPosition;
    procedure UpgradeOscillList;
  public
    Oscill: TOscillSystem;{oscillator system}
    procedure DrawBox(x, y, z, dx, dy, dz: Extended);
    procedure AddSpring(Sender: TObject);
    procedure AddSphere(Sender: TObject);
    procedure DelPrev(Sender: TObject);
    procedure DelAll(Sender: TObject);
    procedure Start(Sender: TObject);
    procedure Stop(Sender: TObject);
  end;

var
  frmLibMain: TfrmLibMain;

procedure InitLibrary(App, CallForm: THandle);

implementation

{$R *.dfm}

procedure InitLibrary(App, CallForm: THandle);
{Library initialization}
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;

  {create additional forms}
  frmOptions := TfrmOptions.Create(Application);
  frmGraphics := TfrmGraphics.Create(Application);
  frmOptions.btnAddSpring.OnClick := frmLibMain.AddSpring;
  frmOptions.btnAddMass.OnClick := frmLibMain.AddSphere;
  frmOptions.btnDelPrev.OnClick := frmLibMain.DelPrev;
  frmOptions.btnDelAll.OnClick := frmLibMain.DelAll;
  frmOptions.btnStart.OnClick := frmLibMain.Start;
  frmOptions.btnStop.OnClick := frmLibMain.Stop;
  frmLibMain.Show;
end;

procedure TfrmLibMain.UpgradeOscillList;
{refresh the weight list in frmGraphics.ComboBox1}
var
  i: Integer;
begin
  frmGraphics.cbWeight.Clear;
  if Oscill.HowManySpheres > 0 then
    for i := 1 to Oscill.HowManySpheres do
      frmGraphics.cbWeight.AddItem('Weight ' + IntToStr(i), Self);
  frmGraphics.cbWeight.ItemIndex := 0;
end;

procedure TfrmLibMain.AddSpring(Sender: TObject);
{add spring}
var
  k, len, dx: Extended;
begin
  frmOptions.CorrectDelimiters;
  k := 0; len := 0; dx := 0;
  try
    k := StrToFloat(frmOptions.txtK.Text);
    len := StrToFloat(frmOptions.txtLength.Text);
    dx := StrToFloat(frmOptions.txtDx.Text);
  except
    MessageBox(Handle, 'Invalid values specified', 'Error', 0);
  end;
  if (k > 0) and (len > 0) then
  begin
    Oscill.AddSpring(k, len, dx);
    UpgradeOscillList;
  end else
    MessageBox(Handle, 'Invalid values specified', 'Error', 0);
end;

procedure TfrmLibMain.AddSphere(Sender: TObject);
{add weight}
var
  mass, radius: Extended;
begin
  frmOptions.CorrectDelimiters;
  mass := 0; radius := 0;
  try
    mass := StrToFloat(frmOptions.txtMass.Text);
    radius := StrToFloat(frmOptions.txtRadius.Text);
  except
    MessageBox(Handle, 'Invalid values specified', 'Error', 0);
  end;
  if (mass > 0) and (radius > 0) then
  begin
    Oscill.AddSphere(mass, radius);
    UpgradeOscillList;
  end else
    MessageBox(Handle, 'Invalid values specified', 'Error', 0);
end;

procedure TfrmLibMain.DelPrev(Sender: TObject);
{delete the previous object}
begin
  Oscill.DelPrev;
  UpgradeOscillList;
end;

procedure TfrmLibMain.DelAll(Sender: TObject);
{delete all}
begin
  Oscill.DelAll;
  UpgradeOscillList;
end;

procedure TfrmLibMain.Start(Sender: TObject);
{Start!}
begin
  frmOptions.CorrectDelimiters;
  If Oscill.IsReady then
    IsRun := True
  else
    MessageBox(Handle, 'Cannot start the system in this configuration',
                       'Error', MB_OK);
end;

procedure TfrmLibMain.Stop(Sender: TObject);
{Stop}
begin
  IsRun := False;
end;

procedure TfrmLibMain.SetDCPixelFormat;
{pixel format setup}
begin
  FillChar(pfd, SizeOf(pfd), 0);
  pfd.dwFlags := PFD_SUPPORT_OPENGL or
                 PFD_DRAW_TO_WINDOW or
                 PFD_DOUBLEBUFFER;
  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);
end;

procedure TfrmLibMain.DrawBox(x, y, z, dx, dy, dz: Extended);
{rectangular parallelepiped}
begin
  glBegin(GL_QUADS);

  glNormal3f(-1, 0, 0);
  glVertex3f(x, y, z);
  glVertex3f(x, y + dy,z);
  glVertex3f(x, y + dy,z + dz);
  glVertex3f(x, y, z + dz);

  glNormal3f(1, 0, 0);
  glVertex3f(x + dx, y, z);
  glVertex3f(x + dx, y + dy, z);
  glVertex3f(x + dx, y + dy,z + dz);
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
  glVertex3f(x + dx, y + dy, z);
  glVertex3f(x, y + dy, z);

  glNormal3f(0, 0, 1);
  glVertex3f(x, y, z + dz);
  glVertex3f(x + dx, y, z + dz);
  glVertex3f(x + dx, y + dy, z + dz);
  glVertex3f(x, y + dy, z + dz);

  glEnd;
end;

procedure TfrmLibMain.Render;
{rendering}
begin
  wglMakeCurrent(DC, HRC);
  BeginPaint(Handle, ps);
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glTranslatef(0, -2, -frmOptions.tbDistance.Position);
  glRotatef(rotation, 0, 1, 0);
  {======================================}

  {rectangular parallelepipeds rendering}
  DrawBox(-frmOptions.tbLength.Position / 2 - 1, -0.5, -3, 1, 1, 6);
  DrawBox(frmOptions.tbLength.Position / 2, -0.5, -3, 1, 1, 6);

  {oscillator system rendering}
  Oscill.minX := -frmOptions.tbLength.Position / 2;
  Oscill.maxX := frmOptions.tbLength.Position / 2;
  IsRun := Oscill.Render(IsRun, frmOptions.cbCollisions.Checked);

  {graphs rendering}
  Oscill.DrawGraphic(frmGraphics.cbWeight.ItemIndex,
                     frmGraphics.tabs.TabIndex);

  {======================================}
  EndPaint(Handle,ps);
  SwapBuffers(DC);
end;

procedure TfrmLibMain.SetDefaultWindowsPosition;
{default window layout setup}
const
  dw = 209;
  dh = 0.7;
begin
  with frmLibMain do
  begin
    Left := dw;
    Top := 0;
    Width := Screen.Width - dw;
    Height := Round(Screen.Height * dh);
  end;

  with frmOptions do
  begin
    Left := 0;
    Top := 0;
    Width := dw;
    Height := Screen.Height;
    Show;
  end;

  with frmGraphics do
  begin
    Left := dw;
    Top := frmLibMain.Height;
    Width := Screen.Width - dw;
    Height := Screen.Height - frmLibMain.Height;
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
  {destroying the rendering timer}
  KillTimer(Handle, RenderTimerID);

  {OpenGL shutdown}
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle, DC);
  DeleteDC(DC);

  {destroying the oscillator system}
  Oscill.Destroy;

  {destroying forms}
  frmOptions.Destroy;
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
var
  material, light: Array[0..3] of GLFloat;
begin
  IsRun := False;
  rotation := 0;
  IsLMouseKeyDown := False;
  preX := 0;

  {OpenGL initialization}
  DC := GetDC(Handle);
  SetDCPixelFormat;
  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC, HRC);

  {OpenGL setup}
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glClearColor(0, 0, 0, 1);
  material[0] := 0.3;
  material[1] := 0.3;
  material[2] := 0.3;
  material[3] := 1;
  light[0] := 0;
  light[1] := 1;
  light[2] := 0;
  light[3] := 1;
  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, @material);
  glLightfv(GL_LIGHT0, GL_POSITION, @light);

  {create the oscillator system}
  Oscill := TOscillSystem.Create(Handle);
  Oscill.minX := -frmOptions.tbLength.Position / 2;
  Oscill.maxX := frmOptions.tbLength.Position / 2;

  {window layout setup}
  SetDefaultWindowsPosition;

  {start rendering timer}
  Randomize;
  RenderTimerID := Random(10000);
  SetTimer(Handle, RenderTimerID, 40, @RenderTimerTick);
end;

procedure TfrmLibMain.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientWidth / ClientHeight, 1, 200);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TfrmLibMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  IsLMouseKeyDown := True;
  preX := X;
end;

procedure TfrmLibMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  IsLMouseKeyDown := False;
end;

procedure TfrmLibMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if IsLMouseKeyDown then
  begin
    rotation := rotation + (X - preX);
    preX := X;
  end;
end;

end.
 