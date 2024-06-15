unit GameCore;

interface

uses
  zglHeader, gm_types, gm_data, gm_patterns, gm_map, gm_obj, gm_creature,
  gm_item, gm_pathfind, gm_generator, gm_gui, gm_utils;

procedure Game_Init;
procedure Game_Draw;
procedure Game_Update; 
procedure Game_Quit;

implementation

uses
  Dialogs, gm_craft;

// ==============================================================================
procedure Game_Init;
var
  x, y, i, j, s, a: Integer;
begin
  cam2d_Init(Cam);

  Data_Load;

  Map := TMap.Create(40, 40, 1);
  Map.Ground.Fill('Grass');

  repeat
    GenerateWalls(Map);

    repeat
      s := 0;
      x := Random(Map.Width);
      y := Random(Map.Height);
      for j := y - 1 to y + 1 do
        for i := x - 1 to x + 1 do
        begin
          if (i < 0) or (j < 0) or (i >= Map.Width) or (j >= Map.Height) then
            Continue;
          if Map.Objects.Obj[i, j] <> nil then
            s := 1;
        end;
    until s = 0;

    CreateWave(Map, x, y, -1, 0, True);
    ClearSmallRooms(Map);

    s := 0;
    for j := 0 to Map.Height - 1 do
      for i := 0 to Map.Width - 1 do
        if Wave[i, j] > 0 then
          s := s + 1;

    if s <= 600 then
      Map.Objects.Clear;
  until s > 600;

  GenerateDoors(Map);
  GenerateTreasures(Map);

  if Map.Objects.Obj[x, y] <> nil then
  begin
    repeat
      i := x + Random(7) - 3;
      j := y + Random(7) - 3;
      if (i < 0) or (j < 0) or (i >= Map.Width) or (j >= Map.Height) then
        Continue;
    until Map.Objects.Obj[i, j] = nil;
    x := i;
    y := j;
  end;
  CreateWave(Map, x, y, -1, 0, True);
  GenerateCreatures(Map);

  GenerateShrine(Map);
  for a := 0 to 19 do
    GenerateTree(Map);

  Hero := Map.CreateCreature('Man', x, y);
  Map.UpdateFog(Hero.TX, Hero.TY, 7);

  TreasuresConvert(Map);

  Hero.ItemsCnt := 30;
  SetLength(Hero.Items, 30);

  Cam.x := Hero.TX * 32 - (ScreenW - 200) div 2 + 16;
  Cam.y := Hero.TY * 32 - ScreenH div 2 + 16;
end;

// ==============================================================================
procedure Game_Draw;
var
  cx, cy: Integer;
begin
  cam2d_Set(@Cam);

  Map.Draw;

  if MouseOverGUI = False then
  begin
    cx := Round(mouse_X + Cam.x);
    cy := Round(mouse_Y + Cam.y);
    if (cx > 0) and (cy > 0) then
    begin
      cx := cx div 32;
      cy := cy div 32;
      if (cx < Map.Width) and (cy < Map.Height) then
        pr2d_Rect(cx * 32, cy * 32, 32, 32, $FFFFFF, 200);
    end;
  end;

  cam2d_Set(nil);

  GUI_Draw;

  if Hero.Health = 0 then
  begin
    pr2d_Rect(0, 0, ScreenW, ScreenH, $232323, 200, PR2D_FILL);
    text_DrawEx(Fnt, ScreenW div 2, ScreenH div 2, 1, 0, 'Game Over', 255, $FFFFFF, TEXT_HALIGN_CENTER);
  end;
end;

// ==============================================================================
procedure Game_Update;
var
  TX, TY, CX, CY, N, I: Integer;
  Cr, Cr2: TCreature;
  bool: Boolean;
  ObjPat: TObjPat;

  procedure ItemToObject(ItName, ObjName: string);
  begin
      if (DragItem.Pat.Name = ItName) then
      begin
        ObjPat := TObjPat(Pattern_Get('OBJECT', ObjName));
        Map.Objects.ObjCreate(cX, cY, ObjPat);
        HeroMoved := True;
        DragItem.Count := DragItem.Count - 1;
        if DragItem.Count = 0 then
          DragItem := nil;    
      end;
  end;
