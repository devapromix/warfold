unit gm_types;

interface

uses
  zglHeader;

type
  TPoint2D = record
    X, Y : Integer;
  end;  

var
  ScreenW         : Integer;
  ScreenH         : Integer;
  FullScr         : Boolean = False;
  VSync           : Boolean = False;

  Cam             : zglTCamera2D;
  Fnt             : zglPFont;  
  Fnt2            : zglPFont;
  mxprev          : Integer;
  myprev          : Integer;
  nmtime          : Integer;
  NewGame         : Boolean = True;

  CharPoints      : Integer = 5;
  SkillPoints     : Integer = 5;

  SpellPoints     : Integer = 0;
  SellSpellN      : Integer = -1;

  WalkPause       : Integer;
  HeroMoved       : Boolean;

function Point2D( X, Y : Integer ) : TPoint2D;

implementation

function Point2D( X, Y : Integer ) : TPoint2D;
begin
  Result.X := X;
  Result.Y := Y;  
end;

end.
