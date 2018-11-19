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

    constructor Create( w, h : Integer );
    destructor Destroy; override;
    procedure Draw;
    procedure Update;
    procedure Fill( GroundName : String );
  end;

implementation

//==============================================================================
constructor TGround.Create( w, h : Integer );
begin
  Width   := w;
  Height  := h;
  SetLength( Tiles, w, h );
end;

//==============================================================================
destructor TGround.Destroy;
begin

  inherited;
end;

//==============================================================================
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

//==============================================================================
procedure TGround.Update;
begin

end;

//==============================================================================
procedure TGround.Fill( GroundName : String );
var
  Pat  : TGroundPat;
  i, j : Integer;
begin
  Pat := TGroundPat( Pattern_Get( 'GROUND', GroundName ) );
  if Pat = nil then Exit;

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      Tiles[ i, j ].Pat := Pat;
end;

end.
