unit gm_generator;

interface

uses
  zglHeader, gm_types, gm_patterns, gm_map, gm_creature, gm_item, gm_pathfind;

type
  PRoom = ^TRoom;
  TRoom = record
    TX, TY  : Integer;
    W, H    : Integer;
    Walls   : array of array of Byte;
  end;

procedure GenerateWalls( M : TMap );
procedure ClearSmallRooms( M : TMap );
procedure GenerateDoors( M : TMap );
procedure GenerateTreasures( M : TMap );
procedure TreasuresConvert( M : TMap );
procedure GenerateCreatures( M : TMap );

implementation

procedure InitRoom( Room : PRoom );
var
  i, j, x1, y1, w, h, k : Integer;
begin
  Room.W := Random( 8 ) + 5;
  Room.H := Random( 8 ) + 5;
  SetLength( Room.Walls, Room.W, Room.H );
  for j := 0 to Room.H - 1 do
    for i := 0 to Room.W - 1 do
    begin
      Room.Walls[ i, j ] := 1;
      if ( i = 0 ) or ( j = 0 ) or ( i = Room.W - 1 ) or ( j = Room.H - 1 ) then Room.Walls[ i, j ] := 2;
    end;

  w  := Random( Room.W - 3 );
  h  := Random( Room.H - 3 );
  if ( w <= 1 ) or ( h <= 1 ) then Exit;
  x1 := 0;
  y1 := 0;
  k := Random( 3 );
  if ( k = 0 ) or ( k = 2 ) then x1 := Room.W - w;
  if ( k = 1 ) or ( k = 2 ) then y1 := Room.H - h;
  if Random( 5 ) = 0 then
  begin
    x1 := Random( Room.W - w );
    y1 := Random( Room.H - h );
  end;

  for j := y1 to y1 + h do
    for i := x1 to x1 + w do
    begin
      if ( i < 0 ) or ( j < 0 ) or ( i >= Room.W ) or ( j >= Room.H ) then Continue;
      Room.Walls[ i, j ] := 0;
      if ( i = 0 ) or ( j = 0 ) or ( i = w ) or ( j = h ) then
        if not( ( i = 0 ) or ( j = 0 ) or ( i = Room.W - 1 ) or ( j = Room.H - 1 ) ) then Room.Walls[ i, j ] := 2;
    end;
end;

procedure GenerateWalls( M : TMap );
var
  i, j, n, l, x, y, dx, dy, k, napr : Integer;
  WallPat     : TObjPat;
  Room        : TRoom;
  Walls       : array of array of Byte;
  bool        : Boolean;
  con         : Integer;
  Tnl         : array of TPoint2D;
  TnlLen      : Integer;
