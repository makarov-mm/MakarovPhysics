unit unitFrmLibMain;
{
program: water surface oscillations\nauthor: M.M. Makarov\ncreated: March 2, 2005
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, OpenGL, Vcl.ExtCtrls, MyEngine;

type
  TField = Array[-50..50, -50..50] of Extended;//height
  TfrmLibMain = class(TForm)
    RenderTimer: TTimer;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure RenderTimerTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    CallerForm: THandle;
    DC: HDC;//device context
    HRC: HGLRC;//OpenGL rendering context
    ps: TPaintStruct;
    preX, preY: Integer;//previous mouse position
    IsMouseDown: Boolean;//whether a mouse button is pressed
    ay: Single;//rotation angle
    ax: Single;//vertical rotation angle
    procedure Calc;
    procedure DrawQuad(x1, y1, z1,
                       x2, y2, z2,
                       x3, y3, z3,
                       x4, y4, z4: Single;
                       ii, jj: Integer);
    procedure SetDefWindowsPos;
  public
    A, B: TField;
    n, n1: Array[-50..50, -50..50, 1..3] of Extended;//normals
    vis: Single;//viscosity
    Ydef: Single;//Y displacement
  end;

var
  frmLibMain: TfrmLibMain;

procedure InitLibrary(App, CallForm: THandle);

implementation

uses unitFrmOptions;

{$R *.dfm}

procedure TfrmLibMain.SetDefWindowsPos;
{window layout}
const
  dw = 209;
begin
  with frmLibMain do
  begin
    Left := dw;
    Top := 0;
    Width := Screen.Width - dw;
    Height := Screen.Height;
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

procedure InitLibrary(App, CallForm:THandle);
{Library initialization}
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;
  frmOptions := TfrmOptions.Create(Application);
  frmLibMain.Show;
end;

procedure TfrmLibMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if frmOptions.Visible then Resize := False;
end;

procedure TfrmLibMain.FormClose(Sender: TObject; var Action: TCloseAction);
{module shutdown}
begin
  RenderTimer.Enabled := False;
  frmOptions.Destroy;
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle, DC);
  DeleteDC(DC);
  SendMessage(CallerForm, WM_USER, 0, 0);
  frmLibMain := nil;
end;

procedure TfrmLibMain.DrawQuad(x1, y1, z1,
                               x2, y2, z2,
                               x3, y3, z3,
                               x4, y4, z4: Single;
                               ii, jj: Integer);
{polygon rendering}
var
  i, j, k: Single;
begin
  glBegin(GL_TRIANGLE_FAN);
  i := (x1 + 128) / 256;
  j := (z4 + 128) / 256;
  k := 1 / 256;

  glNormal3f(n[ii, jj + 1, 1], n[ii, jj + 1, 2], n[ii, jj + 1, 3]);
  glTexCoord2d(i, j + k);
  glVertex3f(x1, y1, z1);

  glNormal3f(n[ii + 1, jj + 1, 1], n[ii + 1, jj + 1, 2], n[ii + 1, jj + 1, 3]);
  glTexCoord2d(i + k, j + k);
  glVertex3f(x2, y2, z2);

  glNormal3f(n[ii + 1, jj, 1], n[ii + 1, jj, 2], n[ii + 1, jj, 3]);
  glTexCoord2d(i + k, j);
  glVertex3f(x3, y3, z3);

  glNormal3f(n[ii, jj, 1], n[ii, jj, 2], n[ii, jj, 3]);
  glTexCoord2d(i, j);
  glVertex3f(x4, y4, z4);

  glEnd;
end;

procedure TfrmLibMain.Calc;
{calculations}
var
  i, j, k: Integer;
  laplas: Single;
  C: TField;
begin
  //oscillation calculation
  if frmOptions.rb1.Checked then glBindTexture(GL_TEXTURE_2D, 1);
  if frmOptions.rb2.Checked then glBindTexture(GL_TEXTURE_2D, 8);
  if frmOptions.rb3.Checked then glBindTexture(GL_TEXTURE_2D, 9);
  if frmOptions.rb4.Checked then glBindTexture(GL_TEXTURE_2D, 10);
  if frmOptions.rb5.Checked then glBindTexture(GL_TEXTURE_2D, 11);
  if frmOptions.rb6.Checked then glBindTexture(GL_TEXTURE_2D, 12);
  if frmOptions.rb7.Checked then glBindTexture(GL_TEXTURE_2D, 13);
  if frmOptions.rb8.Checked then glBindTexture(GL_TEXTURE_2D, 14);
  if frmOptions.rb9.Checked then glBindTexture(GL_TEXTURE_2D, 15);
  if frmOptions.rb10.Checked then glBindTexture(GL_TEXTURE_2D, 16);
  if frmOptions.rb11.Checked then glBindTexture(GL_TEXTURE_2D, 17);
  if frmOptions.rb12.Checked then glBindTexture(GL_TEXTURE_2D, 18);
  for i := -50 to 49 do
    for j := -50 to 49 do
    begin
      //normals calculation
      CalcNormal(i + 1, B[i + 1, j + 1], j + 1,
                 i + 1, B[i + 1, j],j,
                 i, B[i, j], j,
                 n[i, j, 1], n[i, j, 2], n[i, j, 3]);
    end;
  //normals averaging
  for i := -49 to 49 do
    for j := -49 to 49 do
      for k := 1 to 3 do
        n1[i, j, k]:=(n[i + 1, j, k] +
                      n[i - 1, j, k] +
                      n[i, j + 1, k] +
                      n[i, j - 1, k]) / 4 - n[i, j, k];
  //rendering
  for i := -47 to 47 do
    for j := -47 to 47 do
      DrawQuad(i, B[i, j], j,
               i + 1,B[i + 1, j], j,
               i + 1,B[i + 1, j + 1], j + 1,
               i, B[i, j + 1], j + 1,
               i, j);
  //calculations
  for i := -49 to 49 do
    for j := -49 to 49 do
    begin
      laplas := (A[i + 1, j] + A[i - 1, j] +
                 A[i , j + 1] + A[i, j - 1]) / 4 - A[i, j];
      B[i, j] := (2 - vis) * A[i, j] - (1 - vis) * B[i, j] + laplas;
    end;
  C := A;
  A := B;
  B := C;