begin
  if key_Press(K_ESCAPE) then
    zgl_Exit;

  if key_Down(K_ALT) and key_Press(K_ENTER) then
  begin
    FullScr := not(FullScr);
    scr_SetOptions(ScreenW, ScreenH, REFRESH_MAXIMUM, FullScr, VSync);
  end;

  if Hero.Health = 0 then
  begin
    mouse_ClearState;
    key_ClearState;
  end;

  if (mxprev = mouse_X) and (myprev = mouse_Y) then
    nmtime := nmtime + 1
  else
    nmtime := 0;
  if mouse_Click(M_BLEFT) or mouse_Click(M_BRIGHT) then
    nmtime := 0;
  mxprev := mouse_X;
  myprev := mouse_Y;

  if WalkPause > 0 then
    WalkPause := WalkPause - 1;
  TX := Hero.TX;
  TY := Hero.TY;

  cx := Round(mouse_X + Cam.x);
  cy := Round(mouse_Y + Cam.y);
  if (cx > 0) and (cy > 0) then
  begin
    cx := cx div 32;
    cy := cy div 32;
    if (cx >= Map.Width) or (cy >= Map.Height) then
      cx := -1;
  end
  else
    cx := -1;

  if (mouse_Click(M_BLEFT)) and (MouseOverGUI = False) and (cx <> -1) then
  begin
    if DragItem = nil then
    begin
      if Map.Fog[cx, cy] <> 0 then
      begin
        Hero.WalkTo := Point2D(cx, cy);
        Cr := Map.GetCreature(cx, cy);
        if Cr <> nil then
          if Cr.Team <> Hero.Team then
            Hero.Enemy := Cr;
        if SellSpellN <> -1 then
        begin
          if (Hero.Enemy <> nil) and (Hero.Spells[SellSpellN].Name = '�������� ���') then
            Hero.UseSpellN := SellSpellN;
          if (Hero.Enemy <> nil) and (Hero.Spells[SellSpellN].Name = '������') then
          begin
            Hero.Enemy.AddEffect('������', 21);
            Hero.Mana := Hero.Mana - Hero.Spells[SellSpellN].Mana;
            Hero.Enemy.Enemy := nil;
            Hero.Enemy.Team := 0;
            Hero.Enemy := nil;
            Hero.WalkTo.x := -1;
            HeroMoved := True;
            SellSpellN := -1;
          end;
          if (Hero.Enemy <> nil) and (Hero.Spells[SellSpellN].Name = '���������') then
          begin
            Hero.Enemy.AddEffect('���������', 21);
            Hero.Mana := Hero.Mana - Hero.Spells[SellSpellN].Mana;
            Hero.Enemy := nil;
            Hero.WalkTo.x := -1;
            HeroMoved := True;
            SellSpellN := -1;
          end;
          if Hero.Spells[SellSpellN].Name = '����� ������' then
          begin
            if (ABS(cx - Hero.TX) < 2) and (ABS(cy - Hero.TY) < 2) then
            begin
              bool := True;
              if Map.GetCreature(cx, cy) <> nil then
                bool := False;
              if Map.Objects.Obj[cx, cy] <> nil then
                if Map.Objects.Obj[cx, cy].BlockWalk then
                  bool := False;
              if bool = True then
              begin
                Cr2 := Map.CreateCreature('Golem', cx, cy);
                Cr2.LifeTime := 50;
                Hero.Mana := Hero.Mana - Hero.Spells[SellSpellN].Mana;
                HeroMoved := True;
                SellSpellN := -1;
              end;
            end;
            Hero.WalkTo.x := -1;
            Hero.Enemy := nil;
          end;
        end;
        if Cr = Hero then
        begin
          Hero.Walk(0, 0);
          HeroMoved := True;
        end;
      end;
    end
    else
    begin
      if (ABS(cx - Hero.TX) < 2) and (ABS(cy - Hero.TY) < 2) then
        if Map.UseItemsOnTile(DragItem.Pat, DragCount, cx, cy) then
          DragItem := nil;
    end;
  end;
  if (mouse_Click(M_BRIGHT)) and (MouseOverGUI = False) and (cx <> -1) and (DragItem = nil) then
  begin
    Cr := Map.GetCreature(cx, cy);
    if (Cr <> nil) and (Cr <> Hero) then
      if (ABS(Cr.TX - Hero.TX) < 2) and (ABS(Cr.TY - Hero.TY) < 2) then
        if (Cr.Team = 0) and (Cr.Enemy = nil) then
          Cr.WalkAway(Hero.TX, Hero.TY);
  end;

  // ��������� ������ �� �����
  if (Mouse_Click(M_BRIGHT)) and (MouseOverGUI = False) and (CX <> -1) and (Map.Objects.Obj[CX, CY] = nil)
    and (DragItem <> nil) and (ABS(CX - Hero.TX) < 2) and (ABS(CY - Hero.TY) < 2) then
      for I := 0 to High(ItemToObjRec) do
        ItemToObject(ItemToObjRec[I].Item, ItemToObjRec[I].Obj);

  n := 0;
  if key_Press(K_LEFT) or key_Press(K_KP_4) then
    n := 1;
  if key_Press(K_RIGHT) or key_Press(K_KP_6) then
    n := 2;
  if key_Press(K_UP) or key_Press(K_KP_8) then
    n := 3;
  if key_Press(K_DOWN) or key_Press(K_KP_2) then
    n := 4;
  if key_Press(K_HOME) or key_Press(K_KP_7) then
    n := 5;
  if key_Press(K_PAGEUP) or key_Press(K_KP_9) then
    n := 6;
  if key_Press(K_END) or key_Press(K_KP_1) then
    n := 7;
  if key_Press(K_PAGEDOWN) or key_Press(K_KP_3) then
    n := 8;
  if key_Press(K_SPACE) then
    n := 9;
  if n <> 0 then
    Hero.WalkTo.x := -1;
  if (DragItem <> nil) or (BtnDwn <> 0) then
    n := 0;
  if NewGame then
    n := 0;

  if (WalkPause = 0) and (Map.BulletsCnt = 0) then
  begin
    if n = 1 then
      Hero.Walk(-1, 0);
    if n = 2 then
      Hero.Walk(1, 0);
    if n = 3 then
      Hero.Walk(0, -1);
    if n = 4 then
      Hero.Walk(0, 1);
    if n = 5 then
      Hero.Walk(-1, -1);
    if n = 6 then
      Hero.Walk(1, -1);
    if n = 7 then
      Hero.Walk(-1, 1);
    if n = 8 then
      Hero.Walk(1, 1);
    if n = 9 then
      HeroMoved := True;

    Hero.Update;
  end;

  if (Hero.TX <> TX) or (Hero.TY <> TY) then
    HeroMoved := True;

  if SellSpellN <> -1 then
    Hero.UseSpell(SellSpellN);
  if SellSpellN <> -1 then
    if Hero.Spells[SellSpellN].Mana > Hero.Mana then
      SellSpellN := -1;

  if (HeroMoved = True) and (Map.BulletsCnt = 0) then
  begin
    HeroMoved := False;
    Map.ExplosiveBombs;
    Map.UpdateFog(Hero.TX, Hero.TY, 7);
    Map.MoveCreatures;
    for n := 0 to Map.Creatures.Count - 1 do
    begin
      Cr := TCreature(Map.Creatures[n]);
      Cr.UpdateEffects;
      if Cr.LifeTime > 0 then
        Cr.LifeTime := Cr.LifeTime - 1;
      if Cr.LifeTime = 1 then
        Cr.Health := 0;
    end;

    WalkPause := 16;
    if Hero.WalkTo.x = -1 then
      WalkPause := 10;
  end;

  if Map.BulletsCnt <> 0 then
  begin
    Hero.WalkTo.x := -1;
    LookAtObj := nil;
  end
  else
    HeroMoved := False;

  Map.Update;
  GUI_Update;

  Cam.x := Hero.TX * 32 - (ScreenW - 200) div 2 + 16;
  Cam.y := Hero.TY * 32 - ScreenH div 2 + 16;

  mouse_ClearState;
  key_ClearState;
end;

// ==============================================================================
procedure Game_Quit;
begin
  Map.Free;
  Data_Free;
end;

end.
