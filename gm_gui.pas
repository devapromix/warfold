unit gm_gui;

interface

uses
  zglHeader, gm_types, gm_data, gm_patterns, gm_map, gm_creature, gm_item, gm_obj, gm_utils;

procedure GUI_Draw;
procedure GUI_Update;
function MouseOverGUI: Boolean;
procedure InitItemHint(x, y: Integer; Item: PItem);
procedure SomeTextOut(x, y: Integer; Text: String);

type
  THint = record
    x, y: Integer;
    W, H: Integer;
    Text: String;
    Show: Boolean;
  end;

var
  BtnDwn: Integer;
  StBtnDwn: Integer;
  ChestX: Integer = 440;
  ChestY: Integer = 198;
  DragX: Integer;
  DragY: Integer;
  PanelN: Integer;
  Hint: THint;
  HintItem: PItem;
  SomeText: String;
  STPos: TPoint2D;
  STTime: Integer;

implementation

function PointInRect(px, py, x, y, W, H: Integer): Boolean;
begin
  Result := ((px > x) and (py > y) and (px < x + W) and (py < y + H));
end;

procedure GUI_Draw;
var
  x, y, i, j, n, k: Integer;
  bool: Boolean;
  a: Byte;
  clr: LongWord;
begin
  pr2d_Rect(ScreenW - 200, 0, 200, ScreenH, $616777, 255, PR2D_FILL);
  for i := 0 to 2 do
    ssprite2d_Draw(ScrtsTex, ScreenW - 200, 200 + i * 200, 200, 200, 0, 40);
  Map.DrawMinimap(ScreenW - Map.Width * 5, 0);

  pr2d_Line(ScreenW - 200, 310, ScreenW, 310, $000000, 120, PR2D_FILL);
  pr2d_Line(ScreenW - 200, 311, ScreenW, 311, $FFFFFF, 100, PR2D_FILL);

  x := ScreenW - 200 + 24;
  y := 220;
  text_Draw(Fnt, x - 12, y, A2U8('Здоровье:'));
  i := Round(Hero.Health / Hero.HealthMax * 100);
  pr2d_Rect(x + 64, y - 4, 100, 19, $444444, 255, PR2D_FILL);
  pr2d_Rect(x + 64, y - 4, i, 19, $CC7777, 255, PR2D_FILL);
  pr2d_Line(x + 64, y - 3, x + 64 + i, y - 3, $FFFFFF, 100);
  pr2d_Rect(x + 64, y - 4, 100, 19, $000000, 200);
  text_DrawEx(Fnt, x + 114, y, 1, 0, u_IntToStr(Hero.Health) + '/' + u_IntToStr(Hero.HealthMax), 255, $FFFFFF, TEXT_HALIGN_CENTER);

  y := y + 30;
  text_Draw(Fnt, x + 15, y, A2U8('Мана:'));
  pr2d_Rect(x + 64, y - 4, 100, 19, $444444, 255, PR2D_FILL);
  if Hero.ManaMax > 0 then
  begin
    i := Round(Hero.Mana / Hero.ManaMax * 100);
    pr2d_Rect(x + 64, y - 4, i, 19, $7777CC, 255, PR2D_FILL);
    pr2d_Line(x + 64, y - 3, x + 64 + i, y - 3, $FFFFFF, 100);
  end;
  pr2d_Rect(x + 64, y - 4, 100, 19, $000000, 200);
  text_DrawEx(Fnt, x + 114, y, 1, 0, u_IntToStr(Hero.Mana) + '/' + u_IntToStr(Hero.ManaMax), 255, $FFFFFF, TEXT_HALIGN_CENTER);

  y := y + 30;
  text_Draw(Fnt, x + 19, y, A2U8('Опыт:'));
  i := Round(Hero.Exp / Hero.ExpMax * 100);
  pr2d_Rect(x + 64, y - 4, 100, 19, $444444, 255, PR2D_FILL);
  pr2d_Rect(x + 64, y - 4, i, 19, $BBCC77, 255, PR2D_FILL);
  pr2d_Line(x + 64, y - 3, x + 64 + i, y - 3, $FFFFFF, 100);
  pr2d_Rect(x + 64, y - 4, 100, 19, $000000, 200);
  text_DrawEx(Fnt, x + 114, y, 1, 0, u_IntToStr(Hero.Exp) + '/' + u_IntToStr(Hero.ExpMax), 255, $FFFFFF, TEXT_HALIGN_CENTER);

  x := ScreenW - 200 + (200 - 27 * 4) div 2;
  y := 326;
  if PanelN = 0 then
    asprite2d_Draw(BtnTex, x, y, 32, 32, 0, 2)
  else
    asprite2d_Draw(BtnTex, x, y, 32, 32, 0, 1);
  if PanelN = 0 then
    i := 1
  else
    i := 0;
  ssprite2d_Draw(BagTex, x + i, y + i, 32, 32, 0, 220);

  if PanelN = 1 then
    asprite2d_Draw(BtnTex, x + 27, y, 32, 32, 0, 2)
  else
    asprite2d_Draw(BtnTex, x + 27, y, 32, 32, 0, 1);
  if PanelN = 1 then
    i := 1
  else
    i := 0;
  ssprite2d_Draw(StatsTex, x + 27 + i, y + i, 32, 32, 0, 220);

  if PanelN = 2 then
    asprite2d_Draw(BtnTex, x + 27 * 2, y, 32, 32, 0, 2)
  else
    asprite2d_Draw(BtnTex, x + 27 * 2, y, 32, 32, 0, 1);
  if PanelN = 2 then
    i := 1
  else
    i := 0;
  ssprite2d_Draw(SpellTex, x + 27 * 2 - 2 + i, y + i - 2, 32, 32, 0, 220);

  if PanelN = 3 then
    asprite2d_Draw(BtnTex, x + 27 * 3, y, 32, 32, 0, 2)
  else
    asprite2d_Draw(BtnTex, x + 27 * 3, y, 32, 32, 0, 1);
  if PanelN = 3 then
    i := 1
  else
    i := 0;
  ssprite2d_Draw(CraftTex, x + 27 * 3 - 2 + i, y + i - 2, 32, 32, 0, 220);

  if PanelN = 0 then
  begin
    x := (ScreenW - 200) + (200 - DollTex.Width) div 2;
    y := 370;
    ssprite2d_Draw(DollTex, x, y, DollTex.Width, DollTex.Height, 0);
    if DragItem <> nil then
    begin
      if DragItem.Pat.Equip = 'RHand' then
        ssprite2d_Draw(GlowTex, x + 28 - 15, y + 93 - 15, 64, 64, 0);
      if DragItem.Pat.Equip = 'LHand' then
        ssprite2d_Draw(GlowTex, x + 106 - 15, y + 93 - 15, 64, 64, 0);
      if DragItem.Pat.Equip = 'Head' then
        ssprite2d_Draw(GlowTex, x + 67 - 15, y + 27 - 15, 64, 64, 0);
      if DragItem.Pat.Equip = 'Body' then
        ssprite2d_Draw(GlowTex, x + 67 - 15, y + 67 - 15, 64, 64, 0);
      if DragItem.Pat.Equip = 'Legs' then
        ssprite2d_Draw(GlowTex, x + 67 - 15, y + 124 - 15, 64, 64, 0);
    end;
    if Hero.RHandItem.Count > 0 then
      Item_Draw(@Hero.RHandItem, x + 28, y + 93, Hero.RHandItem.Count, 1);
    if Hero.LHandItem.Count > 0 then
      Item_Draw(@Hero.LHandItem, x + 106, y + 93, Hero.LHandItem.Count, 1);
    if Hero.HeadItem.Count > 0 then
      Item_Draw(@Hero.HeadItem, x + 67, y + 27, Hero.HeadItem.Count, 1);
    if Hero.BodyItem.Count > 0 then
      Item_Draw(@Hero.BodyItem, x + 67, y + 67, Hero.BodyItem.Count, 1);
    if Hero.LegsItem.Count > 0 then
      Item_Draw(@Hero.LegsItem, x + 67, y + 124, Hero.LegsItem.Count, 1);

    x := ScreenW - 6 * 33 - 1;
    y := 590;
    for j := 0 to 4 do
      for i := 0 to 5 do
      begin
        ssprite2d_Draw(ItemSlotTex, x + i * 33, y + j * 33, 34, 34, 0);
        n := j * 6 + i;
        if n >= Hero.ItemsCnt then
          Continue;
        if Hero.Items[n].Count = 0 then
          Continue;

        Item_Draw(@Hero.Items[n], x + i * 33, y + j * 33, Hero.Items[n].Count, 1);
      end;
  end;

  pr2d_Line(ScreenW - 200, 0, ScreenW - 200, ScreenH, $AAAAAA, 255, PR2D_FILL);

  if (PanelN = 1) or (NewGame = True) then
  begin
    if NewGame = False then
    begin
      pr2d_Rect(ScreenW - 200 + 16, 370, 200 - 32, 380, $000000, 100, PR2D_FILL);
      pr2d_Rect(ScreenW - 200 + 16, 370, 200 - 32, 380, $000000, 100);
    end;

    x := ScreenW - 200 + 34;
    y := 390;
    if NewGame = True then
    begin
      x := ScreenW div 2 - 80;
      y := 200;
      pr2d_Rect(0, 0, ScreenW, ScreenH, $232323, 200, PR2D_FILL);
      pr2d_Rect(x - 20, y - 70, 200, CrParamsCnt * 20 + 190, $343740, 255, PR2D_FILL);
      pr2d_Rect(x - 20, y - 70, 200, CrParamsCnt * 20 + 190, $FFFFFF, 100);
      text_DrawEx(Fnt, ScreenW div 2, y - 50, 1, 0, A2U8('Параметры персонажа'), 255, $FFFFFF, TEXT_HALIGN_CENTER);

      if CharPoints > 0 then
        text_DrawEx(Fnt, x + 120, y + 4 * 20, 1, 0, u_IntToStr(CharPoints), 255, $FFFF00);

      i := x - 20 + (200 - 80) div 2;
      j := y + CrParamsCnt * 20 + 76;
      if StBtnDwn = 1000 then
      begin
        pr2d_Rect(i, j, 80, 26, $909090, 255, PR2D_FILL);
        pr2d_Line(i + 1, j + 1, i + 79, j + 1, $000000, 100);
        pr2d_Line(i + 1, j + 1, i + 1, j + 25, $000000, 100);
        k := 1;
      end
      else
      begin
        pr2d_Rect(i, j, 80, 26, $A0A0A0, 255, PR2D_FILL);
        pr2d_Line(i + 1, j + 1, i + 79, j + 1, $FFFFFF, 100);
        pr2d_Line(i + 1, j + 1, i + 1, j + 25, $FFFFFF, 100);
        pr2d_Line(i + 78, j + 1, i + 78, j + 25, $000000, 100);
        pr2d_Line(i + 1, j + 24, i + 79, j + 24, $000000, 100);
        k := 0;
      end;
      pr2d_Rect(i, j, 80, 26, $000000, 255);
      if CharPoints = 0 then
        text_DrawEx(Fnt, x - 20 + 100 + k, y + CrParamsCnt * 20 + 83 + k, 1, 0, A2U8('Принять'), 255, $FFFFFF, TEXT_HALIGN_CENTER)
      else
        text_DrawEx(Fnt, x - 20 + 100 + k, y + CrParamsCnt * 20 + 83 + k, 1, 0, A2U8('Принять'), 130, $FFFFFF, TEXT_HALIGN_CENTER);
    end;

    j := 0;
    for i := 0 to CrParamsCnt - 1 do
    begin
      text_Draw(Fnt, x, y + j, A2U8(CrParams[i].RuName + ':'));
      text_Draw(Fnt, x + 120, y + j, u_IntToStr(Hero.ParamValue[i]));
      j := j + 20;
      if i = 3 then
        j := j + 50
    end;
    if NewGame = True then
      text_Draw(Fnt, x + 51, y + 110, A2U8('Навыки'))
    else
      text_Draw(Fnt, x + 38, y + 110, A2U8('Навыки'));
    if SkillPoints > 0 then
      text_DrawEx(Fnt, x + 120, y + j, 1, 0, u_IntToStr(SkillPoints), 255, $FFFF00);

    j := 0;
    n := 0;
    for i := 0 to CrParamsCnt - 1 do
    begin
      n := n + 1;
      if StBtnDwn = n then
        k := 2
      else
        k := 1;
      bool := False;
      if (NewGame = True) or (i > 3) then
        bool := True;
      if (NewGame = False) and (SkillPoints = 0) then
        bool := False;
      if bool = True then
        if Hero.ParamValue[i] < 10 then
          asprite2d_Draw(Btn2Tex, x + 132, y + j - 2, 16, 16, 0, k);
      n := n + 1;
      if StBtnDwn = n then
        k := 4
      else
        k := 3;
      if NewGame = True then
        asprite2d_Draw(Btn2Tex, x + 132 + 14, y + j - 2, 16, 16, 0, k);
      j := j + 20;
      if i = 3 then
        j := j + 50
    end;

    j := j + 30;
    if Hero.EffectsCnt > 0 then
      text_Draw(Fnt, x + 35, y + j, A2U8('Эффекты'));
    for i := 0 to Hero.EffectsCnt - 1 do
    begin
      if i = 3 then
        Exit;
      j := j + 20;
      text_Draw(Fnt, x, y + j, A2U8(Hero.Effects[i].Name));
      if Hero.Effects[i].Int < 100 then
        text_Draw(Fnt, x + 120, y + j, u_IntToStr(Hero.Effects[i].Int));
    end
  end;

  if PanelN = 2 then
  begin
    pr2d_Rect(ScreenW - 200 + 16, 370, 200 - 32, 380, $000000, 100, PR2D_FILL);
    pr2d_Rect(ScreenW - 200 + 16, 370, 200 - 32, 380, $000000, 100);
    x := ScreenW - 200 + 34;
    y := 386;

    if SpellPoints > 0 then
    begin
      text_DrawEx(Fnt, ScreenW - 100, y, 1, 0, A2U8('Выберите'), 255, $FFFFFF, TEXT_HALIGN_CENTER);
      text_DrawEx(Fnt, ScreenW - 100, y + 18, 1, 0, A2U8('новое заклинание'), 255, $FFFFFF, TEXT_HALIGN_CENTER);
      k := Hero.GetParamValue('Интеллект');
      for i := 0 to AllSpellsCnt - 1 do
      begin
        a := 255;
        if k < AllSpells[i].Int then
          a := 120;
        for j := 0 to Hero.SpellsCnt - 1 do
          if Hero.Spells[j].Name = AllSpells[i].Name then
          begin
            a := 120;
            Break;
          end;
        text_DrawEx(Fnt, x, y + i * 20 + 50, 1, 0, A2U8(AllSpells[i].Name), a, $FFFFFF);
        text_DrawEx(Fnt, x + 120, y + i * 20 + 50, 1, 0, u_IntToStr(AllSpells[i].Mana), a, $FFFFFF);
      end;
    end
    else
    begin
      text_Draw(Fnt, x + 24, y, A2U8('Заклинания'));
      for i := 0 to Hero.SpellsCnt - 1 do
      begin
        a := 255;
        if Hero.Mana < Hero.Spells[i].Mana then
          a := 120;
        if (Hero.Spells[i].Name = 'Вампиризм') and (Hero.HasEffect('Вампиризм')) then
          a := 120;
        clr := $FFFFFF;
        if SellSpellN = i then
          clr := $00FF00;
        text_DrawEx(Fnt, x, y + i * 20 + 30, 1, 0, A2U8(Hero.Spells[i].Name), a, clr);
        text_DrawEx(Fnt, x + 120, y + i * 20 + 30, 1, 0, u_IntToStr(Hero.Spells[i].Mana), a, clr);
      end;
    end;
  end;

  {
    LTCraftItem: TItem;
    CTCraftItem: TItem;
    RTCraftItem: TItem;
    LCCraftItem: TItem;
    CCCraftItem: TItem;
    RCCraftItem: TItem;
    LDCraftItem: TItem;
    CDCraftItem: TItem;
    RDCraftItem: TItem;
    RSCraftItem: TItem;
  }

  if PanelN = 3 then
  begin
    x := (ScreenW - 200) + (200 - BoxTex.Width) div 2;
    y := 370;
    ssprite2d_Draw(BoxTex, x, y, BoxTex.Width, BoxTex.Height, 0);

    if Hero.CTCraftItem.Count > 0 then
      Item_Draw(@Hero.CTCraftItem, x + 67, y + 27, Hero.CTCraftItem.Count, 1);

    if Hero.CCCraftItem.Count > 0 then
      Item_Draw(@Hero.CCCraftItem, x + 67, y + 67, Hero.CCCraftItem.Count, 1);

    if Hero.LDCraftItem.Count > 0 then
      Item_Draw(@Hero.LDCraftItem, x + 28, y + 93, Hero.LDCraftItem.Count, 1);
    if Hero.CDCraftItem.Count > 0 then
      Item_Draw(@Hero.CDCraftItem, x + 67, y + 124, Hero.CDCraftItem.Count, 1);
    if Hero.RDCraftItem.Count > 0 then
      Item_Draw(@Hero.RDCraftItem, x + 106, y + 93, Hero.RDCraftItem.Count, 1);

    if Hero.RSCraftItem.Count > 0 then
      Item_Draw(@Hero.RSCraftItem, x + 67, y + 154, Hero.RSCraftItem.Count, 1);

    x := ScreenW - 6 * 33 - 1;
    y := 590;
    for j := 0 to 4 do
      for i := 0 to 5 do
      begin
        ssprite2d_Draw(ItemSlotTex, x + i * 33, y + j * 33, 34, 34, 0);
        n := j * 6 + i;
        if n >= Hero.ItemsCnt then
          Continue;
        if Hero.Items[n].Count = 0 then
          Continue;

        Item_Draw(@Hero.Items[n], x + i * 33, y + j * 33, Hero.Items[n].Count, 1);
      end;
  end;

  if LookAtObj <> nil then
  begin
    pr2d_Rect(ChestX, ChestY, 4 * 33 + 40, 2 * 33 + 20, $616777, 255, PR2D_FILL);
    ssprite2d_Draw(ScrtsTex, ChestX, ChestY, 4 * 33 + 40, 2 * 33 + 20, 0, 40);
    pr2d_Rect(ChestX, ChestY, 4 * 33 + 40, 2 * 33 + 20, $000000, 150);
    if BtnDwn = 1 then
      asprite2d_Draw(Btn1Tex, ChestX + 149, ChestY + 10, 16, 16, 0, 2)
    else
      asprite2d_Draw(Btn1Tex, ChestX + 149, ChestY + 10, 16, 16, 0, 1);
    if BtnDwn = 2 then
      asprite2d_Draw(Btn1Tex, ChestX + 149, ChestY + 27, 16, 16, 0, 4)
    else
      asprite2d_Draw(Btn1Tex, ChestX + 149, ChestY + 27, 16, 16, 0, 3);

    for j := 0 to 1 do
      for i := 0 to 3 do
      begin
        ssprite2d_Draw(ItemSlotTex, ChestX + 10 + i * 33, ChestY + 10 + j * 33, 34, 34, 0);
        n := j * 4 + i;
        if n >= LookAtObj.ItemsCnt then
          Continue;
        if LookAtObj.Items[n].Count = 0 then
          Continue;
        Item_Draw(@LookAtObj.Items[n], ChestX + 10 + i * 33, ChestY + 10 + j * 33, LookAtObj.Items[n].Count, 1);
      end;
  end;

  if DragItem <> nil then
    Item_Draw(DragItem, mouse_X - 16, mouse_Y - 16, DragCount, 2);

  if (Hint.Show) and (DragItem = nil) and (BtnDwn = 0) then
  begin
    pr2d_Rect(Hint.x, Hint.y, Hint.W, Hint.H, $000000, 150, PR2D_FILL);
    pr2d_Rect(Hint.x, Hint.y, Hint.W, Hint.H, $FFFFFF, 150);
    text_DrawEx(Fnt, Hint.x + Hint.W div 2, Hint.y + 5, 1, 0, A2U8(Hint.Text), 255, $FFFFFF, TEXT_HALIGN_CENTER);
  end;

  if STTime > 0 then
  begin
    a := 255;
    if STTime < 25 then
      a := STTime * 10;
    text_DrawEx(Fnt, STPos.x, STPos.y, 1, 0, A2U8(SomeText), a, $FFFFFF, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER);
  end;
