unit gm_obj;

interface

uses
  zglHeader, gm_data, gm_patterns, gm_item;

type
  TObj = class
    Pat: TObjPat;
    FrameN: Byte;
    Durability: Integer;
    BlockWalk: Boolean;
    BlockLook: Boolean;
    Items: array of TItem;
    ItemsCnt: Integer;
    function CreateItem(ItemPat: TItemPat; Count: Integer): Boolean;
  end;

type
  TObjects = class
    Width: Integer;
    Height: Integer;
    Obj: array of array of TObj;

    constructor Create(w, h: Integer);
    destructor Destroy; override;
    procedure Draw;
    procedure Update;
    procedure ObjCreate(tx, ty: Integer; ObjPat: TObjPat);
    procedure Clear;
    function IsWall(tx, ty: Integer): Boolean;
    function PatName(tx, ty: Integer): String;
  end;

var
  LookAtObj: TObj;

implementation

// ==============================================================================
function TObj.CreateItem(ItemPat: TItemPat; Count: Integer): Boolean;
var
  i: Integer;
begin
  Result := True;
  if ItemPat.CanGroup then
    for i := 0 to ItemsCnt - 1 do
      if Items[i].Count > 0 then
        if Items[i].Pat = ItemPat then
        begin
          Items[i].Count := Items[i].Count + Count;
          Exit;
        end;
  for i := 0 to ItemsCnt - 1 do
    if Items[i].Count = 0 then
    begin
      Items[i].Pat := ItemPat;
      Items[i].Count := Count;
      Exit;
    end;
  if ItemsCnt = 8 then
  begin
    Result := False;
    Exit;
  end;
  ItemsCnt := ItemsCnt + 1;
  SetLength(Items, ItemsCnt);
  Items[ItemsCnt - 1].Pat := ItemPat;
  Items[ItemsCnt - 1].Count := Count;
end;

// ==============================================================================
constructor TObjects.Create(w, h: Integer);
begin
  Width := w;
  Height := h;
  SetLength(Obj, w, h);
end;

// ==============================================================================
destructor TObjects.Destroy;
var
  i, j: Integer;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if Obj[i, j] <> nil then
        Obj[i, j].Free;

  inherited;
end;

// ==============================================================================
procedure TObjects.Draw;
var
  i, j, d: Integer;
  Pat: TObjPat;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if Obj[i, j] = nil then
        Continue;
      Pat := Obj[i, j].Pat;

      asprite2d_Draw(Pat.Tex, i * 32, j * 32, 32, 32, 0, Obj[i, j].FrameN + 1);

      if Obj[i, j].Pat.IsWall = False then
        Continue;

      if IsWall(i, j + 1) = False then
      begin
        ssprite2d_Draw(WBlackTex, i * 32, j * 32, 32, 32, 180, 200);
        ssprite2d_Draw(WShadowTex, i * 32, j * 32 + 32, WShadowTex.Width, WShadowTex.Height, 0, 30);
      end;
      if IsWall(i + 1, j) = False then
      begin
        ssprite2d_Draw(WBlackTex, i * 32, j * 32, 32, 32, 90, 200);
        ssprite2d_Draw(WShadowTex, i * 32 + 16, j * 32 + 16, WShadowTex.Width, WShadowTex.Height, 90, 30, FX_BLEND or FX2D_FLIPX);
      end;
      if IsWall(i, j - 1) = False then
        ssprite2d_Draw(WWhiteTex, i * 32, j * 32, 32, 32, 0, 100);
      if IsWall(i - 1, j) = False then
        ssprite2d_Draw(WWhiteTex, i * 32, j * 32, 32, 32, 270, 100);    
    end;
end;

// ==============================================================================
procedure TObjects.Update;
begin

end;

// ==============================================================================
procedure TObjects.ObjCreate(tx, ty: Integer; ObjPat: TObjPat);
begin
  if (tx < 0) or (ty < 0) or (tx >= Width) or (ty >= Height) then
    Exit;
  if Obj[tx, ty] <> nil then
    Obj[tx, ty].Free;
  Obj[tx, ty] := TObj.Create;
  Obj[tx, ty].Pat := ObjPat;
  Obj[tx, ty].BlockWalk := ObjPat.BlockWalk;
  Obj[tx, ty].BlockLook := ObjPat.BlockLook;
  Obj[tx, ty].Durability := ObjPat.Durability;
  if ObjPat.Container then
  begin
    Obj[tx, ty].ItemsCnt := 8;
    SetLength(Obj[tx, ty].Items, 8);
  end;
end;

// ==============================================================================
procedure TObjects.Clear;
var
  i, j: Integer;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if Obj[i, j] <> nil then
      begin
        Obj[i, j].Free;
        Obj[i, j] := nil;
      end;
end;

// ==============================================================================
function TObjects.IsWall(tx, ty: Integer): Boolean;
begin
  Result := False;
  if (tx < 0) or (ty < 0) or (tx >= Width) or (ty >= Height) then
    Exit;
  if Obj[tx, ty] = nil then
    Exit;
  Result := Obj[tx, ty].Pat.IsWall;
end;

// ==============================================================================
function TObjects.PatName(tx, ty: Integer): String;
begin
  Result := '';
  if (tx < 0) or (ty < 0) or (tx >= Width) or (ty >= Height) then
    Exit;
  if Obj[tx, ty] = nil then
    Exit;
  Result := Obj[tx, ty].Pat.Name;
end;

end.
