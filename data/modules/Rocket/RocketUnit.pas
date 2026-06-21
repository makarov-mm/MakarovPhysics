{
Program: Rocket flight\nAuthor: M.M. Makarov\nCreated: November 2004\nIDE: Delphi 7
}
unit RocketUnit;

interface

uses
  Windows, OpenGL, unitFrmGraphics, ParticleSystemModule, Classes, SysUtils;

type
  TRocket = class
  private
    QuadObj: Array[1..4] of GLUquadricObj;
    H1,{First stage height}
    H2,{Second stage height}
    mass,{rocket mass without fuel}
    reactSpeed: Extended;{jet speed}
    SpeedDiagram: Array[1..500] of Single;
    HDiagram: Array[1..500] of Single;
    AccelDiagram: Array[1..500] of Single;
    ParticleSystem1: TParticleSystem;{particle system 1}
    ParticleSystem2: TParticleSystem;{particle system 2}
    tt: Integer;
  public
    Speed,{speed}
    Acceleration,{acceleration}
    H: Extended;{Height}
    IsRun: Boolean;
    FlyTime: Int64;{flight time}
    {fuel}
    fuel: Array[1..3] of record
      mass, speed:Extended;
    end;
    constructor Create;
    destructor Destroy;override;
    procedure Draw(param:Boolean);
    procedure ReturnToBase;
    procedure CanStart(m, rs, fm1, fs1, fm2, fs2, fm3, fs3:Extended);
    procedure Calc;
    procedure DrawDiagram;
    procedure UpgradeArrays;
  end;

implementation

uses unitFrmLibMain;

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

procedure TRocket.UpgradeArrays;
{array update}
var
  i: Integer;
begin
  inc(tt);
  if tt>=10 then
  begin
  tt := 0;
    for i := 1 to 499 do
    begin
      SpeedDiagram[i] := SpeedDiagram[i + 1];
      AccelDiagram[i] := AccelDiagram[i + 1];
      HDiagram[i] := HDiagram[i + 1];
    end;
    SpeedDiagram[500] := Speed;
    AccelDiagram[500] := Acceleration;
    HDiagram[500] := H;
  end;
end;

procedure TRocket.DrawDiagram;
{graph rendering}
var
  i: Integer;
begin
  UpgradeArrays;
  frmLibMain.InfoThread.ShowInfo;
  frmGraphics.Chart.Series[0].Clear;

  case frmGraphics.tabs.TabIndex of
    0: begin
         frmGraphics.Chart.Title.Text.Text := 'Height (m)';
         for i := 1 to 500 do
           frmGraphics.Chart.Series[0].Add(HDiagram[i]);
       end;
    1: begin
         frmGraphics.Chart.Title.Text.Text := 'Speed (m/s)';
         for i := 1 to 500 do
           frmGraphics.Chart.Series[0].Add(SpeedDiagram[i]);
       end;
    2: begin
         frmGraphics.Chart.Title.Text.Text := 'Acceleration (m/s^2)';
         for i := 1 to 500 do
           frmGraphics.Chart.Series[0].Add(AccelDiagram[i]);
       end;
  end;
end;

procedure TRocket.CanStart(m,rs,fm1,fs1,fm2,fs2,fm3,fs3:Extended);
{launches the rocket once the stand drops away}
begin
  if not IsRun then
  begin
    IsRun := True;
    mass := m * 1000;
    reactSpeed := rs;
    fuel[1].mass := fs1 * 1000;
    fuel[1].speed := fm1;
    fuel[2].mass := fs2 * 1000;
    fuel[2].speed := fm2;
    fuel[3].mass := fs3 * 1000;
    fuel[3].speed := fm3;
  end;
end;

procedure TRocket.Calc;
{rocket motion calculation}
const
  t = 1 / 1000;
  g = 9.8067;
var
  i: Integer;