end;

procedure GUI_Update;
var
  x, y, i, j, imo, iob, n, k: Integer;
begin
  HintItem := nil;

  if STTime > 0 then
    STTime := STTime - 1;

  if (NewGame = True) or (PanelN = 1) then
  begin
    if mouse_Down(M_BLEFT) = False then
    begin
      if StBtnDwn = 1000 then
      begin
        x := ScreenW div 2 - 80;
        y := 200;
        i := x - 20 + (200 - 80) div 2;
        j := y + CrParamsCnt * 20 + 76;
        if PointInRect(mouse_X, mouse_Y, i, j, 80, 26) then
        begin
          NewGame := False;
          Hero.HealthMax := 40 + Hero.GetParamValue('Выносливость') * 4;
          Hero.Health := Hero.HealthMax;
          Hero.ManaMax := Hero.GetParamValue('Интеллект') * 5;
          Hero.Mana := Hero.ManaMax;
        end;
        StBtnDwn := 0;
      end;
      if StBtnDwn <> 1000 then
        StBtnDwn := 0;
    end;

    if mouse_Click(M_BLEFT) then
    begin
      x := ScreenW - 200 + 34;
      y := 386;
      if NewGame = True then
      begin
        x := ScreenW div 2 - 80;
        y := 200;
      end;
      j := 0;
      n := 0;
      for i := 0 to CrParamsCnt - 1 do
      begin
        n := n + 1;
        if (NewGame = True) or (i > 3) then
          if PointInRect(mouse_X, mouse_Y, x + 132, y + j - 2, 16, 16) then
            StBtnDwn := n;
        n := n + 1;
        if NewGame = True then
          if PointInRect(mouse_X, mouse_Y, x + 132 + 14, y + j - 2, 16, 16) then
            StBtnDwn := n;
        j := j + 20;
        if i = 3 then
          j := j + 50
      end;
      if StBtnDwn <> 0 then
      begin
        if StBtnDwn mod 2 = 0 then
        begin
          n := StBtnDwn div 2 - 1;
          if Hero.ParamValue[n] > 0 then
          begin
            Hero.ParamValue[n] := Hero.ParamValue[n] - 1;
            if n < 4 then
              CharPoints := CharPoints + 1
            else
              SkillPoints := SkillPoints + 1;
          end;
        end
        else
        begin
          n := (StBtnDwn - 1) div 2;
          if Hero.ParamValue[n] < 10 then
          begin
            if n < 4 then
              if CharPoints > 0 then
                CharPoints := CharPoints - 1
              else
                n := -1;
            if n >= 4 then
              if SkillPoints > 0 then
                SkillPoints := SkillPoints - 1
              else
                n := -1;
            if n <> -1 then
              Hero.ParamValue[n] := Hero.ParamValue[n] + 1;
          end;
        end;
      end;
      i := x - 20 + (200 - 80) div 2;
      j := y + CrParamsCnt * 20 + 76;
      if CharPoints = 0 then
        if PointInRect(mouse_X, mouse_Y, i, j, 80, 26) then
          StBtnDwn := 1000;
    end;
    if NewGame = True then
      Exit;
  end;

  if (mouse_Click(M_BLEFT)) and (DragItem = nil) then
  begin
    x := ScreenW - 200 + (200 - 27 * 4) div 2;
    y := 326;
    if PointInRect(mouse_X, mouse_Y, x, y, 4 * 27, 27) then
    begin
      i := (mouse_X - x) div 27;
      if i < 0 then
        i := 0;
      if i > 3 then
        i := 3;
      PanelN := i;
      if PanelN <> 2 then
        SellSpellN := -1;
    end;
  end;

  if PanelN = 0 then
  begin
    i := (ScreenW - 200) + (200 - DollTex.Width) div 2;
    j := 370;
    if mouse_Click(M_BLEFT) then
    begin
      if PointInRect(mouse_X, mouse_Y, i + 28, j + 93, 33, 33) then
        Item_UpdateSlot(@Hero.RHandItem, 'RHand');
      if PointInRect(mouse_X, mouse_Y, i + 106, j + 93, 33, 33) then
        Item_UpdateSlot(@Hero.LHandItem, 'LHand');
      if PointInRect(mouse_X, mouse_Y, i + 67, j + 27, 33, 33) then
        Item_UpdateSlot(@Hero.HeadItem, 'Head');
      if PointInRect(mouse_X, mouse_Y, i + 67, j + 67, 33, 33) then
        Item_UpdateSlot(@Hero.BodyItem, 'Body');
      if PointInRect(mouse_X, mouse_Y, i + 67, j + 124, 33, 33) then
        Item_UpdateSlot(@Hero.LegsItem, 'Legs');
    end;
    if PointInRect(mouse_X, mouse_Y, i + 28, j + 93, 33, 33) then
      InitItemHint(i + 28, j + 93, @Hero.RHandItem);
    if PointInRect(mouse_X, mouse_Y, i + 106, j + 93, 33, 33) then
      InitItemHint(i + 106, j + 93, @Hero.LHandItem);
    if PointInRect(mouse_X, mouse_Y, i + 67, j + 27, 33, 33) then
      InitItemHint(i + 67, j + 27, @Hero.HeadItem);
    if PointInRect(mouse_X, mouse_Y, i + 67, j + 67, 33, 33) then
      InitItemHint(i + 67, j + 67, @Hero.BodyItem);
    if PointInRect(mouse_X, mouse_Y, i + 67, j + 124, 33, 33) then
      InitItemHint(i + 67, j + 124, @Hero.LegsItem);

    i := 0;
    j := 0;
    imo := -1;
    if (mouse_X > (ScreenW - 200)) and (mouse_Y > 590) and (mouse_Y < 590 + 7 * 33) then
    begin
      i := (mouse_X - (ScreenW - 200) - 2) div 33;
      j := (mouse_Y - 590) div 33;
      if i < 0 then
        i := 0;
      if j < 0 then
        j := 0;
      if i > 5 then
        i := 5;
      if j > 4 then
        j := 4;
      imo := j * 6 + i;
    end;

    if (mouse_Click(M_BLEFT)) and (imo <> -1) then
      Item_UpdateSlot(@Hero.Items[imo], '');
    if (mouse_Click(M_BRIGHT)) and (imo <> -1) and (BtnDwn = 0) then
      Item_Use(@Hero.Items[imo], Hero);

    if imo <> -1 then
      InitItemHint(i * 33 + ScreenW - 200, j * 33 + 590, @Hero.Items[imo]);
  end;

  if (PanelN = 2) and (mouse_Click(M_BLEFT)) and (PointInRect(mouse_X, mouse_Y, 840, 370, 170, 380)) then
  begin
    x := ScreenW - 200 + 34;
    y := 386;
    if SpellPoints > 0 then
    begin
      k := Hero.GetParamValue('Интеллект');
      n := -1;
      for i := 0 to AllSpellsCnt - 1 do
        if PointInRect(mouse_X, mouse_Y, x, y + i * 20 + 50 - 3, 132, 20) then
        begin
          n := i;
          if k < AllSpells[i].Int then
            n := -1;
          for j := 0 to Hero.SpellsCnt - 1 do
            if Hero.Spells[j].Name = AllSpells[i].Name then
            begin
              n := -1;
              Break;
            end;
          Break;
        end;
      if n <> -1 then
      begin
        SpellPoints := SpellPoints - 1;
        Hero.AddSpell(AllSpells[n].Name);
      end;
    end
    else
    begin
      n := -1;
      for i := 0 to Hero.SpellsCnt - 1 do
        if PointInRect(mouse_X, mouse_Y, x, y + i * 20 + 30 - 3, 132, 20) then
        begin
          n := i;
          if Hero.Mana < Hero.Spells[i].Mana then
            n := -1;
          if (Hero.Spells[i].Name = 'Вампиризм') and (Hero.HasEffect('Вампиризм')) then
            n := -1;
          Break;
        end;
      if n <> -1 then
        if SellSpellN = n then
          SellSpellN := -1
        else
          SellSpellN := n;
    end;
  end;

  if (PanelN = 3) then
  begin
    //i := (ScreenW - 200) + (200 - DollTex.Width) div 2;
    //j := 370;
    {if mouse_Click(M_BLEFT) then
    begin
      if PointInRect(mouse_X, mouse_Y, i + 28, j + 93, 33, 33) then
        Item_UpdateSlot(@Hero.RHandItem, 'RHand');
      if PointInRect(mouse_X, mouse_Y, i + 106, j + 93, 33, 33) then
        Item_UpdateSlot(@Hero.LHandItem, 'LHand');
      if PointInRect(mouse_X, mouse_Y, i + 67, j + 27, 33, 33) then
        Item_UpdateSlot(@Hero.HeadItem, 'Head');
      if PointInRect(mouse_X, mouse_Y, i + 67, j + 67, 33, 33) then
        Item_UpdateSlot(@Hero.BodyItem, 'Body');
      if PointInRect(mouse_X, mouse_Y, i + 67, j + 124, 33, 33) then
        Item_UpdateSlot(@Hero.LegsItem, 'Legs');
    end;
    if PointInRect(mouse_X, mouse_Y, i + 28, j + 93, 33, 33) then
      InitItemHint(i + 28, j + 93, @Hero.RHandItem);
    if PointInRect(mouse_X, mouse_Y, i + 106, j + 93, 33, 33) then
      InitItemHint(i + 106, j + 93, @Hero.LHandItem);
    if PointInRect(mouse_X, mouse_Y, i + 67, j + 27, 33, 33) then
      InitItemHint(i + 67, j + 27, @Hero.HeadItem);
    if PointInRect(mouse_X, mouse_Y, i + 67, j + 67, 33, 33) then
      InitItemHint(i + 67, j + 67, @Hero.BodyItem);
    if PointInRect(mouse_X, mouse_Y, i + 67, j + 124, 33, 33) then
      InitItemHint(i + 67, j + 124, @Hero.LegsItem); }

    i := 0;
    j := 0;
    imo := -1;
    if (mouse_X > (ScreenW - 200)) and (mouse_Y > 590) and (mouse_Y < 590 + 7 * 33) then
    begin
      i := (mouse_X - (ScreenW - 200) - 2) div 33;
      j := (mouse_Y - 590) div 33;
      if i < 0 then
        i := 0;
      if j < 0 then
        j := 0;
      if i > 5 then
        i := 5;
      if j > 4 then
        j := 4;
      imo := j * 6 + i;
    end;

    if (mouse_Click(M_BLEFT)) and (imo <> -1) then
      Item_UpdateSlot(@Hero.Items[imo], '');
    if (mouse_Click(M_BRIGHT)) and (imo <> -1) and (BtnDwn = 0) then
      Item_Use(@Hero.Items[imo], Hero);

    if imo <> -1 then
      InitItemHint(i * 33 + ScreenW - 200, j * 33 + 590, @Hero.Items[imo]);
  end;

  if (LookAtObj <> nil) and (DragItem = nil) then
  begin
    if mouse_Click(M_BLEFT) then
    begin
      DragX := mouse_X - ChestX;
      DragY := mouse_Y - ChestY;
      if PointInRect(mouse_X, mouse_Y, ChestX, ChestY, 4 * 33 + 40, 2 * 33 + 20) then
        BtnDwn := 3;
      if PointInRect(mouse_X, mouse_Y, ChestX + 10, ChestY + 10, 4 * 33, 2 * 33) then
        BtnDwn := 0;
      if PointInRect(mouse_X, mouse_Y, ChestX + 149, ChestY + 10, 16, 16) then
        BtnDwn := 1;
      if PointInRect(mouse_X, mouse_Y, ChestX + 149, ChestY + 27, 16, 16) then
        BtnDwn := 2;
    end;
    if BtnDwn = 3 then
    begin
      ChestX := mouse_X - DragX;
      ChestY := mouse_Y - DragY;
      if ChestX < 0 then
        ChestX := 0;
      if ChestY < 0 then
        ChestY := 0;
      if ChestX + 4 * 33 + 40 > ScreenW - 200 then
        ChestX := ScreenW - 200 - 4 * 33 - 40;
      if ChestY + 2 * 33 + 20 > ScreenH then
        ChestY := ScreenH - 2 * 33 - 20;
    end;

    if mouse_Up(M_BLEFT) then
    begin
      if PointInRect(mouse_X, mouse_Y, ChestX + 149, ChestY + 10, 16, 16) and (BtnDwn = 1) then
        LookAtObj := nil;
      if PointInRect(mouse_X, mouse_Y, ChestX + 149, ChestY + 27, 16, 16) and (BtnDwn = 2) then
      begin
        for i := 0 to LookAtObj.ItemsCnt - 1 do
          if LookAtObj.Items[i].Count > 0 then
          begin
            Hero.CreateItem(LookAtObj.Items[i].Pat, LookAtObj.Items[i].Count);
            LookAtObj.Items[i].Count := 0;
          end;
      end;
    end;
  end;
  if mouse_Down(M_BLEFT) = False then
    BtnDwn := 0;

  i := 0;
  j := 0;
  iob := -1;
  if (LookAtObj <> nil) and (BtnDwn = 0) then
    if (mouse_X > ChestX + 10) and (mouse_Y > ChestY + 10) and (mouse_X < ChestX + 10 + 33 * 4) and (mouse_Y < ChestY + 10 + 33 * 2) then
    begin
      i := (mouse_X - (ChestX + 10)) div 33;
      j := (mouse_Y - (ChestY + 10)) div 33;
      if i < 0 then
        i := 0;
      if j < 0 then
        j := 0;
      if i > 3 then
        i := 3;
      if j > 1 then
        j := 1;
      iob := j * 4 + i;
    end;

  if (mouse_Click(M_BLEFT)) and (iob <> -1) then
    Item_UpdateSlot(@LookAtObj.Items[iob], '');
  if iob <> -1 then
    InitItemHint(i * 33 + ChestX + 10, j * 33 + ChestY + 10, @LookAtObj.Items[iob]);

  if DragItem <> nil then
  begin
    if mouse_Click(M_BRIGHT) then
    begin
      DragItem.Count := DragItem.Count + DragCount;
      DragItem := nil;
    end;

    if mouse_Wheel(M_WUP) then
      if DragItem.Count > 0 then
      begin
        DragCount := DragCount + 1;
        DragItem.Count := DragItem.Count - 1;
      end;
    if mouse_Wheel(M_WDOWN) then
      if DragCount > 1 then
      begin
        DragCount := DragCount - 1;
        DragItem.Count := DragItem.Count + 1;
      end;
  end;

  if mouse_Click(M_BRIGHT) then
    SellSpellN := -1;

  if HintItem = nil then
    Hint.Show := False
  else if nmtime > 30 then
    Hint.Show := True;
