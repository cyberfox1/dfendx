unit CheatDBHelpers;

interface

uses SysUtils, Classes, Math, CommonHelpers;

type
  TValueChangeType = (vctUp, vctDown);

  TResultStatus = (rsNoResultsYet, rsNoAddress, rsFound, rsMultipleAddresses);

  TIntegerArray = array of Integer;

  IMergeableActionStep = interface
    ['{D14E3B2A-5F8C-4A91-9B67-1F2C3D4E5F6A}']
    function GetBytes: Integer;
    function GetNewValue: string;
    function GetAddresses: string;
    procedure SetAddresses(const Value: string);
  end;

  TMemorySearchBase = class
  protected
    FCompleteFile: TMemoryStream;
    FAddressList: TList;
    FAddressSizeList: TList;
    FAddressLastValue: TList;
  public
    procedure SearchAddressWholeFile(const AMSt: TMemoryStream; const AValue: Integer);
    procedure SearchAddressInList(const AMSt: TMemoryStream; const AValue: Integer);
    procedure SearchAddressIndirectAgainstWholeFile(const AMSt: TMemoryStream; const AValueChangeType: TValueChangeType);
    procedure SearchAddressIndirectAgainstAddressList(const AMSt: TMemoryStream; const AValueChangeType: TValueChangeType);
    function GetResult(var AAddress, ASize: Integer): TResultStatus;
  end;

function ExtTryStrToInt(const S: String; var I: Integer): Boolean;
function LoadAddresses(const S: String; var List: TIntegerArray): Boolean;
function FileMatchingMaskPart(const Mask, Name: String): Boolean;
function FileMatchingMask(const FileName, FileMask: String): Boolean;
procedure CompressActionSteps(ActionSteps: TList);

Function ExtSeek(const St : TFileStream; const Address : Integer) : Boolean; overload;
Function ExtSeek(const St : TFileStream; const Address, BytesToWrite : Integer) : Boolean; overload;

{ Body of TCheatActionStepChangeAddress.Apply — same logic, free function for tests. }
Function Apply(const St: TFileStream; const FAddressesInt: TIntegerArray; const FBytes, FNewValueInt: Integer): Boolean; overload;

implementation

{ ---------- TMemorySearchBase ---------- }

procedure TMemorySearchBase.SearchAddressWholeFile(const AMSt: TMemoryStream; const AValue: Integer);
Var Address : Integer;
Procedure AddAddress(const ASize : Integer); begin FAddressList.Add(Pointer(Address)); FAddressSizeList.Add(Pointer(ASize)); FAddressLastValue.Add(Pointer(AValue)); end;
Var I : Integer;
    W : Word;
    B : Byte;
begin
  For Address:=0 to AMSt.Size-4 do begin
    AMSt.Position:=Address;
    AMSt.ReadBuffer(I,4);
    If I=AValue then AddAddress(4);
  end;
  If (AValue div $10000)=0 then begin
    {Check word sized values}
    For Address:=0 to AMSt.Size-2 do begin
      AMSt.Position:=Address;
      AMSt.ReadBuffer(W,2);
      If W=AValue then AddAddress(2);
    end;
  end;
  If (AValue div $100)=0 then begin
    {Check byte sized values}
    For Address:=0 to AMSt.Size-1 do begin
      AMSt.Position:=Address;
      AMSt.ReadBuffer(B,1);
      If B=AValue then AddAddress(1);
    end;
  end;
end;

procedure TMemorySearchBase.SearchAddressInList(const AMSt: TMemoryStream; const AValue: Integer);
Var I,J,S : Integer;
    W : Word;
    B : Byte;
