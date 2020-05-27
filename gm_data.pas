unit gm_data;

interface

uses
  zglHeader, gm_types, gm_patterns;

var
  WBlackTex   : zglPTexture;
  WWhiteTex   : zglPTexture;
  WShadowTex  : zglPTexture;
  ItemSlotTex : zglPTexture;
  BtnTex      : zglPTexture;
  Btn1Tex     : zglPTexture;
  DollTex     : zglPTexture;
  GlowTex     : zglPTexture;
  BagTex      : zglPTexture;
  StatsTex    : zglPTexture;
  SpellTex    : zglPTexture;
  CraftTex    : zglPTexture;
  ScrtsTex    : zglPTexture;
  Btn2Tex     : zglPTexture;
  FireTex     : zglPTexture;
  IceTex      : zglPTexture;
  BoxTex      : zglPTexture;

procedure Data_Load;
procedure Data_Free;

implementation

//==============================================================================
procedure Data_Load;
begin
  Fnt         := font_LoadFromFile( 'Data\Fonts\font.zfi' );
  Fnt2        := font_LoadFromFile( 'Data\Fonts\font2.zfi' );

  WBlackTex   := tex_LoadFromFile( 'Data\Sprites\wblack.png' );
  WWhiteTex   := tex_LoadFromFile( 'Data\Sprites\wwhite.png' );
  WShadowTex  := tex_LoadFromFile( 'Data\Sprites\wshadow.png' );
  ItemSlotTex := tex_LoadFromFile( 'Data\Sprites\itemslot.png' );
  BtnTex      := tex_LoadFromFile( 'Data\Sprites\btn.png' );
  Btn1Tex     := tex_LoadFromFile( 'Data\Sprites\chestbtn.png' );
  Btn2Tex     := tex_LoadFromFile( 'Data\Sprites\pmbtn.png' );
  DollTex     := tex_LoadFromFile( 'Data\Sprites\doll.png' );
  GlowTex     := tex_LoadFromFile( 'Data\Sprites\glow.png' );
  BagTex      := tex_LoadFromFile( 'Data\Sprites\bag.png' );
  StatsTex    := tex_LoadFromFile( 'Data\Sprites\stats.png' );
  SpellTex    := tex_LoadFromFile( 'Data\Sprites\spellbook.png' );
  CraftTex    := tex_LoadFromFile( 'Data\Sprites\craft.png' );
  ScrtsTex    := tex_LoadFromFile( 'Data\Sprites\scratches.png' );
  FireTex     := tex_LoadFromFile( 'Data\Sprites\fire.png' );
  IceTex      := tex_LoadFromFile( 'Data\Sprites\ice.png' );
  BoxTex      := tex_LoadFromFile( 'Data\Sprites\box.png' );
  tex_SetFrameSize( BtnTex, 32, 32 );
  tex_SetFrameSize( Btn1Tex, 16, 16 );
  tex_SetFrameSize( Btn2Tex, 16, 16 );

  CrParam_Add( 'Strength', 'Сила' );
  CrParam_Add( 'Agility', 'Ловкость' );
  CrParam_Add( 'Endurance', 'Выносливость' );
  CrParam_Add( 'Intelligence', 'Интеллект' );

  CrParam_Add( 'Sword', 'Меч' );
  CrParam_Add( 'Axe', 'Топор' );
  CrParam_Add( 'Bow', 'Лук' );
  CrParam_Add( 'Throwing', 'Метание' );  
  CrParam_Add( 'Unarmed', 'Без оружия' );
  CrParam_Add( 'Magic', 'Магия' );

  AddSpell( 'Лечение', 3, 2 );
  AddSpell( 'Огненный шар', 3, 2 );
  AddSpell( 'Регенерация', 3, 2 );
  AddSpell( 'Заморозка', 5, 2 );
  AddSpell( 'Гипноз', 7, 5 );
  AddSpell( 'Вампиризм', 3, 5 );
  AddSpell( 'Вызов голема', 10, 5 );
  AddSpell( 'Армагеддон', 30, 8 );

  LoadPatterns( 'Data\' );
end;

//==============================================================================
procedure Data_Free;
begin
  Patterns_Free;
end;

end.
