unit unitFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, unitFrmOptions, Math, Fields;

type
  TfrmLibMain = class(TForm)
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    CallerForm: THandle;{calling form}
    pfd: TPixelFormatDescriptor;
    nPixelFormat: Integer;
    DC: HDC;
    HRC: HGLRC;
    ps: TPaintStruct;
    RenderTimerID: Integer;{rendering timer ID}
    quadObj: GLUQuadricObj;
    procedure Render;
    procedure SetDCPixelFormat;
    procedure SetDefaultWindowsPosition;
  public
    QPosition: array of record {array of charges}
                x, y: Single;{position}
                q: Single;{charge}
              end;
    NumbOfQ: Integer;{number of charges}
    Field: IFields;
    procedure Calc(Sender:TObject);
  end;

var
  frmLibMain: TfrmLibMain;

procedure InitLibrary(App,CallForm:THandle);

implementation

{$R *.dfm}

procedure TfrmLibMain.Calc(Sender:TObject);
{calculations}
var
  i: Integer;
  q: Single;
begin
  frmOptions.btnCalc.Enabled := False;
  Application.ProcessMessages;

  Field := nil;
  
  {set the size of the charges array}
  NumbOfQ := frmOptions.tbQCount.Position;
  SetLength(QPosition, NumbOfQ);

  frmOptions.pbCalc.Position := 0;
  frmOptions.pbCalc.Max := NumbOfQ * 2;
  Application.ProcessMessages;

  {place the charges}
  q := 1;
  for i := 0 to NumbOfQ - 1 do
  begin
    if frmOptions.rbSignChange.Checked then
      q := -q;
    QPosition[i].q := q;
    QPosition[i].x := cos(DegToRad((360 / NumbOfQ) * i)) * 2.5;
    QPosition[i].y := sin(DegToRad((360 / NumbOfQ) * i)) * 2.5;

    frmOptions.pbCalc.Position := i;
    Application.ProcessMessages;
    Sleep(10);
    Application.ProcessMessages;
  end;

  {compute the field}
  if frmOptions.cbMakeLines.Checked then
  begin
    Field := TFields.Create(frmOptions.tbLinesPerQ.Position);
    for i := 0 to NumbOfQ - 1 do
    begin
      Field.AddElement(QPosition[i].x,
                       QPosition[i].y,
                       Round(QPosition[i].q));

      frmOptions.pbCalc.Position := NumbOfQ + i;
      Application.ProcessMessages;
      Sleep(10);
      Application.ProcessMessages;
    end;
    Field.Calc;
  end;

  {render into the display list}
  glNewList(1, GL_COMPILE);
  Field.Render;
  glEndList;

  glNewList(2, GL_COMPILE);
  glEnable(GL_LIGHTING);
  if NumbOfQ <> 0 then
    for i := 0 to NumbOfQ - 1 do
    begin
      if QPosition[i].q > 0 then
        glColor3f(1, 0, 0)
      else
        glColor3f(0, 0, 1);
      glPushMatrix;
      glTranslatef(QPosition[i].x, QPosition[i].y, 0);
      gluSphere(quadObj, 0.15, 15, 15);
      glPopMatrix;
    end;
  glEndList;

  frmOptions.pbCalc.Position := frmOptions.pbCalc.Max;
  Application.ProcessMessages;

  frmOptions.btnCalc.Enabled := True;
end;

procedure InitLibrary(App,CallForm:THandle);
{Library initialization}
begin
  Application.Handle := App;
  frmLibMain := TfrmLibMain.Create(Application);
  frmLibMain.CallerForm := CallForm;
  frmOptions := TfrmOptions.Create(Application);
  frmOptions.btnCalc.OnClick := frmLibMain.Calc;
  frmLibMain.Show;
end;

procedure TfrmLibMain.SetDCPixelFormat;
{pixel format setup}
begin
  FillChar(pfd,SizeOf(pfd),0);
  pfd.dwFlags := PFD_SUPPORT_OPENGL or
                 PFD_DRAW_TO_WINDOW or
                 PFD_DOUBLEBUFFER;
  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC,nPixelFormat, @pfd);
end;

procedure TfrmLibMain.SetDefaultWindowsPosition;
{default window layout setup}
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

procedure TfrmLibMain.Render;
{rendering}
begin
  Application.ProcessMessages;
  wglMakeCurrent(DC, HRC);
  BeginPaint(Handle, ps);
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glTranslatef(0, 0, -frmOptions.tbDistance.Position);

  glCallList(2);
    
  if Field <> nil then
    glCallList(1);

  EndPaint(Handle, ps);
  SwapBuffers(DC);
  Application.ProcessMessages;
end;

procedure RenderTimerTick(AHwnd: HWND; AMsg: UINT; AEvent: UINT_PTR; ATime: DWORD); stdcall;
begin
  frmLibMain.Render;
end;

procedure TfrmLibMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if frmOptions.Visible then Resize := False; 
end;

procedure TfrmLibMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {removing rendering timer}
  KillTimer(Handle, RenderTimerID);

  {removing a quadric object}
  gluDeleteQuadric(quadObj);

  {OpenGL shutdown}
  wglMakeCurrent(0, 0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle, DC);
  DeleteDC(DC);

  {module shutdown}
  frmOptions.Destroy;
  SendMessage(CallerForm, WM_USER, 0, 0);
  Destroy;
end;

procedure TfrmLibMain.FormShow(Sender: TObject);
begin
  {OpenGL initialization}
  DC := GetDC(Handle);
  SetDCPixelFormat;
  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC, HRC);

  {OpenGL setup}
  glClearColor(0, 0, 0, 1);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_POINT_SMOOTH);
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);

  {creating a quadric object}
  quadObj := gluNewQuadric;
  gluQuadricDrawStyle(quadObj, GLU_FILL);
  gluQuadricOrientation(quadObj, GLU_OUTSIDE);

  {window layout setup}
  SetDefaultWindowsPosition;

  {rendering timer initialization}
  Randomize;
  RenderTimerID := Random(1000) + 500;
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

procedure TfrmLibMain.FormCreate(Sender: TObject);
begin
  Field := nil;
end;

end.
 