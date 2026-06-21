unit unitFrmOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Menus, Vcl.Mask;

type
  TfrmOptions = class(TForm)
    groupParams: TGroupBox;
    txtPlanetMass: TLabeledEdit;
    txtSpeed: TLabeledEdit;
    txtHeight: TLabeledEdit;
    groupVisualize: TGroupBox;
    lblDistance: TLabel;
    tbDistance: TTrackBar;
    cbTraectory: TCheckBox;
    btnStart: TButton;
    btnStop: TButton;
    txtPlanetRadius: TLabeledEdit;
    txtObjMass: TLabeledEdit;
    lblTime: TLabel;
    tbTime: TTrackBar;
    lblTimeX1000: TLabel;
    lblObjRadius: TLabel;
    tbObjRadius: TTrackBar;
    MainMenu: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure N2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure tbTimeChange(Sender: TObject);
    procedure N4Click(Sender: TObject);
  private
    function TestDelimiters(s: String): String;
  end;

var
  frmOptions: TfrmOptions;

procedure About(prog, date, dateupdate, version: ShortString; parent: TForm); external 'data\engine\MakarovTools.dll';

implementation

uses unitFrmMain;

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
  r: Boolean;
  s: Extended;
  i: Integer;
begin
  r := False;

  txtPlanetMass.Text := TestDelimiters(txtPlanetMass.Text);
  txtSpeed.Text := TestDelimiters(txtSpeed.Text);
  txtHeight.Text := TestDelimiters(txtHeight.Text);
  txtPlanetRadius.Text := TestDelimiters(txtPlanetRadius.Text);
  txtObjMass.Text := TestDelimiters(txtObjMass.Text);

  try
    s := StrToFloat(txtPlanetMass.Text);
    s := s + StrToFloat(txtSpeed.Text);
    s := s + StrToFloat(txtHeight.Text);
    s := s + StrToFloat(txtPlanetRadius.Text);
    s := s + StrToFloat(txtObjMass.Text);
    if (s > 0) and (StrToFloat(txtPlanetMass.Text) > 0)
             and (StrToFloat(txtSpeed.Text) >= 0)
             and (StrToFloat(txtHeight.Text) > 0)
             and (StrToFloat(txtPlanetRadius.Text) > 0)
             and (StrToFloat(txtObjMass.Text) > 0) then
      r := True
    else
      MessageBox(Handle, 'Invalid values specified', 'Error', MB_OK);
  except
    MessageBox(Handle, 'Invalid values specified', 'Error', MB_OK);
  end;

  if r then
    with frmLibMain do
    begin
      IsRun := False;
      PlanetMass := StrToFloat(txtPlanetMass.Text) * 100000000000000000000.0;
      SatelliteMass := StrToFloat(txtObjMass.Text);
      PlanetRadius := StrToFloat(txtPlanetRadius.Text);
      speedY := StrToFloat(txtSpeed.Text);
      cX := StrToFloat(txtHeight.Text) + PlanetRadius;
      cY := 0;
      speedX := 0;

      for i := 1 to segsCount do
      begin
        ArrX[i] := cX;
        ArrY[i] := cY;
        ArrSX[i] := speedX;
        ArrSY[i] := speedY;
      end;
      IsRun := True;
    end;
end;

procedure TfrmOptions.btnStopClick(Sender: TObject);
begin
  frmLibMain.IsRun := False;
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

procedure TfrmOptions.tbTimeChange(Sender: TObject);
begin
  lblTimeX1000.Caption := 'x ' + IntToStr(tbTime.Position);
end;

procedure TfrmOptions.N2Click(Sender: TObject);
begin
  About('Kepler problem',
    'Created: December 5, 2004',
    'Updated: December 22, 2006',
    'Version: 1.3',
    frmLibMain);
end;

procedure TfrmOptions.N4Click(Sender: TObject);
begin
  frmLibMain.Close;
end;

end.
