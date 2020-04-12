unit gm_creature;

interface

uses
  zglHeader, gm_types, gm_data, gm_patterns, gm_item, gm_obj;

type
  TCreature = class
    Pat       : TCrPat;
    TX, TY    : Integer;
    MP        : Pointer;
    WalkTo    : TPoint2D;
    NextStep  : TPoint2D;

    Health    : Integer;
    HealthMax : Integer;
    Mana      : Integer;
    ManaMax   : Integer;
    Exp       : Integer;
    ExpMax    : Integer;
    AtDX      : Integer;
    AtDY      : Integer;
    AtT       : Integer;
    Team      : Integer;
    Enemy     : TCreature;
    InFog     : Boolean;
    NoAtack   : Boolean;
    LifeTime  : Integer;

    Spells    : array of TSpell;
    SpellsCnt : Integer;
    UseSpellN : Integer;
    Effects   : array of TSpell;
    EffectsCnt: Integer;

    ParamValue  : array of Integer;

    Items     : array of TItem;
    ItemsCnt  : Integer;
    RHandItem : TItem;
    LHandItem : TItem;
    HeadItem  : TItem;
    BodyItem  : TItem;
    LegsItem  : TItem;

    constructor Create( CrPat : TCrPat );
    destructor Destroy; override;
    procedure Draw;
    procedure Update;
    procedure Walk( dx, dy : Integer );
    function CreateItem( ItemPat : TItemPat; Count : Integer ) : Boolean;
    function GetParamValue( ParamName : String ) : Integer;
    procedure AddExp( ExpCnt : Integer );
    procedure WalkAway( tx1, ty1 : Integer );
    procedure AddSpell( SpellName : String );
    procedure UseSpell( SpellN : Integer );
    procedure AddEffect( EffectName : String; Time : Integer );
    procedure DelEffect( EffectName : String );
    function HasEffect( EffectName : String ) : Boolean;
    procedure UpdateEffects;
  end;

var
  Hero : TCreature;

implementation

uses
  gm_map, gm_pathfind, gm_gui;

constructor TCreature.Create( CrPat : TCrPat );
var
  i : Integer;
begin
  Pat       := CrPat;
  WalkTo.X  := -1;
  Health    := CrPat.Health;
  HealthMax := CrPat.Health;
  Mana      := CrPat.Mana;
  ManaMax   := CrPat.Mana;
  Exp       := 0;
  ExpMax    := 10;
  NoAtack   := True;
  SpellsCnt := 0;
  UseSpellN := -1;
  EffectsCnt:= 0;
  LifeTime  := 0;

  SetLength( ParamValue, CrParamsCnt );
  for i := 0 to CrParamsCnt - 1 do
    ParamValue[ i ] := Pat.ParamValue[ i ];

  ItemsCnt := 0;
end;

destructor TCreature.Destroy;
begin

  inherited;
end;

procedure TCreature.Draw;
var
  cx, cy, i : Integer;
  Tex       : zglPTexture;