begin
  WallPat := TObjPat( Pattern_Get( 'OBJECT', 'Wall' ) );

  SetLength( Walls, M.Width, M.Height );
  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      Walls[ i, j ] := 0;

  for n := 0 to 1500 do
  begin
    InitRoom( @Room );
    Room.TX := Random( M.Width - Room.W + 1 );
    Room.TY := Random( M.Height - Room.H + 1 );

    con := 0;
    bool := True;
    for j := 0 to Room.H - 1 do
    begin
      for i := 0 to Room.W - 1 do
      begin
        if ( Walls[ i + Room.TX, j + Room.TY ] = 1 ) and ( Room.Walls[ i, j ] = 2 ) then bool := False;
        if ( Room.Walls[ i, j ] = 2 ) and ( Walls[ i + Room.TX, j + Room.TY ] = 2 ) then con := con + 1;
        if bool = False then Break;
      end;
      if bool = False then Break;
    end;

    if ( n > 0 ) and ( con < 4 ) then Continue;
    if bool = False then Continue;

    for j := 0 to Room.H - 1 do
      for i := 0 to Room.W - 1 do
        Walls[ i + Room.TX, j + Room.TY ] := Room.Walls[ i, j ];
  end;

  for n := 0 to 300 do
  begin
    x := Random( M.Width );
    y := Random( M.Height );
    if Walls[ x, y ] <> 2 then Continue;

    TnlLen := 1;
    SetLength( Tnl, TnlLen );
    Tnl[ TnlLen - 1 ] := Point2D( x, y );

    k := Random( 4 ) + 1;
    for j := 0 to k do
    begin
      l := Random( 5 ) + 3;
      napr := Random( 4 );
      dx := 0;
      dy := 0;
      if Napr = 0 then dx := -1;
      if Napr = 1 then dx := 1;
      if Napr = 2 then dy := -1;
      if Napr = 3 then dy := 1;
      for i := 0 to l do
      begin
        x := x + dx;
        y := y + dy;
        if ( x < 0 ) or ( y < 0 ) or ( x >= M.Width ) or ( y >= M.Height ) then Break;
        if Walls[ x, y ] <> 0 then Break;
        TnlLen := TnlLen + 1;
        SetLength( Tnl, TnlLen );
        Tnl[ TnlLen - 1 ] := Point2D( x, y );
      end;
      if TnlLen < 3 then Break;
      x := Tnl[ TnlLen - 1 ].X;
      Y := Tnl[ TnlLen - 1 ].Y;
    end;

    if TnlLen > 5 then
      for i := 0 to TnlLen - 1 do
        Walls[ Tnl[ i ].X, Tnl[ i ].Y ] := 1;
  end;


  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      if Walls[ i, j ] = 1 then Walls[ i, j ] := 0 else Walls[ i, j ] := 1;

  n := 0;
  for j := 1 to M.Height - 2 do
    for i := 0 to M.Width - 1 do
    begin
      l := n;
      if ( Walls[ i, j ] = 1 ) and ( Walls[ i, j - 1 ] = 0 ) and ( Walls[ i, j + 1 ] = 0 ) then n := n + 1
        else n := 0;
      if ( l > 0 ) and ( n = 0 ) then
      begin
        l := Random( l ) + 1;
        Walls[ i - l, j ] := 0;
      end;
      if i = M.Width - 1 then n := 0;
    end;

  n := 0;
  for i := 1 to M.Width - 2 do
    for j := 0 to M.Height - 1 do
    begin
      l := n;
      if ( Walls[ i, j ] = 1 ) and ( Walls[ i - 1, j ] = 0 ) and ( Walls[ i + 1, j ] = 0 ) then n := n + 1
        else n := 0;
      if ( l > 0 ) and ( n = 0 ) then
      begin
        l := Random( l ) + 1;
        Walls[ i, j - l ] := 0;
      end;
      if j = M.Height - 1 then n := 0;
    end;

  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      if ( i = 0 ) or ( j = 0 ) or ( i = M.Width - 1 ) or ( j = M.Height - 1  ) then Walls[ i, j ] := 1;

  for k := 0 to 5 do
    for j := 1 to M.Height - 2 do
      for i := 1 to M.Width - 2 do
      begin
        if ( Walls[ i, j ] = 0 ) and ( Walls[ i + 1, j + 1 ] = 0 ) and ( Walls[ i + 1, j ] = 1 ) and ( Walls[ i, j + 1 ] = 1 ) then Walls[ i, j ] := 1;
        if ( Walls[ i, j ] = 1 ) and ( Walls[ i + 1, j + 1 ] = 1 ) and ( Walls[ i + 1, j ] = 0 ) and ( Walls[ i, j + 1 ] = 0 ) then Walls[ i + 1, j ] := 1;
        if ( Walls[ i, j ] = 0 ) and ( Walls[ i - 1, j ] = 0 ) and ( Walls[ i + 1, j ] = 1 ) and ( Walls[ i, j - 1 ] = 1 ) and ( Walls[ i, j + 1 ] = 1 ) then Walls[ i, j ] := 1;
        if ( Walls[ i, j ] = 0 ) and ( Walls[ i - 1, j ] = 1 ) and ( Walls[ i + 1, j ] = 0 ) and ( Walls[ i, j - 1 ] = 1 ) and ( Walls[ i, j + 1 ] = 1 ) then Walls[ i, j ] := 1;
        if ( Walls[ i, j ] = 0 ) and ( Walls[ i - 1, j ] = 1 ) and ( Walls[ i + 1, j ] = 1 ) and ( Walls[ i, j - 1 ] = 0 ) and ( Walls[ i, j + 1 ] = 1 ) then Walls[ i, j ] := 1;
        if ( Walls[ i, j ] = 0 ) and ( Walls[ i - 1, j ] = 1 ) and ( Walls[ i + 1, j ] = 1 ) and ( Walls[ i, j - 1 ] = 1 ) and ( Walls[ i, j + 1 ] = 0 ) then Walls[ i, j ] := 1;
      end;

  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
    begin
      if Walls[ i, j ] = 1 then M.Objects.ObjCreate( i, j, WallPat );
    end;
