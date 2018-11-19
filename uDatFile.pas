unit uDatFile;

interface

uses
  zglHeader;

type
  TDatStrings = array of String;

type
  TDatParam = class
    Name   : String;
    Value  : String;
    IsZero : Boolean;

    constructor Create;
    destructor Destroy; override;
    function Str( const DefValue : String ) : String;
    function Int( const DefValue : Integer ) : Integer;
    function Float( const DefValue : Single ) : Single;
    function Bool( const DefValue : Boolean ) : Boolean;
  end;

type
  TDatBlock = class
    Name       : String;
    TextBlock  : Boolean;
    Strings    : array of String;
    StringsCnt : Integer;
    Blocks     : array of TDatBlock;
    BlocksCnt  : Integer;
    Params     : array of TDatParam;
    ParamsCnt  : Integer;
    ZeroParam  : TDatParam;

    constructor Create;
    destructor Destroy; override;
    procedure AddString( Str : String );
    procedure DeleteString( StrN : Integer );
    function AddBlock( BlockName : String ) : TDatBlock;
    function Block( BlockName : String ) : TDatBlock;
    function Param( ParamName : String ) : TDatParam;
    procedure SetParam( ParamName, ParamValue : String );
    function StrGetValid( Str : String ) : String;
    procedure ParseStrings( Strs : TDatStrings; ParseLen : Integer; var ParsePos : Integer );
    procedure GetAllStrings( var Str: TDatStrings; var Cnt : Integer );
  end;

type
  TDat = class( TDatBlock )

    procedure LoadFromFile( FileName : String );
    procedure SaveToFile( FileName : String );
    function GetString : String;
  end;

implementation

//==============================================================================
constructor TDatParam.Create;
begin
  Name   := '';
  Value  := '';
  IsZero := False;
end;

//==============================================================================
destructor TDatParam.Destroy;
begin
  Name  := '';
  Value := '';
  inherited;
end;

//==============================================================================
function TDatParam.Str( const DefValue : String ) : String;
begin
  if IsZero = True then
  begin
    Result := DefValue;
    Exit;
  end;
  Result := Value;
end;

//==============================================================================
function TDatParam.Int( const DefValue : Integer ) : Integer;
var
  e : Integer;
begin
  Val( Value, Result, e );
  if e <> 0 then Result := DefValue;
end;

//==============================================================================
function TDatParam.Float( const DefValue : Single ) : Single;
var
  e : Integer;
begin
  Val( Value, Result, e );
  if e <> 0 then Result := DefValue;
end;

//==============================================================================
function TDatParam.Bool( const DefValue : Boolean ) : Boolean;
begin
  if IsZero = True then
  begin
    Result := DefValue;
    Exit;
  end;
  if Value = '' then
  begin
    Result := True;
    Exit;
  end;
  Result := u_StrToBool( Value );
end;

//==============================================================================
//======== TDatBlock ===========================================================
//==============================================================================
constructor TDatBlock.Create;
begin
  Name       := '';
  TextBlock  := False;
  StringsCnt := 0;
  BlocksCnt  := 0;
  ParamsCnt  := 0;
  ZeroParam  := TDatParam.Create;
  ZeroParam.IsZero := True;
end;

//==============================================================================
destructor TDatBlock.Destroy;
var
  i : Integer;
begin
  Name := '';
  for i := 0 to StringsCnt - 1 do
    Strings[ i ] := '';
  SetLength( Strings, 0 );
  for i := 0 to BlocksCnt - 1 do
    Blocks[ i ].Free;
  SetLength( Blocks, 0 );
  for i := 0 to ParamsCnt - 1 do
    Params[ i ].Free;
  SetLength( Params, 0 );
  ZeroParam.Free;
  inherited;
end;

//==============================================================================
procedure TDatBlock.AddString( Str : String );
begin
  Inc( StringsCnt );
  SetLength( Strings, StringsCnt );
  Strings[ StringsCnt - 1 ] := Str;
end;

//==============================================================================
procedure TDatBlock.DeleteString( StrN : Integer );
var
  i : Integer;
begin
  for i := StrN to StringsCnt - 2 do
    Strings[ i ] := Strings[ i + 1 ];
  Dec( StringsCnt );
  SetLength( Strings, StringsCnt );
end;

