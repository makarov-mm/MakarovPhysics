unit FieldLine;

interface

uses
  OpenGL;

type
  TFieldLine = class
  private
    LineType:Boolean;{line type:\n                      true - field force lines\n                      false - equipotential surfaces}
    QPosition:array of record {array of charges}
                x,y:Extended;{position}
                q:Extended;{charge}
              end;
    NumbOfQ:Integer;{number of charges}
    NumbOfLines:Integer;{number of lines}
    ArrayOfLines:array of record
      x,y:Extended;
    end;
  public
    constructor Create(NewLineType:Boolean; x,y:Extended);
    procedure AddQ(x,y,q:Extended);
    procedure Render;
    procedure Calculate;
  end;

  
implementation

constructor TFieldLine.Create(NewLineType:Boolean; x,y:Extended);
begin
  LineType:=NewLineType;
  NumbOfQ:=0;
  NumbOfLines:=1;
  SetLength(ArrayOfLines,NumbOfLines);
  ArrayOfLines[NumbOfLines-1].x:=x;
  ArrayOfLines[NumbOfLines-1].y:=y;
end;

procedure TFieldLine.AddQ(x,y,q:Extended);
{add charge}
begin
  inc(NumbOfQ);
  SetLength(QPosition,NumbOfQ);
  QPosition[NumbOfQ-1].x:=x;
  QPosition[NumbOfQ-1].y:=y;
  QPosition[NumbOfQ-1].q:=q;
end;

procedure TFieldLine.Render;
{field line rendering}
var
  i:Integer;
begin
  glColor3f(1,1,1);
  glBegin(GL_LINE_STRIP);
  if NumbOfLines<>0 then
    for i:=0 to NumbOfLines-1 do
      glVertex3f(ArrayOfLines[i].x,ArrayOfLines[i].y,0);
  glEnd;
end;

procedure TFieldLine.Calculate;
{field line calculation}
const
  MaxLines=10000;
  dL=0.01;
  k=1{9000000000};
var
  E,Ex,Ey:Extended;
  i:Integer;
begin
  if LineType then
  begin
    while NumbOfLines<MaxLines do
    begin
      inc(NumbOfLines);
      SetLength(ArrayOfLines,NumbOfLines);
      Ex:=0;
      Ey:=0;
      E:=0;
      for i:=0 to NumbOfQ-1 do
      begin
        Ex:=Ex+{k/}sqr(QPosition[i].x-ArrayOfLines[NumbOfLines-2].x);
        Ey:=Ey+{k/}sqr(QPosition[i].y-ArrayOfLines[NumbOfLInes-2].y);
        E:=E+{k/}(sqr(QPosition[i].y-ArrayOfLines[NumbOfLInes-2].y)+
                sqr(QPosition[i].x-ArrayOfLines[NumbOfLines-2].x));
      end;
      ArrayOfLines[NumbOfLines-1].x:=ArrayOfLines[NumbOfLines-2].x+dL*Ex/E;
      ArrayOfLines[NumbOfLines-1].y:=ArrayOfLines[NumbOfLines-2].y+dL*Ey/E;
    end;


  end else begin



  end;
end;

end.