begin
  I:=0;
  While I<FAddressList.Count do begin
    S:=Integer(FAddressSizeList[I]);
    If (NativeUInt(FAddressList[I])>=NativeUInt(AMSt.Size)) or (S>NativeUInt(AMSt.Size)) or (NativeUInt(FAddressList[I])>NativeUInt(AMSt.Size)-S) then begin
      FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I);
      continue;
    end;
    AMSt.Position:=NativeUInt(FAddressList[I]);
    If S=4 then begin
      AMSt.ReadBuffer(J,4);
      If J=AValue then begin FAddressLastValue[I]:=Pointer(AValue); inc(I); end else begin FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I); end;
      continue;
    end;
    If S=2 then begin
      AMSt.ReadBuffer(W,2);
      If W=AValue then begin FAddressLastValue[I]:=Pointer(AValue); inc(I); end else begin FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I); end;
      continue;
    end;
    If S=1 then begin
      AMSt.ReadBuffer(B,1);
      If B=AValue then begin FAddressLastValue[I]:=Pointer(AValue); inc(I); end else begin FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I); end;
      continue;
    end;
    FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I);
  end;
end;

procedure TMemorySearchBase.SearchAddressIndirectAgainstWholeFile(const AMSt: TMemoryStream; const AValueChangeType: TValueChangeType);
Var Address : Integer;
Procedure SetAddress; begin AMSt.Position:=Address; FCompleteFile.Position:=Address; end;
Procedure AddAddress(const ASize, AValue : Integer); begin FAddressList.Add(Pointer(Address)); FAddressSizeList.Add(Pointer(ASize)); FAddressLastValue.Add(Pointer(AValue)); end;
Var I1,I2 : Integer;
    W1,W2 : Word;
    B1,B2 : Byte;
begin
  For Address:=0 to Min(FCompleteFile.Size,AMSt.Size)-4 do begin
    SetAddress;
    FCompleteFile.ReadBuffer(I1,4); AMSt.ReadBuffer(I2,4);
    If ((AValueChangeType=vctUp) and (I2>I1)) or ((AValueChangeType=vctDown) and (I2<I1)) then AddAddress(4,I2);
  end;
  For Address:=0 to Min(FCompleteFile.Size,AMSt.Size)-2 do begin
    SetAddress;
    FCompleteFile.ReadBuffer(W1,2); AMSt.ReadBuffer(W2,2);
    If ((AValueChangeType=vctUp) and (W2>W1)) or ((AValueChangeType=vctDown) and (W2<W1)) then AddAddress(2,W2);
  end;
  For Address:=0 to Min(FCompleteFile.Size,AMSt.Size)-1 do begin
    SetAddress;
    FCompleteFile.ReadBuffer(B1,1); AMSt.ReadBuffer(B2,1);
    If ((AValueChangeType=vctUp) and (B2>B1)) or ((AValueChangeType=vctDown) and (B2<B1)) then AddAddress(1,B2);
  end;
end;

procedure TMemorySearchBase.SearchAddressIndirectAgainstAddressList(const AMSt: TMemoryStream; const AValueChangeType: TValueChangeType);
Var I,J,S,OldValue : Integer;
    W : Word;
    B : Byte;
begin
  I:=0;
  While I<FAddressList.Count do begin
    S:=Integer(FAddressSizeList[I]);
    OldValue:=Integer(FAddressLastValue[I]);
    If (NativeUInt(FAddressList[I])>=NativeUInt(AMSt.Size)) or (S>NativeUInt(AMSt.Size)) or (NativeUInt(FAddressList[I])>NativeUInt(AMSt.Size)-S) then begin
      FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I);
      continue;
    end;
    AMSt.Position:=NativeUInt(FAddressList[I]);
    If S=4 then begin
      AMSt.ReadBuffer(J,4);
      If ((AValueChangeType=vctUp) and (J>OldValue)) or ((AValueChangeType=vctDown) and (J<OldValue)) then begin FAddressLastValue[I]:=Pointer(J); inc(I); end else begin FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I); end;
      continue;
    end;
    If S=2 then begin
      AMSt.ReadBuffer(W,2);
      If ((AValueChangeType=vctUp) and (W>OldValue)) or ((AValueChangeType=vctDown) and (W<OldValue)) then begin J:=W; FAddressLastValue[I]:=Pointer(J); inc(I); end else begin FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I); end;
      continue;
    end;
    If S=1 then begin
      AMSt.ReadBuffer(B,1);
      If ((AValueChangeType=vctUp) and (B>OldValue)) or ((AValueChangeType=vctDown) and (B<OldValue)) then begin J:=B; FAddressLastValue[I]:=Pointer(J); inc(I); end else begin FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I); end;
      continue;
    end;
    FAddressList.Delete(I); FAddressSizeList.Delete(I); FAddressLastValue.Delete(I);
  end;
