unit ScummVMGameOptions;
interface

uses SysUtils, Classes;

type
  TScummVMGameOptionKind = (sgokCheckbox, sgokInteger);

  TScummVMGameOption = record
    Caption : String;
    Kind : TScummVMGameOptionKind;
    IniKey : String;
    DefaultBool : Boolean;
    DefaultInt : Integer;
  end;

  TScummVMGameOptionArray = array of TScummVMGameOption;

function GetScummVMGameOptions(const GameId : String; const Variant : String = '') : TScummVMGameOptionArray;
procedure GetScummVMGameIdVariants(const GameId : String; const Dest : TStrings);
function GetScummVMCanonicalVariant(const GameId, Variant : String) : String;
function GetScummVMGameOptionsCoreThenVariant(const GameId : String; const Variant : String = '') : TScummVMGameOptionArray;
function ScummVMGameOptionKindToStr(const Kind : TScummVMGameOptionKind) : String;

implementation

type
  TScummVMGameOptionDef = record
    Caption : String;
    Kind : TScummVMGameOptionKind;
    IniKey : String;
    DefaultBool : Boolean;
    DefaultInt : Integer;
    GameIds : String; { |-separated: gameid or gameid[v1,v2,...] }
  end;

const
  ScummVMGameOptionTableCount = 272;
  ScummVMGameOptionTable : array[0..271] of TScummVMGameOptionDef = (
    (
      Caption: '16bpp';
      Kind: sgokCheckbox;
      IniKey: '16bpp';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'AbortsOn';
      Kind: sgokCheckbox;
      IniKey: 'AbortsOn';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'Correction';
      Kind: sgokInteger;
      IniKey: 'Correction';
      DefaultBool: False;
      DefaultInt: 2;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'FlyThroughs';
      Kind: sgokCheckbox;
      IniKey: 'FlyThroughs';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'MessageBoxOn';
      Kind: sgokCheckbox;
      IniKey: 'MessageBoxOn';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'MessageSpy';
      Kind: sgokCheckbox;
      IniKey: 'MessageSpy';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'PanSpeed';
      Kind: sgokInteger;
      IniKey: 'PanSpeed';
      DefaultBool: False;
      DefaultInt: 1;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'Panimations';
      Kind: sgokCheckbox;
      IniKey: 'Panimations';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'RandomOn';
      Kind: sgokCheckbox;
      IniKey: 'RandomOn';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'ShowIO';
      Kind: sgokCheckbox;
      IniKey: 'ShowIO';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hodjnpodj|spacebar'
    ),
    (
      Caption: 'Faithful AD&D rules';
      Kind: sgokCheckbox;
      IniKey: 'addrules';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'eob|eob2'
    ),
    (
      Caption: 'Improved font';
      Kind: sgokCheckbox;
      IniKey: 'alt_font';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'queen[cd]'
    ),
    (
      Caption: 'Alternative intro';
      Kind: sgokCheckbox;
      IniKey: 'alt_intro';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'queen[cd,gog.com]|sky'
    ),
    (
      Caption: 'Use an alternative palette';
      Kind: sgokCheckbox;
      IniKey: 'altamigapalette';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc[amiga]|ddp[amiga]|goldrush[amiga]|kq1[amiga]|kq2[amiga]|kq3[amiga]|lsl1[amiga]|mh1[amiga]|mh2[amiga]|mixedup[amiga]|pq1[amiga]|sq1[amiga]|sq2[amiga]|winnie[amiga]'
    ),
    (
      Caption: 'Alternate timing';
      Kind: sgokCheckbox;
      IniKey: 'alternate_timing';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'pelrock'
    ),
    (
      Caption: 'Alternative font';
      Kind: sgokCheckbox;
      IniKey: 'alternative_font';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'toon'
    ),
    (
      Caption: 'Ambient volume';
      Kind: sgokInteger;
      IniKey: 'ambient_volume';
      DefaultBool: False;
      DefaultInt: -750;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Amiga pal system';
      Kind: sgokCheckbox;
      IniKey: 'amiga_pal_system';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'activity|airport|arttime|atlantis|balloon|baseball|baseball2001|baseball2003|basketball|blues123time|bluesabctime|bluesbirthday|bluestreasurehunt|brstorm|catalog|chase|comi|dig|dog|farm|fbear|fbpack|football|football2002|freddi|freddi2|freddi3|freddi4|freddicove|freddisfunshop|ft|funpack|indy3|indyloom|indyzak|jungle|loom|lost|maniac|maze|monkey|monkey2|moonbase|mustard|pajama|pajama2|pajama3|pass|pjgames|puttcircus|puttmoon|puttputt|puttrace|puttsfunshop|putttime|puttzoo|readtime|rebel1|rebel2|samnmax|samsfunshop|soccer|soccer2004|soccermls|socks|spyfox|spyfox2|spyozon|tentacle|thinker1|thinkerk|water|zak|zakloom'
    ),
    (
      Caption: 'Animated game interface';
      Kind: sgokCheckbox;
      IniKey: 'animated_interface';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Animations speed';
      Kind: sgokInteger;
      IniKey: 'animations_speed';
      DefaultBool: False;
      DefaultInt: 1;
      GameIds: 'asylum'
    ),
    (
      Caption: 'AnnoyingInJokes';
      Kind: sgokCheckbox;
      IniKey: 'annoyingInJokes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp'
    ),
    (
      Caption: 'Use checkered cursor';
      Kind: sgokCheckbox;
      IniKey: 'apple2e_cursor';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hires0|hires1|hires2|hires3|hires4[green valley [a],green valley [b],on-line systems [a],on-line systems [b]]|hires5|hires6'
    ),
    (
      Caption: 'Add speed menu';
      Kind: sgokCheckbox;
      IniKey: 'apple2gs_speedmenu';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc[apple2gs]|goldrush[apple2gs]|kq1[apple2gs]|kq2[apple2gs]|kq3[apple2gs]|kq4[apple2gs]|lsl1[apple2gs]|mixedup[apple2gs]|pq1[apple2gs]|sq1[apple2gs]|sq2[apple2gs]'
    ),
    (
      Caption: 'Load modded audio';
      Kind: sgokCheckbox;
      IniKey: 'audio_override';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'activity|airport|arttime|balloon|baseball|baseball2001|blues123time|bluesabctime|bluesbirthday|bluestreasurehunt|brstorm|catalog|chase|dog|farm|fbear|fbpack|football|freddi|freddi2|freddi3|freddi4|freddicove|freddisfunshop|funpack|jungle|lost|maze|mustard|pajama|pajama2|pajama3|pjgames|puttcircus|puttmoon|puttputt|puttrace|puttsfunshop|putttime|puttzoo|readtime|samsfunshop|soccer|soccermls|socks|spyfox|spyfox2|spyozon|thinker1|thinkerk|water'
    ),
    (
      Caption: 'Authentic graphics';
      Kind: sgokCheckbox;
      IniKey: 'authentic_graphics';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|darkside|driller|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Auto Move';
      Kind: sgokCheckbox;
      IniKey: 'auto_move';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nancy10|nancy11|nancy6|nancy7|nancy8|nancy9'
    ),
    (
      Caption: 'Suggest save names';
      Kind: sgokCheckbox;
      IniKey: 'auto_savenames';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lol'
    ),
    (
      Caption: 'Automap (ScummVM feature)';
      Kind: sgokCheckbox;
      IniKey: 'automap';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'eob|eob2'
    ),
    (
      Caption: 'Automatic drilling';
      Kind: sgokCheckbox;
      IniKey: 'automatic_drilling';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'driller'
    ),
    (
      Caption: 'Backported music from C64 releases';
      Kind: sgokCheckbox;
      IniKey: 'ay_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster[amstradcpc]|totaleclipse2|totaleclipse[amstradcpc,demo,zx]'
    ),
    (
      Caption: 'Sprite bilinear filtering (SLOW)';
      Kind: sgokCheckbox;
      IniKey: 'bilinear_filtering';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bickadoodle|chivalry|deadcity|dirtysplit|driller[dos]|escapemansion|helga|ritter|rosemary|twc'
    ),
    (
      Caption: 'Use bright palette mode';
      Kind: sgokCheckbox;
      IniKey: 'bright_palette';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'dreamweb'
    ),
    (
      Caption: 'Camera moves with Silencer';
      Kind: sgokCheckbox;
      IniKey: 'camera_on_player';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'remorse'
    ),
    (
      Caption: 'Cdromdelay';
      Kind: sgokCheckbox;
      IniKey: 'cdromdelay';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|myst|newkid|noah|riven|ruff|seussabc|sheila|stellaluna|tortoise'
    ),
    (
      Caption: 'Character Speech';
      Kind: sgokCheckbox;
      IniKey: 'character_speech';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nancy1|nancy2|nancy3|nancy4|nancy5|vampirediaries'
    ),
    (
      Caption: 'Enable cheats';
      Kind: sgokCheckbox;
      IniKey: 'cheat';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'remorse|ultima8'
    ),
    (
      Caption: 'Check gamedata';
      Kind: sgokCheckbox;
      IniKey: 'check_gamedata';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'grim|monkey4'
    ),
    (
      Caption: 'Color graphics';
      Kind: sgokCheckbox;
      IniKey: 'color';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hires0|hires2|hires3|hires4|hires5|hires6'
    ),
    (
      Caption: 'Color graphics';
      Kind: sgokCheckbox;
      IniKey: 'color';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hires1'
    ),
    (
      Caption: 'Pause when entering commands';
      Kind: sgokCheckbox;
      IniKey: 'commandpromptwindow';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc|ddp|goldrush|kq1|kq2|kq3|kq4|lsl1|mh1|mh2|mickey|mixedup|pq1|sq1|sq2|troll|winnie'
    ),
    (
      Caption: 'Enable title and copy protection screens (if present)';
      Kind: sgokCheckbox;
      IniKey: 'copy_protection';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'anotherworld[amiga,demo,dos]|atlantis[amiga,floppy,mac floppy]|cloudsofxeen[dos]|darksideofxeen[dos]|dreamweb[cd,dos,installer]|goldrush|ite[aga floppy,cd,ecs floppy,floppy,floppy packed]|loom[ega]|lure|maniac[remastered,v1,v2]|monkey2[amiga,dos,mac,se]|monkey[mac,vga]|nebular[dos,fanmade,floppy,mac]|simon1[aga floppy,floppy,infocom floppy,ocs floppy]|simon2[floppy]|swordsofxeen|tot[dos]|voyeur|waxworks[floppy]|worldofxeen[cd,dos,monster spawn mod v1.0]|zak[v1,v2]'
    ),
    (
      Caption: 'Correct movie aspect ratio';
      Kind: sgokCheckbox;
      IniKey: 'correct_movie_aspect';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'syberia2|syberia[android,extracted,ios,mac,nintendoswitch,ps3]'
    ),
    (
      Caption: 'Fix credits for voice actors';
      Kind: sgokCheckbox;
      IniKey: 'correct_spanish_credits';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[windows]'
    ),
    (
      Caption: 'Remove Black Bars';
      Kind: sgokCheckbox;
      IniKey: 'crop_black_bars';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'dw2'
    ),
    (
      Caption: 'Enable debug mode';
      Kind: sgokCheckbox;
      IniKey: 'debug';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lba'
    ),
    (
      Caption: 'Difficulty';
      Kind: sgokInteger;
      IniKey: 'difficulty';
      DefaultBool: False;
      DefaultInt: -1;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Enable low latency audio mode';
      Kind: sgokCheckbox;
      IniKey: 'dimuse_low_latency_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'comi|dig|ft'
    ),
    (
      Caption: 'Disable demo mode';
      Kind: sgokCheckbox;
      IniKey: 'disable_demo_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|darkside|driller|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Skip EGA dithering pass (full color backgrounds)';
      Kind: sgokCheckbox;
      IniKey: 'disable_dithering';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|fairytales[ega]|hoyle1[demo,dos,mac]|hoyle2|hoyle3[ega]|iceman|kq1sci|kq4sci|laurabow|lsl2|lsl3[demo,dos]|mothergoose[ega]|pq2|qfg1|qfg2|sq3'
    ),
    (
      Caption: 'Disable fade-out effects';
      Kind: sgokCheckbox;
      IniKey: 'disable_fade_effects';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'simon1|simon2'
    ),
    (
      Caption: 'Disable falling';
      Kind: sgokCheckbox;
      IniKey: 'disable_falling';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|darkside|driller|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Disable Playback';
      Kind: sgokCheckbox;
      IniKey: 'disable_mi2_ni_demo';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'monkey2[demo]'
    ),
    (
      Caption: 'Disable screensaver';
      Kind: sgokCheckbox;
      IniKey: 'disable_screensaver';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'pelrock'
    ),
    (
      Caption: 'Disable sensors';
      Kind: sgokCheckbox;
      IniKey: 'disable_sensors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|darkside|driller|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Disable shadows';
      Kind: sgokCheckbox;
      IniKey: 'disable_shadows';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'syberia|syberia2'
    ),
    (
      Caption: 'Disable McCoy''s quick stamina drain';
      Kind: sgokCheckbox;
      IniKey: 'disable_stamina_drain';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[windows]'
    ),
    (
      Caption: 'Use DOS version music tempos';
      Kind: sgokCheckbox;
      IniKey: 'dos_music_tempos';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'simon1[25th anniversary edition,cd,cd demo,floppy,infocom cd,infocom floppy]'
    ),
    (
      Caption: 'Double FPS';
      Kind: sgokCheckbox;
      IniKey: 'doublefps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'zgi|znemesis'
    ),
    (
      Caption: 'Load modded assets';
      Kind: sgokCheckbox;
      IniKey: 'enable_assets_mod';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'tlj'
    ),
    (
      Caption: 'Color Blind Mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_color_blind';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sfinx|soltys'
    ),
    (
      Caption: 'Enable demo/kiosk mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_demo_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'maniac[remastered,v1,v2]'
    ),
    (
      Caption: 'Enable font anti-aliasing';
      Kind: sgokCheckbox;
      IniKey: 'enable_font_antialiasing';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'tlj'
    ),
    (
      Caption: 'Gore Mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_gore';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hopkins'
    ),
    (
      Caption: 'Gore Mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_gore';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hopkins[demo,windows]'
    ),
    (
      Caption: 'Enable high resolution graphics';
      Kind: sgokCheckbox;
      IniKey: 'enable_high_resolution_graphics';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'castlebrain[mac]|freddypharkas[mac]|kq6[cd,dos,mac]|lsl1sci[sci]|lsl5[mac]|lsl6[mac]|qfg1vga[vga]|sq1sci[sci]'
    ),
    (
      Caption: 'Use high-quality video scaling';
      Kind: sgokCheckbox;
      IniKey: 'enable_hq_video';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'gk1[cd]'
    ),
    (
      Caption: 'Enable music';
      Kind: sgokCheckbox;
      IniKey: 'enable_music';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Enable sega shadow mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_sega_shadow_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'activity|airport|arttime|atlantis|balloon|baseball|baseball2001|baseball2003|basketball|blues123time|bluesabctime|bluesbirthday|bluestreasurehunt|brstorm|catalog|chase|comi|dig|dog|farm|fbear|fbpack|football|football2002|freddi|freddi2|freddi3|freddi4|freddicove|freddisfunshop|ft|funpack|indy3|indyloom|indyzak|jungle|loom|lost|maniac|maze|monkey|monkey2|moonbase|mustard|pajama|pajama2|pajama3|pass|pjgames|puttcircus|puttmoon|puttputt|puttrace|puttsfunshop|putttime|puttzoo|readtime|rebel1|rebel2|samnmax|samsfunshop|soccer|soccer2004|soccermls|socks|spyfox|spyfox2|spyozon|tentacle|thinker1|thinkerk|water|zak|zakloom'
    ),
    (
      Caption: 'Enable the "A Pirate I Was Meant To Be" song';
      Kind: sgokCheckbox;
      IniKey: 'enable_song';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'comi'
    ),
    (
      Caption: 'Enable sound';
      Kind: sgokCheckbox;
      IniKey: 'enable_sound';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Endgame';
      Kind: sgokCheckbox;
      IniKey: 'endgame';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'Use English speech';
      Kind: sgokCheckbox;
      IniKey: 'english_speech';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sword25'
    ),
    (
      Caption: 'enhancements';
      Kind: sgokCheckbox;
      IniKey: 'enhancements';
      DefaultBool: True;
      DefaultInt: 7;
      GameIds: 'atlantis[amiga,dos,floppy,fm-towns,mac,mac floppy,steam]|comi|dig[dos,steam]|freddi3[dos]|freddi4|ft[dos,remastered]|indy3|loom[ega,fm-towns,mac,no adlib,pc-engine,steam,vga]|maniac[apple ii,nes,remastered,v1,v2]|monkey2[amiga,demo,dos,fm-towns,mac,se]|monkey[cd,ega,fm-towns,mac,no adlib,se,sega,vga]|samnmax|tentacle|zak[fm-towns]'
    ),
    (
      Caption: 'Extended timer';
      Kind: sgokCheckbox;
      IniKey: 'extended_timer';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|darkside|driller|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Extended game resolution';
      Kind: sgokCheckbox;
      IniKey: 'extended_viewport';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'carnival'
    ),
    (
      Caption: 'Pixellated scene transitions';
      Kind: sgokCheckbox;
      IniKey: 'fade_style';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'scalpel[3do,dos]'
    ),
    (
      Caption: 'FadedModal';
      Kind: sgokCheckbox;
      IniKey: 'fadedModal';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'Extend endgame timer';
      Kind: sgokCheckbox;
      IniKey: 'final_timer';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nancy2'
    ),
    (
      Caption: 'Fix audio pops';
      Kind: sgokCheckbox;
      IniKey: 'fix_audio_pops';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|myst|newkid|noah|riven|ruff|seussabc|sheila|stellaluna|tortoise'
    ),
    (
      Caption: 'Floating cursors';
      Kind: sgokCheckbox;
      IniKey: 'floating_cursors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lol'
    ),
    (
      Caption: 'Enable font anti-aliasing';
      Kind: sgokCheckbox;
      IniKey: 'font_antialiasing';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima8'
    ),
    (
      Caption: 'Font highres';
      Kind: sgokCheckbox;
      IniKey: 'font_highres';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'Enable font replacement';
      Kind: sgokCheckbox;
      IniKey: 'font_override';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima8'
    ),
    (
      Caption: 'Play foot step sounds';
      Kind: sgokCheckbox;
      IniKey: 'footsteps';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'ultima8'
    ),
    (
      Caption: 'Force to use 2D renderer (2D games only)';
      Kind: sgokCheckbox;
      IniKey: 'force_2d_renderer';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bickadoodle|chivalry|deadcity|dirtysplit|driller[dos]|escapemansion|helga|ritter|rosemary|twc'
    ),
    (
      Caption: 'Run in original 640 x 480 resolution';
      Kind: sgokCheckbox;
      IniKey: 'force_fmtowns_hires_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'atlantis[fm-towns]|indy3[fm-towns]|indyloom|indyzak|loom[fm-towns]|monkey2[fm-towns]|monkey[fm-towns]|zak[fm-towns]|zakloom'
    ),
    (
      Caption: 'Enable frame limiting';
      Kind: sgokCheckbox;
      IniKey: 'frameLimit';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'remorse|ultima8'
    ),
    (
      Caption: 'Enable frame skipping';
      Kind: sgokCheckbox;
      IniKey: 'frameSkip';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'remorse|ultima8'
    ),
    (
      Caption: 'Max frames per second limit';
      Kind: sgokCheckbox;
      IniKey: 'frames_per_secondfl';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner'
    ),
    (
      Caption: 'Fuzzy logic';
      Kind: sgokCheckbox;
      IniKey: 'fuzzy_logic';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|myst|newkid|noah|riven|ruff|seussabc|sheila|stellaluna|tortoise'
    ),
    (
      Caption: 'Game devel mode';
      Kind: sgokCheckbox;
      IniKey: 'game_devel_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'grim|monkey4'
    ),
    (
      Caption: 'Game speed';
      Kind: sgokInteger;
      IniKey: 'game_speed';
      DefaultBool: False;
      DefaultInt: 1;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Enable gamma correction';
      Kind: sgokCheckbox;
      IniKey: 'gamma_correction';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'atlantis[mac]|indy3[mac]|loom[mac]|monkey2[mac]|monkey[mac]'
    ),
    (
      Caption: 'Gamma level';
      Kind: sgokInteger;
      IniKey: 'gamma_level';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Gfx details';
      Kind: sgokInteger;
      IniKey: 'gfx_details';
      DefaultBool: False;
      DefaultInt: 2;
      GameIds: 'sword2'
    ),
    (
      Caption: 'Enable saving via the GMM';
      Kind: sgokCheckbox;
      IniKey: 'gmm_save_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|castlebrain|ecoquest|ecoquest2[demo,floppy]|fairytales|freddypharkas|hoyle1|hoyle2|hoyle3|hoyle4|iceman|islandbrain|kq1sci|kq4sci|kq5|kq6[demo,dos,mac]|laurabow|laurabow2|longbow|lsl1sci|lsl2|lsl3|lsl5|lsl6|mothergoose|mothergoose256[cd,demo,dos]|pepper[demo,dos]|pq1sci|pq2[amiga,atarist,demo,dos]|pq3|qfg1[amiga,atarist,demo,dos]|qfg1vga|qfg2|qfg3|slater[demo,dos]|sq1sci[demo,sci]|sq3|sq4[amiga,dos,ega,mac,pc98]|sq5'
    ),
    (
      Caption: 'Helium mode';
      Kind: sgokCheckbox;
      IniKey: 'helium_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra3'
    ),
    (
      Caption: 'Don''t show hotspots when moving mouse';
      Kind: sgokCheckbox;
      IniKey: 'help_style';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rosetattoo|scalpel[3do,dos]'
    ),
    (
      Caption: 'Use Hercules hires font';
      Kind: sgokCheckbox;
      IniKey: 'herculesfont';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc|ddp|goldrush|kq1|kq2|kq3|kq4|lsl1|mh1|mh2|mickey|mixedup|pq1|sq1|sq2|troll|winnie'
    ),
    (
      Caption: 'High Quality';
      Kind: sgokCheckbox;
      IniKey: 'high_quality';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'aventuradecine[dos]'
    ),
    (
      Caption: 'Enable high quality panoramas';
      Kind: sgokCheckbox;
      IniKey: 'highquality';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'zgi|znemesis'
    ),
    (
      Caption: 'HP bar graphs';
      Kind: sgokCheckbox;
      IniKey: 'hpbargraphs';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'eob2|eob[amiga,dos,pc98]'
    ),
    (
      Caption: 'HudSentence';
      Kind: sgokCheckbox;
      IniKey: 'hudSentence';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp'
    ),
    (
      Caption: 'Enable cheat mode';
      Kind: sgokCheckbox;
      IniKey: 'hypercheat';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hdb'
    ),
    (
      Caption: 'Ignore font settings';
      Kind: sgokCheckbox;
      IniKey: 'ignore_font_settings';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'tlj'
    ),
    (
      Caption: 'Ignore savegame mismatch';
      Kind: sgokCheckbox;
      IniKey: 'ignore_savegame_mismatch';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'ImportOrigSaves';
      Kind: sgokCheckbox;
      IniKey: 'importOrigSaves';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'eob|eob2'
    ),
    (
      Caption: 'Improved mode';
      Kind: sgokCheckbox;
      IniKey: 'improved';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'msn1|msn2'
    ),
    (
      Caption: 'Easy mouse interface';
      Kind: sgokCheckbox;
      IniKey: 'interface_hotspots';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'IntroSeen';
      Kind: sgokCheckbox;
      IniKey: 'introSeen';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'tot'
    ),
    (
      Caption: 'Play a digital soundtrack during the opening movie';
      Kind: sgokCheckbox;
      IniKey: 'intro_music_digital';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'rtz[cd,demo cd]'
    ),
    (
      Caption: 'Animated inventory items';
      Kind: sgokCheckbox;
      IniKey: 'inventory_mode';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'InvertVerbHighlight';
      Kind: sgokCheckbox;
      IniKey: 'invertVerbHighlight';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'twp'
    ),
    (
      Caption: 'Invert Y-axis on mouse';
      Kind: sgokCheckbox;
      IniKey: 'invert_y';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|darkside|driller|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Logic period';
      Kind: sgokInteger;
      IniKey: 'logic_period';
      DefaultBool: False;
      DefaultInt: 25;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Logic synchro by clock';
      Kind: sgokCheckbox;
      IniKey: 'logic_synchro_by_clock';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Mac graphics smoothing';
      Kind: sgokCheckbox;
      IniKey: 'mac_graphics_smoothing';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'activity|airport|arttime|atlantis|balloon|baseball|baseball2001|baseball2003|basketball|blues123time|bluesabctime|bluesbirthday|bluestreasurehunt|brstorm|catalog|chase|comi|dig|dog|farm|fbear|fbpack|football|football2002|freddi|freddi2|freddi3|freddi4|freddicove|freddisfunshop|ft|funpack|indy3|indyloom|indyzak|jungle|loom|lost|maniac|maze|monkey|monkey2|moonbase|mustard|pajama|pajama2|pajama3|pass|pjgames|puttcircus|puttmoon|puttputt|puttrace|puttsfunshop|putttime|puttzoo|readtime|rebel1|rebel2|samnmax|samsfunshop|soccer|soccer2004|soccermls|socks|spyfox|spyfox2|spyozon|tentacle|thinker1|thinkerk|water|zak|zakloom'
    ),
    (
      Caption: 'Mac nebular preferences at startup';
      Kind: sgokCheckbox;
      IniKey: 'mac_nebular_preferences_at_startup';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Mac nebular story locked';
      Kind: sgokCheckbox;
      IniKey: 'mac_nebular_story_locked';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Play simplified music';
      Kind: sgokCheckbox;
      IniKey: 'mac_v3_low_quality_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'indy3[mac]'
    ),
    (
      Caption: 'Use NES Classic Palette';
      Kind: sgokCheckbox;
      IniKey: 'mm_nes_classic_palette';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'maniac[nes]'
    ),
    (
      Caption: 'Always use sharp monochrome text';
      Kind: sgokCheckbox;
      IniKey: 'monotext';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hires0|hires1|hires2|hires3|hires4[green valley [a],green valley [b],on-line systems [a],on-line systems [b]]|hires5|hires6'
    ),
    (
      Caption: 'Monster difficulty';
      Kind: sgokInteger;
      IniKey: 'monster_difficulty';
      DefaultBool: False;
      DefaultInt: 1;
      GameIds: 'lol'
    ),
    (
      Caption: 'Enable mouse';
      Kind: sgokCheckbox;
      IniKey: 'mouse';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'lba'
    ),
    (
      Caption: 'Mouse inverted';
      Kind: sgokCheckbox;
      IniKey: 'mouse_inverted';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'myst3'
    ),
    (
      Caption: 'Mouse speed';
      Kind: sgokInteger;
      IniKey: 'mouse_speed';
      DefaultBool: False;
      DefaultInt: 50;
      GameIds: 'myst3'
    ),
    (
      Caption: 'Fight Button L/R Swap';
      Kind: sgokCheckbox;
      IniKey: 'mousebtswap';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'eob|eob2'
    ),
    (
      Caption: 'Mouse support';
      Kind: sgokCheckbox;
      IniKey: 'mousesupport';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'bc[apple2gs,coco3,dos,updated]|ddp[atarist,dos]|goldrush[apple2gs,atarist,coco3,dos,mac,updated]|kq1[apple2gs,atarist,coco3,dos,fixed,mac,se,updated]|kq2[apple2gs,coco3,dos,fixed,mac,updated]|kq3[apple2gs,atarist,coco3,dos,mac]|kq4|lsl1[apple2gs,atarist,coco3,demo,dos,mac]|mh1[apple2gs,atarist,coco3,dos,mac,updated]|mh2[atarist,coco3,dos,mac,updated]|mickey|mixedup[apple2gs,coco3,dos,mac]|pq1[apple2gs,coco3,dos,mac,updated]|sq1[apple2gs,atarist,coco3,dos,fixed,mac,updated]|sq2[apple2gs,coco3,dos,mac,updated]|troll|winnie[apple2,c64,dos]'
    ),
    (
      Caption: 'Enable movies';
      Kind: sgokCheckbox;
      IniKey: 'movie';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'lba'
    ),
    (
      Caption: 'Movie volume';
      Kind: sgokInteger;
      IniKey: 'movie_volume';
      DefaultBool: False;
      DefaultInt: -500;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Use high resolution MPEG video';
      Kind: sgokCheckbox;
      IniKey: 'mpegmovies';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'zgi[dvd]'
    ),
    (
      Caption: 'Enhanced thrown weapon reload';
      Kind: sgokCheckbox;
      IniKey: 'mreload';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'eob|eob2'
    ),
    (
      Caption: 'Start with debugger';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_debug_at_start';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mti|obsidian'
    ),
    (
      Caption: 'Autosave at progress points';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_auto_save_at_checkpoints';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'obsidian[cd]'
    ),
    (
      Caption: 'Improved music mixing';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_dynamic_midi';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'mti|obsidian'
    ),
    (
      Caption: 'Enable short transitions';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_minimum_transition_duration';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'mti|obsidian'
    ),
    (
      Caption: '16:9 widescreen mod';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_obsidian_widescreen';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'obsidian'
    ),
    (
      Caption: 'Enable subtitles for important sound effects';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_sound_gameplay_subtitles';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'obsidian[cd]'
    ),
    (
      Caption: 'Music frequency';
      Kind: sgokInteger;
      IniKey: 'music_frequency';
      DefaultBool: False;
      DefaultInt: 75;
      GameIds: 'myst3'
    ),
    (
      Caption: 'Music mute';
      Kind: sgokCheckbox;
      IniKey: 'music_mute';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular|toon'
    ),
    (
      Caption: 'Music status';
      Kind: sgokCheckbox;
      IniKey: 'music_status';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Music volume';
      Kind: sgokInteger;
      IniKey: 'music_volume';
      DefaultBool: False;
      DefaultInt: -1500;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Music volume';
      Kind: sgokInteger;
      IniKey: 'music_volume';
      DefaultBool: False;
      DefaultInt: 192;
      GameIds: 'bladerunner|hadesch|sky|toon'
    ),
    (
      Caption: 'Music volume';
      Kind: sgokInteger;
      IniKey: 'music_volume';
      DefaultBool: False;
      DefaultInt: 255;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Mute';
      Kind: sgokCheckbox;
      IniKey: 'mute';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner|hadesch|sky|toon'
    ),
    (
      Caption: 'Nancy max saves';
      Kind: sgokInteger;
      IniKey: 'nancy_max_saves';
      DefaultBool: False;
      DefaultInt: 999;
      GameIds: 'nancy1|nancy10|nancy11|nancy2|nancy3|nancy4|nancy5|nancy6|nancy7|nancy8|nancy9|vampirediaries'
    ),
    (
      Caption: 'Naughty game mode';
      Kind: sgokCheckbox;
      IniKey: 'naughtiness';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Disable animation while turning';
      Kind: sgokCheckbox;
      IniKey: 'noanimwhileturning';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'zgi|znemesis'
    ),
    (
      Caption: 'Frame limiter high performance mode';
      Kind: sgokCheckbox;
      IniKey: 'nodelaymillisfl';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner'
    ),
    (
      Caption: 'Fix Ileria and Beohram NPCs';
      Kind: sgokCheckbox;
      IniKey: 'npcpatch';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'eob'
    ),
    (
      Caption: 'TV emulation';
      Kind: sgokCheckbox;
      IniKey: 'ntsc';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'hires0|hires1|hires2|hires3|hires4[green valley [a],green valley [b],on-line systems [a],on-line systems [b]]|hires5|hires6'
    ),
    (
      Caption: 'Show Object Line';
      Kind: sgokCheckbox;
      IniKey: 'object_labels';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'comi'
    ),
    (
      Caption: 'Show object labels';
      Kind: sgokCheckbox;
      IniKey: 'object_labels';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sword2'
    ),
    (
      Caption: 'Omni3d speed';
      Kind: sgokInteger;
      IniKey: 'omni3d_speed';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'atlantis|versailles'
    ),
    (
      Caption: 'AdLib OPL3 mode';
      Kind: sgokCheckbox;
      IniKey: 'opl3_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'elvira1[floppy,non-interactive demo]|elvira2|simon1[25th anniversary edition,cd,cd demo,floppy,floppy demo,infocom cd,infocom floppy]|tot|waxworks'
    ),
    (
      Caption: 'Backported music from C64 releases (AdLib)';
      Kind: sgokCheckbox;
      IniKey: 'opl_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster[demo,dos,virtual worlds]|darkside[dos]|driller[dos]|totaleclipse[dos]'
    ),
    (
      Caption: 'Enable the original GUI and Menu';
      Kind: sgokCheckbox;
      IniKey: 'original_gui';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'activity|atlantis[amiga,dos,floppy,fm-towns,mac,mac floppy,steam]|brstorm|comi|dig|fbear[he 62]|fbpack|ft|funpack|indy3|indyloom|indyzak|loom[demo,ega,fm-towns,mac,no adlib,steam,vga]|maniac|monkey|monkey2[amiga,dos,fm-towns,mac,se,se talkie]|pass|puttmoon[demo,dos]|puttputt|samnmax|tentacle|zak|zakloom'
    ),
    (
      Caption: 'Use original Macintosh menus (experimental)';
      Kind: sgokCheckbox;
      IniKey: 'original_mac_menus';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular[mac]'
    ),
    (
      Caption: 'Use original save/load screens';
      Kind: sgokCheckbox;
      IniKey: 'original_menus';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'burger|chewy|hodjnpodj|nebular[demo,dos,fanmade,floppy]|pelrock|riddle|spacebar'
    ),
    (
      Caption: 'Use original save/load screens';
      Kind: sgokCheckbox;
      IniKey: 'originalsaveload';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|bc|camelot|castlebrain[amiga,demo,dos,ega,pc98]|ddp|drascula|dreamweb|ecoquest|ecoquest2[demo,floppy]|fairytales|freddypharkas[cd,cd demo,demo,dos,floppy]|fw|gk1[cd]|goldrush|hoyle1[amiga,atarist,demo,dos]|hoyle2[amiga,atarist,dos]|hoyle3|hoyle4[demo,dos]|iceman|islandbrain|kq1|kq1sci|kq2|kq3|kq4|kq4sci|kq5[amiga,cd,dos,ega,fm-towns,pc98]|kq6[cd,demo,dos]|laurabow|laurabow2|longbow|lsl1|lsl1sci|lsl2|lsl3|lsl5[amiga,demo,dos,ega]|lsl6[cd,dos]|mh1|mh2|mickey|mixedup|mothergoose|mothergoose256|nl|os|pepper[demo,dos]|pq1|pq1sci|pq2|pq3|qfg1|qfg1vga|qfg2|qfg3|rosetattoo|scalpel[dos]|slater[demo,dos]|sq1|sq1sci[demo,sci]|sq2|sq3[amiga,atarist,demo,dos]|sq4[amiga,dos,ega,pc98]|sq5|toltecs|tot|troll|ultima8|winnie|zgi|znemesis'
    ),
    (
      Caption: 'Use original save/load screens';
      Kind: sgokCheckbox;
      IniKey: 'originalsaveload';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nancy1|nancy10|nancy11|nancy2|nancy3|nancy4|nancy5|nancy6|nancy7|nancy8|nancy9|vampirediaries'
    ),
    (
      Caption: 'Use per-resource modified palettes';
      Kind: sgokCheckbox;
      IniKey: 'palette_mods';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lsl2|sq3'
    ),
    (
      Caption: 'Performance';
      Kind: sgokInteger;
      IniKey: 'performance';
      DefaultBool: False;
      DefaultInt: 4;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Play intro';
      Kind: sgokCheckbox;
      IniKey: 'play_intro';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'pelrock'
    ),
    (
      Caption: 'Player Speech';
      Kind: sgokCheckbox;
      IniKey: 'player_speech';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nancy1|nancy2|nancy3|nancy4|nancy5|vampirediaries'
    ),
    (
      Caption: 'Playmystflyby';
      Kind: sgokCheckbox;
      IniKey: 'playmystflyby';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|myst|newkid|noah|riven|ruff|seussabc|sheila|stellaluna|tortoise'
    ),
    (
      Caption: 'Show character portraits';
      Kind: sgokCheckbox;
      IniKey: 'portraits_on';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'scalpel[3do,dos]'
    ),
    (
      Caption: 'Predictive Input Dialog on mouse click';
      Kind: sgokCheckbox;
      IniKey: 'predictivedlgonmouseclick';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc|ddp|goldrush|kq1|kq2|kq3|kq4|lsl1|mh1|mh2|mickey|mixedup|pq1|sq1|sq2|troll|winnie'
    ),
    (
      Caption: 'Prefer digital sound effects';
      Kind: sgokCheckbox;
      IniKey: 'prefer_digitalsfx';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|castlebrain|ecoquest|ecoquest2[demo,floppy]|elvira2|fairytales|freddypharkas|hoyle1|hoyle2|hoyle3|hoyle4|iceman|islandbrain|kq1sci|kq4sci|kq5|kq6[cd,demo,dos,mac]|laurabow|laurabow2|longbow|lsl1sci|lsl2|lsl3|lsl5|lsl6|mothergoose|mothergoose256|pepper[demo,dos]|pq1sci|pq2|pq3|qfg1|qfg1vga|qfg2|qfg3|slater[demo,dos]|sq1sci[demo,sci]|sq3|sq4[amiga,dos,ega,mac,pc98]|sq5|waxworks'
    ),
    (
      Caption: 'Quotes';
      Kind: sgokCheckbox;
      IniKey: 'quotes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'RansomeUnbeeped';
      Kind: sgokCheckbox;
      IniKey: 'ransomeUnbeeped';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp'
    ),
    (
      Caption: 'No damage';
      Kind: sgokCheckbox;
      IniKey: 'rebel1_no_damage';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rebel1'
    ),
    (
      Caption: 'Unlock all levels';
      Kind: sgokCheckbox;
      IniKey: 'rebel1_unlock_all';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rebel1'
    ),
    (
      Caption: 'High resolution mode';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_hires';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'rebel2[demo,dos]'
    ),
    (
      Caption: 'No damage';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_no_damage';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rebel2'
    ),
    (
      Caption: 'Unlock all levels';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_unlock_all';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rebel2'
    ),
    (
      Caption: 'Yoda mode';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_yoda_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rebel2'
    ),
    (
      Caption: 'Replacement png premultiply alpha';
      Kind: sgokCheckbox;
      IniKey: 'replacement_png_premultiply_alpha';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'tlj'
    ),
    (
      Caption: 'Restore missing scenes';
      Kind: sgokCheckbox;
      IniKey: 'restore_scenes';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'syberia[ios,mac]'
    ),
    (
      Caption: 'RetroFonts';
      Kind: sgokCheckbox;
      IniKey: 'retroFonts';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp'
    ),
    (
      Caption: 'RetroVerbs';
      Kind: sgokCheckbox;
      IniKey: 'retroVerbs';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp'
    ),
    (
      Caption: 'Reverse stereo';
      Kind: sgokCheckbox;
      IniKey: 'reverse_stereo';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'asylum|sword2'
    ),
    (
      Caption: 'Use RGB rendering';
      Kind: sgokCheckbox;
      IniKey: 'rgb_rendering';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|castlebrain|ecoquest|ecoquest2[demo,floppy]|fairytales|freddypharkas|hoyle1|hoyle2|hoyle3|hoyle4|iceman|islandbrain|kq1sci|kq4sci|kq5|kq6[cd,demo,dos,mac]|kquestions|laurabow|laurabow2|longbow|lsl1sci|lsl2|lsl3|lsl5|lsl6|mothergoose|mothergoose256|pepper[demo,dos]|pq1sci|pq2|pq3|qfg1|qfg1vga|qfg2|qfg3|slater[demo,dos]|sq1sci[demo,sci]|sq3|sq4[amiga,dos,ega,mac,pc98]|sq5'
    ),
    (
      Caption: 'Enable rock travel';
      Kind: sgokCheckbox;
      IniKey: 'rock_travel';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster'
    ),
    (
      Caption: 'Run threshold';
      Kind: sgokInteger;
      IniKey: 'run_threshold';
      DefaultBool: False;
      DefaultInt: 160;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'Show scanlines';
      Kind: sgokCheckbox;
      IniKey: 'scanlines';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hires0|hires1|hires2|hires3|hires4|hires5|hires6'
    ),
    (
      Caption: 'Allow semi-smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'semi_smooth_scroll';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'loom[fm-towns]'
    ),
    (
      Caption: 'Sfx mute';
      Kind: sgokCheckbox;
      IniKey: 'sfx_mute';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular|toon'
    ),
    (
      Caption: 'Sfx volume';
      Kind: sgokInteger;
      IniKey: 'sfx_volume';
      DefaultBool: False;
      DefaultInt: -1000;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Sfx volume';
      Kind: sgokInteger;
      IniKey: 'sfx_volume';
      DefaultBool: False;
      DefaultInt: 192;
      GameIds: 'bladerunner|hadesch|sky|toon'
    ),
    (
      Caption: 'Shorty mode';
      Kind: sgokCheckbox;
      IniKey: 'shorty';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[windows]'
    ),
    (
      Caption: 'Show encounter subtitles';
      Kind: sgokCheckbox;
      IniKey: 'show_encounter_subtitles';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Show FPS-counter';
      Kind: sgokCheckbox;
      IniKey: 'show_fps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bickadoodle|chivalry|deadcity|dirtysplit|driller[dos]|escapemansion|helga|ritter|rosemary|twc'
    ),
    (
      Caption: 'Show intro';
      Kind: sgokCheckbox;
      IniKey: 'show_intro';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Show scene loading';
      Kind: sgokCheckbox;
      IniKey: 'show_scene_loading';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Show speech boxes';
      Kind: sgokCheckbox;
      IniKey: 'show_speech_boxes';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Use silver cursors';
      Kind: sgokCheckbox;
      IniKey: 'silver_cursors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sq4[cd,dos]'
    ),
    (
      Caption: 'Use lower quality single speed CD-ROM video';
      Kind: sgokCheckbox;
      IniKey: 'single_speed_videos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cpatrol[dos]|dwars[dos]|johnroc|lbhunter[demo]|maddog2|spirates[dos]'
    ),
    (
      Caption: 'Sitcom mode';
      Kind: sgokCheckbox;
      IniKey: 'sitcom';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[windows]'
    ),
    (
      Caption: 'Skip confirm';
      Kind: sgokCheckbox;
      IniKey: 'skip_confirm';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'syberia|syberia2'
    ),
    (
      Caption: 'Skip mainmenu';
      Kind: sgokCheckbox;
      IniKey: 'skip_mainmenu';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'syberia|syberia2'
    ),
    (
      Caption: 'Skip splash';
      Kind: sgokCheckbox;
      IniKey: 'skip_splash';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'syberia|syberia2'
    ),
    (
      Caption: 'Skip support';
      Kind: sgokCheckbox;
      IniKey: 'skip_support';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'buried|kyra3'
    ),
    (
      Caption: 'Skip videos';
      Kind: sgokCheckbox;
      IniKey: 'skip_videos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'syberia|syberia2'
    ),
    (
      Caption: 'Smoother movement';
      Kind: sgokCheckbox;
      IniKey: 'smooth_movement';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'totaleclipse2|totaleclipse[amstradcpc,atarist,demo,dos,zx]'
    ),
    (
      Caption: 'Enable smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'smooth_scroll';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'atlantis[fm-towns]|indy3[fm-towns]|indyloom|indyzak|loom[fm-towns]|monkey2[fm-towns]|monkey[fm-towns]|zak[fm-towns]|zakloom'
    ),
    (
      Caption: 'Smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'smooth_scrolling';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'lol'
    ),
    (
      Caption: 'Fix softlocks';
      Kind: sgokCheckbox;
      IniKey: 'softlocks_fix';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'nancy2|nancy5|nancy6|nancy7'
    ),
    (
      Caption: 'Enable sound';
      Kind: sgokCheckbox;
      IniKey: 'sound';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'lba'
    ),
    (
      Caption: 'Sound volume';
      Kind: sgokInteger;
      IniKey: 'sound_volume';
      DefaultBool: False;
      DefaultInt: 255;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Enable Text to Speech';
      Kind: sgokCheckbox;
      IniKey: 'speak';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'airport|alice[dos]|corruption|fairytales[dos]|farm|fish|goldrush[dos]|grandma[dos]|guild|jinxter|life[dos]|lighthouse[dos]|littlered|myth|os[dos]|pawn|puzzle[dos]|tortoise[dos]|troll|warlock[dos]|wonderland'
    ),
    (
      Caption: 'Also read input text';
      Kind: sgokCheckbox;
      IniKey: 'speak_input';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'airport|alice[dos]|corruption|fairytales[dos]|farm|fish|goldrush[dos]|grandma[dos]|guild|jinxter|life[dos]|lighthouse[dos]|littlered|myth|os[dos]|pawn|puzzle[dos]|tortoise[dos]|troll|warlock[dos]|wonderland'
    ),
    (
      Caption: 'Speech mute';
      Kind: sgokCheckbox;
      IniKey: 'speech_mute';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner|hadesch|myst3|nebular|remorse|toon|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'Speech volume';
      Kind: sgokInteger;
      IniKey: 'speech_volume';
      DefaultBool: False;
      DefaultInt: -750;
      GameIds: 'asylum'
    ),
    (
      Caption: 'Speech volume';
      Kind: sgokInteger;
      IniKey: 'speech_volume';
      DefaultBool: False;
      DefaultInt: 192;
      GameIds: 'bladerunner|hadesch|sky|toon'
    ),
    (
      Caption: 'Splash enabled';
      Kind: sgokCheckbox;
      IniKey: 'splash_enabled';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Splash time';
      Kind: sgokInteger;
      IniKey: 'splash_time';
      DefaultBool: False;
      DefaultInt: 3000;
      GameIds: 'dogncat|dogncat2|karliknos|maski|mng|nupogodi3|pilots3|pilots3d|rybalka|shveik'
    ),
    (
      Caption: 'Studio audience';
      Kind: sgokCheckbox;
      IniKey: 'studio_audience';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'kyra3'
    ),
    (
      Caption: 'Enable text';
      Kind: sgokCheckbox;
      IniKey: 'subtitles';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'lba'
    ),
    (
      Caption: 'Talkspeed';
      Kind: sgokInteger;
      IniKey: 'talkspeed';
      DefaultBool: False;
      DefaultInt: 240;
      GameIds: 'duckman'
    ),
    (
      Caption: 'Talkspeed';
      Kind: sgokInteger;
      IniKey: 'talkspeed';
      DefaultBool: False;
      DefaultInt: 179;
      GameIds: 'grim|monkey4'
    ),
    (
      Caption: 'Talkspeed';
      Kind: sgokInteger;
      IniKey: 'talkspeed';
      DefaultBool: False;
      DefaultInt: 60;
      GameIds: 'hadesch|toon'
    ),
    (
      Caption: 'Talkspeed';
      Kind: sgokInteger;
      IniKey: 'talkspeed';
      DefaultBool: False;
      DefaultInt: 255;
      GameIds: 'ihnm|ite'
    ),
    (
      Caption: 'Talkspeed';
      Kind: sgokInteger;
      IniKey: 'talkspeed';
      DefaultBool: False;
      DefaultInt: 24;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'Enable jump to mouse position';
      Kind: sgokCheckbox;
      IniKey: 'targetedjump';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'ultima8'
    ),
    (
      Caption: '32 Bits';
      Kind: sgokCheckbox;
      IniKey: 'tex_filter';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'aventuradecine[dos]'
    ),
    (
      Caption: 'ToiletPaperOver';
      Kind: sgokCheckbox;
      IniKey: 'toiletPaperOver';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp'
    ),
    (
      Caption: 'Transition mode';
      Kind: sgokCheckbox;
      IniKey: 'transition_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|myst|newkid|noah|riven|ruff|seussabc|sheila|stellaluna|tortoise'
    ),
    (
      Caption: 'Transition speed';
      Kind: sgokInteger;
      IniKey: 'transition_speed';
      DefaultBool: False;
      DefaultInt: 50;
      GameIds: 'myst3'
    ),
    (
      Caption: 'Disable scene transitions';
      Kind: sgokCheckbox;
      IniKey: 'transitions_disable';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'tot'
    ),
    (
      Caption: 'Transparent windows';
      Kind: sgokCheckbox;
      IniKey: 'transparent_windows';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'rosetattoo'
    ),
    (
      Caption: 'Use transparent dialog boxes in 16 color scenes';
      Kind: sgokCheckbox;
      IniKey: 'transparentdialogboxes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'fw|os'
    ),
    (
      Caption: 'Trim FM-TOWNS games to 200 pixels height';
      Kind: sgokCheckbox;
      IniKey: 'trim_fmtowns_to_200_pixels';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'atlantis[fm-towns]|indy3[fm-towns]|indyloom|indyzak|monkey2[fm-towns]|monkey[fm-towns]|zak[fm-towns]|zakloom'
    ),
    (
      Caption: 'Show item costs in standard inventory mode';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'activity|airport|arttime|astrochicken|atlantis[amiga,dos,floppy,fm-towns,mac,mac floppy,steam]|balloon|baseball|baseball2001|baseball2003|basketball|bc|bickadoodle|blues123time|bluesabctime|bluesbirthday|bluestreasurehunt|brstorm|camelot|castlebrain|catalog|chase|chivalry|cloudsofxeen[dos]|comi|cruise|darksideofxeen[dos]|ddp|deadcity|dig|dirtysplit|dog|drascula|driller[dos]|ecoquest2[demo,floppy]|ecoquest[demo,floppy]|efh|escapemansion|fairytales|farm|fbear|fbpack|football|football2002|freddi|freddi2|freddi3|freddi4|freddicove|freddisfunshop|freddypharkas[demo,dos,floppy,mac]|ft|funpack|fw|goldrush|got|griffon|helga|hires0|hires1|hires2|hires3|hires4[green valley [a],green valley [b],on-line systems [a],on-line systems [b]]|hires5|hires6|hoyle1|hoyle2|hoyle3|hoyle4[demo]|hugo1|hugo2|hugo3|iceman|indy3|indyloom|indyzak|islandbrain|jumble[xn--lsjumble -nd0e]|jungle|kq1|kq1sci|kq2|kq3|kq4' +
               '|kq4sci|kq5[amiga,dos,ega,fm-towns,mac,pc98]|kq6[demo,dos,mac]|laurabow|laurabow2[demo,dos]|lgop2|longbow|loom|lost|lsl1|lsl1sci|lsl2|lsl3|lsl5|lsl6[dos,mac]|manhole[dos,dos-v,ega,fm-towns]|maniac|maze|mh1|mh2|mickey|mixedup|monkey|monkey2|moonbase|mortevielle|mothergoose|mothergoose256[demo,dos]|msn1|msn2|mustard|nippon|os|pajama|pajama2|pajama3|pass|pepper[demo,dos]|pjgames|pq1|pq1sci|pq2[amiga,atarist,demo,dos]|pq3|puttcircus|puttmoon|puttputt|puttrace|puttsfunshop|putttime|puttzoo|qfg1[amiga,atarist,demo,dos]|qfg1vga|qfg2|qfg3|readtime|ritter|rodney|rosemary|rtz|samnmax|samsfunshop|soccer|soccer2004|soccermls|socks|soltys[freeware,freeware v1.0,russian fan-translation v1.0,russian fan-translation v1.1]|spyfox|spyfox2|spyozon|sq1|sq1sci[demo,sci]|sq2|sq3|sq4[amiga,dos,ega,mac,pc98]|sq5|swordsofxeen|tentacle|thinker1|thinkerk|troll|twc|wage|water|winnie' +
               '|worldofxeen[cd,dos,monster spawn mod v1.0]|zak|zakloom'
    ),
    (
      Caption: 'Enable Text to Speech for Missing Voiceovers';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_missing_voice';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'draci|prince[galador: der fluch des prinzen,ksiaze i tchorz,windows]'
    ),
    (
      Caption: 'Enable Text to Speech for Objects, Options, and the Bible Quote';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_objects';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'draci|dreamweb|prince|sfinx[demo,freeware,freeware v0.3,freeware v1.0,freeware v1.1]|teenagent'
    ),
    (
      Caption: 'Enable Text to Speech for Subtitles';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_speech';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'draci|dreamweb|prince[dos,windows]|sfinx[demo,freeware v0.3,freeware v1.0,freeware v1.1]|teenagent'
    ),
    (
      Caption: 'TTS Narrator';
      Kind: sgokCheckbox;
      IniKey: 'tts_narrator';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lba|lure[ega,konami vga,vga]|nebular[dos,floppy,mac]|scalpel[dos]'
    ),
    (
      Caption: 'Use arb shaders';
      Kind: sgokCheckbox;
      IniKey: 'use_arb_shaders';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'grim|monkey4'
    ),
    (
      Caption: 'Use CD audio';
      Kind: sgokCheckbox;
      IniKey: 'use_cdaudio';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'jones[cd]'
    ),
    (
      Caption: 'Show subtitles during text crawl';
      Kind: sgokCheckbox;
      IniKey: 'use_crawl_subs';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'bladerunner[windows]'
    ),
    (
      Caption: 'Use floppy version music';
      Kind: sgokCheckbox;
      IniKey: 'use_floppy_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'darkseed[cd]'
    ),
    (
      Caption: 'Enable linear filtering of the backgrounds images';
      Kind: sgokCheckbox;
      IniKey: 'use_linear_filtering';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'tlj'
    ),
    (
      Caption: 'Use Pro Audio Spectrum 16 instead of AdLib';
      Kind: sgokCheckbox;
      IniKey: 'use_pas';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular[demo,dos,floppy]'
    ),
    (
      Caption: 'Use remastered audio';
      Kind: sgokCheckbox;
      IniKey: 'use_remastered_audio';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'monkey2[se]|monkey[se]|tentacle[remastered]'
    ),
    (
      Caption: 'Use original Acorn system cursor';
      Kind: sgokCheckbox;
      IniKey: 'use_system_cursor';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'simon1[cd,cd demo,floppy,floppy demo]'
    ),
    (
      Caption: 'Use Windows interface';
      Kind: sgokCheckbox;
      IniKey: 'use_windows_interface';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hugo1[dos]|hugo2[dos]|hugo3[dos]'
    ),
    (
      Caption: 'Enable high resolution';
      Kind: sgokCheckbox;
      IniKey: 'usehighres';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lba|remorse|ultima8'
    ),
    (
      Caption: 'Start with debugger';
      Kind: sgokCheckbox;
      IniKey: 'vcruise_debug';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'reah|schizm'
    ),
    (
      Caption: 'Faster animations';
      Kind: sgokCheckbox;
      IniKey: 'vcruise_fast_animations';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'reah|schizm'
    ),
    (
      Caption: 'Faster video decoder (lower quality)';
      Kind: sgokCheckbox;
      IniKey: 'vcruise_fast_video_decoder';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'schizm'
    ),
    (
      Caption: 'Improved click sensitivity';
      Kind: sgokCheckbox;
      IniKey: 'vcruise_increase_drag_distance';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'reah|schizm'
    ),
    (
      Caption: 'Preload sounds';
      Kind: sgokCheckbox;
      IniKey: 'vcruise_preload_sounds';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'reah|schizm'
    ),
    (
      Caption: 'Skip main menu';
      Kind: sgokCheckbox;
      IniKey: 'vcruise_skip_menu';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'reah|schizm'
    ),
    (
      Caption: 'Enable Venus';
      Kind: sgokCheckbox;
      IniKey: 'venusenabled';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'znemesis'
    ),
    (
      Caption: 'Use the USA version';
      Kind: sgokCheckbox;
      IniKey: 'version';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lba'
    ),
    (
      Caption: 'Vibrations';
      Kind: sgokCheckbox;
      IniKey: 'vibrations';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'myst3'
    ),
    (
      Caption: 'Video quality';
      Kind: sgokInteger;
      IniKey: 'video_quality';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra3'
    ),
    (
      Caption: 'Walk threshold';
      Kind: sgokInteger;
      IniKey: 'walk_threshold';
      DefaultBool: False;
      DefaultInt: 50;
      GameIds: 'remorse|ultima4|ultima6|ultima8'
    ),
    (
      Caption: 'Walkspeed';
      Kind: sgokInteger;
      IniKey: 'walkspeed';
      DefaultBool: False;
      DefaultInt: 2;
      GameIds: 'kyra1'
    ),
    (
      Caption: 'Walkspeed';
      Kind: sgokInteger;
      IniKey: 'walkspeed';
      DefaultBool: False;
      DefaultInt: 5;
      GameIds: 'kyra2|kyra3'
    ),
    (
      Caption: 'Enable wall collisions';
      Kind: sgokCheckbox;
      IniKey: 'wallcollision';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lba'
    ),
    (
      Caption: 'Warn about missing files';
      Kind: sgokCheckbox;
      IniKey: 'warn_about_missing_files';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'tlj'
    ),
    (
      Caption: 'WASD controls';
      Kind: sgokCheckbox;
      IniKey: 'wasd_controls';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|totaleclipse2|totaleclipse[amstradcpc,atarist,demo,dos,zx]'
    ),
    (
      Caption: 'Water effects';
      Kind: sgokCheckbox;
      IniKey: 'water_effects';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|myst|myst3|newkid|noah|riven|ruff|seussabc|sheila|stellaluna|tortoise'
    ),
    (
      Caption: 'Enable widescreen support';
      Kind: sgokCheckbox;
      IniKey: 'widescreen';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'zgi|znemesis'
    ),
    (
      Caption: 'Widescreen mod';
      Kind: sgokCheckbox;
      IniKey: 'widescreen_mod';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'myst3'
    ),
    (
      Caption: 'Slide dialogs into view';
      Kind: sgokCheckbox;
      IniKey: 'window_style';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'scalpel[3do,dos]'
    ),
    (
      Caption: 'Windows audio mode';
      Kind: sgokCheckbox;
      IniKey: 'windows_audio_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sword1'
    ),
    (
      Caption: 'Use Windows cursors';
      Kind: sgokCheckbox;
      IniKey: 'windows_cursors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kq6[cd]'
    ),
    (
      Caption: 'Use Windows cursors';
      Kind: sgokCheckbox;
      IniKey: 'windows_cursors';
      DefaultBool: True;
      DefaultInt: 0;
      GameIds: 'rodney'
    ),
    (
      Caption: 'Zip mode';
      Kind: sgokCheckbox;
      IniKey: 'zip_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|myst|myst3|newkid|noah|riven|ruff|seussabc|sheila|stellaluna|tortoise'
    )
  );

