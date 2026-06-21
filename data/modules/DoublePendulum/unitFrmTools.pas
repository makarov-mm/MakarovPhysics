unit unitFrmTools;

interface

uses
  Windows, Messages, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Menus, unitMakarovTools, System.SysUtils,
  Vcl.Mask;

type
  TfrmTools = class(TForm)
    groupView: TGroupBox;
    cbViewPend: TCheckBox;
    cbViewMass: TCheckBox;
    lblMassSize: TLabel;
    lblMassSizeValue: TLabel;
    tbMassSize: TTrackBar;
    lblDistance: TLabel;
    lblDistanceValue: TLabel;
    tbDistance: TTrackBar;
    groupPendulum1: TGroupBox;
    txtLength1: TLabeledEdit;
    txtMass1: TLabeledEdit;
    txtAngle1: TLabeledEdit;
    txtSpeed1: TLabeledEdit;
    groupCalc: TGroupBox;
    btnStart: TButton;
    btnPause: TButton;
    btnStop: TButton;
    groupPendulum2: TGroupBox;
    txtLength2: TLabeledEdit;
    txtMass2: TLabeledEdit;
    txtAngle2: TLabeledEdit;
    txtSpeed2: TLabeledEdit;
    cbGrid: TCheckBox;
    MainMenu: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tbMassSizeChange(Sender: TObject);
    procedure tbDistanceChange(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure N8Click(Sender: TObject);
  private
    function TestDelimiters(s: String): String;
  end;

var
  frmTools: TfrmTools;

implementation

uses unitFrmMain;

{$R *.dfm}

function TfrmTools.TestDelimiters(s: String): String;
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

procedure TfrmTools.tbMassSizeChange(Sender: TObject);
begin
  lblMassSizeValue.Caption := FloatToStr(tbMassSize.Position / 40);
end;

procedure TfrmTools.tbDistanceChange(Sender: TObject);
begin
  lblDistanceValue.Caption := IntToStr(tbDistance.Position);
end;

procedure TfrmTools.N4Click(Sender: TObject);
begin
  frmLibMain.Close;
end;

procedure TfrmTools.N2Click(Sender: TObject);
begin
  About('Double pendulum',
    'Created: December 3, 2004',
    'Updated: December 22, 2006',
    'Version: 1.3',
    frmLibMain);
end;

procedure TfrmTools.btnStartClick(Sender: TObject);
var
  r, n: Boolean;
  tmp:Extended;
begin
  r := False; n := False;
  if not frmLibMain.IsPaused then
  begin
    txtLength1.Text := TestDelimiters(txtLength1.Text);
    txtMass1.Text := TestDelimiters(txtMass1.Text);
    txtAngle1.Text := TestDelimiters(txtAngle1.Text);
    txtSpeed1.Text := TestDelimiters(txtSpeed1.Text);
    txtLength2.Text := TestDelimiters(txtLength2.Text);
    txtMass2.Text := TestDelimiters(txtMass2.Text);
    txtAngle2.Text := TestDelimiters(txtAngle2.Text);
    txtSpeed2.Text := TestDelimiters(txtSpeed2.Text);

    try
      tmp := StrToFloat(txtLength1.Text);
      tmp := tmp + StrToFloat(txtMass1.Text);
      tmp := tmp + StrToFloat(txtAngle1.Text);
      tmp := tmp + StrToFloat(txtSpeed1.Text);
      tmp := tmp + StrToFloat(txtLength2.Text);
      tmp := tmp + StrToFloat(txtMass2.Text);
      tmp := tmp + StrToFloat(txtAngle2.Text);
      tmp := tmp + StrToFloat(txtSpeed2.Text);
      if (StrToFloat(txtLength1.Text) > 0) and
         (StrToFloat(txtMass1.Text) > 0) and
         (StrToFloat(txtLength2.Text) > 0) and
         (StrToFloat(txtMass2.Text) > 0) and
         (tmp > 0) then
        r := True;
    except
      n := True;
      MessageBox(Handle,'Invalid values entered',
                        'Error',MB_OK);
    end;
  end else
    r := True;

  if r then
  begin
    frmLibMain.IsRun := False;
    if not frmLibMain.IsPaused then
      with frmLibMain do
      begin
        frmLibMain.ClearArrays;
        with Pendulums[1] do
        begin
          Len := StrToFloat(txtLength1.Text);
          mass := StrToFloat(txtMass1.Text);
          Angle := StrToFloat(txtAngle1.Text);
          Speed := StrToFloat(txtSpeed1.Text);
          preSpeed := Speed;
          preAngle := Angle;
        end;
        with Pendulums[2] do
        begin
          Len := StrToFloat(txtLength2.Text);
          mass := StrToFloat(txtMass2.Text);
          Angle := StrToFloat(txtAngle2.Text);
          Speed := StrToFloat(txtSpeed2.Text);
          preSpeed := Speed;
          preAngle := Angle;
        end;
      end;
      frmLibMain.IsRun := True;
      frmLibMain.IsPaused := False;
  end else
    if not n then
      MessageBox(Handle,'Invalid values entered',
                        'Error',MB_OK);
end;

procedure TfrmTools.btnPauseClick(Sender: TObject);
begin
  frmLibMain.IsPaused := True;
end;

procedure TfrmTools.btnStopClick(Sender: TObject);
begin
  frmLibMain.IsRun := False;
  frmLibMain.IsPaused := False;
end;

procedure TfrmTools.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if Visible then Resize := False;
end;

procedure TfrmTools.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  frmLibMain.Close;
end;

procedure TfrmTools.N6Click(Sender: TObject);
begin
  btnStart.Click;
end;

procedure TfrmTools.N7Click(Sender: TObject);
begin
  btnPause.Click;
end;

procedure TfrmTools.N8Click(Sender: TObject);
begin
  btnStop.Click;
end;

end.