begin
  for i := 1 to 40 do
  begin
    Inc(FlyTime);
    if fuel[1].mass > 0 then
    begin
      Acceleration := (reactSpeed * fuel[1].speed)/
                      (fuel[1].mass + fuel[2].mass + fuel[3].mass+mass) - g;
      Speed := Speed + Acceleration * t;

      if (H + Speed * t - 20) >= 12 then
      begin
        H := H + Speed * t;
        H1 := H - 20;
        H2 := H - 10;
      end else
        Speed := 0;

      fuel[1].mass := fuel[1].mass - fuel[1].speed * t;
      ParticleSystem1.ParticleGenSphere(0, 27, 0, 5, Speed);
      ParticleSystem2.ParticleGenSphere(0, 27, 0, 5, Speed);
    end else
      if fuel[2].mass > 0 then
      begin
        Acceleration := (reactSpeed * fuel[2].speed) /
                        (fuel[2].mass + fuel[3].mass + mass) - g;
        Speed := Speed + Acceleration * t;

        if (H + Speed * t - 10) >= 10 then
        begin
          H := H + Speed * t;
          H1 := H1 + Speed * t * 0.99;
          H2 := H - 10;
        end else
          Speed := 0;

        fuel[2].mass := fuel[2].mass - fuel[2].speed * t;
        ParticleSystem1.ParticleGenSphere(0, 17, 0, 5, Speed);
        ParticleSystem2.ParticleGenSphere(0, 17, 0, 5, Speed);
      end else
        if fuel[3].mass > 0 then
        begin
          Acceleration := (reactSpeed * fuel[3].speed) /
                          (fuel[3].mass + mass) - g;
          Speed := Speed + Acceleration * t;

          if (H + Speed * t) >= 10 then
          begin
            H := H + Speed * t;
            H2 := H2 + Speed * t * 0.995;
          end else
            Speed := 0;

          fuel[3].mass := fuel[3].mass - fuel[3].speed * t;
          ParticleSystem1.ParticleGenSphere(0, 7, 0, 5, Speed);
          ParticleSystem2.ParticleGenSphere(0, 7, 0, 5, Speed);
        end else begin
          Acceleration := -g;
          Speed := Speed + Acceleration * t;

          if (H + Speed * t) >= 10 then
            H := H + Speed * t
          else
            Speed := 0;

          ParticleSystem1.ParticleGenSphere(0, 27, 0, 5, Speed);
          ParticleSystem2.ParticleGenSphere(0, 27, 0, 5, Speed);
        end;
  end;
  DrawDiagram;
end;

procedure TRocket.ReturnToBase;
{return to base}
{resets all rocket values except\n the parameters set in the options}
var
  i: Integer;
begin
  H := 32;
  H1 := 12;
  H2 := 22;
  Speed := 0;
  Acceleration := 0;

  for i := 1 to 3 do
    fuel[i].mass := 0;

  for i := 1 to 500 do
  begin
    HDiagram[i] := 0;
    SpeedDiagram[i] := 0;
    AccelDiagram[i] := 0;
  end;

  FlyTime := 0;
  ParticleSystem1.ParticleGenSphere(0, 30, 0, 5, Speed);
  ParticleSystem2.ParticleGenSphere(0, 30, 0, 5, Speed);
  tt := 0;
end;

constructor TRocket.Create;
var
  i: Integer;
begin
  {create particle systems}
  ParticleSystem1 := TParticleSystem.Create(0, 30, 0, 5);
  ParticleSystem2 := TParticleSystem.Create(0, 30, 0, 5);

  {create Quadric objects}
  for i := 1 to 4 do
  begin
    QuadObj[i] := gluNewQuadric;
    gluQuadricDrawStyle(QuadObj[i], GLU_FILL);
    gluQuadricOrientation(QuadObj[i], GLU_OUTSIDE);
  end;

  {reset rocket parameters}
  IsRun := False;
  ReturnToBase;
end;

destructor TRocket.Destroy;
var
  i: Integer;
