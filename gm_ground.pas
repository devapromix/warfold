unit gm_ground;

interface

uses
  zglHeader, gm_patterns;

type
  TTile = record
    Pat     : TGroundPat;
    FrameN  : Byte;
  end;

type
  TGround = class
    Width   : Integer;
    Height  : Integer;
    Tiles   : array of array of TTile;

    constructor Create(W, H: Integer);
    destructor Destroy; override;
    procedure Draw;
    procedure Update;
    procedure Fill(GroundName: string);
    procedure FillRandom(GroundName: String; Count: Integer);
  end;

implementation

constructor TGround.Create( w, h : Integer );
begin
  Width   := w;
  Height  := h;
  SetLength( Tiles, w, h );
end;

destructor TGround.Destroy;
begin

  inherited;
end;

procedure TGround.Draw;
var
  i, j  : Integer;
  Pat   : TGroundPat;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if Tiles[ i, j ].Pat = nil then Continue;
      Pat := Tiles[ i, j ].Pat;

      asprite2d_Draw( Pat.Tex, i * 32, j * 32, 32, 32, 0, 1 );
    end;
end;

procedure TGround.Update;
begin

end;

procedure TGround.Fill( GroundName : String );
var
  Pat: TGroundPat;
  i, j: Integer;
begin
  Pat := TGroundPat( Pattern_Get( 'GROUND', GroundName ) );
  if Pat = nil then Exit;

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      Tiles[ i, j ].Pat := Pat;
end;

procedure TGround.FillRandom(GroundName : String; Count: Integer);
var
  X, Y, I, J, C, N: Integer;
  Pat: TGroundPat;
begin
  Pat := TGroundPat(Pattern_Get('GROUND', GroundName));
  if Pat = nil then Exit;
  for I := 0 to Count - 1 do
  begin
    X := Random(Width - 1) + 1;
    Y := Random(Height - 1) + 1;
    C := Random(9) + 10;
    for J := 0 to C do
    begin
      N := Random(9);
      case N of
        0: X := X + 1;
        1: Y := Y + 1;
        2: X := X - 1;
        3: Y := Y - 1;
        4: begin
          X := X + 1;
          Y := Y + 1;
        end;
        5: begin
          X := X - 1;
          Y := Y - 1;
        end;
        6: begin
          X := X + 1;
          Y := Y - 1;
        end;
        7: begin
          X := X - 1;
          Y := Y + 1;
        end;
      end;
      if (X < 0) or (Y < 0) or (X >= Width) or (Y >= Height) then Continue;
      Tiles[x, y].Pat := Pat;
    end;
  end;
end;

end.
