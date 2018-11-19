unit gm_item;

interface

uses
  zglHeader, gm_types, gm_data, gm_patterns;

type
  PItem = ^TItem;
  TItem = record
    Pat   : TItemPat;
    Count : Integer;
    TX    : Integer;
    TY    : Integer;
  end;

procedure Item_Draw( Item : PItem; x, y, Cnt : Integer; CntPos : Byte );
procedure Item_UpdateSlot( Item : PItem; const Equip : String );
procedure Item_Use( Item : PItem; UseCr : Pointer );

var
  DragItem  : PItem;
  DragCount : Integer;

implementation

uses
  gm_creature, gm_map, gm_gui;

//==============================================================================
procedure Item_Draw( Item : PItem; x, y, Cnt : Integer; CntPos : Byte );
var
  l, h : Integer;
begin
  ssprite2d_Draw( Item.Pat.Tex, x, y, 32, 32, 0 );

  l := 0;
  h := 0;
  if CntPos = 0 then Exit;
  if CntPos = 2 then h := 15;
  if Cnt >= 10 then l := ( Length( u_IntToStr( Cnt ) ) - 1 ) * 6;
  if Cnt > 1 then text_Draw( Fnt2, x + 25 - l, y + 22 - h, u_IntToStr( Cnt ) );
end;

//==============================================================================
procedure Item_UpdateSlot( Item : PItem; const Equip : String );
var
  Pat : TItemPat;
  i   : Integer;
begin
  if ( DragItem = nil ) and ( Item.Count > 0 ) then
  begin
    DragItem  := Item;
    DragCount := DragItem.Count;
    if key_Down( K_CTRL ) or key_Down( K_SHIFT ) then DragCount := 1;
    DragItem.Count := DragItem.Count - DragCount;
    Exit;
  end;
  if DragItem <> nil then
  begin
    if Equip <> '' then
      if DragItem.Pat.Equip <> Equip then Exit;
    //------------------------------------------------------------------------
    if Item.Count = 0 then
    begin
      Item.Pat := DragItem.Pat;
      Item.Count := Item.Count + DragCount;
      DragItem := nil;
      Exit;
    end;
    //------------------------------------------------------------------------
    if ( Item.Count > 0 ) and ( DragItem.Pat = Item.Pat ) and ( DragItem.Pat.CanGroup ) then
    begin
      if key_Down( K_CTRL ) or key_Down( K_SHIFT ) then
      begin
        DragCount := DragCount + 1;
        Item.Count := Item.Count - 1;
        DragItem := Item;
      end else
      begin
        Item.Count := Item.Count + DragCount;
        DragItem := nil;
      end;
      Exit;
    end;
    //------------------------------------------------------------------------
    if ( Item.Count > 0 ) and ( ( DragItem.Pat <> Item.Pat ) or ( DragItem.Pat.CanGroup = False ) ) then
      if DragItem.Count = 0 then
      begin
        Pat := DragItem.Pat;
        DragItem.Pat := Item.Pat;
        Item.Pat := Pat;
        i := DragCount;
        DragCount := Item.Count;
        Item.Count := i;
        Exit;
      end;
  end;
end;

//==============================================================================
procedure Item_Use( Item : PItem; UseCr : Pointer );
var
  i, j, k, t, x2, y2  : Integer;
  Cr, Cr2             : TCreature;
  bool                : Boolean;
begin
  if Item.Count = 0 then Exit;
  if Dragitem <> nil then Exit;

  Cr := TCreature( UseCr );
  if Item.Pat.Name = 'HEALTH' then
  begin
    Cr.Health := Cr.Health + 30;
    if Cr.Health > Cr.HealthMax then Cr.Health := Cr.HealthMax;
    Item.Count := Item.Count - 1;
  end;
  if Item.Pat.Name = 'MANA' then
  begin
    Cr.Mana := Cr.Mana + 30;
    if Cr.Mana > Cr.ManaMax then Cr.Mana := Cr.ManaMax;
    Item.Count := Item.Count - 1;
  end;
  if Item.Pat.Name = 'ANTIDOTE' then
  begin
    Cr.DelEffect( 'Отравление' ); 
    Item.Count := Item.Count - 1;
  end;
  if Item.Pat.Name = 'LAMP' then
  begin
    for i := 0 to 3 do
    begin
      x2 := Cr.TX;
      y2 := Cr.TY;
      if i = 0 then x2 := x2 - 1;
      if i = 1 then x2 := x2 + 1;
      if i = 2 then y2 := y2 - 1;
      if i = 3 then y2 := y2 + 1;
      if ( x2 < 0 ) or ( y2 < 0 ) or ( x2 >= Map.Width ) or ( y2 >= Map.Height ) then Continue;
      if Map.Objects.Obj[ x2, y2 ] = nil then
        if Map.GetCreature( x2, y2 ) = nil then
        begin
          Cr2 := Map.CreateCreature( 'Jinn', x2, y2 );
          Cr2.NoAtack := False;
          Item.Count := Item.Count - 1;
          Break;
        end;
    end;
  end;
  if Item.Pat.Name = 'BOMB' then
  begin
    Item.Pat := TItempat( Pattern_Get( 'ITEM', 'FBomb' ) );
  end;

  if Item.Pat.Name = 'BOOK' then
  begin
    t := 0;
    k := Hero.GetParamValue( 'Интеллект' );
    for i := 0 to AllSpellsCnt - 1 do
    begin
      bool := True;
      if k < AllSpells[ i ].Int then bool := False;
      for j := 0 to Hero.SpellsCnt - 1 do
        if Hero.Spells[ j ].Name = AllSpells[ i ].Name then
        begin
          bool := False;
          Break;
        end;
      if bool = True then t := t + 1;
    end;

    if t > SpellPoints then
    begin
      Item.Count := Item.Count - 1;
      SpellPoints := SpellPoints + 1;
      PanelN := 2;
    end else SomeTextOut( mouse_X, mouse_Y - 10, 'Вы не можете выучить новое заклинание' );
  end;
end;

end.