//==============================================================================
function TDatBlock.AddBlock( BlockName : String ) : TDatBlock;
begin
  Inc( BlocksCnt );
  SetLength( Blocks, BlocksCnt );
  Blocks[ BlocksCnt - 1 ] := TDatBlock.Create;
  Blocks[ BlocksCnt - 1 ].Name := BlockName;
  Result := Blocks[ BlocksCnt - 1 ];
end;

//==============================================================================
function TDatBlock.Block( BlockName : String ) : TDatBlock;
var
  i : Integer;
begin
  Result := nil;
  BlockName := u_StrUp( BlockName );

  for i := 0 to BlocksCnt - 1 do
    if u_StrUp( Blocks[ i ].Name ) = BlockName then
    begin
      Result := Blocks[ i ];
      Exit;
    end;
end;

//==============================================================================
function TDatBlock.Param( ParamName : String ) : TDatParam;
var
  i : Integer;
begin
  Result := ZeroParam;
  ParamName := u_StrUp( ParamName );

  for i := 0 to ParamsCnt - 1 do
    if u_StrUp( Params[ i ].Name ) = ParamName then
    begin
      Result := Params[ i ];
      Exit;
    end;
end;

//==============================================================================
procedure TDatBlock.SetParam( ParamName, ParamValue : String );
var
  i     : Integer;
  PName : String;
begin
  PName := u_StrUp( ParamName );

  for i := 0 to ParamsCnt - 1 do
    if u_StrUp( Params[ i ].Name ) = PName then
    begin
      Params[ i ].Value := ParamValue;
      Exit;
    end;

  Inc( ParamsCnt );
  SetLength( Params, ParamsCnt );
  Params[ ParamsCnt - 1 ]       := TDatParam.Create;
  Params[ ParamsCnt - 1 ].Name  := ParamName;
  Params[ ParamsCnt - 1 ].Value := ParamValue;
end;

//==============================================================================
function TDatBlock.StrGetValid( str : String ) : String;
var
  len, i   : Integer;
  IsString : Boolean;
  IsValid  : Boolean;
begin
  Result := '';
  len := Length( str );
  if len = 0 then Exit;

  IsString := False;

  for i := 1 to len do
  begin
    if str[ i ] = '"' then IsString := not ( IsString );

    if ( IsString = False ) and ( str[ i ] = '/' ) and ( i < len ) then
      if str[ i + 1 ] = '/' then Break;

    IsValid := True;
    if ( str[ i ] = ' ' ) and ( IsString = False ) then IsValid := False;
    if str[ i ] = '"' then IsValid := False;
    if Ord( str[ i ] ) = 9 then IsValid := False;

    if IsValid = True then Result := Result + str[ i ];
  end;
end;

//==============================================================================
procedure TDatBlock.ParseStrings( Strs : TDatStrings; ParseLen : Integer; var ParsePos : Integer );
var
  j          : Integer;
  str        : String;
  len        : Integer;
  BlockName  : String;
  Blck       : TDatBlock;
  ParamName  : String;
  ParamValue : String;
  IsParam    : Boolean;
begin
  while ParsePos > 0 do
  begin
    str := StrGetValid( Strs[ ParseLen - ParsePos ] );
    if str = '</' + Name + '>' then
    begin
      ParsePos := ParsePos - 1;
      Exit;
    end;
    len := Length( str );

    if TextBlock then
    begin
      while str <> '[/' + Name + ']' do
      begin
        AddString( Strs[ ParseLen - ParsePos ] );
        ParsePos := ParsePos - 1;
        if ParsePos = 0 then Exit;
        str := Strs[ ParseLen - ParsePos ];
        if str <> '' then
        begin
          len := Length( str );
          for j := 1 to len do
          begin
            if str[ j ] = '[' then
            begin
              str := StrGetValid( Strs[ ParseLen - ParsePos ] );
              Break;
            end;
            if not( ( str[ j ] = ' ' ) or ( Ord( str[ j ] ) = 9 ) ) then Break;            
          end;
        end;
      end;
      ParsePos := ParsePos - 1;
      Exit;
    end;

    if len > 0 then
    begin
      if ( ( str[ 1 ] = '<' ) and ( str[ len ] = '>' ) ) or ( ( str[ 1 ] = '[' ) and ( str[ len ] = ']' ) ) then
      begin
        BlockName := '';
        for j := 2 to len - 1 do
          BlockName := BlockName + str[ j ];

        Blck := AddBlock( BlockName );
        if str[ 1 ] = '[' then Blck.TextBlock := True;

        ParsePos := ParsePos - 1;
        if ParsePos = 0 then Exit;
        Blck.ParseStrings( Strs, ParseLen, ParsePos );

        Continue;
      end;

      ParamName  := '';
      ParamValue := '';
      IsParam    := False;
      for j := 1 to len do
      begin
        if ( str[ j ] = '=' ) and ( IsParam = False ) then
        begin
          IsParam := True;
          Continue;
        end;

        if IsParam = False then ParamName := ParamName + str[ j ]
          else ParamValue := ParamValue + str[ j ];
      end;

      Inc( ParamsCnt );
      SetLength( Params, ParamsCnt );
      Params[ ParamsCnt - 1 ]       := TDatParam.Create;
      Params[ ParamsCnt - 1 ].Name  := ParamName;
      Params[ ParamsCnt - 1 ].Value := ParamValue;
    end;

    ParsePos := ParsePos - 1;
  end;