type
  TScummVMGameIdVariantsDef = record
    GameId : String;
    Variants : String;
  end;

const
  ScummVMGameIdVariantMapCount = 355;
  ScummVMGameIdVariantMap : array[0..354] of TScummVMGameIdVariantsDef = (
    (
      GameId: 'alice';
      Variants: 'Digipak|Hybrid'
    ),
    (
      GameId: 'amazon';
      Variants: 'CD|Demo|dos'
    ),
    (
      GameId: 'anotherworld';
      Variants: '20th Anniversary|amiga|Demo|dos|windows'
    ),
    (
      GameId: 'apeodyssey';
      Variants: 'Ape Man & Bambi (Ape Man)|Ape Man & Bambi (Bambi)|CBGB (Boyfriend)|CBGB (Girlfriend)|CBGB (Jet Stream)|CBGB (One Eyed Jack)|CBGB (Romantic Thriller)|CBGB (RR Diner)|KenKen'
    ),
    (
      GameId: 'arthur';
      Variants: 'Demo|Demo v1.1|mac|Super Living Books|windows'
    ),
    (
      GameId: 'arthurbday';
      Variants: 'Demo|mac|windows'
    ),
    (
      GameId: 'astrochicken';
      Variants: 'dos'
    ),
    (
      GameId: 'atlantis';
      Variants: 'Amiga|Floppy|FM-TOWNS|Mac|Mac Floppy|Steam'
    ),
    (
      GameId: 'babayaga';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'bbvs';
      Variants: 'Demo|Loogie Demo|windows'
    ),
    (
      GameId: 'bc';
      Variants: 'coco3|dos|updated'
    ),
    (
      GameId: 'beamish';
      Variants: 'CD|dos|EGA|FDD|mac'
    ),
    (
      GameId: 'beardark';
      Variants: '32-bit|mac|windows'
    ),
    (
      GameId: 'bearfight';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'betterd';
      Variants: 'Demo'
    ),
    (
      GameId: 'blackwell1';
      Variants: 'ac2game.dat|Blackwell Legacy.ags'
    ),
    (
      GameId: 'blackwell2';
      Variants: 'ac2game.dat|Unbound.ags'
    ),
    (
      GameId: 'blackwell3';
      Variants: 'ac2game.dat|Convergence.ags'
    ),
    (
      GameId: 'blackwell4';
      Variants: 'ac2game.dat|agsgame.dat|deception.ags'
    ),
    (
      GameId: 'blackwell5';
      Variants: 'ac2game.dat|agsgame.dat|epiphany.ags'
    ),
    (
      GameId: 'bladerunner';
      Variants: 'Non-Interactive Demo|windows'
    ),
    (
      GameId: 'blueforce';
      Variants: 'CD|Demo|dos|Floppy'
    ),
    (
      GameId: 'bluesbirthday';
      Variants: 'Red|Yellow'
    ),
    (
      GameId: 'burger';
      Variants: 'Demo|dos|Non-Interactive Demo'
    ),
    (
      GameId: 'buried';
      Variants: 'Demo 24BPP|Demo 8BPP|Trial 24BPP|Trial 8BPP|v1.00 24BPP|v1.00 8BPP|v1.01 24BPP|v1.01 8BPP|v1.04 24BPP|v1.04 8BPP|v1.05 24BPP|v1.05 8BPP|v1.051 24BPP|v1.051 8BPP|v1.1 24BPP|v1.1 8BPP'
    ),
    (
      GameId: 'camelot';
      Variants: 'amiga|atarist|Demo|dos'
    ),
    (
      GameId: 'carnival';
      Variants: 'Demo|windows'
    ),
    (
      GameId: 'castlebrain';
      Variants: 'amiga|Demo|dos|EGA|mac|pc98'
    ),
    (
      GameId: 'castlemaster';
      Variants: 'amiga|amstradcpc|atarist|c64|CD release|Demo|Domark PC Collection|dos|Virtual Worlds|zx'
    ),
    (
      GameId: 'chest';
      Variants: 'dos'
    ),
    (
      GameId: 'chewy';
      Variants: 'dos'
    ),
    (
      GameId: 'china';
      Variants: 'dos|EGA|mac'
    ),
    (
      GameId: 'cloudsofxeen';
      Variants: 'dos|Non-Interactive Demo'
    ),
    (
      GameId: 'comi';
      Variants: 'Demo|windows'
    ),
    (
      GameId: 'corruption';
      Variants: 'Collection'
    ),
    (
      GameId: 'cpatrol';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'create';
      Variants: 'Demo|mac|windows'
    ),
    (
      GameId: 'cruise';
      Variants: '16 colors|256 colors|amiga|atarist|Fanmade'
    ),
    (
      GameId: 'cubert';
      Variants: 'v1.1|v1.2|v1.25|windows'
    ),
    (
      GameId: 'cutemachine';
      Variants: 'Windows 95'
    ),
    (
      GameId: 'daniel';
      Variants: 'Demo|windows'
    ),
    (
      GameId: 'darby';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'darkeye';
      Variants: 'Beta|v1.0'
    ),
    (
      GameId: 'darkseed';
      Variants: 'CD|Demo|dos'
    ),
    (
      GameId: 'darkside';
      Variants: 'amiga|amstradcpc|atarist|Demo|dos|zx'
    ),
    (
      GameId: 'darksideofxeen';
      Variants: 'dos|Non-Interactive Demo'
    ),
    (
      GameId: 'dig';
      Variants: 'Demo|Steam'
    ),
    (
      GameId: 'dimp';
      Variants: 'CD'
    ),
    (
      GameId: 'dirtysplit';
      Variants: 'PC Action'
    ),
    (
      GameId: 'dogncat2';
      Variants: 'c250f79a8e404b13a588e6a03e3a6d20'
    ),
    (
      GameId: 'draci';
      Variants: 'dos'
    ),
    (
      GameId: 'dracula1';
      Variants: '7 Wolf|EU release|GOG release|Retail version|windows'
    ),
    (
      GameId: 'dracula2';
      Variants: 'GOG release|Retail version|Russobit-M'
    ),
    (
      GameId: 'dragons';
      Variants: 'psx'
    ),
    (
      GameId: 'drascula';
      Variants: 'dos'
    ),
    (
      GameId: 'dreamweb';
      Variants: 'CD|CD Demo|Demo|dos|Installer'
    ),
    (
      GameId: 'driller';
      Variants: 'amiga|amstradcpc|Demo|dos|Not implemented yet|Rolling Demo|zx'
    ),
    (
      GameId: 'duckman';
      Variants: 'Demo|windows'
    ),
    (
      GameId: 'dw';
      Variants: 'CD|CD Demo|CD v1.1|Floppy|Floppy Demo'
    ),
    (
      GameId: 'dw2';
      Variants: 'CD|Demo|dos|windows'
    ),
    (
      GameId: 'dwars';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'easternmind';
      Variants: 'Tong-Nou Characters|Transcript'
    ),
    (
      GameId: 'ecoquest';
      Variants: 'CD|Demo|Floppy'
    ),
    (
      GameId: 'ecoquest2';
      Variants: 'CD|Demo|Floppy'
    ),
    (
      GameId: 'efh';
      Variants: 'dos'
    ),
    (
      GameId: 'elvira1';
      Variants: 'Floppy|Non-Interactive Demo|pc98'
    ),
    (
      GameId: 'elvira2';
      Variants: 'Floppy'
    ),
    (
      GameId: 'eob';
      Variants: 'amiga|dos|pc98|sega-cd'
    ),
    (
      GameId: 'eob2';
      Variants: 'amiga|dos|fm-towns|pc98'
    ),
    (
      GameId: 'escapemansion';
      Variants: 'Beta 1|Beta 2'
    ),
    (
      GameId: 'excavationhb';
      Variants: 'ac2game.dat'
    ),
    (
      GameId: 'fairytales';
      Variants: 'Demo|dos|EGA'
    ),
    (
      GameId: 'fbear';
      Variants: 'HE 62|HE 70'
    ),
    (
      GameId: 'feeble';
      Variants: '2CD|4CD|CD|Demo'
    ),
    (
      GameId: 'fish';
      Variants: 'Collection'
    ),
    (
      GameId: 'footballgame';
      Variants: 'AGSProject.ags'
    ),
    (
      GameId: 'frasse';
      Variants: 'v1.03|v1.04|v2.02|v2.03'
    ),
    (
      GameId: 'freddi';
      Variants: 'HE 71|HE 73'
    ),
    (
      GameId: 'freddi3';
      Variants: 'HE 99'
    ),
    (
      GameId: 'freddi4';
      Variants: 'HE 99|unenc'
    ),
    (
      GameId: 'freddicove';
      Variants: 'HE 100|unenc'
    ),
    (
      GameId: 'freddypharkas';
      Variants: 'CD|CD Demo|Demo|dos|Floppy|mac'
    ),
    (
      GameId: 'ft';
      Variants: 'Demo|Remastered'
    ),
    (
      GameId: 'fta2';
      Variants: 'dos'
    ),
    (
      GameId: 'fullpipe';
      Variants: 'Demo|Steam|windows'
    ),
    (
      GameId: 'fw';
      Variants: 'amiga|atarist|CD|Demo|dos|Sony CD version'
    ),
    (
      GameId: 'gadget';
      Variants: 'Demo|Read Me|Room(306)'
    ),
    (
      GameId: 'ganbareinuchan';
      Variants: 'Demo'
    ),
    (
      GameId: 'ganbareinuchan2';
      Variants: 'Demo'
    ),
    (
      GameId: 'geminirue';
      Variants: 'ac2game.dat|agsgame.dat|Gemini Rue.ags'
    ),
    (
      GameId: 'gk1';
      Variants: 'CD|dos|mac'
    ),
    (
      GameId: 'gk2';
      Variants: 'Demo|dos|mac'
    ),
    (
      GameId: 'gnap';
      Variants: 'Fargus|windows'
    ),
    (
      GameId: 'goldenwake';
      Variants: 'ac2game.dat'
    ),
    (
      GameId: 'goldrush';
      Variants: 'coco3|updated'
    ),
    (
      GameId: 'grandma';
      Variants: 'Demo|Demo v1.0|Demo v1.1|Demo v1.2|v1.0|v1.1|v2.0|windows'
    ),
    (
      GameId: 'greeneggs';
      Variants: '32-bit|Demo|mac|windows'
    ),
    (
      GameId: 'gregory';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'griffon';
      Variants: 'windows'
    ),
    (
      GameId: 'grim';
      Variants: '7Wolf|Demo|ENPY|Fanmade|Fargus|Remastered|windows'
    ),
    (
      GameId: 'guild';
      Variants: 'Collection'
    ),
    (
      GameId: 'hadesch';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'harryhh';
      Variants: 'Demo|mac|Super Living Books|v1.0|v1.1|windows'
    ),
    (
      GameId: 'hdb';
      Variants: 'Demo|Handango Demo|linux|pocketpc|windows'
    ),
    (
      GameId: 'helga';
      Variants: 'Demo'
    ),
    (
      GameId: 'henachoco02';
      Variants: 'Itachoco Taizen 2 rerelease'
    ),
    (
      GameId: 'henachoco03';
      Variants: 'Demo|Itachoco Taizen 3 rerelease|Trial Version'
    ),
    (
      GameId: 'henachoco04';
      Variants: 'Itachoco Taizen 1 rerelease'
    ),
    (
      GameId: 'henachoco05';
      Variants: 'Demo|Itachoco Taizen 2 rerelease'
    ),
    (
      GameId: 'hires0';
      Variants: 'apple2'
    ),
    (
      GameId: 'hires1';
      Variants: 'Malibu Microcomputing [A]|Malibu Microcomputing [B]|On-Line Systems [A]|On-Line Systems [B]|On-Line Systems [C]|Public Domain'
    ),
    (
      GameId: 'hires2';
      Variants: 'Green Valley [A]|Green Valley [B]|On-Line Systems [A]|On-Line Systems [B]'
    ),
    (
      GameId: 'hires3';
      Variants: 'apple2'
    ),
    (
      GameId: 'hires4';
      Variants: 'atari8bit|Green Valley [A]|Green Valley [B]|On-Line Systems [A]|On-Line Systems [B]'
    ),
    (
      GameId: 'hires5';
      Variants: 'On-Line Systems|Sierra On-Line'
    ),
    (
      GameId: 'hires6';
      Variants: 'SierraVenture [A]|SierraVenture [B]'
    ),
    (
      GameId: 'hodjnpodj';
      Variants: 'Demo|windows'
    ),
    (
      GameId: 'hopkins';
      Variants: 'beos|Demo|linux|os2|windows'
    ),
    (
      GameId: 'hoyle1';
      Variants: 'amiga|atarist|Demo|dos|mac'
    ),
    (
      GameId: 'hoyle2';
      Variants: 'amiga|atarist|dos|mac'
    ),
    (
      GameId: 'hoyle3';
      Variants: 'amiga|Demo|dos|EGA'
    ),
    (
      GameId: 'hoyle4';
      Variants: 'Demo|dos|mac'
    ),
    (
      GameId: 'hoyle5';
      Variants: 'Demo|mac|windows'
    ),
    (
      GameId: 'hoyle5solitaire';
      Variants: 'CD|Hard Drive|mac'
    ),
    (
      GameId: 'hugo1';
      Variants: 'dos|windows'
    ),
    (
      GameId: 'hugo2';
      Variants: 'dos|windows'
    ),
    (
      GameId: 'hugo3';
      Variants: 'dos|windows'
    ),
    (
      GameId: 'iceman';
      Variants: 'amiga|atarist|Debug Build|Demo|dos'
    ),
    (
      GameId: 'ihnm';
      Variants: 'Demo|dos|fan-made|mac'
    ),
    (
      GameId: 'imoking';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'indy3';
      Variants: 'EGA|FM-TOWNS|Mac|No AdLib|Steam|VGA'
    ),
    (
      GameId: 'indyloom';
      Variants: 'FM-TOWNS'
    ),
    (
      GameId: 'indyzak';
      Variants: 'FM-TOWNS'
    ),
    (
      GameId: 'islandbrain';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'ite';
      Variants: 'AGA CD|AGA Demo CD|AGA Demo Floppy|AGA Floppy|CD|CD Version|Demo|Demo 1|Demo 2|DOS CD Version|DOS CD Version 1|DOS CD Version 2|ECS CD|ECS Demo CD|ECS Demo Floppy|ECS Floppy|Floppy|Floppy Packed|GOG.com CD Mac v1.1|Linux CD Version|Multi-OS CD Version|Win Demo 2|Win Demo 3|Windows CD Version|Wyrmkeep CD'
    ),
    (
      GameId: 'johnroc';
      Variants: 'dos'
    ),
    (
      GameId: 'jones';
      Variants: 'CD|dos|EGA'
    ),
    (
      GameId: 'jumble';
      Variants: 'CD|xn--LSJUMBLE -nd0e'
    ),
    (
      GameId: 'karliknos';
      Variants: 'a3f1b86c07bf72f688e7f2b5f20aa7f9'
    ),
    (
      GameId: 'kingdom';
      Variants: '3do|Demo|dos|windows'
    ),
    (
      GameId: 'kq1';
      Variants: 'coco3|dos|fixed|se|updated'
    ),
    (
      GameId: 'kq1sci';
      Variants: 'Demo|SCI'
    ),
    (
      GameId: 'kq2';
      Variants: 'coco3|dos|fixed|updated'
    ),
    (
      GameId: 'kq3';
      Variants: 'coco3|dos'
    ),
    (
      GameId: 'kq4';
      Variants: 'coco3|Demo|updated'
    ),
    (
      GameId: 'kq4sci';
      Variants: 'Demo|SCI'
    ),
    (
      GameId: 'kq5';
      Variants: 'amiga|CD|dos|EGA|fm-towns|mac|pc98'
    ),
    (
      GameId: 'kq6';
      Variants: 'CD|Demo|dos|mac|windows'
    ),
    (
      GameId: 'kq7';
      Variants: 'Demo|dos|mac|windows'
    ),
    (
      GameId: 'kquestions';
      Variants: 'dos'
    ),
    (
      GameId: 'kyra1';
      Variants: 'amiga|CD|Demo|dos|Extracted|fm-towns|mac|pc98|StuffIt|StuffIt multi-floppy'
    ),
    (
      GameId: 'kyra2';
      Variants: 'CD|Demo|dos|Extracted|fm-towns'
    ),
    (
      GameId: 'kyra3';
      Variants: 'dos|mac'
    ),
    (
      GameId: 'lab';
      Variants: 'amiga|dos|Lowres|Rerelease'
    ),
    (
      GameId: 'lastexpress';
      Variants: 'Demo|Gold Edition|Interplay Release|se'
    ),
    (
      GameId: 'laurabow';
      Variants: 'amiga|atarist|Demo|dos'
    ),
    (
      GameId: 'laurabow2';
      Variants: 'CD|Demo|dos'
    ),
    (
      GameId: 'lba';
      Variants: 'CD Original European Version|Classic Version (Steam)|Demo Version|dos|DotEmu|DotEmu (Steam)|DotEmu Enhanced Version (Steam)|DotEmu Version (Steam)|Fan Translation by ChaosFish|Fan Translation by Cody|Fan Translation by Gregorius|Fan Translation by xesf|Fan Translation by Zink|GOG.com Classic Version|GOG.com Version|Original Japanese Version|Preview Version|Virgin Asia CD release'
    ),
    (
      GameId: 'lbhunter';
      Variants: 'demo|dos'
    ),
    (
      GameId: 'leptonsquest';
      Variants: 'linux|mac|windows'
    ),
    (
      GameId: 'lgop2';
      Variants: 'dos'
    ),
    (
      GameId: 'liam';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'lighthouse';
      Variants: 'Demo|dos|Glider Demo|mac|Non-interactive Demo'
    ),
    (
      GameId: 'lilmonster';
      Variants: 'Demo|mac|windows'
    ),
    (
      GameId: 'littlesamurai';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'lol';
      Variants: 'CD|Demo|dos|Extracted|fm-towns|pc98'
    ),
    (
      GameId: 'longbow';
      Variants: 'amiga|Demo|dos|EGA'
    ),
    (
      GameId: 'loom';
      Variants: 'Demo|EGA|FM-TOWNS|Mac|No AdLib|PC-Engine|Steam|VGA'
    ),
    (
      GameId: 'lsl1';
      Variants: 'coco3|Demo'
    ),
    (
      GameId: 'lsl1sci';
      Variants: 'Demo|EGA|SCI'
    ),
    (
      GameId: 'lsl2';
      Variants: 'amiga|atarist|Demo|dos'
    ),
    (
      GameId: 'lsl3';
      Variants: 'amiga|atarist|Demo|dos'
    ),
    (
      GameId: 'lsl5';
      Variants: 'amiga|Demo|dos|EGA|mac'
    ),
    (
      GameId: 'lsl6';
      Variants: 'CD|dos|mac'
    ),
    (
      GameId: 'lsl6hires';
      Variants: 'Hi-res'
    ),
    (
      GameId: 'lsl7';
      Variants: 'Demo|dos|Fargus|mac|Softclub'
    ),
    (
      GameId: 'lure';
      Variants: 'dos|EGA|Konami VGA|VGA'
    ),
    (
      GameId: 'lzone';
      Variants: 'macii|Readme|v2'
    ),
    (
      GameId: 'maddog';
      Variants: 'dos'
    ),
    (
      GameId: 'maddog2';
      Variants: 'dos'
    ),
    (
      GameId: 'majestic';
      Variants: '16-bit|32-bit'
    ),
    (
      GameId: 'mandy';
      Variants: 'v1.2|v1.3|v1.4'
    ),
    (
      GameId: 'manhole';
      Variants: 'dos|DOS-V|EGA|fm-towns|Masterpiece Edition Demo'
    ),
    (
      GameId: 'maniac';
      Variants: 'Apple II|C64|C64 Demo|NES|Remastered|V1|V1 Demo|V2|V2 Demo'
    ),
    (
      GameId: 'martian';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'mh1';
      Variants: 'coco3|updated'
    ),
    (
      GameId: 'mh2';
      Variants: 'coco3|updated'
    ),
    (
      GameId: 'mickey';
      Variants: 'dos'
    ),
    (
      GameId: 'mixedup';
      Variants: 'coco3|mac'
    ),
    (
      GameId: 'mm1';
      Variants: 'dos'
    ),
    (
      GameId: 'monkey';
      Variants: 'CD|Demo|EGA|FM-TOWNS|Mac|No AdLib|SE|SE Talkie|SEGA|VGA|VGA Demo'
    ),
    (
      GameId: 'monkey2';
      Variants: 'Amiga|Demo|FM-TOWNS|Mac|SE|SE Talkie'
    ),
    (
      GameId: 'monkey4';
      Variants: 'CD Demo|Demo|Fanmade|mac|ps2|Web Demo|windows'
    ),
    (
      GameId: 'moonbase';
      Variants: 'Demo'
    ),
    (
      GameId: 'mortevielle';
      Variants: 'dos'
    ),
    (
      GameId: 'mothergoose';
      Variants: 'amiga|EGA'
    ),
    (
      GameId: 'mothergoose256';
      Variants: 'CD|Demo|dos|fm-towns'
    ),
    (
      GameId: 'mothergoosehires';
      Variants: 'Demo|mac|windows'
    ),
    (
      GameId: 'msn1';
      Variants: 'dos'
    ),
    (
      GameId: 'msn2';
      Variants: 'dos'
    ),
    (
      GameId: 'mti';
      Variants: 'CD|Demo|mac|windows'
    ),
    (
      GameId: 'mybigsister';
      Variants: 'AGSProject.ags'
    ),
    (
      GameId: 'myst';
      Variants: 'Demo|Masterpiece Edition|unknown|unknown (Masterpiece Edition)|windows'
    ),
    (
      GameId: 'myst3';
      Variants: 'DVD|windows'
    ),
    (
      GameId: 'nancy1';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy10';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy11';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy2';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy3';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy4';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy5';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy6';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy7';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy8';
      Variants: 'windows'
    ),
    (
      GameId: 'nancy9';
      Variants: 'windows'
    ),
    (
      GameId: 'nebular';
      Variants: 'Demo|dos|Fanmade|floppy|mac'
    ),
    (
      GameId: 'necrono';
      Variants: 'Steam|windows'
    ),
    (
      GameId: 'neverhood';
      Variants: 'Big Demo|Demo|DR|Fargus|Stream|windows'
    ),
    (
      GameId: 'newkid';
      Variants: 'Demo|Demo v1.0|Demo v1.1|mac|windows'
    ),
    (
      GameId: 'nippon';
      Variants: 'amiga|Demo|Multi-lingual|Multi-lingual alt'
    ),
    (
      GameId: 'nl';
      Variants: 'amiga|Demo|windows'
    ),
    (
      GameId: 'noah';
      Variants: 'ios|windows'
    ),
    (
      GameId: 'noctropolis';
      Variants: 'Demo|Rerelease|windows'
    ),
    (
      GameId: 'nsc';
      Variants: 'v1.03'
    ),
    (
      GameId: 'nupogodi3';
      Variants: '???|c0fab62fe6f3a339e96b1dd4a034e40a|cd'
    ),
    (
      GameId: 'obsidian';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'oldskies';
      Variants: 'ac2game.dat|OldSkies.ags'
    ),
    (
      GameId: 'os';
      Variants: '256 colors|alt|amiga|atarist|Demo|dos'
    ),
    (
      GameId: 'outoforder';
      Variants: 'v1.0'
    ),
    (
      GameId: 'pajama2';
      Variants: 'HE 99'
    ),
    (
      GameId: 'pass';
      Variants: 'dos'
    ),
    (
      GameId: 'pawn';
      Variants: 'cd'
    ),
    (
      GameId: 'pegasus';
      Variants: 'Demo|DVD|DVD Demo|mac|v1.0 Demo'
    ),
    (
      GameId: 'pelrock';
      Variants: 'dos'
    ),
    (
      GameId: 'penumbraoverture';
      Variants: 'linux|mac|windows'
    ),
    (
      GameId: 'pepper';
      Variants: 'Demo|dos|windows'
    ),
    (
      GameId: 'peril';
      Variants: 'Compressed|Demo|windows'
    ),
    (
      GameId: 'petka1';
      Variants: 'Compressed|Demo|windows'
    ),
    (
      GameId: 'petka2';
      Variants: 'Compressed|windows'
    ),
    (
      GameId: 'phantasmagoria';
      Variants: 'Demo|dos|mac'
    ),
    (
      GameId: 'phantasmagoria2';
      Variants: 'windows'
    ),
    (
      GameId: 'plumbers';
      Variants: '3do|windows'
    ),
    (
      GameId: 'pn';
      Variants: 'Floppy|Non-Interactive Demo'
    ),
    (
      GameId: 'pokus';
      Variants: 'v1.0|v2.0|windows'
    ),
    (
      GameId: 'pq1';
      Variants: 'coco3|dos|updated'
    ),
    (
      GameId: 'pq1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'pq2';
      Variants: 'amiga|atarist|Demo|dos|pc98'
    ),
    (
      GameId: 'pq3';
      Variants: 'amiga|Demo|dos|EGA'
    ),
    (
      GameId: 'pq4';
      Variants: 'CD|dos|mac'
    ),
    (
      GameId: 'pqswat';
      Variants: 'dos|mac'
    ),
    (
      GameId: 'primordia';
      Variants: 'ac2game.dat|agsgame.dat|primordia.ags'
    ),
    (
      GameId: 'prince';
      Variants: 'Ksiaze i Tchorz|windows'
    ),
    (
      GameId: 'princess';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'puttmoon';
      Variants: 'Demo|HE 70'
    ),
    (
      GameId: 'puttputt';
      Variants: 'Demo|HE 60|HE 61|HE 62'
    ),
    (
      GameId: 'puttrace';
      Variants: 'HE 98|HE 99'
    ),
    (
      GameId: 'puttzoo';
      Variants: 'HE 100|HE 72|HE 99'
    ),
    (
      GameId: 'puzzle';
      Variants: 'CD'
    ),
    (
      GameId: 'qfg1';
      Variants: '16 Colors|8 Colors|amiga|atarist|Demo|dos'
    ),
    (
      GameId: 'qfg1vga';
      Variants: 'Demo|VGA'
    ),
    (
      GameId: 'qfg2';
      Variants: 'amiga|Demo|dos'
    ),
    (
      GameId: 'qfg3';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'qfg4';
      Variants: 'CD|dos'
    ),
    (
      GameId: 'queen';
      Variants: 'CD|Demo|Demo Alt|Floppy|GOG.com|Interview'
    ),
    (
      GameId: 'rama';
      Variants: 'Demo|dos|mac'
    ),
    (
      GameId: 'reah';
      Variants: 'English CD|English Digital|English DVD|German CD|Polish Demo|Russian CD'
    ),
    (
      GameId: 'rebel1';
      Variants: 'dos'
    ),
    (
      GameId: 'rebel2';
      Variants: 'Demo|dos|PlayStation'
    ),
    (
      GameId: 'redbow';
      Variants: 'AGSProject.ags'
    ),
    (
      GameId: 'remorse';
      Variants: 'Demo|dos|Fan Translation|windows'
    ),
    (
      GameId: 'resonance';
      Variants: 'ac2game.dat|agsgame.dat|resonance.ags'
    ),
    (
      GameId: 'riddle';
      Variants: 'Demo|Demo2|dos'
    ),
    (
      GameId: 'ringworld';
      Variants: 'CD|Demo|dos|Floppy|Floppy Demo'
    ),
    (
      GameId: 'ringworld2';
      Variants: 'CD|CD Demo'
    ),
    (
      GameId: 'rise';
      Variants: 'amiga|dos|EGA|mac'
    ),
    (
      GameId: 'ritter';
      Variants: 'Demo|Fanmade'
    ),
    (
      GameId: 'riven';
      Variants: '25th Anniversary|Demo|DVD|unknown|unknown (DVD)|windows'
    ),
    (
      GameId: 'robinsrescue';
      Variants: 'v1.0'
    ),
    (
      GameId: 'rodney';
      Variants: 'dos'
    ),
    (
      GameId: 'rosetattoo';
      Variants: 'CD'
    ),
    (
      GameId: 'rosewater';
      Variants: 'Rosewater.ags'
    ),
    (
      GameId: 'rtz';
      Variants: 'CD|Demo|Demo CD|dos|Floppy|fm-towns|pc98'
    ),
    (
      GameId: 'ruff';
      Variants: 'Demo|mac|windows'
    ),
    (
      GameId: 'samnmax';
      Variants: 'Floppy'
    ),
    (
      GameId: 'scalpel';
      Variants: '3do|dos|Interactive Demo|Non-Interactive Demo'
    ),
    (
      GameId: 'schizm';
      Variants: 'English CD|English Digital|English DVD|French Digital|German Digital|German DVD|Hungarian Digital|Italian Digital|Japanese DVD|Polish Digital|Polish DVD|Russian Digital|Spanish Digital'
    ),
    (
      GameId: 'seussabc';
      Variants: '32-bit|Demo|mac|windows'
    ),
    (
      GameId: 'sfinx';
      Variants: 'Demo|Freeware|Freeware v0.3|Freeware v1.0|Freeware v1.1|Unknown version'
    ),
    (
      GameId: 'shardlight';
      Variants: 'ac2game.dat|Shardlight.ags'
    ),
    (
      GameId: 'sheila';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'shivahkosher';
      Variants: 'ac2game.dat|Shivah.ags'
    ),
    (
      GameId: 'shivers';
      Variants: 'CD Demo|Demo|mac|Non-interactive Demo|windows'
    ),
    (
      GameId: 'simon1';
      Variants: '25th Anniversary Edition|AGA Floppy|CD|CD Demo|CD32|CD32 Demo|Floppy|Floppy Demo|Infocom CD|Infocom Floppy|OCS Demo|OCS Floppy'
    ),
    (
      GameId: 'simon2';
      Variants: '25th Anniversary Edition|Amiga|Amiga CD - Original Release|CD|CD Demo|CD Non-Interactive Demo|Floppy'
    ),
    (
      GameId: 'slater';
      Variants: 'Demo|dos|mac'
    ),
    (
      GameId: 'sleepingcub';
      Variants: 'mac|windows'
    ),
    (
      GameId: 'soltys';
      Variants: 'Freeware|Freeware v1.0|Russian fan-translation v1.0|Russian fan-translation v1.1|Unknown version'
    ),
    (
      GameId: 'spacebar';
      Variants: 'mac|Medium Demo|Not Installed|Small Demo|windows'
    ),
    (
      GameId: 'spirates';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'sq1';
      Variants: 'coco3|dos|fixed|updated'
    ),
    (
      GameId: 'sq1sci';
      Variants: 'Demo|EGA|SCI'
    ),
    (
      GameId: 'sq2';
      Variants: 'coco3|dos|updated'
    ),
    (
      GameId: 'sq3';
      Variants: 'amiga|atarist|Demo|dos|mac'
    ),
    (
      GameId: 'sq4';
      Variants: 'amiga|CD|dos|EGA|mac|pc98'
    ),
    (
      GameId: 'sq5';
      Variants: 'dos'
    ),
    (
      GameId: 'sq6';
      Variants: 'Demo|dos|mac'
    ),
    (
      GameId: 'sqinc';
      Variants: 'SQinc.ags'
    ),
    (
      GameId: 'stellaluna';
      Variants: '32-bit|mac|windows'
    ),
    (
      GameId: 'strangeland';
      Variants: 'ac2game.dat|Strangeland.ags'
    ),
    (
      GameId: 'sumatra';
      Variants: 'AGSProject.ags'
    ),
    (
      GameId: 'swampy';
      Variants: 'CD'
    ),
    (
      GameId: 'sword1';
      Variants: 'Akella|Demo|English speech|English speech and DXA cutscenes|GOG.com|mac|Mediahauz|Novy Disk|psx|Rerelease|Steam|TecToy|windows'
    ),
    (
      GameId: 'sword2';
      Variants: '1CD release|Demo|English speech|EU|Fargus|PC Gamer Demo|psx|windows'
    ),
    (
      GameId: 'sword25';
      Variants: 'Extracted|Latest version|psylog version'
    ),
    (
      GameId: 'swordsofxeen';
      Variants: 'dos'
    ),
    (
      GameId: 'syberia';
      Variants: 'android|Extracted|ios|mac|nintendoswitch|ps3'
    ),
    (
      GameId: 'syberia2';
      Variants: 'android|Extracted|ios|mac|nintendoswitch|ps3'
    ),
    (
      GameId: 'technobabylon';
      Variants: 'ac2game.dat|technobabylon.ags'
    ),
    (
      GameId: 'teenagent';
      Variants: 'Alt version|dos'
    ),
    (
      GameId: 'tentacle';
      Variants: 'Floppy|Remastered'
    ),
    (
      GameId: 'tgttpoacs';
      Variants: 'linux|windows'
    ),
    (
      GameId: 'the7colors';
      Variants: 'CD'
    ),
    (
      GameId: 'titanic';
      Variants: 'windows'
    ),
    (
      GameId: 'tlc';
      Variants: 'Demo|Trailer'
    ),
    (
      GameId: 'tlj';
      Variants: '2 CD|4 CD|4 CD build 142|CD|Demo|DVD|Fanmade|GOG.com|Old Demo|Remastered|Steam|Triada|v1.61 Demo'
    ),
    (
      GameId: 'toltecs';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'tony';
      Variants: 'Demo|Extracted Demo|windows'
    ),
    (
      GameId: 'toon';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'torin';
      Variants: 'Demo|mac|windows'
    ),
    (
      GameId: 'tortoise';
      Variants: 'Demo|Demo v1.0|Demo v1.1|mac|Super Living Books|Wanderful|windows'
    ),
    (
      GameId: 'tot';
      Variants: 'Demo|dos'
    ),
    (
      GameId: 'totaleclipse';
      Variants: 'amiga|amstradcpc|atarist|Demo|dos|zx'
    ),
    (
      GameId: 'totaleclipse2';
      Variants: 'amstradcpc|zx'
    ),
    (
      GameId: 'troll';
      Variants: 'dos'
    ),
    (
      GameId: 'tsotc';
      Variants: 'v6'
    ),
    (
      GameId: 'tucker';
      Variants: 'Demo|dos|Non-Interactive Demo'
    ),
    (
      GameId: 'twc';
      Variants: 'Anniversary Edition|Definitive Edition|Spanish fanmade'
    ),
    (
      GameId: 'twp';
      Variants: 'GOG|STEAM'
    ),
    (
      GameId: 'ultima4';
      Variants: 'dos|Fanmade'
    ),
    (
      GameId: 'ultima8';
      Variants: 'dos|Gold Edition'
    ),
    (
      GameId: 'unavowed';
      Variants: 'ac2game.dat|unavowed.ags'
    ),
    (
      GameId: 'unrest';
      Variants: 'Demo'
    ),
    (
      GameId: 'vampirediaries';
      Variants: 'windows'
    ),
    (
      GameId: 'versailles';
      Variants: '7fa3cb6a3c18f6b4ba6be85dcd433cff|Demo|dos|mac|windows'
    ),
    (
      GameId: 'voyeur';
      Variants: 'Demo|dos|German Fan Made Version'
    ),
    (
      GameId: 'wage';
      Variants: 'mac|Mac Spudd!'
    ),
    (
      GameId: 'warlock';
      Variants: 'AV Trailer|Demo|Trailer|v1.0|v1.0 Demo'
    ),
    (
      GameId: 'waxworks';
      Variants: 'Floppy|Non-Interactive Demo'
    ),
    (
      GameId: 'winnie';
      Variants: 'amiga|apple2|c64|dos'
    ),
    (
      GameId: 'worldofxeen';
      Variants: 'CD|dos|Monster Spawn Mod v1.0|Non-Interactive Demo'
    ),
    (
      GameId: 'wrath';
      Variants: 'Demo'
    ),
    (
      GameId: 'zak';
      Variants: 'FM-TOWNS|V1|V2'
    ),
    (
      GameId: 'zakloom';
      Variants: 'FM-TOWNS'
    ),
    (
      GameId: 'zgi';
      Variants: 'CD|Demo|DVD'
    ),
    (
      GameId: 'znemesis';
      Variants: 'Demo|dos'
    )
  );

