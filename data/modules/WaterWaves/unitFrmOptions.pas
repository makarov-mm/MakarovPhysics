unit unitFrmOptions;
{
program: water surface oscillations\nauthor: M.M. Makarov\ncreated: March 2, 2005
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.Mask;

type
  TfrmOptions = class(TForm)
    txtVyaz: TLabeledEdit;
    btnStart: TButton;
    cbDy: TLabeledEdit;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    groupTex: TGroupBox;
    cbTexturing: TCheckBox;
    groupTexNumb: TGroupBox;
    rb1: TRadioButton;
    rb2: TRadioButton;
    rb3: TRadioButton;
    rb4: TRadioButton;
    rb5: TRadioButton;
    rb6: TRadioButton;
    rb7: TRadioButton;
    rb8: TRadioButton;
    rb9: TRadioButton;
    rb10: TRadioButton;
    rb11: TRadioButton;
    rb12: TRadioButton;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
  private
    function TestDelimiters(s: String): String;
  end;

var
  frmOptions: TfrmOptions;

implementation

uses unitFrmLibMain;

{$R *.dfm}

function TfrmOptions.TestDelimiters(s: String): String;
var
  i: Integer;
begin
  Result := '';
  if Length(s) > 0 then
    for i := 1 to Length(s) do
      if (s[i] <> '.') and (s[i] <> ',') then
        Result := Result + s[i]
      else
        Result := Result + FormatSettings.DecimalSeparator;
end;

procedure TfrmOptions.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if Visible then Resize := False;
end;

procedure TfrmOptions.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  frmLibMain.Close;
end;

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  txtVyaz.Text := FloatToStr(0.005);
end;

procedure TfrmOptions.btnStartClick(Sender: TObject);
var
  i, j: Integer;
begin
  txtVyaz.Text := TestDelimiters(txtVyaz.Text);
  cbDy.Text := TestDelimiters(cbDy.Text);

  try
    frmLibMain.vis := StrToFloat(txtVyaz.Text);
    frmLibMain.Ydef := StrToFloat(cbDy.Text);
    for i := -50 to 50 do
      for j := -50 to 50 do
      begin
        frmLibMain.A[i, j] := 0;
        frmLibMain.B[i, j] := 0;
      end;
  except
    MessageBox(Handle, 'Invalid values entered',
                       'Error', MB_OK or MB_ICONERROR);
  end;
  frmLibMain.RenderTimer.Enabled:=True;
  //disturb the surface
  for i := -5 to 5 do
    for j := -5 to 5 do
      frmLibMain.A[i, j] := frmLibMain.Ydef;
end;

procedure TfrmOptions.N5Click(Sender: TObject);
begin
  frmLibMain.Close;
end;

procedure TfrmOptions.N3Click(Sender: TObject);
begin
  MessageBox(frmLibMain.Handle,
             'Water surface oscillations'#13#10+
             'Author: M.M. Makarov'#13#10+
             'Created: March 2, 2005','About', MB_OK);
end;

end.