end;

procedure ClearSmallRooms( M : TMap );
var
  WallPat : TObjPat;
  i, j    : Integer;
begin
  WallPat := TObjPat( Pattern_Get( 'OBJECT', 'Wall' ) );
  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      if Wave[ i, j ] = 0 then M.Objects.ObjCreate( i, j, WallPat );
end;

procedure GenerateDoors( M : TMap );
var
  i, j, k : Integer;
  DoorPat : TObjPat;
  WallPat : TObjPat;
begin
  DoorPat := TObjPat( Pattern_Get( 'OBJECT', 'Door' ) );
  WallPat := TObjPat( Pattern_Get( 'OBJECT', 'Wall' ) );

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
      if M.Objects.Obj[ i, j ] = nil then
      begin
        k := 0;
        if ( M.Objects.Obj[ i - 1, j ] = nil ) and ( M.Objects.Obj[ i + 1, j ] = nil ) and ( M.Objects.Obj[ i, j - 1 ] <> nil ) and ( M.Objects.Obj[ i, j + 1 ] <> nil ) then
        begin
          if M.Objects.Obj[ i - 1, j - 1 ] = nil then k := k + 1;
          if M.Objects.Obj[ i + 1, j - 1 ] = nil then k := k + 1;
          if M.Objects.Obj[ i - 1, j + 1 ] = nil then k := k + 1;
          if M.Objects.Obj[ i + 1, j + 1 ] = nil then k := k + 1;
          if k > 1 then
            if Random( 10 ) > 0 then M.Objects.ObjCreate( i, j, DoorPat );
        end;
        if M.Objects.Obj[ i, j ] <> nil then Continue;
        k := 0;
        if ( M.Objects.Obj[ i - 1, j ] <> nil ) and ( M.Objects.Obj[ i + 1, j ] <> nil ) and ( M.Objects.Obj[ i, j - 1 ] = nil ) and ( M.Objects.Obj[ i, j + 1 ] = nil ) then
        begin
          if M.Objects.Obj[ i - 1, j - 1 ] = nil then k := k + 1;
          if M.Objects.Obj[ i + 1, j - 1 ] = nil then k := k + 1;
          if M.Objects.Obj[ i - 1, j + 1 ] = nil then k := k + 1;
          if M.Objects.Obj[ i + 1, j + 1 ] = nil then k := k + 1;
          if k > 1 then
            if Random( 10 ) > 0 then M.Objects.ObjCreate( i, j, DoorPat );
        end;
      end;

  for j := 0 to M.Height - 2 do
    for i := 0 to M.Width - 2 do
    begin
      if M.Objects.Obj[ i, j ] = nil then Continue;
      if M.Objects.Obj[ i, j ].Pat <> DoorPat then Continue;
      k := 0;
      if M.Objects.Obj[ i + 1, j ] <> nil then
        if M.Objects.Obj[ i + 1, j ].Pat = DoorPat then k := 1;
      if M.Objects.Obj[ i, j + 1 ] <> nil then
        if M.Objects.Obj[ i, j + 1 ].Pat = DoorPat then k := 1;
      {if M.Objects.Obj[ i + 1, j + 1 ] <> nil then
        if M.Objects.Obj[ i + 1, j + 1 ].Pat = DoorPat then k := 1;}
      if k = 1 then
      begin
        M.Objects.Obj[ i, j ].Free;
        M.Objects.Obj[ i, j ] := nil;
      end;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[ i, j ] = nil then Continue;
      if M.Objects.Obj[ i, j ].Pat <> DoorPat then Continue;
      if ( M.Objects.Obj[ i - 1, j ] = nil ) and ( M.Objects.Obj[ i + 1, j ] = nil ) then
      begin
        if M.Objects.Obj[ i, j - 1 ] = nil then M.Objects.ObjCreate( i, j - 1, WallPat );
        if M.Objects.Obj[ i, j + 1 ] = nil then M.Objects.ObjCreate( i, j + 1, WallPat );
      end;
      if ( M.Objects.Obj[ i, j - 1 ] = nil ) and ( M.Objects.Obj[ i, j + 1 ] = nil ) then
      begin
        if M.Objects.Obj[ i - 1, j ] = nil then M.Objects.ObjCreate( i - 1, j, WallPat );
        if M.Objects.Obj[ i + 1, j ] = nil then M.Objects.ObjCreate( i + 1, j, WallPat );
      end;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[ i, j ] = nil then Continue;
      if M.Objects.Obj[ i, j ].Pat.Name <> 'DOOR' then Continue;
      if M.Objects.Obj[ i - 1, j ] = nil then
      begin
        CreateWave( M, i - 1, j, -1, 0, True );
        if Wave[ i + 1, j ] <> 0 then
        begin
          M.Objects.Obj[ i, j ].Free;
          M.Objects.Obj[ i, j ] := nil;
          Continue;
        end;
      end;
      if M.Objects.Obj[ i, j - 1 ] = nil then
      begin
        CreateWave( M, i, j - 1, -1, 0, True );
        if Wave[ i, j + 1 ] <> 0 then
        begin
          M.Objects.Obj[ i, j ].Free;
          M.Objects.Obj[ i, j ] := nil;
          Continue;
        end;
      end;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[ i, j ] = nil then Continue;
      if M.Objects.Obj[ i, j ].Pat.Name <> 'DOOR' then Continue;
      M.Objects.Obj[ i, j ].BlockWalk := False;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[ i, j ] = nil then Continue;
      if M.Objects.Obj[ i, j ].Pat.Name <> 'DOOR' then Continue;
      M.Objects.Obj[ i, j ].BlockWalk := True;
      if M.Objects.Obj[ i - 1, j ] = nil then
      begin
        CreateWave( M, i - 1, j, -1, 0, True );
        if ( Wave[ i + 1, j ] > 0 ) and ( Wave[ i + 1, j ] < 20 ) and ( Random( 3 ) = 0 ) then
        begin
          M.Objects.Obj[ i, j ].Free;
          M.Objects.Obj[ i, j ] := nil;
          M.Objects.ObjCreate( i, j, WallPat );
        end;
      end;
      if M.Objects.Obj[ i, j - 1 ] = nil then
      begin
        CreateWave( M, i, j - 1, -1, 0, True );
        if ( Wave[ i, j + 1 ] > 0 ) and ( Wave[ i, j + 1 ] < 20 ) and ( Random( 3 ) = 0 ) then
        begin
          M.Objects.Obj[ i, j ].Free;
          M.Objects.Obj[ i, j ] := nil;
          M.Objects.ObjCreate( i, j, WallPat );
        end;
      end;
      if M.Objects.Obj[ i, j ].Pat.Name = 'DOOR' then M.Objects.Obj[ i, j ].BlockWalk := False;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[ i, j ] = nil then Continue;
      if M.Objects.Obj[ i, j ].Pat.Name <> 'DOOR' then Continue;
      M.Objects.Obj[ i, j ].BlockWalk := True;
    end;
