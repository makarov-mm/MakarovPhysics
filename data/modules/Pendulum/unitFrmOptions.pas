{
Program: Mathematical pendulum\nAuthor: M.M. Makarov\nCreated: November 25, 2004\nIDE: Delphi 7
}
unit unitFrmOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus, Vcl.Mask;

type
  TfrmOptions = class(TForm)
    groupPendulum: TGroupBox;
    groupDefVals: TGroupBox;
    txtAngle: TLabeledEdit;
    txtSpeed: TLabeledEdit;
    txtLength: TLabeledEdit;
    txtAccel: TLabeledEdit;
    btnStart: TButton;
    btnStop: TButton;
    groupVisualization: TGroupBox;
    cbShowGrid: TCheckBox;
    MainMenu: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    Image1: TImage;
    txtT: TEdit;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
  private
    function TestDelimiters(s: String): String;
  end;

var
  frmOptions: TfrmOptions;

procedure About(prog, date, dateupdate, version: ShortString; parent: TForm); external 'data\engine\MakarovTools.dll';

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

procedure TfrmOptions.btnStartClick(Sender: TObject);
var
  i:Integer;
begin
  try
    with frmLibMain do
    begin
      txtAngle.Text := TestDelimiters(txtAngle.Text);
      txtSpeed.Text := TestDelimiters(txtSpeed.Text);
      txtLength.Text := TestDelimiters(txtLength.Text);
      txtAccel.Text := TestDelimiters(txtAccel.Text);

      Angle := StrToFloat(txtAngle.Text);
      Speed := StrToFloat(txtSpeed.Text);
      Len := StrToFloat(txtLength.Text);
      g := StrToFloat(txtAccel.Text);

      Period := 1;
      preSpeed := Speed;

      for i := 1 to 250 do
      begin
        AngleArray[i] := 0;
        SpeedArray[i] := 0;
        AccelArray[i] := 0;
      end;
    end;

    txtT.Text := FloatToStrF(2 * pi * sqrt(frmLibMain.Len / frmLibMain.g), ffFixed, 10, 5);
    btnStart.Enabled := False;
    frmLibMain.IsRun := True;
    btnStop.Enabled := True;
  except
    MessageBox(frmLibMain.Handle, 'Invalid values entered',
      'Error', MB_ICONERROR);
  end;
end;

procedure TfrmOptions.btnStopClick(Sender: TObject);
begin
  btnStop.Enabled := False;
  frmLibMain.IsRun := False;
  btnStart.Enabled := True;
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

procedure TfrmOptions.N7Click(Sender: TObject);
begin
  frmLibMain.Close;
end;

procedure TfrmOptions.N3Click(Sender: TObject);
begin
  btnStart.Click;
end;

procedure TfrmOptions.N4Click(Sender: TObject);
begin
  btnStop.Click;
end;

procedure TfrmOptions.N5Click(Sender: TObject);
begin
  About('Mathematical pendulum',
    'Created: November 25, 2004',
    'Updated: December 22, 2006',
    'Version: 1.3',
    frmLibMain);
end;

end.
