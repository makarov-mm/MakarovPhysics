unit unitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, MyEngine, StdCtrls, XPMan, ComCtrls, ExtCtrls, Math;

type
  TLibProc = procedure (App, CallForm:THandle);
  TfrmMain = class(TForm)
    pnlMain: TPanel;
    imgLoading: TImage;
    pbLoading: TProgressBar;
    XPManifest1: TXPManifest;
    lblLoading: TLabel;
    RenderTimer: TTimer;
    lblVersion: TLabel;
    imgME: TImage;
    lblDesigned1: TLabel;
    lblDesigned2: TLabel;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RenderTimerTimer(Sender: TObject);
    procedure WMUser(var Msg: TMessage);message WM_USER;
    procedure FormCreate(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    DC: HDC;
    HRC: HGLRC;
    Handles: Array[1..10] of LongWord;
    rotate: Integer;    // current carousel angle
    mouseX: Integer;    // last cursor X (drives rotation); -1 until first move
    hovered: Integer;   // panel under the cursor, 0 if none
    InitLibrary: TLibProc;
    isloaded: Boolean;
    procedure LoadModule(number: Integer);
    function PickPanel(X, Y: Integer): Integer;
    procedure DrawPanels(SelectMode: Boolean);
  end;

const
  loadDelay = 100;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.WMUser(var Msg:TMessage);
begin
  Enabled := True;
  mouseX := ClientWidth div 2;   // do not auto-spin right after returning
  hovered := 0;
  RenderTimer.Enabled := True;
end;

procedure TfrmMain.LoadModule(number:Integer);
begin
  wglMakeCurrent(0, 0);
  @InitLibrary := GetProcAddress(Handles[number], 'InitLibrary');
  if @InitLibrary <> nil then
  begin
    RenderTimer.Enabled := False;
    Enabled := False;
    InitLibrary(Application.Handle, Handle);
  end else
    MessageBox(Handle, 'Can''t find InitLibrary procedure', 'Error', MB_OK or MB_ICONERROR);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 27 then   // Esc
    Close;
end;

procedure IncProgressBar;
begin
  frmMain.pbLoading.Position := frmMain.pbLoading.Position + 1;

  if frmMain.pbLoading.Position = 100 then
    frmMain.pbLoading.Position := 0;

  Application.ProcessMessages;
end;

procedure Loading2;
var
  libarr: Array of string;
  s: String;
  i,j: Integer;
  f: TextFile;
begin
  with frmMain do
  begin
    i := 0;

    try
      AssignFile(f, 'data\engine\modules.cfg');
      Reset(f);
      lblLoading.Caption := 'Modules list initialization';
      Sleep(loadDelay);
      Application.ProcessMessages;
      IncProgressBar;

      while not EOF(f) do
      begin
        ReadLn(f,s);
        if (Length(s) > 1) and (s[1] <> '/') and (s[2] <> '/') then
        begin
          inc(i);
          SetLength(libarr,i);
          libarr[i - 1] := s;
          IncProgressBar;
        end;
      end;
    except
      MessageBox(Handle, 'Error while "data\engine\modules.cfg" reading', 'Error', MB_OK or MB_ICONERROR);
      Close;
    end;

    if i > 0 then
      for j := 1 to i do
      begin
        lblLoading.Caption := 'Module ' + libarr[j - 1] + ' loading';
        IncProgressBar;
        Sleep(loadDelay);
        Application.ProcessMessages;
        s := libarr[j - 1];
        Handles[j] := LoadLibrary(PChar(s));
      end;
    Finalize(libarr);
    CloseFile(f);

    lblLoading.Caption := 'Display lists initialization';
    frmMain.pbLoading.Position := 80;
    
    Sleep(loadDelay);
    Application.ProcessMessages;
    Sleep(1000);
    Application.ProcessMessages;

    glNewList(1,GL_COMPILE);
      DrawOneSideTexturedBox(-4.5, -4.5, -0.25, 9, 9, 0.5);
    glEndList;

    glNewList(2,GL_COMPILE);
      DrawSkyBox(-80, -80, -80, 160, 160, 160, 1, 2, 3, 4, 5, 6);
    glEndList;
  end;
  frmMain.isloaded := True;

  frmMain.lblLoading.Caption := 'Start...';
  frmMain.pbLoading.Position := 100;
  for i := 0 to 2 do
  begin
    Application.ProcessMessages;
    Sleep(500);
  end;

  with frmMain do
  begin
    imgME.Hide;
    lblDesigned1.Hide;
    lblDesigned2.Hide;
  end;
end;

procedure Loading(AHwnd: HWND; AMsg: UINT; AEvent: UINT_PTR; ATime: DWORD); stdcall;
var
  texarr: Array of Array[1..3] of ShortString;
  s: ShortString;
  i, j, k: Integer;
  x: Boolean;
  f: TextFile;
begin
  with frmMain do
  begin
    KillTimer(Handle, 1);

    with pnlMain do
    begin
      Left := Round((frmMain.ClientWidth - Width) / 2);
      Top := Round((frmMain.ClientHeight - Height) / 2);
      Show;
    end;

    lblLoading.Caption := 'Textures initialization';
    IncProgressBar;
    Sleep(loadDelay);
    Application.ProcessMessages;

    i:=0;
    try
      AssignFile(f, 'data\engine\maintex.cfg');
      Reset(f);
      while not EOF(f) do
      begin
        ReadLn(f,s);
        if (Length(s) > 1) and (s[1] <> '/') and (s[2] <> '/') then
        begin
          inc(i);
          SetLength(texarr, i);
          j := 1;
          k := 1;
          x := False;
          IncProgressBar;

          while (j <= Length(s)) do
          begin
            if (s[j] = ' ') and (x = False) then
            begin
              x := True;
              inc(k);
            end;

            if s[j] <> ' ' then x := False;
            texarr[i-1,k] := texarr[i-1,k] + s[j];
            inc(j);
          end;
        end;
      end;
      CloseFile(f);
    except
      MessageBox(Handle, 'Error while "data\engine\maintex.cfg" reading', 'Error', MB_OK or MB_ICONERROR);
      Close;
    end;

    lblLoading.Caption := 'OpenGL initialization';
    Sleep(loadDelay);
    Application.ProcessMessages;

    DC := GetDC(Handle);
    SetDCPixelFormat(DC);
    HRC := wglCreateContext(DC);
    wglMakeCurrent(DC, HRC);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_DEPTH_TEST);

    if i > 0 then
      for j := 0 to i - 1 do
      begin
        Application.ProcessMessages;
        lblLoading.Caption := 'Texture loading: ' +
          texarr[j,1] + '  ' + texarr[j,2];
        IncProgressBar;
        Sleep(loadDelay);
        Application.ProcessMessages;

        if j < 6 then
          LoadTexture(texarr[j,1], StrToInt(texarr[j,2]), StrToInt(texarr[j,3]))
        else
          LoadTexture512(texarr[j,1], StrToInt(texarr[j,2]), StrToInt(texarr[j,3]));
      end;

    Finalize(texarr);
    Loading2;
    pnlMain.Hide;
    FormResize(nil);
    RenderTimer.Enabled := True;
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  WindowState := wsMaximized;
  if not frmMain.isloaded then
    SetTimer(Handle, 1, 300, @Loading);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  glDeleteLists(1,2);
  wglMakeCurrent(0,0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle,DC);
  DeleteDC(DC);
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(30, ClientWidth / ClientHeight, 1, 200);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TfrmMain.DrawPanels(SelectMode: Boolean);
var
  i: Integer;
