unit unitFormPhaseTraectory;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ExtCtrls, TeeProcs, Chart, ComCtrls,
  VclTee.TeeGDIPlus;

type
  TfrmPhaseTraectory = class(TForm)
    chartPhase1: TChart;
    Series1: TPointSeries;
    chartPhase2: TChart;
    PointSeries1: TPointSeries;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure chartPhase2Resize(Sender: TObject);
  end;

var
  frmPhaseTraectory: TfrmPhaseTraectory;

implementation

uses unitFrmMain;

{$R *.dfm}

procedure TfrmPhaseTraectory.chartPhase2Resize(Sender: TObject);
begin
  with chartPhase1 do
  begin
    Left:=0;
    Top:=0;
    Height:=frmPhaseTraectory.ClientHeight;
    Width:=Round(frmPhaseTraectory.ClientWidth/2);
  end;
  with chartPhase2 do
  begin
    Left:=Round(frmPhaseTraectory.ClientWidth/2);
    Top:=0;
    Height:=frmPhaseTraectory.ClientHeight;
    Width:=Round(frmPhaseTraectory.ClientWidth/2);
  end;
end;

procedure TfrmPhaseTraectory.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if Visible then Resize := False;
end;

procedure TfrmPhaseTraectory.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  frmLibMain.Close;
end;

end.
