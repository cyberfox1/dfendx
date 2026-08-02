unit PackageManagerHelpers;

interface

uses Classes, SysUtils, CommonHelpers, GameDBUnit;

Function FindGameByNameOrChecksum(const Name, Checksum : String; const GameDB : TGameDB) : Boolean;
Procedure AddUniqueSemicolonValues(const S : String; const ListUpper, List : TStringList);

implementation

Function FindGameByNameOrChecksum(const Name, Checksum : String; const GameDB : TGameDB) : Boolean;
Var I : Integer;
    S : String;
begin
  result:=False;
  S:=ExtUpperCase(Name);
  For I:=0 to GameDB.Count-1 do If ExtUpperCase(GameDB[I].CacheName)=S then begin
    If Checksum='' then begin result:=True; exit; end;
    If GameDB[I].GameExeMD5='' then begin result:=True; end
    else If GameDB[I].GameExeMD5=Checksum then begin result:=True; exit; end
    else begin If result then result:=False; end;
  end;
end;

Procedure AddUniqueSemicolonValues(const S : String; const ListUpper, List : TStringList);
Var I : Integer;
    T,U : String;
begin
  T:=S;
  I:=Pos(';',T);
  While T<>'' do begin
    If I>0 then begin
      U:=Trim(Copy(T,1,I-1)); T:=Trim(Copy(T,I+1,MaxInt));
    end else begin
      U:=T; T:='';
    end;
    I:=Pos(';',T);
    If (U<>'') and (ListUpper.IndexOf(ExtUpperCase(U))<0) then begin List.Add(U); ListUpper.Add(ExtUpperCase(U)); end;
  end;
end;

end.
