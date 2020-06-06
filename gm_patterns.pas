unit gm_patterns;

interface

uses
  zglHeader, SysUtils, uDatFile;

type
  TPattern = class
    Name: string;
    GameName: string;
    pType: string;
    Next: TPattern;

    Tex: zglPTexture;
    OffsetX: Integer;
    OffsetY: Integer;
    FrmW: Integer;
    FrmH: Integer;
  end;

  // ------ Ground ----------------------------------------------------------------
type
  TGroundPat = class(TPattern)

  end;

  // ------ Map -------------------------------------------------------------------
type
  TMapPat = class(TPattern)
    Ground : string;
    Plants : string;
    Walls  : Boolean;
    Trees  : Boolean;
    PlantCount: Integer;
    Water  : Boolean;
    WaterCount: Integer;
  end;

  // ------ Object ----------------------------------------------------------------
type
  TObjPat = class(TPattern)
    IsWall: Boolean;
    BlockWalk: Boolean;
    BlockLook: Boolean;
    BlockWall: Boolean;
    Locked: Boolean;
    Container: Boolean;
    Shrine: Boolean;
    Wall: Boolean;
    ShrineType: Integer;
    Durability: Integer;
  end;

  // ------ Creature --------------------------------------------------------------
type
  TCrPat = class(TPattern)
    Health: Integer;
    Mana: Integer;
    ParamValue: array of Integer;
    ParamsCnt: Integer;
    Exp: Integer;
    Drop: string;
    Rarity: Integer;
    Amount: Integer;
  end;

type
  TCrParam = record
    Name: String;
    RuName: String;
  end;

var
  CrParams: array of TCrParam;
  CrParamsCnt: Integer;

procedure CrParam_Add(PrName, PrRuName: String);

// ------ Item ------------------------------------------------------------------
type
  TItemPat = class(TPattern)
    CanGroup: Boolean;
    Equip: String;
    EquipTex: zglPTexture;
    Damage: Integer;
    Throw: Boolean;
    Rot: Boolean;
    FlyAng: Boolean;
    Sword: Boolean;
    Axe: Boolean;
    Bow: Boolean;
    Arrow: Boolean;
    Shield: Boolean;
    Rock: Boolean;
    Hatchet: Boolean;
    Pickaxe: Boolean;
  end;

  // ------ Spells ----------------------------------------------------------------
type
  TSpell = record
    Name: String;
    Mana: Integer;
    Int: Integer;
  end;

var
  AllSpells: array of TSpell;
  AllSpellsCnt: Integer = 0;

var
  Patterns: TPattern;

function Pattern_Get(pType, Name: String): TPattern;
procedure Pattern_Load(FileName: String);
procedure LoadPatterns(PatDir: String);
procedure Patterns_Free;
procedure AddSpell(Name: String; Mana, Int: Integer);

implementation

// ==============================================================================
procedure CrParam_Add(PrName, PrRuName: String);
begin
  CrParamsCnt := CrParamsCnt + 1;
  SetLength(CrParams, CrParamsCnt);
  CrParams[CrParamsCnt - 1].Name := PrName;
  CrParams[CrParamsCnt - 1].RuName := PrRuName;
end;

// ==============================================================================
function Pattern_Get(pType, Name: String): TPattern;
begin
  pType := u_StrUp(pType);
  Name := u_StrUp(Name);
  Result := Patterns;
  while Result <> nil do
  begin
    if (Result.pType = pType) and (Result.Name = Name) then
      Exit;
    Result := Result.Next;
  end;
end;

// ==============================================================================
procedure Pattern_Load(FileName: String);
var
  dat: TDat;
  Pat: TPattern;
  str, fdir: String;
  i: Integer;
