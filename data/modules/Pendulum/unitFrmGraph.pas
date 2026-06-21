{
Program: Mathematical pendulum\nAuthor: M.M. Makarov\nCreated: November 25, 2004\nIDE: Delphi 7
}
unit unitFrmGraph;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ExtCtrls, TeeProcs, Chart, ComCtrls;

type
  TfrmGraph = class(TForm)
    tabs: TTabControl;
    Chart: TChart;
    Series1: TLineSeries;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  end;

var
  frmGraph: TfrmGraph;

implementation

uses unitFrmLibMain;

{$R *.dfm}

procedure TfrmGraph.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if Visible then Resize := False;
end;

procedure TfrmGraph.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  frmLibMain.Close;
end;

end.
