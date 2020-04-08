unit gm_map;

interface

uses
  Classes, zglHeader, gm_types, gm_data, gm_patterns, gm_ground, gm_obj, gm_creature, gm_item;

type
  TBullet = record
    Pat     : TItemPat;
    X, Y    : Single;
    Ang     : Integer;
    Dist    : Single;
    tx2     : Integer;
    ty2     : Integer;
    Owner   : TCreature;
    Enemy   : TCreature;
    RotAng  : Integer;
  end;

type
  TMap = class
    Width         : Integer;
    Height        : Integer;
    Number        : Integer;
    Ground        : TGround;
    Objects       : TObjects;
    Creatures     : TList;
    Fog           : array of array of Byte;
    Items         : array of TItem;
    ItemsCnt      : Integer;
    Bullets       : array of TBullet;
    BulletsCnt    : Integer;
    Fire          : array of Tpoint2D;
    FireTime      : array of Integer;
    FireCnt       : Integer;

    constructor Create( w, h, n : Integer );
    destructor Destroy; override;
    procedure Draw;
    procedure Update;
    function CreateCreature( CrName : String; tx, ty : Integer ) : TCreature;
    function GetCreature( tx, ty : Integer ) : TCreature;
    procedure UpdateFog( x, y, r : Integer );
    function LineOfSign( x1, y1, x2, y2 : Integer; UpdFog : Boolean ) : Boolean;
    procedure DrawMinimap( x, y : Integer );
    procedure CreateItem( ItemPat : TItemPat; Count, tx, ty : Integer );
    function UseItemsOnTile( ItemPat : TItemPat; Cnt, tx, ty : Integer ) : Boolean;
    procedure MoveCreatures;
    procedure CreateBullet( BulletItemPat : TItemPat; Owner, Enemy : TCreature );
    procedure Explosive( tx, ty : Integer );
    procedure ExplosiveBombs;
  end;

var
  Map : TMap;

implementation

uses
  gm_pathfind;

//==============================================================================
constructor TMap.Create( w, h, n : Integer );
begin
  Width     := w;
  Height    := h;
  Number    := n;
  Ground    := TGround.Create( w, h );
  Objects   := TObjects.Create( w, h );
  Creatures := TList.Create;
  ItemsCnt  := 0;
  BulletsCnt:= 0;
  FireCnt   := 0;
  SetLength( Fog, w, h );
end;

//==============================================================================
destructor TMap.Destroy;
var
  i : Integer;
begin
  Ground.Free;
  Objects.Free;
  for i := 0 to Creatures.Count - 1 do
    TCreature( Creatures[ i ] ).Free;
  Creatures.Free;

  inherited;
end;

//==============================================================================
procedure TMap.Draw;
var
  i, j  : Integer;
  Cr    : TCreature;
begin
  Ground.Draw;
  Objects.Draw;

  for i := 0 to ItemsCnt - 1 do
    if Items[ i ].Count > 0 then Item_Draw( @Items[ i ], Items[ i ].TX * 32, Items[ i ].TY * 32, 0, 0 );

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature( Creatures[ i ] );
    if Cr.Health = 0 then Continue;
    if Fog[ Cr.TX, Cr.TY ] <> 2 then Continue;
    Cr.Draw;
  end;

  for i := 0 to BulletsCnt - 1 do
  begin
    if Bullets[ i ].Pat.FlyAng then Bullets[ i ].RotAng := Bullets[ i ].Ang - 45;
    ssprite2d_Draw( Bullets[ i ].Pat.Tex, Bullets[ i ].X + 8, Bullets[ i ].Y + 8, 16, 16, Bullets[ i ].RotAng );
  end;

  for i := 0 to FireCnt - 1 do
    ssprite2d_Draw( FireTex, Fire[ i ].X * 32, Fire[ i ].Y * 32, 32, 32, 0 );

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if Fog[ i, j ] = 0 then pr2d_Rect( i * 32, j * 32, 32, 32, $000000, 255, PR2D_FILL );
      if Fog[ i, j ] = 1 then pr2d_Rect( i * 32, j * 32, 32, 32, $000000, 150, PR2D_FILL );
    end;
end;

//==============================================================================
procedure TMap.Update;
var
  i, j, s, Dmg  : Integer;
  Cr            : TCreature;
  si            : Single;
  bool          : Boolean;