begin
  ssprite2d_Draw( Pat.Tex, TX * 32 + AtDX + Pat.OffsetX, TY * 32 + AtDY + Pat.OffsetY, Pat.Tex.Width, Pat.Tex.Height, 0 );
  if RHandItem.Count > 0 then
    if RHandItem.Pat.EquipTex <> nil then
    begin
      Tex := RHandItem.Pat.EquipTex;
      cx  := TX * 32 + AtDX + Pat.OffsetX - 13;
      cy  := TY * 32 + AtDY + Pat.OffsetY - 5;
      ssprite2d_Draw( Tex, cx, cy, Tex.Width, Tex.Height, 0 );
    end;
  if HeadItem.Count > 0 then
    if HeadItem.Pat.EquipTex <> nil then
    begin
      Tex := HeadItem.Pat.EquipTex;
      cx  := TX * 32 + AtDX + Pat.OffsetX - 1;
      cy  := TY * 32 + AtDY + Pat.OffsetY - 11;
      ssprite2d_Draw( Tex, cx, cy, Tex.Width, Tex.Height, 0 );
    end;
  if LHandItem.Count > 0 then
    if LHandItem.Pat.EquipTex <> nil then
    begin
      Tex := LHandItem.Pat.EquipTex;
      cx  := TX * 32 + AtDX + Pat.OffsetX + 3;
      cy  := TY * 32 + AtDY + Pat.OffsetY;
      ssprite2d_Draw( Tex, cx, cy, Tex.Width, Tex.Height, 0 );
    end;
  if HasEffect( 'Заморозка' ) then ssprite2d_Draw( IceTex, TX * 32, TY * 32, 32, 32, 0, 150 );

  if Health <> HealthMax then
  begin
    i := Round( Health / HealthMax * 24 );
    pr2d_Rect( TX * 32 + 4, TY * 32 + 26, 32 - 8, 4, $333333, 255, PR2D_FILL );
    pr2d_Rect( TX * 32 + 4, TY * 32 + 26, i, 4, $FF3333, 255, PR2D_FILL );
    pr2d_Rect( TX * 32 + 4, TY * 32 + 26, 32 - 8, 4, $000000, 255 );
  end;
end;

procedure TCreature.Update;
var
  M   : TMap;
  p   : TPoint2D;
  si  : PItem;
begin
  if Health = 0 then Exit;
  M := TMap( MP );

  if UseSpellN <> -1 then
    if Mana >= Spells[ UseSpellN ].Mana then
    begin
      if ( Spells[ UseSpellN ].Name = 'Огненный шар' ) and ( Enemy <> nil ) then
        if M.LineOfSign( TX, TY, Enemy.TX, Enemy.TY, False ) then
        begin
          M.CreateBullet( TItemPat( Pattern_Get( 'ITEM', 'Fireball' ) ), Self, Enemy );
          Mana := Mana - Spells[ UseSpellN ].Mana;
          UseSpellN := -1;
          WalkTo.X  := -1;
          if Self = Hero then
          begin
            Enemy     := nil;
            HeroMoved := True;
          end;
          Exit;
        end;
    end;
  UseSpellN := -1;

  if Enemy <> nil then
    if Enemy.Health > 0 then
    begin
      si := nil;

      if RHandItem.Count > 0 then
        if RHandItem.Pat.Throw then si := @RHandItem;

      if ( RHandItem.Count > 0 ) and ( LHandItem.Count > 0 ) then
        if ( RHandItem.Pat.Bow ) and ( LHandItem.Pat.Arrow ) then si := @LHandItem;

      if si <> nil then
        if m_Distance( TX, TY, Enemy.TX, Enemy.TY ) < 8 then
          if M.LineOfSign( TX, TY, Enemy.TX, Enemy.TY, False ) = True then
          begin
            M.CreateBullet( si.Pat, Self, Enemy );
            si.Count  := si.Count - 1;
            WalkTo.X  := -1;
            if Self = Hero then
            begin
              Enemy     := nil;
              HeroMoved := True;
            end;
            Exit;
          end;

      if (Pat.Name = 'LEECH') or (Pat.Name = 'DARKEYE') then
        if m_Distance( TX, TY, Enemy.TX, Enemy.TY ) < 8 then
          if M.LineOfSign( TX, TY, Enemy.TX, Enemy.TY, False ) = True then
          begin
            M.CreateBullet( TItemPat( Pattern_Get( 'ITEM', 'Iceball' ) ), Self, Enemy );
            WalkTo.X  := -1;
            Exit;
          end;

      if (Pat.Name = 'NECROMANCER') then
        if m_Distance( TX, TY, Enemy.TX, Enemy.TY ) < 8 then
          if M.LineOfSign( TX, TY, Enemy.TX, Enemy.TY, False ) = True then
          begin
            M.CreateBullet( TItemPat( Pattern_Get( 'ITEM', 'Poisonball' ) ), Self, Enemy );
            WalkTo.X  := -1;
            Exit;
          end;

      WalkTo := Point2D( Enemy.TX, Enemy.TY );

      if ( si = nil ) and ( RHandItem.Count > 0 ) then
        if RHandItem.Pat.Bow then
        begin
          Enemy := nil;
          WalkTo.X := -1;
        end;
    end;

  if ( WalkTo.X = TX ) and ( WalkTo.Y = TY ) then WalkTo.X := -1;

  if WalkTo.X <> -1 then
  begin
    CreateWave( M, WalkTo.X, WalkTo.Y, TX, TY );
    NextStep := GetNextStep( TX, TY );
    if NextStep.X = -1 then
    begin
      WalkTo.X  := -1;
      if Self = Hero then Enemy := nil;
    end;

    p := Point2D( TX, TY );
    if WalkTo.X <> -1 then Walk( NextStep.X - TX, NextStep.Y - TY );
    if ( TX = p.X ) and ( TY = p.Y ) then WalkTo.X := -1;
  end;