begin
  dat := TDat.Create;
  dat.LoadFromFile(FileName);

  Pat := nil;
  if u_StrUp(dat.Param('Type').str('')) = 'GROUND' then
    Pat := TGroundPat.Create;
  if u_StrUp(dat.Param('Type').str('')) = 'OBJECT' then
    Pat := TObjPat.Create;
  if u_StrUp(dat.Param('Type').str('')) = 'CREATURE' then
    Pat := TCrPat.Create;
  if u_StrUp(dat.Param('Type').str('')) = 'ITEM' then
    Pat := TItemPat.Create;
  if u_StrUp(dat.Param('Type').str('')) = 'MAP' then
    Pat := TMapPat.Create;

  if Pat = nil then
  begin
    dat.Free;
    Exit;
  end;

  Pat.pType := u_StrUp(dat.Param('Type').str(''));
  Pat.Name := file_GetName(FileName);
  Pat.GameName := dat.Param('GameName').str(Pat.Name);
  Pat.Name := u_StrUp(dat.Param('Name').str(Pat.Name));
  Pat.Next := Patterns;
  Patterns := Pat;

  fdir := file_GetDirectory(FileName);

  with Pat do
  begin
    str := dat.Param('Texture').str('');
    if str = '' then
      str := dat.Param('Sprite').str('');
    Tex := tex_LoadFromFile(fdir + str);

    OffsetX := dat.Param('OffsetX').Int(0);
    OffsetY := dat.Param('OffsetY').Int(0);
    FrmW := dat.Param('FramesWidth').Int(32);
    FrmH := dat.Param('FramesHeight').Int(32);

    if (FrmW <> 0) and (FrmH <> 0) then
      tex_SetFrameSize(Tex, FrmW, FrmH);
  end;

  // ---------- Map -------------------------------------------------------------
  if Pat.pType = 'MAP' then
    with TMapPat(Pat) do
    begin
      Ground := dat.Param('Ground').str('Floor');
      Plants := dat.Param('Plants').str('');
      PlantCount := dat.Param('PlantCount').Int(0);
      Walls  := dat.Param('Walls').Bool(False);
      Trees  := dat.Param('Trees').Bool(False);
      Water  := dat.Param('Water').Bool(False);
      WaterCount := dat.Param('WaterCount').Int(0);
    end;

  // ---------- Ground ----------------------------------------------------------
  if Pat.pType = 'GROUND' then
    with TGroundPat(Pat) do
    begin
      
    end;

  // ---------- Object ----------------------------------------------------------
  if Pat.pType = 'OBJECT' then
    with TObjPat(Pat) do
    begin
      IsWall := dat.Param('Wall').Bool(False);
      if IsWall then
        BlockWalk := True;
      if IsWall then
        BlockLook := True;
      BlockWalk := dat.Param('BlockWalk').Bool(BlockWalk);
      BlockLook := dat.Param('BlockLook').Bool(BlockLook);
      BlockWall := dat.Param('BlockWall').Bool(False);
      Locked := dat.Param('Locked').Bool(False);
      Container := dat.Param('Container').Bool(False);
      Shrine := dat.Param('Shrine').Bool(False);
      ShrineType := dat.Param('ShrineType').Int(0);
      Durability := dat.Param('Durability').Int(0);
    end;

  // ---------- Creature --------------------------------------------------------
  if Pat.pType = 'CREATURE' then
    with TCrPat(Pat) do
    begin
      FrmW := dat.Param('FramesWidth').Int(0);
      FrmH := dat.Param('FramesHeight').Int(0);

      Health := dat.Param('Health').Int(40);
      Mana := dat.Param('Mana').Int(10);
      Exp := dat.Param('Exp').Int(1);

      SetLength(ParamValue, CrParamsCnt);
      for i := 0 to CrParamsCnt - 1 do
        if i < 4 then
          ParamValue[i] := dat.Param(CrParams[i].Name).Int(4)
        else
          ParamValue[i] := dat.Param(CrParams[i].Name).Int(0);

      Drop := dat.Param('Drop').str('');
      Rarity := dat.Param('Rarity').Int(100);
      Amount := dat.Param('Amount').Int(1);
    end;

  // ---------- Item ------------------------------------------------------------
  if Pat.pType = 'ITEM' then
    with TItemPat(Pat) do
    begin
      CanGroup := dat.Param('CanGroup').Bool(False);
      Equip := dat.Param('Equip').str('');
      str := dat.Param('EquipTex').str('');
      if str <> '' then
        EquipTex := tex_LoadFromFile(fdir + str);

      Damage := dat.Param('Damage').Int(1);

      Throw := dat.Param('Throw').Bool(False);
      Rot := dat.Param('Rotate').Bool(False);
      FlyAng := dat.Param('FlyAng').Bool(False);

      Sword := dat.Param('Sword').Bool(False);
      Axe := dat.Param('Axe').Bool(False);
      Bow := dat.Param('Bow').Bool(False);
      Arrow := dat.Param('Arrow').Bool(False);
      Shield := dat.Param('Shield').Bool(False);
      Rock := dat.Param('Rock').Bool(False);

      Hatchet := dat.Param('Hatchet').Bool(False);
      Pickaxe := dat.Param('Pickaxe').Bool(False);
    end;

  dat.Free;
end;

// ==============================================================================
procedure LoadPatterns(PatDir: String);
var
  fs: TSearchRec;
begin
  if PatDir <> '' then
    if PatDir[Length(PatDir)] <> '\' then
      PatDir := PatDir + '\';

  if FindFirst(PatDir + '*.*', faAnyFile, fs) = 0 then
    repeat
      if (fs.Name = '.') or (fs.Name = '..') then
        Continue;
      if (fs.Attr and faDirectory) <> 0 then
        LoadPatterns(PatDir + fs.Name)
      else if u_StrUp(file_GetExtension(fs.Name)) = 'DAT' then
        Pattern_Load(PatDir + fs.Name);
    until FindNext(fs) <> 0;
  FindClose(fs);
end;

// ==============================================================================
procedure Patterns_Free;
var
  p, pn: TPattern;
begin
  p := Patterns;
  while p <> nil do
  begin
    pn := p.Next;
    p.Free;
    p := pn;
  end;
  Patterns := nil;
end;

// ==============================================================================
procedure AddSpell(Name: String; Mana, Int: Integer);
begin
  AllSpellsCnt := AllSpellsCnt + 1;
  SetLength(AllSpells, AllSpellsCnt);
  AllSpells[AllSpellsCnt - 1].Name := Name;
  AllSpells[AllSpellsCnt - 1].Mana := Mana;
  AllSpells[AllSpellsCnt - 1].Int := Int;
end;

end.
