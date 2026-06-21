unit unitFrmOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Menus;

type
  TfrmOptions = class(TForm)
    groupAddSpring: TGroupBox;
    lblK: TLabel;
    txtK: TEdit;
    lblKm: TLabel;
    lblLength: TLabel;
    txtLength: TEdit;
    lblLengthm: TLabel;
    lblDx: TLabel;
    txtDx: TEdit;
    lblDxm: TLabel;
    btnAddSpring: TButton;
    groupAddMass: TGroupBox;
    lblMass: TLabel;
    txtMass: TEdit;
    lblMassm: TLabel;
    lblRadius: TLabel;
    txtRadius: TEdit;
    lblRadiusm: TLabel;
    btnAddMass: TButton;
    btnDelPrev: TButton;
    btnDelAll: TButton;
    groupSystemLength: TGroupBox;
    tbLength: TTrackBar;
    lblLengthValue: TLabel;
    cbCollisions: TCheckBox;
    groupVisualization: TGroupBox;
    lblDistance: TLabel;
    tbDistance: TTrackBar;
    btnStart: TButton;
    btnStop: TButton;
    MainMenu: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure tbLengthChange(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
  private
    function TestDelimiters(s: String): String;
  public
    procedure CorrectDelimiters;
  end;

var
  frmOptions: TfrmOptions;

procedure About(prog, date, dateupdate, version: ShortString; parent: TForm); external 'data\engine\MakarovTools.dll';

implementation

uses unitFrmMain;

{$R *.dfm}

procedure TfrmOptions.CorrectDelimiters;
begin
  txtK.Text := TestDelimiters(txtK.Text);
  txtLength.Text := TestDelimiters(txtLength.Text);
  txtDx.Text := TestDelimiters(txtDx.Text);
  txtMass.Text := TestDelimiters(txtMass.Text);
  txtRadius.Text:= TestDelimiters(txtRadius.Text);
end;

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

procedure TfrmOptions.FormShow(Sender: TObject);
begin
  txtRadius.Text := FloatToStr(0.5);
end;

procedure TfrmOptions.tbLengthChange(Sender: TObject);
begin
  lblLengthValue.Caption := IntToStr(tbLength.Position) + ' m';
end;

procedure TfrmOptions.N2Click(Sender: TObject);
begin
  About('Oscillator systems',
    'Created: December 1, 2004',
    'Updated: December 22, 2006',
    'Version: 1.3',
    frmLibMain);
end;

procedure TfrmOptions.N3Click(Sender: TObject);
begin
  frmLibMain.Close;
end;

end.
