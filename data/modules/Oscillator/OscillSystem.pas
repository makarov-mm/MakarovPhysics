unit OscillSystem;

interface

uses
  Windows, OpenGL, SysUtils, unitFrmGraphics;

type
  {array for storing values}
  TMyArr = array[1..250] of Extended;

  {spring class}
  TSpring = class
  public
    x1,{start coordinate}
    x2,{end coordinate}
    deflen,{initial length (without stretching or compression)}
    k:Extended;{stiffness}
    procedure Render;
  end;

  {weight class}
  TSphere = class
  private
    quadobj:GLUQuadricObj;
    procedure UpgradeArrays(x1,x2,deflen:Extended);
  public
    mass,{mass}
    radius,{radius}
    x,{center coordinate}
    speed,{speed}
    acceleration:Extended;{acceleration}
    ArrOfX,{array of displacements}
    ArrOfSpeed,{array of speeds}
    ArrOfAcceleration:TMyArr;{array of accelerations}
    constructor Create;
    destructor Destroy;override;
    procedure Render(x1,x2,deflen:Extended);
  end;

  {oscillator system class}
  TOscillSystem = class
  private
    NumbOfSprings:Integer;{number of springs}
    NumbOfSpheres:Integer;{number of weights}
    Handle:THandle;{main window handle}
    procedure Calculate(CollisionDetection:Boolean);
  public
    ArrOfSprings:Array of TSpring;{array of springs}
    ArrOfSpheres:Array of TSphere;{array of weights}
    minX,maxX:Extended;{minimum and maximum coordinates in the system}
    constructor Create(ParentHandle:THandle);
    destructor Destroy;override;
    function Render(IsRun,CollisionDetection:Boolean):Boolean;
    procedure DrawGraphic(numb,param:Integer);
    procedure AddSphere(mass,radius:Extended);
    procedure AddSpring(k,len,dx:Extended);
    procedure DelPrev;
    procedure DelAll;
    function GetInfo(numb:Integer):ShortString;
    function IsReady:Boolean;
    property HowManySpheres:Integer read NumbOfSpheres;
  end;

implementation

{=====================================================}

procedure TSpring.Render;
const
  width=0.5;
  parts=5;
var
  step:Extended;
  xsize:Extended;
  i:Word;
begin
  xsize:=width/2;
  glDisable(GL_LIGHTING);
  glColor3f(1,0,0);
  glBegin(GL_LINE_STRIP);

  step:=(x2-x1)/Round(parts*deflen);

  glVertex3f(x1-0.2,xsize,xsize);
  for i:=1 to Round(parts*deflen) do
  begin
    glVertex3f(x1+step*((i-1)*4+0)/4,xsize,xsize);
    glVertex3f(x1+step*((i-1)*4+1)/4,xsize,-xsize);
    glVertex3f(x1+step*((i-1)*4+2)/4,-xsize,-xsize);
    glVertex3f(x1+step*((i-1)*4+3)/4,-xsize,xsize);
  end;
  glVertex3f(x1+step*((Round(parts*deflen)-1)*4+4)/4+0.2,-xsize,xsize);

  glEnd;
  glEnable(GL_LIGHTING);
end;

{=====================================================}

constructor TSphere.Create;
begin
  quadObj:=gluNewQuadric;
  gluQuadricDrawStyle(quadObj, GLU_FILL);
  gluQuadricOrientation(quadObj, GLU_OUTSIDE);
end;

destructor TSphere.Destroy;
begin
  gluDeleteQuadric(quadObj);
  Inherited Destroy;
end;

procedure TSphere.UpgradeArrays(x1,x2,deflen:Extended);
var
  i:Integer;
begin
  for i:=1 to 249 do
  begin
    ArrOfX[i]:=ArrOfX[i+1];
    ArrOfSpeed[i]:=ArrOfSpeed[i+1];
    ArrOfAcceleration[i]:=ArrOfAcceleration[i+1];
  end;
  ArrOfX[250]:=(x2-x1)-deflen;
  ArrOfSpeed[250]:=speed;
  ArrOfAcceleration[250]:=acceleration;
end;

procedure TSphere.Render(x1,x2,deflen:Extended);
begin
  UpgradeArrays(x1,x2,deflen);
  glColor3f(1,1,1);
  glPushMatrix;
  glTranslatef(x,0,0);
  gluSphere(quadObj,radius,15,15);
  glPopMatrix;
end;

{=====================================================}

procedure TOscillSystem.Calculate(CollisionDetection:Boolean);
{motion calculation}
const
  dt=40/1000;{time integration step}
var
  i,j:Integer;
