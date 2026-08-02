unit ModernProfileEditorDrivesFrameHelpers;

interface

uses Classes;

function NextFreeDriveLetter(const Mounting: TStringList): Char;
function UsedDriveLetters(const Mounting: TStringList; const AllowedNr: Integer = -1): String;

implementation

uses
  CommonHelpers, SysUtils;

function NextFreeDriveLetter(const Mounting: TStringList): Char;
Var I : Integer;
    B : Boolean;
    St : TStringList;
begin
  result:='C';
  repeat
    B:=True;
    For I:=0 to Mounting.Count-1 do begin
      St:=ValueToList(Mounting[I]);
      try
        If St.Count<3 then continue;
        if UpperCase(St[2])=result then begin inc(result); B:=False; break; end;
      finally
        St.Free;
      end;
    end;
  until B;
end;

function UsedDriveLetters(const Mounting: TStringList; const AllowedNr : Integer): String;
Var I : Integer;
    St : TStringList;
begin
  result:='';
  For I:=0 to Mounting.Count-1 do If I<>AllowedNr then begin
    St:=ValueToList(Mounting[I]);
    try
      If St.Count>=3 then result:=result+UpperCase(St[2]);
    finally
      St.Free;
    end;
  end;
end;

end.
