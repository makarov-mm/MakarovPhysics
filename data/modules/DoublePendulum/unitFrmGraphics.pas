unit unitFrmGraphics;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ExtCtrls, TeeProcs, Chart, ComCtrls, ArrowCha,
  VclTee.TeeGDIPlus;

type
  TfrmGraphics = class(TForm)
    tabs: TTabControl;
    chartPendulum2: TChart;
    Series2: TLineSeries;
    chartPendulum1: TChart;
    LineSeries1: TLineSeries;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
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

procedure TfrmGraphics.FormResize(Sender: TObject);
const
  u=24;
begin
  with chartPendulum1 do
  begin
    Left:=0;
    Top:=u;
    Height:=tabs.ClientHeight-u;
    Width:=Round(tabs.ClientWidth/2);
  end;
  with chartPendulum2 do
  begin
    Left:=Round(tabs.ClientWidth/2);
    Top:=u;
    Height:=tabs.ClientHeight-u;
    Width:=Round(tabs.ClientWidth/2);
  end;
end;

end.
