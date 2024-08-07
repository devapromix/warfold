unit gm_craft;

interface

type
  TItemToObjRecStr = record
    Item: string;
    Obj: string;
  end;

const
  // ��������� �������� �� �����������
  ItemToObjRec: array [0..1] of TItemToObjRecStr = (
  // ��������� �����
  (Item:'ITEM_DOOR';      Obj:'DOOR'),
  // ��������� �����
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
  // ��������� ��������� �� ��������
  ObjToItemRec: array[0..1] of TObjToItemRecStr = (
  // ���. ������ �� ������
  (Obj:'TREE';      Item:'WOOD';    ItemCount:ic2To4;     Tool:tlHatchet),
  // ���. �������� �� ����
  (Obj:'WALL';      Item:'ROCK';    ItemCount:ic2To4;     Tool:tlPickaxe)
  //
  );

implementation

end.