function ScummVMGameOptionKindToStr(const Kind : TScummVMGameOptionKind) : String;
begin
  case Kind of
    sgokCheckbox : Result := 'checkbox';
    sgokInteger : Result := 'integer';
  else Result := 'unknown';
  end;
end;

function OptionAppliesTo(const GameIds, GameId, Variant : String) : Boolean;
var
  Id, VarTok, Token, Inside, List : String;
  P : Integer;
begin
  Id := LowerCase(Trim(GameId));
  VarTok := LowerCase(Trim(Variant));
  Result := False;
  List := GameIds;
  while List <> '' do begin
    P := Pos('|', List);
    if P = 0 then begin Token := List; List := ''; end
    else begin Token := Copy(List, 1, P - 1); Delete(List, 1, P); end;
    Token := Trim(Token);
    if Token = '' then Continue;
    { Bare gameid = all variants }
    if Token = Id then begin Result := True; Exit; end;
    if (Length(Token) > Length(Id) + 2) and
       (Copy(Token, 1, Length(Id) + 1) = Id + '[') and
       (Token[Length(Token)] = ']') then begin
      if VarTok = '' then Continue;
      Inside := Copy(Token, Length(Id) + 2, Length(Token) - Length(Id) - 2);
      Inside := ',' + LowerCase(Inside) + ',';
      if Pos(',' + VarTok + ',', Inside) > 0 then begin
        Result := True; Exit;
      end;
    end;
  end;