begin
  i := 0;
  while i < BulletsCnt do
  begin
    Bullets[ i ].X := Bullets[ i ].X - m_Cos( Bullets[ i ].Ang ) * 5;
    Bullets[ i ].Y := Bullets[ i ].Y - m_Sin( Bullets[ i ].Ang ) * 5;
    if Bullets[ i ].Pat.Rot then Bullets[ i ].RotAng := Bullets[ i ].RotAng + 20;
    Bullets[ i ].Dist := Bullets[ i ].Dist - 5;
    if Bullets[ i ].Dist < 0 then
    begin
      Cr := GetCreature( Bullets[ i ].tx2, Bullets[ i ].ty2 );
      if Cr <> nil then
      begin
        if Cr.HasEffect( 'Заморозка' ) then Cr.AddEffect( 'Заморозка', 1 );

        Dmg := 7;
        if Bullets[ i ].Pat.Arrow then
        begin
          s   := Bullets[ i ].Owner.GetParamValue( 'Сила' );
          Dmg := Bullets[ i ].Owner.GetParamValue( 'Лук' );
          Dmg := Round( ( s + 5 ) * 0.2 + ( Dmg + 5 ) * 0.3 + Bullets[ i ].Pat.Damage * 0.3 );
        end;
        if Bullets[ i ].Pat.Rock then
        begin
          s   := Bullets[ i ].Owner.GetParamValue( 'Сила' );
          Dmg := Bullets[ i ].Owner.GetParamValue( 'Метание' );
          Dmg := Round( ( s + 5 ) * 0.2 + ( Dmg + 5 ) * 0.3 + Bullets[ i ].Pat.Damage * 0.3 );
        end;
        if Bullets[ i ].Pat.Name = 'FIREBALL' then
        begin
          s   := Bullets[ i ].Owner.GetParamValue( 'Магия' );
          Dmg := Round( ( s + 5 ) * 0.5 + ( Dmg + 5 ) * 0.3 );
        end;

        if Random( 20 ) < Bullets[ i ].Enemy.GetParamValue( 'Agility' ) then Dmg := Dmg div 2;

        si := 1;
        if Bullets[ i ].Enemy.HeadItem.Count > 0 then si := si - 0.1;
        if Bullets[ i ].Enemy.LHandItem.Count > 0 then
          if Bullets[ i ].Enemy.LHandItem.Pat.Shield then si := si - 0.2;
        Dmg := Round( Dmg * si );

        Cr.Health := Cr.Health - Dmg;
        if Cr.Health <= 0 then
        begin
          Cr.Health := 0;
          Bullets[ i ].Owner.AddExp( Cr.Pat.Exp );
        end;
        if Cr = Hero then Hero.Enemy := nil;
      end;
      for j := i to BulletsCnt - 2 do
        Bullets[ j ] := Bullets[ j + 1 ];
      BulletsCnt := BulletsCnt - 1;
      i := i - 1;
    end;
    i := i + 1;
  end;

  j := 0;
  for i := 0 to FireCnt - 1 do
  begin
    FireTime[ i ] := FireTime[ i ] - 1;
    if FireTime[ i ] = 0 then Continue;
    if i <> j then
    begin
      Fire[ j ] := Fire[ i ];
      FireTime[ j ] := FireTime[ i ];
    end;
    j := j + 1;
  end;
  FireCnt := j;

  i := 0;
  while i < Creatures.Count do
  begin
    Cr := TCreature( Creatures[ i ] );

    if Cr.AtT > 0 then Cr.AtT := Cr.AtT - 1;
    if Cr.AtT = 0 then
    begin
      Cr.AtDX := 0;
      Cr.AtDY := 0;
    end;

    if ( Cr.Health = 0 ) and ( Cr <> Hero ) then
    begin
      bool := True;
      for j := 0 to BulletsCnt - 1 do
        if ( Bullets[ j ].Owner = Cr ) or ( Bullets[ j ].Enemy = Cr ) then Bool := False;
      if bool = True then
      begin
        for j := 0 to Cr.ItemsCnt - 1 do
          if Cr.Items[ j ].Count > 0 then
            CreateItem( Cr.Items[ j ].Pat, Cr.Items[ j ].Count, Cr.TX, Cr.TY );
        if Cr.RHandItem.Count > 0 then CreateItem( Cr.RHandItem.Pat, Cr.RHandItem.Count, Cr.TX, Cr.TY );
        if Cr.LHandItem.Count > 0 then CreateItem( Cr.LHandItem.Pat, Cr.LHandItem.Count, Cr.TX, Cr.TY );
        if Cr.HeadItem.Count > 0 then CreateItem( Cr.HeadItem.Pat, Cr.HeadItem.Count, Cr.TX, Cr.TY );
        if Cr.BodyItem.Count > 0 then CreateItem( Cr.BodyItem.Pat, Cr.BodyItem.Count, Cr.TX, Cr.TY );
        if Cr.LegsItem.Count > 0 then CreateItem( Cr.LegsItem.Pat, Cr.LegsItem.Count, Cr.TX, Cr.TY );
        for j := 0 to Creatures.Count - 1 do
          if TCreature( Creatures[ j ] ).Enemy = Cr then TCreature( Creatures[ j ] ).Enemy := nil;
        Cr.Free;
        Creatures.Delete( i );
        i := i - 1;
      end;
    end;
    i := i + 1;
  end;
