unit unitFrmOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus, Vcl.Mask;

type
  TfrmOptions = class(TForm)
    groupVisualize: TGroupBox;
    groupDist: TGroupBox;
    tbDist: TTrackBar;
    groupPotencials: TGroupBox;
    txtUpP: TLabeledEdit;
    txtDownP: TLabeledEdit;
    btnStart: TButton;
    btnStop: TButton;
    groupsParams: TGroupBox;
    txtSpeed: TLabeledEdit;
    txtAngle: TLabeledEdit;
    groupCondensator: TGroupBox;
    lblDistance: TLabel;
    lblDistanceValue: TLabel;
    tbDistance: TTrackBar;
    lblLength: TLabel;
    tbLength: TTrackBar;
    lblLengthValue: TLabel;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tbDistanceChange(Sender: TObject);
    procedure tbLengthChange(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
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

procedure TfrmOptions.tbDistanceChange(Sender: TObject);
begin
  lblDistanceValue.Caption:=FloatToStr(tbDistance.Position/10);
end;

procedure TfrmOptions.tbLengthChange(Sender: TObject);
begin
  lblLengthValue.Caption:=FloatToStr(tbLength.Position/10);
end;

procedure TfrmOptions.btnStopClick(Sender: TObject);
begin
  if frmLibMain.IsRun then
  begin
    frmLibMain.IsRun:=False;
    txtUpP.Enabled:=True;
    txtDownP.Enabled:=True;
    txtSpeed.Enabled:=True;
    txtAngle.Enabled:=True;

    btnStart.Enabled := True;
    btnStop.Enabled := False;
  end;
end;

procedure TfrmOptions.btnStartClick(Sender: TObject);
begin
  if not frmLibMain.IsRun then
  begin
    try
      with frmLibMain do
      begin
        txtUpP.Text := TestDelimiters(txtUpP.Text);
        txtDownP.Text := TestDelimiters(txtDownP.Text);
        txtSpeed.Text := TestDelimiters(txtSpeed.Text);
        txtAngle.Text := TestDelimiters(txtAngle.Text);

        StartSpeed:=StrToFloat(txtSpeed.Text);
        StartAngle:=StrToFloat(txtAngle.Text);
        p1:=StrToFloat(txtUpP.Text);
        p2:=StrToFloat(txtDownP.Text);

        txtUpP.Enabled:=False;
        txtDownP.Enabled:=False;
        txtSpeed.Enabled:=False;
        txtAngle.Enabled:=False;

        btnStart.Enabled := False;
        btnStop.Enabled := True;

        IsRun:=True;
      end;
    except
      MessageBox(Handle,'Invalid values entered','Error',MB_OK or MB_ICONERROR);
    end;
  end;
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
  txtUpP.Text:=FloatToStr(0.2);
  txtDownP.Text:=FloatToStr(-0.2);
end;

procedure TfrmOptions.N4Click(Sender: TObject);
begin
  frmLibMain.Close;
end;

procedure TfrmOptions.N2Click(Sender: TObject);
begin
  About('Electrons in an electric field',
    'Created: December 26, 2004',
    'Updated: December 22, 2006',
    'Version: 1.3',
    frmLibMain);
end;

end.