end;

function GetScummVMGameOptions(const GameId : String; const Variant : String = '') : TScummVMGameOptionArray;
var
  I, N : Integer;
begin
  Result := nil;
  SetLength(Result, 0);
  if Trim(GameId) = '' then Exit;
  N := 0;
  for I := 0 to ScummVMGameOptionTableCount - 1 do
    if OptionAppliesTo(ScummVMGameOptionTable[I].GameIds, GameId, Variant) then Inc(N);
  SetLength(Result, N);
  N := 0;
  for I := 0 to ScummVMGameOptionTableCount - 1 do
    if OptionAppliesTo(ScummVMGameOptionTable[I].GameIds, GameId, Variant) then begin
      Result[N].Caption := ScummVMGameOptionTable[I].Caption;
      Result[N].Kind := ScummVMGameOptionTable[I].Kind;
      Result[N].IniKey := ScummVMGameOptionTable[I].IniKey;
      Result[N].DefaultBool := ScummVMGameOptionTable[I].DefaultBool;
      Result[N].DefaultInt := ScummVMGameOptionTable[I].DefaultInt;
      Inc(N);
    end;
end;

procedure GetScummVMGameIdVariants(const GameId : String; const Dest : TStrings);
var
  I, P : Integer;
  Id, List, One : String;
  Tmp : TStringList;
