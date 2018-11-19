unit gm_pathfind;

interface

uses
  gm_types, gm_map, gm_creature;

var
  Wave              : array of array of Integer;
  WaveW, WaveH      : Integer;
  wt1, wt2          : array of TPoint2D;
  wt1Cnt, wt2Cnt    : Integer;
  wt1Len, wt2Len    : Integer;

procedure CreateWave( M : TMap; x, y, x2, y2 : Integer; IgnoreFog : Boolean = False; IgnoreCr : Boolean = False );
function GetNextStep( x, y : Integer ) : TPoint2D;

implementation

//==============================================================================
function Wave_GetNear( t : TPoint2D; napr : Byte; var t2 : TPoint2D ) : Integer;
begin
  Result := -1;
  case napr of
    1 : t2 := Point2D( t.X + 1, t.Y );
    2 : t2 := Point2D( t.X, t.Y + 1 );
    3 : t2 := Point2D( t.X - 1, t.Y );
    4 : t2 := Point2D( t.X, t.Y - 1 );
    5 : t2 := Point2D( t.X + 1, t.Y + 1 );
    6 : t2 := Point2D( t.X + 1, t.Y - 1 );
    7 : t2 := Point2D( t.X - 1, t.Y + 1 );
    8 : t2 := Point2D( t.X - 1, t.Y - 1 );
  end;
  if ( t2.X < 0 ) or ( t2.X >= WaveW ) or ( t2.Y < 0 ) or ( t2.Y >= WaveH ) then Exit;
  Result := Wave[ t2.X, t2.Y ];
end;

//==============================================================================
procedure FillWave( x, y, x2, y2 : Integer );
var
  i, k    : Integer;
  t2      : TPoint2D;
  Napr    : Byte;
begin
  Wave[ x, y ] := 1;
  k := 1;

  wt1Cnt := 1;
  wt2Cnt := 0;
  if wt1Cnt > wt1Len - 10 then
  begin
    wt1Len := wt1Len + 100;
    SetLength( wt1, wt1Len );
  end;
  if wt2Cnt > wt2Len - 10 then
  begin
    wt2Len := wt2Len + 100;
    SetLength( wt2, wt2Len );
  end;
  wt1[ 0 ] := Point2D( x, y );

  while True do
  begin
    wt2Cnt := 0;
    k := k + 1;
    for i := 0 to wt1Cnt - 1 do
    begin
      for Napr := 1 to 8 do
        if Wave_GetNear( wt1[ i ], Napr, t2 ) = 0 then
        begin
          INC( wt2Cnt );
          wt2[ wt2Cnt - 1 ] := t2;
          Wave[ t2.X, t2.Y ] := k;
          if ( t2.X = x2 ) and ( t2.Y = y2 ) then Exit;
        end;
      if wt2Cnt > wt2Len - 10 then
      begin
        wt2Len := wt2Len + 100;
        SetLength( wt2, wt2Len );
      end;
    end;

    if wt2Cnt = 0 then Exit;

    wt1Cnt := 0;
    k := k + 1;
    for i := 0 to wt2Cnt - 1 do
    begin
      for Napr := 1 to 8 do
        if Wave_GetNear( wt2[ i ], Napr, t2 ) = 0 then
        begin
          INC( wt1Cnt );
          wt1[ wt1Cnt - 1 ] := t2;
          Wave[ t2.X, t2.Y ] := k;
          if ( t2.X = x2 ) and ( t2.Y = y2 ) then Exit;
        end;
      if wt1Cnt > wt1Len - 10 then
      begin
        wt1Len := wt1Len + 100;
        SetLength( wt1, wt1Len );
      end;
    end;

    if wt1Cnt = 0 then Exit;
  end;
end;

//==============================================================================
procedure CreateWave( M : TMap; x, y, x2, y2 : Integer; IgnoreFog : Boolean = False; IgnoreCr : Boolean = False );
var
  w, h : Integer;
  i, j : Integer;
  Cr   : TCreature;
begin
  w := M.Width;
  h := M.Height;
  if ( x < 0 ) or ( x >= w ) or ( y < 0 ) or ( y >= h ) then Exit;

  if ( w > WaveW ) or ( h > WaveH ) then SetLength( Wave, w, h );
  WaveW := w;
  WaveH := h;

  for j := 0 to WaveH - 1 do
    for i := 0 to WaveW - 1 do
    begin
      Wave[ i, j ] := 0;
      if M.Objects.Obj[ i, j ] <> nil then
        if M.Objects.Obj[ i, j ].BlockWalk then Wave[ i, j ] := -1;
      if ( IgnoreFog = False ) and ( M.Fog[ i, j ] = 0 ) then Wave[ i, j ] := -1;
    end;

  if IgnoreCr = False then
    for i := 0 to Map.Creatures.Count - 1 do
    begin
      Cr := TCreature( Map.Creatures[ i ] );
      if ( IgnoreFog = False ) and ( M.Fog[ Cr.TX, Cr.TY ] <> 2 ) then Continue;
      Wave[ Cr.TX, Cr.TY ] := -1;
    end;

  FillWave( x, y, x2, y2 );
end;

//==============================================================================
function GetNextStep( x, y : Integer ) : TPoint2D;
var
  Napr  : Byte;
  t, t2 : TPoint2D;
  i, j  : Integer;
begin
  j  := 1000000;
  t2 := Point2D( -1, 0 );
  for Napr := 1 to 8 do
  begin
    i := Wave_GetNear( Point2D( x, y ), Napr, t );
    if ( i > 0 ) and ( i < j ) then
    begin
      j  := i;
      t2 := t;
    end;
  end;
  Result := t2;
end;

end.
