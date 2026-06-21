{
Program: Rocket flight\nAuthor: M.M. Makarov\nCreated: November 2004\nIDE: Delphi 7
}
unit InfoUnit;

interface

uses
  unitFrmResults, Classes, SysUtils, RocketUnit;

type
  TMyThread = class(TThread)
    MyRocket: TRocket;{object of the Rocket class}
    procedure Execute;override;
    procedure ShowInfo;
  private
    i, j, k: Extended;
  end;

implementation

procedure TMyThread.ShowInfo;
{output rocket information to frmResults.RichEdit1}
begin
  i := MyRocket.fuel[1].mass;
  j := MyRocket.fuel[2].mass;
  k := MyRocket.fuel[3].mass;

  if i < 0 then i := 0;
  if j < 0 then j := 0;
  if k < 0 then k := 0;

  frmResults.txtResult.Text :=
    'Flight time: ' + IntToStr(Round(MyRocket.FlyTime / 1000)) + ' (s)' + #13#10 +
    'Height: ' + FloatToStr(MyRocket.H - 32) + ' (m)' + #13#10 +
    'Speed: ' + FloatToStr(MyRocket.Speed) + ' (m/s)' + #13#10 +
    'Acceleration: ' + FloatToStr(MyRocket.Acceleration) + ' (m/s^2)' + #13#10 +
    'First stage fuel mass: ' + FloatToStr(i) + ' (kg)' + #13#10 +
    'Second stage fuel mass: ' + FloatToStr(j) + ' (kg)' + #13#10 +
    'Third stage fuel mass: ' + FloatToStr(k) + ' (kg)';
end;

procedure TMyThread.Execute;
{main thread loop}
begin
  repeat
    Synchronize(ShowInfo);
  until Terminated;
end;

end.