begin
  {motion calculation}
  for i:=0 to NumbOfSpheres-1 do
  begin
    {acceleration calculation}
    ArrOfSpheres[i].acceleration:=
      ((ArrOfSprings[i+1].k*
      ((ArrOfSprings[i+1].x2-ArrOfSprings[i+1].x1)-ArrOfSprings[i+1].deflen))/
      ArrOfSpheres[i].mass)-
      ((ArrOfSprings[i].k*
      ((ArrOfSprings[i].x2-ArrOfSprings[i].x1)-ArrOfSprings[i].deflen))/
      ArrOfSpheres[i].mass);
    {speed calculation}
    ArrOfSpheres[i].speed:=ArrOfSpheres[i].speed+ArrOfSpheres[i].acceleration*dt;
    {collision calculation}
    if CollisionDetection then
    begin
      if (ArrOfSpheres[0].x-ArrOfSpheres[0].radius)<minX then
        ArrOfSpheres[0].speed:=Abs(ArrOfSpheres[0].speed);
      if (ArrOfSpheres[NumbOfSpheres-1].x+ArrOfSpheres[NumbOfSpheres-1].radius)>maxX then
        ArrOfSpheres[NumbOfSpheres-1].speed:=-Abs(ArrOfSpheres[NumbOfSpheres-1].speed);
      if NumbOfSpheres>=2 then
        for j:=0 to NumbOfSpheres-2 do
          if (ArrOfSpheres[j].x+ArrOfSpheres[j].radius)>=
             (ArrOfSpheres[j+1].x-ArrOfSpheres[j+1].radius) then
          begin
            ArrOfSpheres[j].Speed:=(ArrOfSpheres[j].Speed+ArrOfSpheres[j+1].Speed)*
              (ArrOfSpheres[j].mass/(ArrOfSpheres[j].mass+ArrOfSpheres[j+1].mass));
            ArrOfSpheres[j+1].Speed:=(ArrOfSpheres[j].Speed+ArrOfSpheres[j+1].Speed)*
              (ArrOfSpheres[j+1].mass/(ArrOfSpheres[j].mass+ArrOfSpheres[j+1].mass));
          end;
    end;
    {coordinate calculation}
    ArrOfSpheres[i].x:=ArrOfSpheres[i].x+ArrOfSpheres[i].speed*dt;
  end;
  {spring correction}
  ArrOfSprings[0].x1:=minX;
  ArrOfSprings[0].x2:=ArrOfSpheres[0].x-ArrOfSpheres[0].radius;
  ArrOfSprings[NumbOfSprings-1].x2:=maxX;
  ArrOfSprings[NumbOfSprings-1].x1:=ArrOfSpheres[NumbOfSpheres-1].x+
    ArrOfSpheres[NumbOfSpheres-1].radius;
  if NumbOfSpheres>1 then
    for i:=0 to NumbOfSpheres-2 do
    begin
      ArrOfSprings[i+1].x1:=ArrOfSpheres[i].x+ArrOfSpheres[i].radius;
      ArrOfSprings[i+1].x2:=ArrOfSpheres[i+1].x-ArrOfSpheres[i+1].radius;
    end;
end;

function TOscillSystem.Render(IsRun,CollisionDetection:Boolean):Boolean;
{rendering}
var
  i:Integer;
begin
  if IsRun then
  begin
    if IsReady then
    begin
      Calculate(CollisionDetection);
      Result:=True;
    end else
      Result:=False;
  end else
    Result:=False;
  if NumbOfSprings>0 then
    for i:=0 to NumbOfSprings-1 do
      ArrOfSprings[i].Render;
  if NumbOfSpheres>0 then
    for i:=0 to NumbOfSpheres-1 do
      ArrOfSpheres[i].Render(ArrOfSprings[i].x2,
                             ArrOfSprings[i].x1,
                             ArrOfSprings[i].deflen);
end;

constructor TOscillSystem.Create(ParentHandle:THandle);
begin
  Finalize(ArrOfSprings);
  Finalize(ArrOfSpheres);
  NumbOfSprings:=0;
  NumbOfSpheres:=0;
  Handle:=ParentHandle;
end;

destructor TOscillSystem.Destroy;
var
  i:Integer;
begin
  if NumbOfSpheres>0 then
    for i:=0 to NumbOfSpheres-1 do
      ArrOfSpheres[i].Destroy;
  if NumbOfSprings>0 then
    for i:=0 to NumbOfSprings-1 do
      ArrOfSprings[i].Destroy;
  Finalize(ArrOfSprings);
  Finalize(ArrOfSpheres);
  NumbOfSprings:=0;
  NumbOfSpheres:=0;
  Inherited Destroy;
end;

procedure TOscillSystem.AddSphere(mass,radius:Extended);
{add weight}
var
  i:Integer;
  currLen:Extended;
begin
  if NumbOfSprings=(NumbOfSpheres+1) then
  begin
    currLen:=minX;
    if NumbOfSprings>0 then
      for i:=0 to NumbOfSprings-1 do
        currLen:=currLen+(ArrOfSprings[i].x2-ArrOfSprings[i].x1);
    if NumbOfSpheres>0 then
      for i:=0 to NumbOfSpheres-1 do
        currLen:=currLen+ArrOfSpheres[i].radius;
    inc(NumbOfSpheres);
    SetLength(ArrOfSpheres,NumbOfSpheres);
    ArrOfSpheres[NumbOfSpheres-1]:=TSphere.Create;
    ArrOfSpheres[NumbOfSpheres-1].mass:=mass;
    ArrOfSpheres[NumbOfSpheres-1].radius:=radius;
    ArrOfSpheres[NumbOfSpheres-1].x:=currLen+radius;
  end else
    MessageBox(Handle,'Add a spring first','Error',MB_OK);
