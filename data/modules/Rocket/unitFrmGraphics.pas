{
Program: Rocket flight\nAuthor: M.M. Makarov\nCreated: November 2004\nIDE: Delphi 7
}
unit unitFrmGraphics;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ExtCtrls, TeeProcs, Chart, ComCtrls;

type
  TfrmGraphics = class(TForm)
    tabs: TTabControl;
    Chart: TChart;
    Series1: TLineSeries;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tabsChange(Sender: TObject);
  end;

var
  frmGraphics: TfrmGraphics;

implementation

uses unitFrmLibMain;

{$R *.dfm}

procedure TfrmGraphics.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if Visible then Resize := False;
end;

procedure TfrmGraphics.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  frmLibMain.Close;
end;

procedure TfrmGraphics.tabsChange(Sender: TObject);
begin
  case tabs.TabIndex of
    0: frmGraphics.Chart.Title.Text.Text := 'Height (m)';
    1: frmGraphics.Chart.Title.Text.Text := 'Speed (m/s)';
    2: frmGraphics.Chart.Title.Text.Text := 'Acceleration (m/s^2)';
  end;
end;

end.