end;

procedure GenerateTreasures( M : TMap );
var
  i, j, k, i1, j1, cnt : Integer;
  ChestPat  : TObjPat;
  bool      : Boolean;
  PatNames  : array [ 0..3 ] of String;
begin
  ChestPat := TObjPat( Pattern_Get( 'OBJECT', 'Chest' ) );

  cnt := Random( 10 ) + 20;
  repeat
    i := Random( M.Width - 2 ) + 1;
    j := Random( M.Height - 2 ) + 1;
    if M.Objects.Obj[ i, j ] <> nil then Continue;

    PatNames[ 0 ] := M.Objects.PatName( i - 1, j );
    PatNames[ 1 ] := M.Objects.PatName( i + 1, j );
    PatNames[ 2 ] := M.Objects.PatName( i, j - 1 );
    PatNames[ 3 ] := M.Objects.PatName( i, j + 1 );

    bool := True;

    if bool = True then
    begin
      for j1 := j - 2 to j + 2 do
      begin
        for i1 := i - 2 to i + 2 do
          if M.Objects.PatName( i1, j1 ) = 'DOOR' then
          begin
            bool := False;
            Break;
          end;
        if bool = False then Break;
      end;

      if ( ( PatNames[ 0 ] <> '' ) and ( PatNames[ 1 ] <> '' ) ) or ( ( PatNames[ 2 ] <> '' ) and ( PatNames[ 3 ] <> '' ) ) then bool := False;
    end;

    if bool = True then
    begin
      k := 0;
      for j1 := j - 1 to j + 1 do
        for i1 := i - 1 to i + 1 do
          if M.Objects.PatName( i1, j1 ) = 'WALL' then k := k + 1;
      if ( k = 0 ) and ( Random( 3 ) > 0 ) then bool := False;
    end;

   if bool = True then
     if ( M.Objects.PatName( i, j + 1 ) = '' ) and ( M.Objects.PatName( i - 1, j + 1 ) = 'WALL' ) and ( M.Objects.PatName( i + 1, j + 1 ) = 'WALL' ) then bool := False;
   if bool = True then
     if ( M.Objects.PatName( i, j - 1 ) = '' ) and ( M.Objects.PatName( i - 1, j - 1 ) = 'WALL' ) and ( M.Objects.PatName( i + 1, j - 1 ) = 'WALL' ) then bool := False;
   if bool = True then
     if ( M.Objects.PatName( i + 1, j ) = '' ) and ( M.Objects.PatName( i + 1, j + 1 ) = 'WALL' ) and ( M.Objects.PatName( i + 1, j - 1 ) = 'WALL' ) then bool := False;
   if bool = True then
     if ( M.Objects.PatName( i - 1, j ) = '' ) and ( M.Objects.PatName( i - 1, j + 1 ) = 'WALL' ) and ( M.Objects.PatName( i - 1, j - 1 ) = 'WALL' ) then bool := False;

    if bool = True then
    begin
      k := 0;
      for j1 := j - 7 to j + 7 do
        for i1 := i - 7 to i + 7 do
          if M.Objects.PatName( i1, j1 ) = 'CHEST' then k := k + 1;
      if k > 2 then bool := False;
      if ( k = 2 ) and ( Random( 10 ) = 0 ) then bool := False;
      if ( k = 1 ) and ( Random( 5 ) = 0 ) then bool := False;
    end;

    if bool = True then
    begin
      M.Objects.ObjCreate( i, j, ChestPat );
      cnt := cnt - 1;
    end;
  until cnt = 0;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[ i, j ] <> nil then Continue;

      k := 0;
      if M.Objects.PatName( i - 1, j ) = 'WALL' then k := k + 1;
      if M.Objects.PatName( i + 1, j ) = 'WALL' then k := k + 1;
      if M.Objects.PatName( i, j - 1 ) = 'WALL' then k := k + 1;
      if M.Objects.PatName( i, j + 1 ) = 'WALL' then k := k + 1;
      if ( k = 3 ) and ( Random( 5 ) > 0 ) then M.Objects.ObjCreate( i, j, ChestPat );
    end;