end;

//==============================================================================
procedure TCreature.Walk( dx, dy : Integer );
var
  x2, y2, i, j, Dmg, s : Integer;
  M   : TMap;
  Cr  : TCreature;
  si  : Single;
begin
  LookAtObj := nil;
  M := TMap( MP );
  x2 := TX + dx;
  y2 := TY + dy;
  if ( x2 < 0 ) or ( y2 < 0 ) or ( x2 >= M.Width ) or ( y2 >= M.Height ) then Exit;
  if M.Objects.Obj[ x2, y2 ] <> nil then
  begin

    if ( Self = Hero ) and not ( M.Objects.Obj[ x2, y2 ].Pat.Locked ) and ( M.Objects.Obj[ x2, y2 ].Pat.Container ) then
      LookAtObj := M.Objects.Obj[ x2, y2 ];



    if M.Objects.Obj[ x2, y2 ].Pat.Name = 'DOOR' then
      if M.Objects.Obj[ x2, y2 ].FrameN = 0 then
      begin
        if Self = Hero then HeroMoved := True;
        M.Objects.Obj[ x2, y2 ].FrameN := 1;
        M.Objects.Obj[ x2, y2 ].BlockLook := False;
        M.Objects.Obj[ x2, y2 ].BlockWalk := False;
        M.UpdateFog( TX, TY, 7 );
        Exit;
      end;
    if (M.Objects.Obj[ x2, y2 ].Pat.Shrine) then
      if M.Objects.Obj[ x2, y2 ].FrameN = 0 then
      if Self = Hero then
      begin
        HeroMoved := True;
        M.Objects.Obj[ x2, y2 ].FrameN := 1;
        case M.Objects.Obj[ x2, y2 ].Pat.ShrineType of
        0:
          Self.Health := Self.HealthMax;
        1:
          Self.Mana := Self.ManaMax;
        2:
          begin
            Self.Health := Self.HealthMax;
            Self.Mana := Self.ManaMax;
          end;
        end;
        Exit;
      end;
    if (M.Objects.Obj[ x2, y2 ].Pat.Name = 'CHEST') then
      if M.Objects.Obj[ x2, y2 ].FrameN = 0 then
      begin
        M.Objects.Obj[ x2, y2 ].FrameN := 1;
        Exit;
      end;
    if (M.Objects.Obj[ x2, y2 ].Pat.Name = 'CHEST2') then
      if M.Objects.Obj[ x2, y2 ].FrameN = 0 then
      begin
        if not ( M.Objects.Obj[ x2, y2 ].Pat.Locked ) then
          M.Objects.Obj[ x2, y2 ].FrameN := 1;
        Exit;
      end;
      
    if M.Objects.Obj[ x2, y2 ].BlockWalk = True then Exit;
  end;
  for i := 0 to M.Creatures.Count - 1 do
  begin
    Cr := TCreature( M.Creatures[ i ] );
    if Cr = Self then Continue;
    if ( Cr.TX = x2 ) and ( Cr.TY = y2 ) then
    begin
      if Team = Cr.Team then Exit;
      if RHandItem.Count > 0 then
        if RHandItem.Pat.Bow then Exit;      
      if Self = Hero then
      begin
        HeroMoved := True;
        Enemy := nil;
      end;
      if Cr.HasEffect( 'Заморозка' ) then Cr.AddEffect( 'Заморозка', 1 );

      Dmg := 0;
      if RHandItem.Count = 0 then
      begin
        s   := GetParamValue( 'Сила' );
        Dmg := GetParamValue( 'Без оружия' );
        Dmg := Round( ( s + 5 ) * 0.2 + ( Dmg + 5 ) * 0.3 );
      end else
      begin
        if RHandItem.Pat.Sword = True then
        begin
          s   := GetParamValue( 'Сила' );
          Dmg := GetParamValue( 'Меч' );
          Dmg := Round( ( s + 5 ) * 0.2 + ( Dmg + 5 ) * 0.3 + RHandItem.Pat.Damage * 0.3 );
        end;
        if RHandItem.Pat.Axe = True then
        begin
          s   := GetParamValue( 'Сила' );
          Dmg := GetParamValue( 'Топор' );
          Dmg := Round( ( s + 5 ) * 0.2 + ( Dmg + 5 ) * 0.3 + RHandItem.Pat.Damage * 0.3 );
        end;
      end;

      if Random( 20 ) < Cr.GetParamValue( 'Agility' ) then Dmg := Dmg div 2;

      si := 1;
      if HeadItem.Count > 0 then si := si - 0.1;
      if LHandItem.Count > 0 then
        if LHandItem.Pat.Shield then si := si - 0.2;
      Dmg := Round( Dmg * si );

      Cr.Health := Cr.Health - Dmg;
      if Cr.Health <= 0 then
      begin
        Cr.Health := 0;
        AddExp( Cr.Pat.Exp );
      end;

      AtDX := ( Cr.TX - TX ) * 5;
      AtDY := ( Cr.TY - TY ) * 5;
      AtT  := 10;
      if HasEffect( 'Вампиризм' ) then
      begin
        Health := Health + GetParamValue( 'Магия' );
        if Health > HealthMax then Health := HealthMax;
      end;
      if ( ( Pat.Name = 'SCORPION' ) or ( Pat.Name = 'SPIDER' ) or ( Pat.Name = 'SNAKE' ) ) and ( Random( 10 ) = 0 ) then
      begin
        Cr.AddEffect( 'Отравление', 41);
        if Cr = Hero then SomeTextOut( ( ScreenW - 200 ) div 2, ScreenH div 2 - 30, 'Отравление ядом' );
      end;
      Cr.WalkTo.X := -1;
      if Cr = Hero then Cr.Enemy := nil;
      Exit;
    end;
  end;

  TX := x2;
  TY := y2;

  if Self = Hero then
  begin
    i := 0;
    while i < M.ItemsCnt do
    begin
      if ( M.Items[ i ].TX = TX ) and ( M.Items[ i ].TY = TY ) then
      begin
        if CreateItem( M.Items[ i ].Pat, M.Items[ i ].Count ) = False then Break;
        for j := i to M.ItemsCnt - 2 do
          M.Items[ j ] := M.Items[ j + 1 ];
        M.ItemsCnt := M.ItemsCnt - 1;
        SetLength( M.Items, M.ItemsCnt );
        WalkTo.X := -1;
        i := i - 1;
      end;
      i := i + 1;
    end;
  end;