end;

//==============================================================================
function TMap.CreateCreature( CrName : String; tx, ty : Integer ) : TCreature;
var
  CrPat : TCrPat;
begin
  Result := nil;
  CrPat := TCrPat( Pattern_Get( 'CREATURE', CrName ) );
  if CrPat = nil then Exit;
  Result    := TCreature.Create( CrPat );
  Result.TX := tx;
  Result.TY := ty;
  Result.MP := Self;
  Creatures.Add( Result );
end;

//==============================================================================
function TMap.GetCreature( tx, ty : Integer ) : TCreature;
var
  i : Integer;
begin
  for i := 0 to Creatures.Count - 1 do
  begin
    Result := TCreature( Creatures[ i ] );
    if ( Result.TX = tx ) and ( Result.TY = ty ) then Exit;
  end;
  Result := nil;
end;

//==============================================================================
procedure TMap.UpdateFog( x, y, r : Integer );
var
  i, j  : Integer;
  Cr    : TCreature;
begin
  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature( Creatures[ i ] );
    Cr.InFog := ( Fog[ Cr.TX, Cr.TY ] <> 2 );
  end;

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if Fog[ i, j ] <> 0 then Fog[ i, j ] := 1;

  for j := y - r to y + r do
    for i := x - r to x + r do
    begin
      if ( i < 0 ) or ( j < 0 ) or ( i >= Width ) or ( j >= Height ) then Continue;
      if Round( m_Distance( x, y, i, j ) ) > r then Continue;
      LineOfSign( x, y, i, j, True );
    end;

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature( Creatures[ i ] );
    if Cr.Team = Hero.Team then Continue;
    if ( Fog[ Cr.TX, Cr.TY ] = 2 ) and ( Cr.InFog = True ) then
    begin
      Hero.WalkTo.X := -1;
      Break;
    end;
  end;    
end;

//==============================================================================
function TMap.LineOfSign( x1, y1, x2, y2 : Integer; UpdFog : Boolean ) : Boolean;
var
  px, py, dx, dy, dx2, dy2, ix, iy, i, err : Integer;
begin
  Result := False;
  px := x1;
  py := y1;
  dx := x2 - x1;
  dy := y2 - y1;
  ix := 0;
  iy := 0;
  if dx >= 0 then ix := 1;
  if dx < 0 then
  begin
    ix := -1;
    dx := abs( dx );
  end;
  if dy >= 0 then iy := 1;
  if dy < 0 then
  begin
    iy := -1;
    dy := abs( dy );
  end;
  dx2 := dx * 2;
  dy2 := dy * 2;

  if dx > dy then
  begin
    err := dy2 - dx;
    for i := 0 to dx do
    begin
      if UpdFog then Fog[ px, py ] := 2;
      if Objects.Obj[ px, py ] <> nil then
        if Objects.Obj[ px, py ].BlockLook then Exit;
      if err >= 0 then
      begin
        err := err - dx2;
        py  := py + iy;
      end;
      err := err + dy2;
      px  := px + ix;
    end;
  end else
  begin
    err := dx2 - dy;
    for i := 0 to dy do
    begin
      if UpdFog then Fog[ px, py ] := 2;
      if Objects.Obj[ px, py ] <> nil then
        if Objects.Obj[ px, py ].BlockLook then Exit;
      if err >= 0 then
      begin
        err := err - dy2;
        px  := px + ix;
      end;
      err := err + dx2;
      py  := py + iy;
    end;
  end;
  Result := True;
end;

//==============================================================================
procedure TMap.DrawMinimap( x, y : Integer );
var
  i, j : Integer;
