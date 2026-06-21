unit Unit1;
{
program that displays video card and OpenGL information\nauthor: M.M. Makarov\ncreated: 20.II.2005
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, StdCtrls;

type
  TfrmVideoInfo = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    DC:HDC;
    HRC:HGLRC;
    procedure SetDCPixelFormat;
  end;

var
  frmVideoInfo: TfrmVideoInfo;

implementation

{$R *.dfm}

procedure TfrmVideoInfo.SetDCPixelFormat;
var
  pfd:TPixelFormatDescriptor;
  nPixelFormat:Integer;
begin
  FillChar(pfd,SizeOf(pfd),0);
  pfd.dwFlags:=PFD_DOUBLEBUFFER or
               PFD_SUPPORT_OPENGL or
               PFD_DRAW_TO_WINDOW;
  nPixelFormat:=ChoosePixelFormat(DC,@pfd);
  SetPixelFormat(DC,nPixelFormat,@pfd);
end;

procedure TfrmVideoInfo.FormCreate(Sender: TObject);
var
  s:String;
  i:Integer;
  r:Boolean;
begin
  DC:=GetDC(Handle);
  SetDCPixelFormat;
  HRC:=wglCreateContext(DC);
  wglMakeCurrent(DC,HRC);
  Label5.Caption:=glGetString(GL_VENDOR);
  Label6.Caption:=glGetString(GL_RENDERER);
  Label7.Caption:=glGetString(GL_VERSION);
  s:=glGetString(GL_EXTENSIONS);
  r:=True;
  while r do
  begin
    r:=False;
    for i:=0 to Length(s) do
      if (s[i]=Chr($20)) and (i<>Length(s)) then
      begin
        Delete(s,i,1);
        Insert(#13#10,s,i);
        r:=True;
      end;
  end;
  Memo1.Text:=s;
  wglMakeCurrent(0,0);
  wglDeleteContext(HRC);
  ReleaseDC(Handle,DC);
  DeleteDC(DC);
end;

procedure TfrmVideoInfo.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_F1 then
    MessageBox(Handle,'Video card and OpenGL information'#13#10+
                      'Program author: M.M. Makarov'#13#10+
                      'Created: February 16, 2005'#13#10+
                      'Version: 1.0','About',MB_OK);
end;

end.