begin
  for i := 1 to 10 do
  begin
    glPushMatrix;
    glRotatef(i * 36, 0, 1, 0);
    glTranslatef(0, 0, 20);

    if SelectMode then
      glLoadName(i)
    else
      glBindTexture(GL_TEXTURE_2D, i + 6);

    glCallList(1);

    // highlight frame around the panel the cursor is over
    if (not SelectMode) and (i = hovered) then
    begin
      glPushAttrib(GL_ENABLE_BIT or GL_LINE_BIT or GL_CURRENT_BIT);
      glDisable(GL_LIGHTING);
      glDisable(GL_TEXTURE_2D);
      glColor3f(1, 1, 0);
      glLineWidth(3);
      glBegin(GL_LINE_LOOP);
        glVertex3f(-4.7, -4.7, 0.27);
        glVertex3f( 4.7, -4.7, 0.27);
        glVertex3f( 4.7,  4.7, 0.27);
        glVertex3f(-4.7,  4.7, 0.27);
      glEnd;
      glPopAttrib;
    end;

    glPopMatrix;
  end;
end;

// Returns the module index (1..10) of the panel under the given client point,
// or 0 if none. Uses the legacy OpenGL selection buffer.
function TfrmMain.PickPanel(X, Y: Integer): Integer;
const
  BUFSIZE = 256;