end;

procedure TreasuresConvert( M : TMap );
var
  i, j, n, k  : Integer;
  ItemPat     : TItemPat;
  CPos        : array of TPoint2D;
  CCnt        : Integer;
  IPos        : array of TPoint2D;
  ICnt        : Integer;
  ItmCnt      : Integer;
begin
  ICnt := 0;
  CCnt := 0;
  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
    begin
      if M.Objects.Obj[ i, j ] = nil then Continue;
      if M.Objects.Obj[ i, j ].Pat.Name <> 'CHEST' then Continue;

      if Random( 3 ) > 0 then
      begin
        M.Objects.Obj[ i, j ].Free;
        M.Objects.Obj[ i, j ] := nil;
        ICnt := ICnt + 1;
        SetLength( IPos, ICnt );
        IPos[ ICnt - 1 ] := Point2D( i, j );
      end else
      begin
        CCnt := CCnt + 1;
        SetLength( CPos, CCnt );
        CPos[ CCnt - 1 ] := Point2D( i, j );
      end;
    end;

  for i := 0 to CCnt - 1 do
  begin
    ItmCnt := Random( 2 ) + 1;
    for j := 0 to ItmCnt - 1 do
    begin
      n := Random( 8 );
      k := 1;
      ItemPat := nil;
      if n = 0 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Health' ) );
      if n = 1 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Mana' ) );
      if n = 2 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Antidote' ) );
      if n = 3 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Suriken' ) );
      if n = 4 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Knife' ) );
      if n = 5 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Arrow' ) );
      if n = 6 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Arrow' ) );
      if n = 7 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Arrow' ) );
      if ItemPat <> nil then
      begin
        if ( ItemPat.Name = 'SURIKEN' ) or ( ItemPat.Name = 'KNIFE' ) or ( ItemPat.Name = 'ARROW' ) then k := Random( 5 ) + 3;
        M.Objects.Obj[ CPos[ i ].X, CPos[ i ].Y ].CreateItem( ItemPat, k );
      end;
    end;
  end;

  ItmCnt := 3; //Books
  if Hero.GetParamValue( 'Интеллект' ) > 5 then ItmCnt := 5;
  for i := 0 to ItmCnt - 1 do
  begin
    n := Random( CCnt );
    ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Book' ) );
    M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );
  end;

  ItmCnt := 1;
  repeat
    i := Random( 11 ) - 5;
    j := Random( 11 ) - 5;
    if ( i = 0 ) and ( j = 0 ) then Continue;
    i := Hero.TX + i;
    j := Hero.TY + j;
    if ( i < 0 ) or ( j < 0 ) or ( i >= M.Width ) or ( j >= M.Height ) then Continue;
    if M.Objects.Obj[ i, j ] <> nil then Continue;

    ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Book' ) );
    M.CreateItem( ItemPat, 1, i, j );
    ItmCnt := 0;
  until ItmCnt = 0;

  //Lamp
  n := Random( CCnt );
  ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Lamp' ) );
  M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );

  ItmCnt := 3; //Bombs
  for i := 0 to ItmCnt - 1 do
  begin
    n := Random( CCnt );
    ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Bomb' ) );
    M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );
  end;

  //Shield
  n := Random( CCnt );
  ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Shield' ) );
  M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );

  //Helmet
  n := Random( CCnt );
  ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Helmet' ) );
  M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );

  //Bow
  n := Random( CCnt );
  ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Bow' ) );
  M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );

  //Sword
  n := Random( CCnt );
  ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Sword' ) );
  M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );

  //Axe
  n := Random( CCnt );
  ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Axe' ) );
  M.Objects.Obj[ CPos[ n ].X, CPos[ n ].Y ].CreateItem( ItemPat, 1 );

  for i := 0 to ICnt - 1 do
  begin
    n := Random( 6 );
    k := 1;
    ItemPat := nil;
    if n = 0 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Health' ) );
    if n = 1 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Mana' ) );
    if n = 2 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Suriken' ) );
    if n = 3 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Knife' ) );
    if n = 4 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Rock' ) );
    if n = 5 then
    begin
      n := Random( 3 );
      if n = 0 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Axe' ) );
      if n = 1 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Sword' ) );
      if n = 2 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Bow' ) );
    end;
    if ItemPat <> nil then
    begin
      if ( ItemPat.Name = 'SURIKEN' ) or ( ItemPat.Name = 'KNIFE' ) or ( ItemPat.Name = 'ROCK' ) then k := Random( 5 ) + 3;
      M.CreateItem( ItemPat, k, IPos[ i ].X, IPos[ i ].Y );
    end;
  end;