begin
  Inherited Destroy;
  ParticleSystem1.Destroy;
  ParticleSystem1 := nil;
  ParticleSystem2.Destroy;
  ParticleSystem2 := nil;

  for i := 1 to 4 do
    gluDeleteQuadric(QuadObj[i]);
end;

procedure TRocket.Draw(param:Boolean);
{rocket redraw}
var
  i: Integer;
begin
  glEnable (GL_TEXTURE_GEN_S);
  glEnable (GL_TEXTURE_GEN_T);

  for i := 1 to 20 do
    glPushMatrix;

  {stage 1}
  glTranslatef(0, H1, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 2, 2, 10, 50, 50);

  glBindTexture(GL_TEXTURE_2D, 3);
  glPopMatrix;
  glTranslatef(0, H1 - 3, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 2.6, 2.6, 7, 50, 50);
  glBindTexture(GL_TEXTURE_2D, 7);

  glPopMatrix;
  glTranslatef(0, H1 - 2, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 2, 2.6, 1, 50, 50);

  glPopMatrix;
  glTranslatef(0, H1 - 10, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 2.6, 4, 1, 50, 50);

  glBindTexture(GL_TEXTURE_2D, 5);

  {small rockets}
  glPopMatrix;
  glTranslatef(-2.3, H1 - 2, -2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 0.8, 8, 16, 16);

  glPopMatrix;
  glTranslatef(2.3, H1 - 2, -2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 0.8, 8, 16, 16);

  glPopMatrix;
  glTranslatef(-2.3, H1 - 2, 2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 0.8, 8, 16, 16);

  glPopMatrix;
  glTranslatef(2.3, H1 - 2, 2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 0.8, 8, 16, 16);

  glPopMatrix;
  glTranslatef(-2.3, H1, -2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0, 0.8, 2, 16, 16);

  glPopMatrix;
  glTranslatef(2.3, H1, -2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0, 0.8, 2, 16, 16);

  glPopMatrix;
  glTranslatef(-2.3, H1, 2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0, 0.8, 2, 16, 16);

  glPopMatrix;
  glTranslatef(2.3, H1, 2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0, 0.8, 2, 16, 16);

  glPopMatrix;
  glTranslatef(-2.3, H1 - 10, -2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 1.2, 1, 16, 16);

  glPopMatrix;
  glTranslatef(2.3, H1 - 10, -2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 1.2, 1, 16, 16);

  glPopMatrix;
  glTranslatef(-2.3, H1 - 10, 2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 1.2, 1, 16, 16);

  glPopMatrix;
  glTranslatef(2.3, H1 - 10, 2.3);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[1], 0.8, 1.2, 1, 16, 16);

  glBindTexture(GL_TEXTURE_2D, 7);
  {==========================================}
  {stage 2}
  glPopMatrix;
  glTranslatef(0, H2, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[2], 2, 2, 10, 50, 50);

  glPopMatrix;
  glTranslatef(0, H2 - 2, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[2], 2.5, 2.5, 6, 50, 50);

  {==========================================}
  {stage 3}
  glPopMatrix;
  glTranslatef(0, H - 5, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[3], 2, 2, 5, 50, 50);

  glPopMatrix;
  glTranslatef(0, H - 6, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[3], 2.3, 2.3, 3, 50, 50);

  {==========================================}
  glPopMatrix;
  glTranslatef(0, H, 0);
  glRotatef(90, 1, 0, 0);
  gluCylinder(QuadObj[4], 0, 2, 5, 50, 50);

  glDisable (GL_TEXTURE_GEN_S);
  glDisable (GL_TEXTURE_GEN_T);

  for i := 1 to 10 do
  begin
    ParticleSystem1.Generate;
    ParticleSystem2.Generate;
  end;
  if param then
    if fuel[3].mass > 0 then
    begin
      ParticleSystem1.Render;
      ParticleSystem2.Render;
    end;
end;

end.
