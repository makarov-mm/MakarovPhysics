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
    hovered: Integer;   // centered panel that gets the highlight frame
    selModule: Integer; // module index (1..10) currently centred
    InitLibrary: TLibProc;
    isloaded: Boolean;
    procedure LoadModule(number: Integer);
    procedure DrawPanels;
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

procedure TfrmMain.DrawPanels;
var
  i: Integer;
begin
  for i := 1 to 10 do
  begin
    glPushMatrix;
    glRotatef(i * 36, 0, 1, 0);
    glTranslatef(0, 0, 20);

    glBindTexture(GL_TEXTURE_2D, i + 6);
    glCallList(1);

    // highlight frame around the centered (selected) panel
    if i = hovered then
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
  offset := mouseX - center;
  dead := ClientWidth div 8;   // central dead zone where the carousel rests

  if Abs(offset) > dead then
  begin
    step := 1 + (Abs(offset) - dead) * 5 div (center - dead + 1);
    if step > 6 then step := 6;
    // Swap the next two lines to reverse the spin direction.
    if offset > 0 then
      rotate := rotate - step
    else
      rotate := rotate + step;
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

  // The preview textures are packed in reverse module order. The module to
  // launch follows the original mapping (Floor(rotate/36)+1); the panel that
  // visually faces the camera is its mirror (11 - selModule) and gets the frame.
  selModule := (Round(rotate / 36) mod 10) + 1;
  hovered := 11 - selModule;
  if hovered > 10 then hovered := hovered - 10;
  if hovered < 1 then hovered := hovered + 10;

  glTranslatef(0, 0, -70);
  glRotatef(rotate, 0, 1, 0);
  glCallList(2);
  DrawPanels;

  EndPaint(Handle, ps);
  SwapBuffers(DC);
end;

procedure TfrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not isloaded then Exit;
  mouseX := X;   // horizontal position drives the rotation in RenderTimerTimer
end;

procedure TfrmMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (not isloaded) or (Button <> mbLeft) then Exit;
  // launch the module that is currently centred (and highlighted)
  if (selModule >= 1) and (selModule <= 10) and (Handles[selModule] > 0) then
    LoadModule(selModule);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetCurrentDir(ExtractFilePath(Application.ExeName));
  isloaded := False;
  mouseX := -1;
  hovered := 0;
  selModule := 0;
end;

end.