begin
  if Dest = nil then Exit;
  Dest.Clear;
  Id := LowerCase(Trim(GameId));
  if Id = '' then Exit;
  Tmp := TStringList.Create;
  try
    Tmp.Sorted := True;
    Tmp.Duplicates := dupIgnore;
    for I := 0 to ScummVMGameIdVariantMapCount - 1 do begin
      if LowerCase(ScummVMGameIdVariantMap[I].GameId) <> Id then Continue;
      List := ScummVMGameIdVariantMap[I].Variants;
      while List <> '' do begin
        P := Pos('|', List);
        if P = 0 then begin One := List; List := ''; end
        else begin One := Copy(List, 1, P - 1); Delete(List, 1, P); end;
        One := Trim(One);
        if One <> '' then
          Tmp.Add(One);
      end;
      Break;
    end;
    Dest.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

function GetScummVMCanonicalVariant(const GameId, Variant : String) : String;
var
  St : TStringList;
  I : Integer;
  Want : String;
begin
  Result := Trim(Variant);
  Want := Result;
  if Want = '' then Exit;
  St := TStringList.Create;
  try
    GetScummVMGameIdVariants(GameId, St);
    for I := 0 to St.Count - 1 do
      if SameText(St[I], Want) then begin
        Result := St[I];
        Exit;
      end;
  finally
    St.Free;
  end;
