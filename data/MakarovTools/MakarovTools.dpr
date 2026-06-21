library MakarovTools;

uses
  Windows,
  Forms,
  SysUtils,
  Controls,
  Classes,
  unitFrmAbout in 'unitFrmAbout.pas' {frmAbout};

{$R *.res}

procedure SetWindowParams(x, y, width, height: Integer; window: TForm);
begin
  x := abs(x);
  y := abs(y);

  if width <= x then
    width := x + 1;

  if height <= y then
    height := y + 1;

  MessageBox(window.Handle, 'Everything is nothing....', 'WTF?', MB_OK);
  //.....
end;

procedure About(prog, date, dateupdate, version: ShortString; parent: TForm);
var
  maxlen: Integer;
begin
  frmAbout := TfrmAbout.Create(parent);

  frmAbout.lblProg.Caption := prog;
  frmAbout.lblDate.Caption := date;
  frmAbout.lblDateUpdate.Caption := dateupdate;
  frmAbout.lblVersion.Caption := version;

  maxlen := frmAbout.lblProg.Width;

  if frmAbout.lblDate.Width > maxlen then
    maxlen := frmAbout.lblDate.Width;

  if frmAbout.lblDateUpdate.Width > maxlen then
    maxlen := frmAbout.lblDate.Width;

  if frmAbout.lblDateUpdate.Width > maxlen then
    maxlen := frmAbout.lblDate.Width;

  if frmAbout.lblVersion.Width > maxlen then
    maxlen := frmAbout.lblVersion.Width;

  if frmAbout.lblDesigner.Width > maxlen then
    maxlen := frmAbout.lblDesigner.Width;

  frmAbout.btnClose.Left := (frmAbout.ClientWidth - frmAbout.btnClose.Width) div 2;

  frmAbout.Left := (Screen.Width - frmAbout.Width) div 2;
  frmAbout.Top := (Screen.Height - frmAbout.Height) div 2;

  Beep;
  frmAbout.ShowModal;
  frmAbout.Free;

  parent.SetFocus;
end;

exports
  SetWindowParams,
  About;

begin
end.