end;

procedure TOscillSystem.AddSpring(k,len,dx:Extended);
{add spring}
var
  i:Integer;
  currLen:Extended;
begin
  if NumbOfSprings=NumbOfSpheres then
  begin
    currLen:=minX;
    if NumbOfSprings>0 then
      for i:=0 to NumbOfSprings-1 do
        currLen:=currLen+(ArrOfSprings[i].x2-ArrOfSprings[i].x1);
    if NumbOfSpheres>0 then
      for i:=0 to NumbOfSpheres-1 do
        currLen:=currLen+ArrOfSpheres[i].radius;
    inc(NumbOfSprings);
    SetLength(ArrOfSprings,NumbOfSprings);
    ArrOfSprings[NumbOfSprings-1]:=TSpring.Create;
    ArrOfSprings[NumbOfSprings-1].x1:=currLen;
    ArrOfSprings[NumbOfSprings-1].x2:=currLen+len+dx;
    ArrOfSprings[NumbOfSprings-1].deflen:=len;
    ArrOfSprings[NumbOfSprings-1].k:=k;
  end else
    MessageBox(Handle,'Add a weight first','Error',MB_OK);
end;

procedure TOscillSystem.DelPrev;
{delete the previous object}
begin
  if NumbOfSprings>NumbOfSpheres then
  begin
    dec(NumbOfSprings);
    ArrOfSprings[NumbOfSprings].Destroy;
    SetLength(ArrOfSprings,NumbOfSprings);
  end else
    if NumbOfSpheres>0 then
    begin
      dec(NumbOfSpheres);
      ArrOfSpheres[NumbOfSpheres].Destroy;
      SetLength(ArrOfSpheres,NumbOfSpheres);
    end;
  if (NumbOfSprings=0) and (NumbOfSpheres=0) then
    MessageBox(Handle,'Nothing left to delete','Error',MB_OK);
end;

function TOscillSystem.GetInfo(numb:Integer):ShortString;
var
  s:ShortString;
begin
  if (numb>=0) and (numb<NumbOfSpheres) then
  begin
    s:='Number of springs: '+IntToStr(NumbOfSprings)+#13#10+
       'Number of weights: '+IntToStr(NumbOfSpheres);
    if NumbOfSpheres>numb then
      s:=s+'Mass: '+FloatToStr(ArrOfSpheres[numb-1].mass)+#13#10+
           'Coordinate: '+FloatToStr(ArrOfSpheres[numb-1].x)+#13#10+
           'Speed: '+FloatToStr(ArrOfSpheres[numb-1].speed)+#13#10+
           'Acceleration: '+FloatToStr(ArrOfSpheres[numb-1].acceleration);
    Result:=s;
  end else
    Result:='Number of springs: '+IntToStr(NumbOfSprings)+#13#10+
            'Number of weights: '+IntToStr(NumbOfSpheres);
end;

function TOscillSystem.IsReady:Boolean;
{whether the system is ready for calculations}
begin
  if (NumbOfSpheres>0) and
     (NumbOfSprings>0) and
     (NumbOfSprings-NumbOfSpheres=1) then
    Result:=True
  else
    Result:=False;
end;

procedure TOscillSystem.DrawGraphic(numb,param:Integer);
{graphs rendering}
var
  i:Integer;
begin
  if (numb>=0) and (numb<NumbOfSpheres) then
  begin
    frmGraphics.Chart.Series[0].Clear;
    case param of
      0: for i:=1 to 250 do
           frmGraphics.Chart.Series[0].Add(ArrOfSpheres[numb].ArrOfX[i]);
      1: for i:=1 to 250 do
           frmGraphics.Chart.Series[0].Add(ArrOfSpheres[numb].ArrOfSpeed[i]);
      2: for i:=1 to 250 do
           frmGraphics.Chart.Series[0].Add(ArrOfSpheres[numb].ArrOfAcceleration[i]);
    end;
  end;
end;

procedure TOscillSystem.DelAll;
{delete all objects}
var
  i:Integer;
begin
  if (NumbOfSprings=0) and (NumbOfSpheres=0) then
    MessageBox(Handle,'Nothing left to delete','Error',MB_OK);
  if NumbOfSpheres>0 then
    for i:=0 to NumbOfSpheres-1 do
      ArrOfSpheres[i].Destroy;
  if NumbOfSprings>0 then
    for i:=0 to NumbOfSprings-1 do
      ArrOfSprings[i].Destroy;
  SetLength(ArrOfSprings,0);
  SetLength(ArrOfSpheres,0);
  NumbOfSprings:=0;
  NumbOfSpheres:=0;
end;

end.