var
  buf: array[0..BUFSIZE - 1] of GLuint;
  hits, i, p, names: Integer;
  minZ, z: GLuint;
  vpW, vpH, px, py: Integer;
begin
  Result := 0;
  if not isloaded then Exit;
  vpW := ClientWidth;
  vpH := ClientHeight;
  if (vpW = 0) or (vpH = 0) then Exit;

  wglMakeCurrent(DC, HRC);
  glSelectBuffer(BUFSIZE, @buf[0]);
  glRenderMode(GL_SELECT);
  glInitNames;
  glPushName(0);

  px := X;
  py := vpH - Y;   // GL origin is bottom-left

  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;
  // gluPickMatrix(px, py, 4, 4, [0, 0, vpW, vpH]) built by hand:
  glTranslatef((vpW - 2 * px) / 4, (vpH - 2 * py) / 4, 0);
  glScalef(vpW / 4, vpH / 4, 1);
  gluPerspective(30, vpW / vpH, 1, 200);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslatef(0, 0, -70);
  glRotatef(rotate, 0, 1, 0);
  DrawPanels(True);

  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);

  hits := glRenderMode(GL_RENDER);

  p := 0;
  minZ := High(GLuint);
  for i := 0 to hits - 1 do
  begin
    names := buf[p]; Inc(p);
    z := buf[p]; Inc(p);   // min depth of this hit
    Inc(p);                // max depth (unused)
    if names > 0 then
    begin
      if z <= minZ then    // keep the nearest panel
      begin
        minZ := z;
        Result := buf[p + names - 1];
      end;
      Inc(p, names);
    end;
  end;
end;

procedure TfrmMain.RenderTimerTimer(Sender: TObject);
var
  ps: TPaintStruct;
  center, offset, dead, step, target: Integer;
begin
  BeginPaint(Handle, ps);
  wglMakeCurrent(DC, HRC);
  frmMain.Resize;
  glClearColor(0, 1, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;

  // rotation is driven by how far the cursor sits from the screen centre
  center := ClientWidth div 2;
  if mouseX < 0 then mouseX := center;
  offset := center - mouseX;
  dead := ClientWidth div 8;   // central dead zone where the carousel rests

  if Abs(offset) > dead then
  begin
    step := 1 + (Abs(offset) - dead) * 5 div (center - dead + 1);
    if step > 6 then step := 6;
    if offset > 0 then
      rotate := rotate + step
    else
      rotate := rotate - step;
  end
  else
  begin
    // ease onto the nearest module (multiple of 36 degrees)
    target := Round(rotate / 36) * 36;
    if rotate <> target then
      if Abs(target - rotate) <= 3 then
        rotate := target
      else
        rotate := rotate + Sign(target - rotate) * 3;
  end;

  rotate := rotate mod 360;
  if rotate < 0 then rotate := rotate + 360;

  glTranslatef(0, 0, -70);
  glRotatef(rotate, 0, 1, 0);
  glCallList(2);
  DrawPanels(False);

  EndPaint(Handle, ps);
  SwapBuffers(DC);
end;

procedure TfrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not isloaded then Exit;
  mouseX := X;
  hovered := PickPanel(X, Y);
end;

procedure TfrmMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  h: Integer;
begin
  if (not isloaded) or (Button <> mbLeft) then Exit;
  h := PickPanel(X, Y);
  if (h >= 1) and (h <= 10) and (Handles[h] > 0) then
    LoadModule(h);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetCurrentDir(ExtractFilePath(Application.ExeName));
  isloaded := False;
  mouseX := -1;
  hovered := 0;
end;

end.