end;

function GetScummVMGameOptionsCoreThenVariant(const GameId : String; const Variant : String = '') : TScummVMGameOptionArray;
var
  Core, Extra : TScummVMGameOptionArray;
  I, J, N : Integer;
  Seen : TStringList;
  Key : String;
begin
  Result := nil;
  SetLength(Result, 0);
  Core := GetScummVMGameOptions(GameId, '');
  if Trim(Variant) = '' then begin
    Result := Core;
    Exit;
  end;
  Extra := GetScummVMGameOptions(GameId, Variant);
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    for I := 0 to High(Core) do
      Seen.Add(LowerCase(Core[I].IniKey));
    N := Length(Core);
    for I := 0 to High(Extra) do begin
      Key := LowerCase(Extra[I].IniKey);
      if Seen.IndexOf(Key) < 0 then Inc(N);
    end;
    SetLength(Result, N);
    for I := 0 to High(Core) do
      Result[I] := Core[I];
    J := Length(Core);
    for I := 0 to High(Extra) do begin
      Key := LowerCase(Extra[I].IniKey);
      if Seen.IndexOf(Key) < 0 then begin
        Result[J] := Extra[I];
        Seen.Add(Key);
        Inc(J);
      end;
    end;
  finally
    Seen.Free;
  end;
end;

end.
