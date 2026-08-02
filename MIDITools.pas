unit MIDITools;
interface

uses Classes;

Function GetMIDIDevices : TStringList;
Function MakeDOSBoxMIDIString(const ProfileString : String) : String;
Procedure ProcessMIDIInfoLine(const Line : String; const List : TStringList);

implementation

uses SysUtils, Winapi.MMSystem, LanguageSetupUnit, CommonHelpers;

Procedure ProcessMIDIInfoLine(const Line : String; const List : TStringList);
Var I : Integer;
    S,T : String;
begin
  I:=Pos(' ',Line); If I=0 then exit;
  S:=Trim(Copy(Line,1,I-1)); T:=Trim(Copy(Line,I+1,MaxInt));
  If not TryStrToInt(S,I) then exit;
  If (T<>'') and (T[1]='"') and (T[length(T)]='"') then T:=Trim(Copy(T,2,length(T)-2));
  If T<>'' then List.AddObject(T+' ('+LanguageSetup.ProfileEditorSoundMIDIConfigID+'='+IntToStr(I)+')',TObject(I));
end;

Function MidiOutDeviceName(const Caps : TMidiOutCaps) : String;
{ Fixed WideChar product-name buffer from MIDIOUTCAPS. }
Var P : PWideChar;
begin
  P:=@Caps.szPname[0];
  result:=Trim(string(P));
end;

Function GetMIDIDevices : TStringList;
{ WinMM midiOut* enumeration — same device indices DOSBox midiconfig uses on Windows.
  Does not launch DOSBox. }
Var Caps : TMidiOutCaps;
    I, N : Integer;
    DeviceName : String;
begin
  result:=TStringList.Create;
  N:=Integer(midiOutGetNumDevs);
  For I:=0 to N-1 do begin
    FillChar(Caps,SizeOf(Caps),0);
    If midiOutGetDevCaps(UIntPtr(I),@Caps,SizeOf(Caps))<>MMSYSERR_NOERROR then continue;
    DeviceName:=MidiOutDeviceName(Caps);
    If DeviceName='' then continue;
    { Objects[i] = device id (index). Critical for conf + list picker. }
    result.AddObject(
      DeviceName+' ('+LanguageSetup.ProfileEditorSoundMIDIConfigID+'='+IntToStr(I)+')',
      TObject(I)
    );
  end;
end;

Function ExtractDeviceNameFromListEntry(const Display : String) : String;
Var Paren : Integer;
begin
  Paren:=LastDelimiter('(',Display);
  If Paren>0 then result:=Trim(Copy(Display,1,Paren-1)) else result:=Trim(Display);
end;

Function MakeDOSBoxMIDIString(const ProfileString : String) : String;
{ Profile midiconfig → numeric DOSBox midiconfig value only.
  - Already a number → pass through
  - Device name → resolve via WinMM to id
  - No match → empty (never write a raw name; that is not a valid stock DOSBox id) }
Var Wanted, DeviceName : String;
    I : Integer;
    St : TStringList;
begin
  result:='';
  Wanted:=Trim(ProfileString);
  If Wanted='' then exit;
  If TryStrToInt(Wanted,I) then begin result:=IntToStr(I); exit; end;

  St:=GetMIDIDevices;
  try
    For I:=0 to St.Count-1 do begin
      DeviceName:=ExtractDeviceNameFromListEntry(St[I]);
      If DeviceName='' then continue;
      If (ExtUpperCase(DeviceName)=ExtUpperCase(Wanted))
         or (Pos(ExtUpperCase(Wanted),ExtUpperCase(DeviceName))>0)
         or (Pos(ExtUpperCase(DeviceName),ExtUpperCase(Wanted))>0) then begin
        result:=IntToStr(Integer(St.Objects[I]));
        exit;
      end;
    end;
  finally
    St.Free;
  end;
  { Unresolved name: leave empty. Do not emit the string into midiconfig. }
end;

end.