begin
  pr2d_Rect( x, y, Width * 5, Height * 5, $333333, 255, PR2D_FILL );
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if Fog[ i, j ] = 0 then
      begin
        pr2d_Rect( x + i * 5, y + j * 5, 5, 5, $000000, 255, PR2D_FILL );
        Continue;
      end;    
      if Objects.Obj[ i, j ] <> nil then
      begin
        if Objects.Obj[ i, j ].Pat.Name = 'WALL' then pr2d_Rect( x + i * 5, y + j * 5, 5, 5, $999999, 255, PR2D_FILL );
        if Objects.Obj[ i, j ].Pat.Name = 'DOOR' then pr2d_Rect( x + i * 5, y + j * 5, 5, 5, $775544, 255, PR2D_FILL );
      end;
    end;
  pr2d_Rect( x + Hero.TX * 5, y + Hero.TY * 5, 5, 5, $FFFFFF, 255, PR2D_FILL );
  pr2d_Rect( x, y, Width * 5, Height * 5, $AAAAAA, 255 );
end;

//==============================================================================
procedure TMap.CreateItem( ItemPat : TItemPat; Count, tx, ty : Integer );
var
  i : Integer;
begin
  if ItemPat.CanGroup then
    for i := 0 to ItemsCnt - 1 do
      if ( Items[ i ].TX = TX ) and ( Items[ i ].TY = TY ) and ( Items[ i ].Pat = ItemPat ) then
      begin
        Items[ i ].Count := Items[ i ].Count + Count;
        Exit;
      end;
  ItemsCnt := ItemsCnt + 1;
  SetLength( Items, ItemsCnt );
  Items[ ItemsCnt - 1 ].Pat   := ItemPat;
  Items[ ItemsCnt - 1 ].Count := Count;
  Items[ ItemsCnt - 1 ].TX    := tx;
  Items[ ItemsCnt - 1 ].TY    := ty;
end;

//==============================================================================
function TMap.UseItemsOnTile( ItemPat : TItemPat; Cnt, tx, ty : Integer ) : Boolean;
var
  bool  : Boolean;
  i     : Integer;
  Cr    : TCreature;
begin
  Result := False;
  if ( tx < 0 ) or ( ty < 0 ) or ( tx >= Width ) or ( ty >= Height ) then Exit;

  if Objects.Obj[ tx, ty ] <> nil then
  begin
    bool := False;
    if ( Objects.Obj[ tx, ty ].Pat.Name = 'DOOR' ) and ( Objects.Obj[ tx, ty ].FrameN = 1 ) then bool := True;
    if Objects.Obj[ tx, ty ].Pat.Container then
    begin
      if ( Objects.Obj[ tx, ty ].Pat.Name = 'CHEST' ) and ( Objects.Obj[ tx, ty ].FrameN = 0 ) then Exit;
      if Objects.Obj[ tx, ty ].CreateItem( DragItem.Pat, DragCount ) then
      begin
        Result := True;
        Exit;
      end;
    end;
    if bool = False then Exit;
  end;

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature( Creatures[ i ] );
    if Cr = Hero then Continue;
    if ( tx = Cr.TX ) and ( ty = Cr.TY ) then Exit;
  end;

  CreateItem( ItemPat, Cnt, tx, ty );

  Result := True;
end;

//==============================================================================
procedure TMap.MoveCreatures;
var
  i, j, d, x, y : Integer;
  Cr, Cr2, e    : TCreature;
  bool          : Boolean;