end;

function TCreature.CreateItem( ItemPat : TItemPat; Count : Integer ) : Boolean;
var
  i : Integer;
begin
  Result := True;
  if ItemPat.CanGroup then
    for i := 0 to ItemsCnt - 1 do
      if Items[ i ].Count > 0 then
        if Items[ i ].Pat = ItemPat then
        begin
          Items[ i ].Count := Items[ i ].Count + Count;
          Exit;
        end;
  for i := 0 to ItemsCnt - 1 do
    if Items[ i ].Count = 0 then
    begin
      Items[ i ].Pat    := ItemPat;
      Items[ i ].Count  := Count;
      Exit;
    end;
  if ItemsCnt = 30 then
  begin
    Result := False;
    Exit;
  end;
  ItemsCnt := ItemsCnt + 1;
  SetLength( Items, ItemsCnt );
  Items[ ItemsCnt - 1 ].Pat   := ItemPat;
  Items[ ItemsCnt - 1 ].Count := Count;
end;

function TCreature.GetParamValue( ParamName : String ) : Integer;
var
  i : Integer;
begin
  Result := 0;
  for i := 0 to CrParamsCnt - 1 do
    if CrParams[ i ].RuName = ParamName then
    begin
      Result := ParamValue[ i ];
      Exit;
    end;
  for i := 0 to CrParamsCnt - 1 do
    if CrParams[ i ].Name = ParamName then
    begin
      Result := ParamValue[ i ];
      Exit;
    end;