end;

//==============================================================================
procedure TDatBlock.GetAllStrings( var Str : TDatStrings; var Cnt : Integer );
var
  i : Integer;
begin
  if Name <> '' then
  begin
    Inc( Cnt );
    SetLength( Str, Cnt );
    if TextBlock = False then Str[ Cnt - 1 ] := '<' + Name + '>'
      else Str[ Cnt - 1 ] := '[' + Name + ']';
  end;
  for i := 0 to StringsCnt - 1 do
  begin
    Inc( Cnt );
    SetLength( Str, Cnt );
    Str[ Cnt - 1 ] := Strings[ i ];
  end;
  for i := 0 to BlocksCnt - 1 do
    Blocks[ i ].GetAllStrings( Str, Cnt );
  if Name <> '' then
  begin
    Inc( Cnt );
    SetLength( Str, Cnt );
    if TextBlock = False then Str[ Cnt - 1 ] := '</' + Name + '>'
      else Str[ Cnt - 1 ] := '[/' + Name + ']';
  end;
end;

//==============================================================================
//======== TDat ================================================================
//==============================================================================
procedure TDat.LoadFromFile( FileName : String );
var
  f             : zglTFile;
  sz            : LongWord;
  sCnt, sLen    : Integer;
  n, k          : Integer;
  str, str2     : String;
  strs          : TDatStrings;
begin
  file_Open( f, FileName, FOM_OPENR );
  sz := file_GetSize( f );
  SetLength( str, sz );
  file_Read( f, str[ 1 ], sz );
  file_Close( f );
  n := Pos( '﻿', str );
  if n = 1 then Delete( str, 1, 3 );
  k := 1;
  if Pos( #13, str ) > 0 then k := 2;

  str2  := '';
  sCnt  := 0;
  sLen  := 32;
  SetLength( strs, sLen );
  repeat
    n := Pos( #10, str );
    if n > 0 then
    begin
      strs[ sCnt ] := Copy( str, 1, n - k );
      Delete( str, 1, n );
    end else
    begin
      strs[ sCnt ] := str;
      Break;
    end;

    INC( sCnt );
    if sCnt = sLen then
    begin
      sLen := sLen + 32;
      SetLength( strs, sLen );
    end;
  until False;
  INC( sCnt );
  SetLength( strs, sCnt );

  ParseStrings( strs, sCnt, sCnt );
end;

//==============================================================================
procedure TDat.SaveToFile( FileName : String );
var
  f     : zglTFile;
  i     : Integer;
  strs  : TDatStrings;
  sCnt  : Integer;
  str   : String;
begin
  sCnt := 0;
  GetAllStrings( strs, sCnt );
  str := '';
  for i := 0 to sCnt - 1 do
  begin
    str := str + strs[ i ];
    if i < sCnt - 1 then str := str + #13#10;
  end;

  file_Open( f, FileName, FOM_CREATE );
  file_Write( f, str[ 1 ], Length( str ) );
  file_Close( f );
end;

//==============================================================================
function TDat.GetString : String;
var
  i    : Integer;
  str  : TDatStrings;
  sCnt : Integer;
begin
  Result := '';
  sCnt := 0;
  GetAllStrings( str, sCnt );

  for i := 0 to sCnt - 1 do
  begin
    Result := Result + str[ i ];
    Result := Result + #13;
    Result := Result + #10;
  end;
end;

end.