end;

function TMemorySearchBase.GetResult(var AAddress, ASize: Integer): TResultStatus;
Var I,MaxBytes,MaxNr : Integer;
begin
  If not Assigned(FAddressList) then begin result:=rsNoResultsYet; exit; end;
  If FAddressList.Count=0 then begin result:=rsNoAddress; exit; end;
  result:=rsMultipleAddresses;

  MaxNr:=0;
  MaxBytes:=Integer(FAddressSizeList[0]);
  For I:=1 to FAddressList.Count-1 do begin
    If NativeUInt(FAddressList[0])<>NativeUInt(FAddressList[I]) then exit;
    If NativeUInt(FAddressSizeList[I])>MaxBytes then begin
      MaxNr:=I;
      MaxBytes:=Integer(FAddressSizeList[I]);
    end;
  end;

  result:=rsFound;
  AAddress:=Integer(FAddressList[MaxNr]);
  ASize:=MaxBytes;
end;

{ ---------- ExtTryStrToInt ---------- }

function ExtTryStrToInt(const S: String; var I: Integer): Boolean;
var T: String;
    J: Integer;
    Temp: Cardinal;
    Minus: Boolean;
begin
  T := Trim(S);

  Minus := (T <> '') and (T[1] = '-');
  if Minus then T := Trim(Copy(T, 2, MaxInt));

  if (T <> '') and (T[1] = '$') then begin
    Result := False;
    T := UpperCase(Trim(Copy(T, 2, MaxInt)));
    Temp := 0;
    for J := 1 to Length(T) do begin
      Temp := Temp * 16;
      case T[J] of
        '0'..'9': Temp := Temp + Cardinal(Ord(T[J]) - Ord('0'));
        'A'..'F': Temp := Temp + Cardinal(Ord(T[J]) - Ord('A') + 10);
        else Exit;
      end;
      I := Integer(Temp);
      Result := True;
    end;
  end else begin
    Result := TryStrToInt(S, I);
    Minus := False;  { TryStrToInt already handled the sign }
  end;

  if Minus then I := -I;
end;

{ ---------- LoadAddresses ---------- }

function LoadAddresses(const S: String; var List: TIntegerArray): Boolean;
var T: String;
    L: TIntegerArray;
    I, J: Integer;

  function Add(const S: String): Boolean;
  var J, K: Integer;
  begin
    if Trim(S) = '' then begin Result := True; Exit; end;
    Result := ExtTryStrToInt(Trim(S), J);
    if not Result then Exit;
    K := Length(L);
    SetLength(L, K + 1);
    L[K] := J;
  end;

begin
  Result := False;
  T := Trim(S);
  SetLength(L, 0);
  I := Pos(';', T);
  J := Pos(';', T);
  if I * J > 0 then I := Min(I, J) else I := Max(I, J);
  while I <> 0 do begin
    if I = 1 then begin
      T := Trim(Copy(T, 2, MaxInt));
    end else begin
      if not Add(Copy(T, 1, I - 1)) then Exit;
      if I = Length(T) then T := '' else T := Trim(Copy(T, I + 1, MaxInt));
    end;
    I := Pos(';', T);
    J := Pos(';', T);
    if I * J > 0 then I := Min(I, J) else I := Max(I, J);
  end;
  if T <> '' then begin
    if not Add(T) then Exit;
  end;
  List := L;
  Result := True;
end;

{ ---------- FileMatchingMaskPart ---------- }

