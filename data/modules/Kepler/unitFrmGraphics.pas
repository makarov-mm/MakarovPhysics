unit unitFrmGraphics;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ArrowCha, ExtCtrls, TeeProcs, Math, VCLTee.Chart,
  VclTee.TeeGDIPlus;

type
  TfrmGraphics = class(TForm)
    chartPhase1: TChart;
    Series1: TPointSeries;
    chartPhase2: TChart;
    PointSeries1: TPointSeries;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
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
begin
  with chartPhase1 do
  begin
    Left := 0;
    Top := 0;
    Width := Floor(frmGraphics.ClientWidth / 2);
    Height := frmGraphics.ClientHeight;
  end;
  with chartPhase2 do
  begin
    Left := Floor(frmGraphics.ClientWidth / 2);
    Top := 0;
    Width := frmGraphics.ClientWidth - chartPhase1.Width;;
    Height := frmGraphics.ClientHeight;
  end;
end;

end.