end;

procedure TCreature.AddExp( ExpCnt : Integer );
begin
  Exp := Exp + ExpCnt;
  if Exp > ExpMax then
  begin
    Exp := Exp - ExpMax;
    ExpMax := ExpMax + Round( ExpMax * 0.5 );
    if Self = Hero then
    begin
      SkillPoints := SkillPoints + 3;
      SomeTextOut( ( ScreenW - 200 ) div 2, ScreenH div 2 - 30, 'Повышение уровня' );
    end;
  end;
end;

procedure TCreature.WalkAway( tx1, ty1 : Integer );
var
  M           : TMap;
  tx2, ty2, i : Integer;
  bool        : Boolean;
begin
  M := TMap( MP );

  for i := 0 to 8 do
  begin
    tx2 := TX;
    ty2 := TY;
    if i = 0 then
    begin
      tx2 := TX + ( TX - tx1 );
      ty2 := TY + ( TY - ty1 );
    end;
    if i = 1 then tx2 := tx2 - 1;
    if i = 2 then tx2 := tx2 + 1;
    if i = 3 then ty2 := ty2 - 1;
    if i = 4 then ty2 := ty2 + 1;
    if ( i = 5 ) or ( i = 6 ) then tx2 := tx2 - 1;
    if ( i = 7 ) or ( i = 8 ) then tx2 := tx2 + 1;
    if ( i = 5 ) or ( i = 7 ) then ty2 := ty2 - 1;
    if ( i = 6 ) or ( i = 8 ) then ty2 := ty2 + 1;

    if ( tx2 < 0 ) or ( ty2 < 0 ) or ( tx2 >= Map.Width ) or ( ty2 >= Map.Height ) then Continue;

    bool := True;
    if M.Objects.Obj[ tx2, ty2 ] <> nil then
      if M.Objects.Obj[ tx2, ty2 ].BlockWalk = True then bool := False;
    if M.GetCreature( tx2, ty2 ) <> nil then bool := False;
    if bool = True then
    begin
      Walk( tx2 - TX, ty2 - TY );
      HeroMoved := True;
      Exit;
    end;
  end;
end;

procedure TCreature.AddSpell( SpellName : String );
var
  i, n : Integer;
begin
  n := -1;
  for i := 0 to AllSpellsCnt - 1 do
    if AllSpells[ i ].Name = SpellName then
    begin
      n := i;
      Break;
    end;
  if n = -1 then Exit;
  SpellsCnt := SpellsCnt + 1;
  Setlength( Spells, SpellsCnt );
  Spells[ SpellsCnt - 1 ] := AllSpells[ n ];
