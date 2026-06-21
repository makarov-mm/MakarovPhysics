unit unitFrmGraphics;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ExtCtrls, TeeProcs, Chart, ComCtrls, StdCtrls;

type
  TfrmGraphics = class(TForm)
    cbWeight: TComboBox;
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

uses unitFrmMain;

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
    0: Chart.Title.Text.Text := 'Displacement (m)';
    1: Chart.Title.Text.Text := 'Speed (m/s)';
    2: Chart.Title.Text.Text := 'Acceleration (m/s^2)';
  end;
end;

end.
