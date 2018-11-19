unit gm_utils;

interface

uses
  Windows;

function A2U8(const S: string; const cp : integer = 1251): UTF8String;

implementation

//==============================================================================
function A2U8(const S: string; const cp : integer = 1251): UTF8String;
var
  wlen, ulen : integer;
  wbuf : PWideChar;
begin
  Result := '';
  wlen := MultiByteToWideChar(cp, 0, PChar(S), length(S), NIL, 0); // wlen is the number of UCS2 without NULL terminater.
  if wlen = 0 then exit;
  wbuf := GetMemory(wlen * sizeof(wchar));
  try
    MultiByteToWideChar(cp, 0, PChar(S), length(S), wbuf, wlen);

    ulen := WideCharToMultiByte(CP_UTF8, 0, wbuf, wlen, NIL, 0, NIL, NIL);
    setlength(Result, ulen);
    WideCharToMultiByte(CP_UTF8, 0, wbuf, wlen, PChar(Result), ulen, NIL, NIL);
  finally
    FreeMemory(WBuf);
  end;
end;

end.