begin
  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature( Creatures[ i ] );
    if Cr = Hero then Continue;
    if Cr.Health = 0 then Continue;
    if Cr.HasEffect( 'Заморозка' ) then Continue;

    if ( Cr.RHandItem.Count > 0 ) and ( Cr.LHandItem.Count = 0 ) then
      if Cr.RHandItem.Pat.Bow then
      begin
        Cr.CreateItem( Cr.RHandItem.Pat, 1 );
        Cr.RHandItem.Count := 0;
      end;

    e := Cr.Enemy;

    if Cr.Enemy = nil then
      for j := 0 to Creatures.Count - 1 do
      begin
        if i = j then Continue;
        Cr2 := TCreature( Creatures[ j ] );
        if Cr.Team = Cr2.Team then Continue;
        if m_Distance( Cr.TX, Cr.TY, Cr2.TX, Cr2.TY ) > 8 then Continue;
        if LineOfSign( Cr.TX, Cr.TY, Cr2.TX, Cr2.TY, False ) = True then Cr.Enemy := Cr2;
        if Cr.Enemy <> nil then Break;
      end;

    if Cr.Enemy <> nil then
    begin
      CreateWave( Self, Cr.TX, Cr.TY, Cr.Enemy.TX, Cr.Enemy.TY, True, True );
      d := Wave[ Cr.Enemy.TX, Cr.Enemy.TY ];
      for j := 0 to Creatures.Count - 1 do
      begin
        if i = j then Continue;
        Cr2 := TCreature( Creatures[ j ] );
        if Cr.Team = Cr2.Team then Continue;
        if ( Wave[ Cr2.TX, Cr2.TY ] > 1 ) and ( Wave[ Cr2.TX, Cr2.TY ] < d ) then
        begin
          Cr.Enemy := Cr2;
          d := Wave[ Cr2.TX, Cr2.TY ];
        end;
      end;
      if d < 2 then Cr.Enemy := nil;
    end;

    if ( Cr.Enemy = nil ) and ( Fog[ Cr.TX, Cr.TY ] = 2 ) then
    begin
      CreateWave( Self, Cr.TX, Cr.TY, -1, 0, True, True );
      d := 10;
      for j := 0 to Creatures.Count - 1 do
      begin
        if i = j then Continue;
        Cr2 := TCreature( Creatures[ j ] );
        if Cr.Team = Cr2.Team then Continue;
        if ( Wave[ Cr2.TX, Cr2.TY ] > 1 ) and ( Wave[ Cr2.TX, Cr2.TY ] < d ) then
        begin
          Cr.Enemy := Cr2;
          d := Wave[ Cr2.TX, Cr2.TY ];
        end;
      end;
    end;

    if ( Cr.Team = 0 ) and ( Cr.Enemy = nil ) then
    begin
      Cr.WalkTo.X := -1;
      if not( ( ABS( Cr.TX - Hero.TX ) < 3 ) and ( ABS( Cr.TY - Hero.TY ) < 3 ) ) then Cr.WalkTo := Point2D( Hero.TX, Hero.TY );
    end;

    bool := True;

    if ( Cr.Enemy <> nil ) and ( Cr.Team <> 0 ) then
      if not( ( ABS( Cr.TX - Cr.Enemy.TX ) < 2 ) and ( ABS( Cr.TY - Cr.Enemy.TY ) < 2 ) ) then
        if Random( 10 ) = 0 then bool := False;

    if ( e = nil ) and ( Cr.Enemy <> nil ) and ( Cr.NoAtack = True ) then
    begin
      Cr.NoAtack := False;
      bool := False;
    end;

    if ( bool = True ) and ((Cr.Pat.Name = 'LEECH') or (Cr.Pat.Name = 'NECROMANCER')) and ( Cr.Enemy <> nil ) and ( Random( 5 ) = 0 ) then
    begin
      x := 0;
      y := 0;
      if ABS( Cr.TX - Cr.Enemy.TX ) > ABS( Cr.TY - Cr.Enemy.TY ) then x := 1 else y := 1;
      if ( x = 1 ) and ( Cr.TX > Cr.Enemy.TX ) then x := -1;
      if ( y = 1 ) and ( Cr.TY > Cr.Enemy.TY ) then y := -1;
      if Objects.Obj[ Cr.TX + x, Cr.TY + y ] = nil then
        if GetCreature( Cr.TX + x, Cr.TY + y ) = nil then
        begin
          if (Cr.Pat.Name = 'LEECH') then
            Cr2 := Map.CreateCreature( 'Skelet', Cr.TX + x, Cr.TY + y );
          if (Cr.Pat.Name = 'NECROMANCER') then
          begin
            Cr2 := Map.CreateCreature( 'Leech', Cr.TX + x, Cr.TY + y );
            Cr.AddEffect( 'Регенерация', Cr.HealthMax + 1);
          end;
          Cr2.Team := Cr.Team;
          Cr.Enemy := nil;
          bool := False;
        end;
    end;

    if ( Cr.Team <> 0 ) and ( bool = True ) and ( Cr.Enemy <> nil ) then
    begin
      CreateWave( Self, Cr.TX, Cr.TY, -1, 0, True, True );
      for j := 0 to Creatures.Count - 1 do
      begin
        Cr2 := TCreature( Creatures[ j ] );
        if Cr.Team <> Cr2.Team then Continue;
        if Cr2.Enemy <> nil then Continue;
        if ( Wave[ Cr2.TX, Cr2.TY ] > 1 ) and ( Wave[ Cr2.TX, Cr2.TY ] < 8 ) then Cr2.Enemy := Cr.Enemy;
      end
    end;

    if bool = True then Cr.Update;
  end;

  for i := 0 to BulletsCnt - 1 do
  begin
    Cr  := Bullets[ i ].Owner;
    Cr2 := Bullets[ i ].Enemy;
    Bullets[ i ].tx2   := Cr2.TX;
    Bullets[ i ].ty2   := Cr2.TY;
    Bullets[ i ].Ang   := Round( m_Angle( Cr.TX * 32, Cr.TY * 32, Cr2.TX * 32, Cr2.TY * 32 ) );
    Bullets[ i ].Dist  := m_Distance( Cr.TX * 32, Cr.TY * 32, Cr2.TX * 32, Cr2.TY * 32 );
  end;