end;

function MouseOverGUI: Boolean;
begin
  Result := True;

  if NewGame = True then
    Exit;
  if BtnDwn <> 0 then
    Exit;
  if Hero.Health = 0 then
    Exit;

  if mouse_X > (ScreenW - 200) then
    Exit;

  if LookAtObj <> nil then
    if PointInRect(mouse_X, mouse_Y, ChestX, ChestY, 4 * 33 + 40, 2 * 33 + 20) then
      Exit;

  Result := False;
end;

procedure InitItemHint(x, y: Integer; Item: PItem);
var
  W: Integer;
begin
  if Item.Count = 0 then
    Exit;
  Hint.Text := Item.Pat.GameName;
  if Hero.GetParamValue('Интеллект') = 0 then
    Hint.Text := 'Какая-то штука';

  W := Round(text_GetWidth(Fnt, A2U8(Hint.Text)));
  Hint.W := W + 20;
  Hint.H := 21;
  Hint.x := x - (Hint.W - 32) div 2;
  Hint.y := y - Hint.H + 5;
  if Hint.x < 0 then
    Hint.x := 0;
  if Hint.y < 0 then
    Hint.y := 0;
  if Hint.x + Hint.W > ScreenW then
    Hint.x := ScreenW - Hint.W;
  if Hint.y + Hint.H > ScreenH then
    Hint.y := ScreenH - Hint.H;
  HintItem := Item;
end;

procedure SomeTextOut(x, y: Integer; Text: String);
var
  W: Integer;
begin
  SomeText := Text;
  STPos := Point2D(x, y);
  STTime := Length(Text) * 10;
  W := Round(text_GetWidth(Fnt, A2U8(Text)));
  if STPos.x + W div 2 > ScreenW then
    STPos.x := ScreenW - W div 2;
  if STPos.x + W div 2 < 0 then
    STPos.x := W div 2;
end;

end.