end;

//==============================================================================
procedure GenerateCreatures( M : TMap );
var
  i, j, cnt, k  : Integer;
  bool          : Boolean;
  Cr            : TCreature;
  ItemPat       : TItemPat;
  CCnt          : Integer;
begin
  cnt := Random( 10 ) + 20;
  CCnt := 0;
  repeat
    i := Random( M.Width - 2 ) + 1;
    j := Random( M.Height - 2 ) + 1;
    if M.GetCreature( i, j ) <> nil then Continue;
    bool := True;
    for k := 0 to M.Creatures.Count - 1 do
    begin
      Cr := TCreature( M.Creatures[ k ] );
      if ( ABS( Cr.TX - i ) < 7 ) and ( ABS( Cr.TY - j ) < 7 ) then
        if Random( 2 ) = 0 then bool := False;
      if bool = False then Break;
    end;
    if bool = False then Continue;
    if ( Wave[ i, j ] = 0 ) or ( Wave[ i, j ] > 8 ) then
    begin
      Cr := nil;
      if cnt = 1 then Cr := Map.CreateCreature( 'Leech', i, j );
      if ( Cr = nil ) and ( Random( 10 ) = 0 ) and ( CCnt = 0 ) then
      begin
        Cr := Map.CreateCreature( 'Leech', i, j );
        CCnt := 1;
      end;
      if Cr = nil then
      case Random(5) of
        0:
          Cr := Map.CreateCreature( 'Skelet', i, j );
        1:
          Cr := Map.CreateCreature( 'Spider', i, j );
        2:
          Cr := Map.CreateCreature( 'Scorpion', i, j );
        3:
          Cr := Map.CreateCreature( 'Darkeye', i, j );
        else
          Cr := Map.CreateCreature( 'Snake', i, j );
      end;
      Cr.Team := 1;
      if ( Cr.Pat.Name = 'SKELET' ) and ( Random( 2 ) = 0 ) then
      begin
        k := Random( 5 );
        ItemPat := nil;
        if k = 0 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Sword' ) );
        if k = 1 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Axe' ) );
        if k = 2 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Rock' ) );
        if k = 3 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Bow' ) );
        if k = 4 then ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Suriken' ) );
        if ItemPat <> nil then
        begin
          Cr.RHandItem.Pat := ItemPat;
          Cr.RHandItem.Count := 1;
          if ItemPat.Throw = True then Cr.RHandItem.Count := Random( 3 ) + 3;
          if ItemPat.Bow = True then
          begin
            Cr.LHandItem.Pat    := TItemPat( Pattern_Get( 'ITEM', 'Arrow' ) );
            Cr.LHandItem.Count  := Random( 3 ) + 4;
          end;
        end;
      end;
      if ( Cr.Pat.Name = 'SKELET' ) and ( Random( 4 ) = 0 ) then
      begin
        ItemPat := TItemPat( Pattern_Get( 'ITEM', 'Health' ) );
        Cr.CreateItem( ItemPat, 1 );
      end;  
      cnt := cnt - 1;
    end;
  until cnt = 0;
end;

end.