end;

procedure TMap.CreateBullet( BulletItemPat : TItemPat; Owner, Enemy : TCreature );
var
  i : Integer;
begin
  BulletsCnt := BulletsCnt + 1;
  SetLength( Bullets, BulletsCnt );
  i := BulletsCnt - 1;
  Bullets[ i ].Pat   := BulletItemPat;
  Bullets[ i ].Owner := Owner;
  Bullets[ i ].Enemy := Enemy;
  Bullets[ i ].tx2   := Enemy.TX;
  Bullets[ i ].ty2   := Enemy.TY;
  Bullets[ i ].X     := Owner.TX * 32;
  Bullets[ i ].Y     := Owner.TY * 32;
  Bullets[ i ].Ang   := Round( m_Angle( Owner.TX * 32, Owner.TY * 32, Enemy.TX * 32, Enemy.TY * 32 ) );
  Bullets[ i ].Dist  := m_Distance( Owner.TX * 32, Owner.TY * 32, Enemy.TX * 32, Enemy.TY * 32 );
end;

procedure TMap.Explosive( tx, ty : Integer );
var
  i, j : Integer;
  Cr   : TCreature;
begin
  for j := ty - 1 to ty + 1 do
    for i := tx - 1 to tx + 1 do
    begin
      if ( i < 0 ) or ( j < 0 ) or ( i >= Width ) or ( j >= Height ) then Continue;
      {if Objects.Obj[ i, j ] <> nil then
        if Objects.Obj[ i, j ].Pat.Name = 'WALL' then Continue;  }
      if Objects.Obj[ i, j ] <> nil then
      begin
        Objects.Obj[ i, j ].Free;
        Objects.Obj[ i, j ] := nil;
      end;

      Cr := GetCreature( i, j );
      if Cr <> nil then
      begin
        if Cr.HasEffect( 'Заморозка' ) then Cr.AddEffect( 'Заморозка', 1 );
        Cr.Health := Cr.Health - 50;
        if Cr.Health <= 0 then
        begin
          Cr.Health := 0;
          if Cr.Team <> Hero.Team then Hero.AddExp( Cr.Pat.Exp );
        end;
      end;

      FireCnt := FireCnt + 1;
      SetLength( Fire, FireCnt );
      SetLength( FireTime, FireCnt );
      Fire[ FireCnt - 1 ] := Point2D( i, j );
      FireTime[ FireCnt - 1 ] := 10;
    end;
  Hero.WalkTo.X := -1;
  Hero.Enemy := nil;
end;

procedure TMap.ExplosiveBombs;
var
  i, j, k : Integer;
  Cr      : TCreature;
  Obj     : TObj;
begin
  i := 0;
  while i < ItemsCnt do
  begin
    if Items[ i ].Pat.Name = 'FBOMB' then
    begin
      Explosive( Items[ i ].TX, Items[ i ].TY );
      for j := i to ItemsCnt - 2 do
        Items[ j ] := Items[ j + 1 ];
      ItemsCnt := ItemsCnt - 1;
      SetLength( Items, ItemsCnt );
      i := i - 1;
    end;
    i := i + 1;
  end;

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature( Creatures[ i ] );
    for j := 0 to Cr.ItemsCnt - 1 do
      if Cr.Items[ j ].Count > 0 then
        if Cr.Items[ j ].Pat.Name = 'FBOMB' then
        begin
          Explosive( Cr.TX, Cr.TY );
          Cr.Items[ j ].Count := 0;
        end
  end;

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if Objects.Obj[ i, j ] <> nil then
      begin
        Obj := Objects.Obj[ i, j ];
        if Obj.Pat.Container = False then Continue;
        for k := 0 to Obj.ItemsCnt - 1 do
          if Obj.Items[ k ].Count > 0 then
            if Obj.Items[ k ].Pat.Name = 'FBOMB' then
            begin
              Explosive( i, j );
              Break;
            end;
      end;
end;

end.