end;

procedure TfrmLibMain.RenderTimerTimer(Sender: TObject);
begin
  BeginPaint(Handle, ps);
  wglMakeCurrent(DC, HRC);
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT);

  //oscillation initiation
  if Random(100) > 85 then
    frmLibMain.A[Random(90) - 45,Random(90) - 45] := frmLibMain.Ydef;

  //texturing
  if frmOptions.CheckBox1.Checked then
    glEnable(GL_TEXTURE_2D)
  else
    glDisable(GL_TEXTURE_2D);

  //lighting
  if frmOptions.cbLighting.Checked then
    glEnable(GL_LIGHTING)
  else
    glDisable(GL_LIGHTING);

  glLoadIdentity;
  glTranslatef(0, 0, -200);
  glRotatef(ay, 0, 1, 0);
  glRotatef(ax, 1, 0, 0);

  glDisable(GL_TEXTURE_GEN_S);
  glDisable(GL_TEXTURE_GEN_T);
  DrawSkyBox(-300, -300, -300, 600, 600, 600, 2, 3, 4, 5, 6, 7);
  
  glEnable(GL_TEXTURE_GEN_S);
  glEnable(GL_TEXTURE_GEN_T);
  glColor3f(0, 0, 1);
  Calc;

  EndPaint(Handle, ps);
  SwapBuffers(DC);
end;

procedure TfrmLibMain.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientHeight / ClientWidth, 1, 1000);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TfrmLibMain.FormCreate(Sender: TObject);
begin
  preX := 0;
  preY := 0;
  ax := 35;
  ay := 25;
  IsMouseDown := False;
end;

procedure TfrmLibMain.FormShow(Sender: TObject);
begin
  wglMakeCurrent(0, 0);
  SetDefWindowsPos;
  DC:=GetDC(Handle);
  SetDCPixelFormat(DC);
  HRC:=wglCreateContext(DC);
  wglMakeCurrent(DC,HRC);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);

  LoadTextureSphere('data\textures\other.dat', 1, 1);
  LoadTextureSphere('data\textures\other.dat', 2, 8);
  LoadTextureSphere('data\textures\other.dat', 3, 9);
  LoadTextureSphere('data\textures\other.dat', 4, 10);
  LoadTextureSphere('data\textures\other.dat', 5, 11);
  LoadTextureSphere('data\textures\other.dat', 6, 12);
  LoadTextureSphere('data\textures\other.dat', 7, 13);
  LoadTextureSphere('data\textures\other.dat', 8, 14);
  LoadTextureSphere('data\textures\other.dat', 9, 15);
  LoadTextureSphere('data\textures\other.dat', 10, 16);
  LoadTextureSphere('data\textures\other.dat', 11, 17);
  LoadTextureSphere('data\textures\other.dat', 12, 18);

  glDisable(GL_TEXTURE_GEN_S);
  glDisable(GL_TEXTURE_GEN_T);

  LoadTexture('data\textures\skybox.dat', 1, 2);
  LoadTexture('data\textures\skybox.dat', 2, 3);
  LoadTexture('data\textures\skybox.dat', 3, 4);
  LoadTexture('data\textures\skybox.dat', 4, 5);
  LoadTexture('data\textures\skybox.dat', 5, 6);
  LoadTexture('data\textures\skybox.dat', 6, 7);

  glClearColor(0, 0, 0, 1);
  RenderTimer.Enabled := True;
end;

procedure TfrmLibMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  IsMouseDown := True;
  preX := X;
  preY := Y;
end;

procedure TfrmLibMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  IsMouseDown := False;
end;

procedure TfrmLibMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if IsMouseDown then
  begin
    ay:=ay + (X - preX);
    preX := X;
    ax := ax + (Y - preY);
    preY := Y;
    if ay > 70 then ay := 70;
    if ay < -70 then ay := -70;
    if ax > 160 then ax := 160;
    if ax < 20 then ax := 20;
  end;
end;

end.
 