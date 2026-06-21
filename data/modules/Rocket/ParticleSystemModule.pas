{
Program: Rocket flight\nAuthor: M.M. Makarov\nCreated: November 2004\nIDE: Delphi 7
}
unit ParticleSystemModule;

interface

uses Windows, OpenGL;

type
  TMyParticle = record
    x, y, z: Single;{particle coordinates}
    speed: record{particle speed}
      x, y, z: Single;
    end;
    lifetime: Integer;{particle lifetime}
  end;

  TParticleSystem = class
  private
    p: TMyParticle;{particle spawn position}
    pa: Array[1..5000] of TMyParticle; {array of particles}
    r: Single;{sphere radius}
  public
    constructor Create(x, y, z, Radius: Single);
    destructor Destroy; override;
    procedure ParticleGenSphere(x, y, z, Radius, s:Single);
    procedure Render;
    procedure Generate;
  end;

implementation

procedure TParticleSystem.Render;
{particle rendering}
const
  dt = 40 / 1000;
var
  i: Integer;
begin
  glDisable(GL_TEXTURE_2D);
  glPointSize(7);
  glBegin(GL_POINTS);

  for i := 1 to 5000 do
    if pa[i].lifetime > 0 then
    begin
      case Random(2) of
        0: glColor3f(0.7, 0, 0);
        1: if Random(100) < 95 then
             glColor3f(0.2, 0.2, 0.2)
           else
             glColor3f(0.7, 0.7, 0);
      end;
      pa[i].x := pa[i].x + pa[i].speed.x * dt;
      pa[i].y := pa[i].y + pa[i].speed.y * dt;
      pa[i].z := pa[i].z + pa[i].speed.z * dt;
      pa[i].lifetime := pa[i].lifetime - 1;
      glVertex3f(pa[i].x, pa[i].y, pa[i].z);
    end;

  glEnd;
  glColor3f(1, 1, 1);
  glEnable(GL_TEXTURE_2D);
end;

destructor TParticleSystem.Destroy;
begin
  Inherited Destroy;
end;

procedure TParticleSystem.Generate;
{particle generation}
var
  i: Integer;
  t: Boolean;
begin
  t := False;
  i := 0;
  while (t = False) and (i < 5000) do
  begin
    inc(i);

    if pa[i].lifetime <= 0 then
    begin
      pa[i].x := 0;//p.x;
      pa[i].y := 0;//p.y;
      pa[i].z := p.y;//p.z;
      pa[i].speed.x := (Random(400) - 200) / 20;
      pa[i].speed.y := (Random(400) - 200) / 20;
      pa[i].speed.z := 30;//+p.speed.y;
      t := True;
      pa[i].lifetime := Random(50);
    end;

  end;
end;

constructor TParticleSystem.Create(x, y, z, Radius: Single);
begin
  p.x := x;
  p.y := y;
  p.z := z;
end;

procedure TParticleSystem.ParticleGenSphere(x, y, z, Radius, s: Single);
{set parameters of the sphere where particles are generated}
begin
  p.x := x;
  p.y := y;
  p.z := z;
  p.speed.y := s;
  r := Radius;
end;

end.
