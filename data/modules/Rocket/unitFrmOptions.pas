{
Program: Rocket flight\nAuthor: M.M. Makarov\nCreated: November 2004\nIDE: Delphi 7
}
unit unitFrmOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ExtCtrls, unitFrmResults, unitFrmGraphics, Vcl.Mask;

type
  TfrmOptions = class(TForm)
    MainMenu: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    groupRocket: TGroupBox;
    txtMass: TLabeledEdit;
    txtSpeed: TLabeledEdit;
    groupLevel1: TGroupBox;
    txtFuelPerSec1: TLabeledEdit;
    txtFuelMass1: TLabeledEdit;
    groupLevel2: TGroupBox;
    txtFuelPerSec2: TLabeledEdit;
    txtFuelMass2: TLabeledEdit;
    groupLevel3: TGroupBox;
    txtFuelPerSec3: TLabeledEdit;
    txtFuelMass3: TLabeledEdit;
    LabeledEdit9: TLabeledEdit;
    btnStart: TButton;
    btnStop: TButton;
    btnClear: TButton;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure N2Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
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

procedure TfrmOptions.N2Click(Sender: TObject);
begin
  About('Reactive motion',
    'Created: November 2004',
    'Updated: December 22, 2006',
    'Version: 1.3',
    frmLibMain);
end;

procedure TfrmOptions.N4Click(Sender: TObject);
begin
  frmLibMain.Close;
end;

{$HINTS OFF}
procedure TfrmOptions.btnStartClick(Sender: TObject);
var
  i: Single;
  t: Boolean;
begin
  t := True;

  txtMass.Text := TestDelimiters(txtMass.Text);
  txtSpeed.Text := TestDelimiters(txtSpeed.Text);
  txtFuelPerSec1.Text := TestDelimiters(txtFuelPerSec1.Text);
  txtFuelMass1.Text := TestDelimiters(txtFuelMass1.Text);
  txtFuelPerSec2.Text := TestDelimiters(txtFuelPerSec2.Text);
  txtFuelMass2.Text := TestDelimiters(txtFuelMass2.Text);
  txtFuelPerSec3.Text := TestDelimiters(txtFuelPerSec3.Text);
  txtFuelMass3.Text := TestDelimiters(txtFuelMass3.Text);

  try
    i := StrToFloat(txtMass.Text);
    i := StrToFloat(txtSpeed.Text);
    i := StrToFloat(txtFuelPerSec1.Text);
    i := StrToFloat(txtFuelMass1.Text);
    i := StrToFloat(txtFuelPerSec2.Text);
    i := StrToFloat(txtFuelMass2.Text);
    i := StrToFloat(txtFuelPerSec3.Text);
    i := StrToFloat(txtFuelMass3.Text);
  except
    t := False;
    MessageBox(Handle, 'Invalid values entered', 'Error', 0);
  end;
  if t then
  begin

    if not frmLibMain.Paused then
    begin
      frmLibMain.RotationSpeed := 0;
      frmLibMain.RocketBase.Turn;
    end else
      frmLibMain.Rocket.IsRun := True;

    frmLibMain.Paused := False;
  end;
end;
{$HINTS ON}

procedure TfrmOptions.btnStopClick(Sender: TObject);
begin
  if frmLibMain.Rocket.IsRun and (not frmLibMain.Paused) then
  begin
    frmLibMain.Rocket.IsRun := False;
    frmLibMain.Paused := True;
  end;
end;

procedure TfrmOptions.btnClearClick(Sender: TObject);
begin
  if frmLibMain.Rocket.IsRun and (not frmLibMain.Paused) then
  begin
    frmLibMain.Rocket.IsRun := False;
    frmLibMain.Paused := True;
  end;

  frmResults.txtResult.Clear;
  frmGraphics.Chart.Series[0].Clear;
  frmLibMain.Paused := False;
  frmLibMain.RocketBase.Angle := -20;
  frmLibMain.Rocket.ReturnToBase;
  frmLibMain.RotationSpeed := 0.3;
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

end.