function FileMatchingMaskPart(const Mask, Name: String): Boolean;
var I, J, L, P: Integer;
begin
  Result := False;
  I := 1;
  J := 1;
  while I <= Length(Mask) do begin
    if Mask[I] = '*' then begin
      if I = Length(Mask) then begin Result := True; Exit; end else begin
        L := I + 1;
        while (L < Length(Mask)) and (Mask[L + 1] <> '*') do Inc(L);
        P := Pos(Copy(Mask, I + 1, L - I), Name);
        if P > 0 then J := P - 1 else Exit;
      end;
    end else begin
      if Mask[I] = '?' then begin
        if J > Length(Name) then Exit;
      end else begin
        if (Length(Name) < J) or (Mask[I] <> Name[J]) then Exit;
      end;
    end;
    Inc(I);
    Inc(J);
  end;
  Result := (J > Length(Name));
end;

{ ---------- FileMatchingMask ---------- }

function FileMatchingMask(const FileName, FileMask: String): Boolean;
var NameMask, Name, ExtMask, Ext: String;
    I: Integer;
begin
  I := Pos('.', FileMask);
  if I = 0 then begin
    NameMask := FileMask;
    ExtMask := '*';
  end else begin
    NameMask := Copy(FileMask, 1, I - 1);
    ExtMask := Copy(FileMask, I + 1, MaxInt);
  end;

  I := Pos('.', FileName);
  if I = 0 then begin
    Name := FileName;
    Ext := '';
  end else begin
    Name := Copy(FileName, 1, I - 1);
    Ext := Copy(FileName, I + 1, MaxInt);
  end;

  Result := FileMatchingMaskPart(ExtUpperCase(NameMask), ExtUpperCase(Name))
        and FileMatchingMaskPart(ExtUpperCase(ExtMask), ExtUpperCase(Ext));
end;

{ ---------- ExtSeek / Apply (from CheatDBToolsUnit / CheatDBUnit) ---------- }

Function ExtSeek(const St : TFileStream; const Address : Integer) : Boolean; overload;
begin
  result:=False;
  If Address>=0 then begin
    If St.Size<=Address then exit;
    St.Position:=Address;
  end else begin
    If St.Size-Abs(Address)<0 then exit;
    St.Position:=St.Size-Abs(Address);
  end;
  result:=True;
end;

Function ExtSeek(const St : TFileStream; const Address, BytesToWrite : Integer) : Boolean; overload;
begin
  result:=False;
  if not ExtSeek(St,Address) then exit;
  result:=(St.Position+BytesToWrite<=St.Size);
end;

Function Apply(const St: TFileStream; const FAddressesInt: TIntegerArray; const FBytes, FNewValueInt: Integer): Boolean; overload;
Var I : Integer;
begin
  result:=False;
  If FBytes<0 then exit;

  For I:=0 to length(FAddressesInt)-1 do begin
    If not ExtSeek(St,FAddressesInt[I],FBytes) then exit;
    St.WriteBuffer(FNewValueInt,FBytes); {lower order byte first so it's ok just to write the first FBytesInt Bytes}
  end;

  result:=True;
end;

{ ---------- CompressActionSteps ---------- }

procedure CompressActionSteps(ActionSteps: TList);
var I: Integer;
    Info0, Info1: IMergeableActionStep;
    S: string;
begin
  I := 0;
  while I < ActionSteps.Count - 1 do begin
    if not Supports(TObject(ActionSteps[I]), IMergeableActionStep, Info0) then begin Inc(I); Continue; end;
    while ActionSteps.Count > I + 1 do begin
      if not Supports(TObject(ActionSteps[I+1]), IMergeableActionStep, Info1) then Break;
      if (Info1.GetBytes <> Info0.GetBytes) or (Info1.GetNewValue <> Info0.GetNewValue) then Break;
      S := Info1.GetAddresses;
      if (S <> '') and ((S[1] = ';') or (S[1] = ',')) then S := Copy(S, 2, MaxInt);
      if (S <> '') and ((S[Length(S)] = ';') or (S[Length(S)] = ',')) then S := Copy(S, 1, Length(S) - 1);
      Info0.SetAddresses(Info0.GetAddresses + ';' + S);
      TObject(ActionSteps[I+1]).Free;
      ActionSteps.Delete(I+1);
    end;
    Inc(I);
  end;
end;

end.
