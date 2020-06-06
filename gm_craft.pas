unit gm_craft;

interface

type
  TItemToObjRecStr = record
    Item: string;
    Obj: string;
  end;

const
  // Установка объектов на поверхность
  ItemToObjRec: array [0..1] of TItemToObjRecStr = (
  // Деревяная дверь
  (Item:'ITEM_DOOR';      Obj:'DOOR'),
  // Кирпичная стена
  (Item:'ROCK';           Obj:'WALL')
  //
  );

type
  TToolEnum = (tlPickaxe, tlHatchet);

type
  TItemCountEnum = (icOne, ic2To4);

type
  TObjToItemRecStr = record
    Obj: string;
    Item: string;
    ItemCount: TItemCountEnum;
    Tool: TToolEnum;
  end;

const
  // Добывание предметов из объектов
  ObjToItemRec: array[0..2] of TObjToItemRecStr = (
  // Доб. бревна из дерева
  (Obj:'TREE';      Item:'WOOD';    ItemCount:ic2To4;     Tool:tlHatchet),
  (Obj:'DTREE';     Item:'WOOD';    ItemCount:icOne;      Tool:tlHatchet),
  // Доб. булыжник из стен
  (Obj:'WALL';      Item:'ROCK';    ItemCount:ic2To4;     Tool:tlPickaxe)
  //
  );

implementation

end.
