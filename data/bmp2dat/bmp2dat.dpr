program bmp2dat;
{
Texture packer for the physics programs complex.
Packs <dir>\1.bmp .. N.bmp (each size x size, 24-bit) into one raw .dat pack,
in the byte layout the engine expects (row-major RGB, source pixel mirrored
horizontally to match the original GL orientation).

Usage:
  bmp2dat <sourceDir> <size> <outFile>
    e.g.  bmp2dat data\textures\skybox  256 data\textures\skybox.dat
          bmp2dat data\textures\preview 512 data\textures\preview.dat

With no arguments it falls back to the old interactive behaviour:
reads 1.bmp.. from the current directory into TexturesPack.dat (256 px).
}

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, Graphics;

type
  TTripleRow = array[0..65535] of TRGBTriple;
  PTripleRow = ^TTripleRow;

var
  srcDir, outFile: string;
  size, i, j, k, n: Integer;
  bmp: TBitmap;
  fs: TFileStream;
  buf: array of Byte;
  fn: string;
  scan: PTripleRow;
  interactive: Boolean;
begin
  WriteLn('bmp2dat converter');

  interactive := ParamCount < 3;
  if interactive then
  begin
    srcDir := '.';
    size := 256;
    outFile := 'TexturesPack.dat';
  end
  else
  begin
    srcDir := ParamStr(1);
    size := StrToInt(ParamStr(2));
    outFile := ParamStr(3);
  end;

  bmp := TBitmap.Create;
  SetLength(buf, size * size * 3);
  fs := TFileStream.Create(outFile, fmCreate);
  try
    i := 0;
    n := 0;
    repeat
      Inc(i);
      fn := IncludeTrailingPathDelimiter(srcDir) + IntToStr(i) + '.bmp';
      if not FileExists(fn) then Break;
      WriteLn('  ' + fn);
      bmp.LoadFromFile(fn);
      bmp.PixelFormat := pf24bit;
      for j := 0 to size - 1 do
      begin
        scan := bmp.ScanLine[j];
        for k := 0 to size - 1 do
        begin
          // original orientation: take source pixel (size-1-k, j)
          buf[(j * size + k) * 3 + 0] := scan[size - 1 - k].rgbtRed;
          buf[(j * size + k) * 3 + 1] := scan[size - 1 - k].rgbtGreen;
          buf[(j * size + k) * 3 + 2] := scan[size - 1 - k].rgbtBlue;
        end;
      end;
      fs.WriteBuffer(buf[0], Length(buf));
      Inc(n);
    until False;
  finally
    fs.Free;
    bmp.Free;
  end;

  WriteLn(Format('Complete: %d textures -> %s', [n, outFile]));
  if interactive then
  begin
    WriteLn('press Enter...');
    ReadLn;
  end;
end.