end;

procedure TCreature.UseSpell( SpellN : Integer );
var
  i, j, k : Integer;
  M       : TMap;
begin
  if Spells[ SpellN ].Name = 'Лечение' then
  begin
    Health := Health + 10 + GetParamValue( 'Магия' ) * 2;
    if Health > HealthMax then Health := HealthMax;
    Mana := Mana - Spells[ SpellN ].Mana;
    SellSpellN := -1;
    HeroMoved := True;
    Exit;
  end;
  if Spells[ SpellN ].Name = 'Регенерация' then
  begin
    AddEffect( 'Регенерация', 41);
    Mana := Mana - Spells[ SpellN ].Mana;
    SellSpellN := -1;
    HeroMoved := True;
    Exit;
  end;
  if Spells[ SpellN ].Name = 'Вампиризм' then
  begin
    AddEffect( 'Вампиризм', GetParamValue( 'Магия' ) * 3 );
    Mana := Mana - Spells[ SpellN ].Mana;
    SellSpellN := -1;
    HeroMoved := True;
    Exit;
  end;
  if Spells[ SpellN ].Name = 'Армагеддон' then
  begin
    M := TMap( MP );
    for k := 0 to 50 do
    begin
      i := Random( M.Width );
      j := Random( M.Height );
      //if ( ABS( Hero.TX - i ) < 3 ) and ( ABS( Hero.TY - j ) < 3 ) then Continue;
      M.Explosive( i, j );
    end;
    Mana := Mana - Spells[ SpellN ].Mana;
    SellSpellN := -1;
    HeroMoved := True;
    Exit;
  end;
end;

procedure TCreature.AddEffect( EffectName : String; Time : Integer );
var
  i : Integer;
begin
  if ( Pat.Name = 'GOLEM' ) and ( EffectName = 'Отравление' ) then Exit;
  for i := 0 to EffectsCnt - 1 do
    if Effects[ i ].Name = EffectName then
    begin
      Effects[ i ].Int := Time;
      Exit;
    end;
  EffectsCnt := EffectsCnt + 1;
  Setlength( Effects, EffectsCnt );
  Effects[ EffectsCnt - 1 ].Name  := EffectName;
  Effects[ EffectsCnt - 1 ].Int   := Time;
end;

procedure TCreature.DelEffect( EffectName : String );
var
  i, j : Integer;
begin
  for i := 0 to EffectsCnt - 1 do
    if Effects[ i ].Name = EffectName then
    begin
      for j := i to EffectsCnt - 2 do
        Effects[ j ] := Effects[ j + 1 ];
      EffectsCnt := EffectsCnt - 1;
      Exit;
    end;
end;

function TCreature.HasEffect( EffectName : String ) : Boolean;
var
  i : Integer;
begin
  Result := True;
  for i := 0 to EffectsCnt - 1 do
    if Effects[ i ].Name = EffectName then Exit;
  Result := False;
end;

procedure TCreature.UpdateEffects;
var
  i, j : Integer;
begin
  j := 0;
  for i := 0 to EffectsCnt - 1 do
  begin
    if Effects[ i ].Name = 'Отравление' then
    begin
      Health := Health - 1;
      if Health < 0 then Health := 0;
    end;
    if Effects[ i ].Name = 'Регенерация' then
    begin
      Health := Health + 1;
      if Health > HealthMax then Health := HealthMax;
    end;
    if ( Effects[ i ].Int = 1 ) and ( Effects[ i ].Name = 'Гипноз' ) then Team := 1;
    if Effects[ i ].Int < 100 then Effects[ i ].Int := Effects[ i ].Int - 1;
    if Effects[ i ].Int = 0 then Continue;
    if i <> j then Effects[ j ] := Effects[ i ];
    j := j + 1;
  end;
  EffectsCnt := j;
end;

end.
