unit unitFrmGraphics;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, TeEngine, Series, Vcl.ExtCtrls, TeeProcs, Chart,
  VclTee.TeeGDIPlus;

type
  TfrmGraphics = class(TForm)
    chartDX: TChart;
    Series1: TLineSeries;
    chartSpeed: TChart;
    LineSeries1: TLineSeries;
    chartAccel: TChart;
    LineSeries2: TLineSeries;
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
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

procedure TfrmGraphics.FormResize(Sender: TObject);
begin
  with chartDX do
  begin
    Top := 8;
    Height := Round((frmGraphics.ClientHeight - 32) / 3);
  end;

  with chartSpeed do
  begin
    Top := chartDX.Top+chartDX.Height + 8;
    Height := Round((frmGraphics.ClientHeight - 32) / 3);
  end;

  with chartAccel do
  begin
    Top := chartSpeed.Top + chartSpeed.Height + 8;
    Height := Round((frmGraphics.ClientHeight - 32) / 3);
  end;
end;

end.
