program Warfold;

uses
  FastMM4, zglHeader, GameCore, gm_types;

procedure gmInit;
begin
  Game_Init;
end;

procedure gmDraw;
begin
  Game_Draw;
end;

procedure gmTimer;
begin
  Game_Update;
end;

procedure gmQuit;
begin
  Game_Quit;
end;

begin
  if not zglLoad( libZenGL ) then Exit;
  
  Randomize;

  timer_Add( @gmTimer, 10 );
  zgl_Reg( SYS_LOAD, @gmInit );
  zgl_Reg( SYS_DRAW, @gmDraw );
  zgl_Reg( SYS_EXIT, @gmQuit );

  wnd_SetCaption( 'Rogue' );
  wnd_ShowCursor( True );

  zgl_Disable( APP_USE_LOG );
  zgl_Enable( CLIP_INVISIBLE );

  ScreenW := 1024;
  ScreenH := 768;   

  scr_SetOptions( ScreenW, ScreenH, REFRESH_MAXIMUM, FullScr, VSync );
  zgl_Init;
end.

