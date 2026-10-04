unit ScummVMGameOptions;
interface

uses SysUtils, Classes;

type
  TScummVMGameOptionKind = (sgokCheckbox, sgokInteger, sgokSpecial);

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
  ScummVMGameOptionTableCount = 151;
  ScummVMGameOptionTable : array[0..150] of TScummVMGameOptionDef = (
    (
      Caption: 'More durable armor';
      Kind: sgokCheckbox;
      IniKey: 'DurableArmor';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cloudsofxeen|darksideofxeen|swordsofxeen|worldofxeen'
    ),
    (
      Caption: 'Hitpoint bars';
      Kind: sgokCheckbox;
      IniKey: 'ShowHpSpBars';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cloudsofxeen|darksideofxeen|swordsofxeen|worldofxeen'
    ),
    (
      Caption: 'Show item costs in standard inventory mode';
      Kind: sgokCheckbox;
      IniKey: 'ShowItemCosts';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cloudsofxeen|darksideofxeen|swordsofxeen|worldofxeen'
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
      Caption: 'Alternative intro';
      Kind: sgokCheckbox;
      IniKey: 'alt_intro';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'queen|sky'
    ),
    (
      Caption: 'Use an alternative palette';
      Kind: sgokCheckbox;
      IniKey: 'altamigapalette';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc[]|ddp|goldrush[]|kq1[]|kq2[]|kq3|lsl1[]|mh1[]|mh2[]|mixedup|pq1[]|sq1[]|sq2[]|winnie'
    ),
    (
      Caption: 'Animated game interface';
      Kind: sgokCheckbox;
      IniKey: 'animated_interface';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Use checkered cursor';
      Kind: sgokCheckbox;
      IniKey: 'apple2e_cursor';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hires1'
    ),
    (
      Caption: 'Add speed menu';
      Kind: sgokCheckbox;
      IniKey: 'apple2gs_speedmenu';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc[]|goldrush[]|kq1[]|kq2[]|kq3|kq4[]|lsl1[]|mixedup|pq1[]|sq1[]|sq2[]'
    ),
    (
      Caption: 'Load modded audio';
      Kind: sgokCheckbox;
      IniKey: 'audio_override';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'activity|airport|arttime|balloon|baseball|baseball2001|blues123time|bluesabctime|bluesbirthday|bluestreasurehunt|brstorm|catalog|chase|dog|farm|fbear|fbpack|football|freddi|freddi2|freddi3|freddi4|freddicove|freddisfunshop|funpack|jungle|lost|maze|mustard|pajama|pajama2|pajama3|pjgames|puttcircus|puttmoon|puttputt|puttrace|puttsfunshop|putttime|puttzoo|readtime|samsfunshop|soccer|soccermls|socks|spyfox|spyfox2|spyozon|thinker1|thinkerk|water'
    ),
    (
      Caption: 'Repair speech audio';
      Kind: sgokCheckbox;
      IniKey: 'audio_popfix_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'gk1[cd]'
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
      DefaultBool: False;
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
      GameIds: 'castlemaster[]|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Camera moves with Silencer';
      Kind: sgokCheckbox;
      IniKey: 'camera_on_player';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'remorse'
    ),
    (
      Caption: 'Simulate loading times of old CD drives';
      Kind: sgokCheckbox;
      IniKey: 'cdromdelay';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'myst'
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
      GameIds: 'adibou1|anotherworld|atlantis[amiga,floppy,mac floppy]|cloudsofxeen|darksideofxeen|dreamweb|gob1|gob2|goldrush|ite|loom[demo,ega,mac,no adlib]|lure|maniac[remastered,v1,v2]|monkey2[]|monkey2[amiga,mac,se]|monkey[mac,vga]|nebular[]|nebular[fanmade,floppy]|simon1[aga floppy,floppy,infocom floppy,ocs floppy]|simon2[floppy]|swordsofxeen|tot[]|voyeur|waxworks[floppy]|worldofxeen|zak[v1,v2]'
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
      Caption: 'Load user patch (unsupported)';
      Kind: sgokCheckbox;
      IniKey: 'datausr_load';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'grim|monkey4'
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
      Caption: 'Skip EGA dithering pass (full color backgrounds)';
      Kind: sgokCheckbox;
      IniKey: 'disable_dithering';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|fairytales[ega]|hoyle1|hoyle2|hoyle3[ega]|iceman|kq1sci|kq4sci|laurabow|lsl2|lsl3|mothergoose[ega]|pq2|qfg1|qfg2|sq3'
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
      Caption: 'Disable McCoy''s quick stamina drain';
      Kind: sgokCheckbox;
      IniKey: 'disable_stamina_drain';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[]|bladerunner[game not implemented]'
    ),
    (
      Caption: 'Use DOS version music tempos';
      Kind: sgokCheckbox;
      IniKey: 'dos_music_tempos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'simon1[25th anniversary edition,cd,cd demo,floppy,infocom cd,infocom floppy]|simon1[]'
    ),
    (
      Caption: 'Easier AI';
      Kind: sgokCheckbox;
      IniKey: 'easier_ai';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'clandestiny[]|t7g[25th anniversary edition]|t7g[]|unclehenry'
    ),
    (
      Caption: 'Enable bearded musicians';
      Kind: sgokCheckbox;
      IniKey: 'enable_bearded_musicians';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sq1sci'
    ),
    (
      Caption: 'Enable black-lined video';
      Kind: sgokCheckbox;
      IniKey: 'enable_black_lined_video';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'gk2[]|lighthouse[]|lsl7[]|lsl7[fargus,softclub]|phantasmagoria|phantasmagoria2|pqswat[]|rama|shivers|sq6[]|torin[]'
    ),
    (
      Caption: 'Enable content censoring';
      Kind: sgokCheckbox;
      IniKey: 'enable_censoring';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'phantasmagoria2'
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
      GameIds: 'maniac[remastered,v1]'
    ),
    (
      Caption: 'Gore Mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_gore';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hopkins'
    ),
    (
      Caption: 'Enable high resolution graphics';
      Kind: sgokCheckbox;
      IniKey: 'enable_high_resolution_graphics';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlebrain[]|freddypharkas[]|gk1[cd]|kq6[]|kq6[cd]|lsl1sci[sci]|lsl5[]|lsl6[]|pq4[cd]|qfg1vga[vga]|sq1sci[sci]'
    ),
    (
      Caption: 'Use high-quality video scaling';
      Kind: sgokCheckbox;
      IniKey: 'enable_hq_video';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'gk1[cd]|gk2|kq7[]|lighthouse|lsl7[]|lsl7[fargus,softclub]|phantasmagoria|phantasmagoria2|pqswat[]|qfg4[cd]|rama|shivers|sq6[]|torin[]'
    ),
    (
      Caption: 'Host games over LAN';
      Kind: sgokCheckbox;
      IniKey: 'enable_lan_broadcast';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'football2002|moonbase'
    ),
    (
      Caption: 'Use high-quality "LarryScale" cel scaling';
      Kind: sgokCheckbox;
      IniKey: 'enable_larryscale';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lsl7'
    ),
    (
      Caption: 'Simulate Sega colors';
      Kind: sgokCheckbox;
      IniKey: 'enable_sega_shadow_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'monkey[sega]'
    ),
    (
      Caption: 'Enable connection to Multiplayer Server';
      Kind: sgokCheckbox;
      IniKey: 'enable_session_server';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'football2002|moonbase'
    ),
    (
      Caption: 'Upscale videos';
      Kind: sgokCheckbox;
      IniKey: 'enable_video_upscale';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kq7[]|pqswat[]'
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
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scalpel'
    ),
    (
      Caption: 'Fast movie speed';
      Kind: sgokCheckbox;
      IniKey: 'fast_movie_speed';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 't7g'
    ),
    (
      Caption: 'Fix audio pops/clicks';
      Kind: sgokCheckbox;
      IniKey: 'fix_audio_pops';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'arthur|arthurbday|beardark|bearfight|create|daniel|grandma|greeneggs|harryhh|lilmonster|newkid|noah|ruff|seussabc|sheila|stellaluna|tortoise'
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
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima8'
    ),
    (
      Caption: 'Run in original 640 x 480 resolution';
      Kind: sgokCheckbox;
      IniKey: 'force_fmtowns_hires_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'atlantis[fm-towns]|indy3[fm-towns]|indyloom|indyzak|loom[fm-towns]|monkey2[fm-towns]|zak[fm-towns]|zakloom'
    ),
    (
      Caption: 'Enable frame limiting';
      Kind: sgokCheckbox;
      IniKey: 'frameLimit';
      DefaultBool: False;
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
      Caption: 'Improve Selenitic Age puzzle accessibility';
      Kind: sgokCheckbox;
      IniKey: 'fuzzy_logic';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'myst[]|myst[masterpiece edition]'
    ),
    (
      Caption: 'Generate random maps';
      Kind: sgokCheckbox;
      IniKey: 'generate_random_maps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'moonbase'
    ),
    (
      Caption: 'Enable saving via the GMM';
      Kind: sgokCheckbox;
      IniKey: 'gmm_save_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|castlebrain|ecoquest|ecoquest2|fairytales|freddypharkas|gk1|gk2|hoyle1|hoyle2|hoyle3|hoyle4|hoyle5|iceman|islandbrain|kq1sci|kq4sci|kq5|kq6|kq7|laurabow|laurabow2|lighthouse[]|longbow|lsl1sci|lsl2|lsl3|lsl5|lsl6|lsl6hires|lsl7[]|lsl7[fargus,softclub]|mothergoose|mothergoose256|pepper|phantasmagoria2|pq1sci|pq2|pq3|pq4|pqswat|qfg1[]|qfg1[demo]|qfg1vga|qfg2|qfg3|qfg4|shivers|slater|sq1sci|sq3|sq4|sq5|sq6|torin'
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
      GameIds: 'rosetattoo|scalpel'
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
      Caption: 'HP bar graphs';
      Kind: sgokCheckbox;
      IniKey: 'hpbargraphs';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'eob|eob2'
    ),
    (
      Caption: 'Improved mode';
      Kind: sgokCheckbox;
      IniKey: 'improved';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'msn1|msn2'
    ),
    (
      Caption: 'Easy mouse interface';
      Kind: sgokCheckbox;
      IniKey: 'interface_hotspots';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Play a digital soundtrack during the opening movie';
      Kind: sgokCheckbox;
      IniKey: 'intro_music_digital';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rtz'
    ),
    (
      Caption: 'Animated inventory items';
      Kind: sgokCheckbox;
      IniKey: 'inventory_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular'
    ),
    (
      Caption: 'Overture Timing';
      Kind: sgokInteger;
      IniKey: 'loom_overture_ticks';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'loom[demo,ega,mac,no adlib]'
    ),
    (
      Caption: 'Playback Adjust';
      Kind: sgokInteger;
      IniKey: 'loom_playback_adjustment';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'loom[vga]'
    ),
    (
      Caption: 'Intro Adjust';
      Kind: sgokInteger;
      IniKey: 'mi1_intro_adjustment';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'monkey[cd,fm-towns,sega]'
    ),
    (
      Caption: 'Outlook Adjust';
      Kind: sgokInteger;
      IniKey: 'mi1_outlook_adjustment';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'monkey[cd,fm-towns,sega]'
    ),
    (
      Caption: 'MIDI mode';
      Kind: sgokInteger;
      IniKey: 'midi_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|castlebrain|ecoquest|ecoquest2|elvira1|fairytales|freddypharkas|hoyle1|hoyle2|hoyle3|hoyle4|iceman|islandbrain|jones|kq1sci|kq4sci|kq5|kq6|laurabow|laurabow2|longbow|lsl1sci|lsl2|lsl3|lsl5|lsl6|mothergoose|mothergoose256|pepper|pq1sci|pq2|pq3|qfg1|qfg1vga|qfg2|qfg3|slater|sq1sci|sq3|sq4|sq5'
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
      Caption: 'Mono music';
      Kind: sgokCheckbox;
      IniKey: 'mono_sound';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kingdom'
    ),
    (
      Caption: 'Always use sharp monochrome text';
      Kind: sgokCheckbox;
      IniKey: 'monotext';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hires1'
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
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bc|ddp|goldrush|kq1|kq2|kq3|kq4|lsl1|mh1|mh2|mickey|mixedup|pq1|sq1|sq2|troll|winnie'
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
      Caption: 'Autosave at progress points';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_auto_save_at_checkpoints';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'obsidian[cd]'
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
      Caption: 'Naughty game mode';
      Kind: sgokCheckbox;
      IniKey: 'naughtiness';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular'
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
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hires1'
    ),
    (
      Caption: 'Show Object Line';
      Kind: sgokCheckbox;
      IniKey: 'object_labels';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'comi'
    ),
    (
      Caption: 'Use ''high definition'' OGG music';
      Kind: sgokCheckbox;
      IniKey: 'ogg_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'noctropolis'
    ),
    (
      Caption: 'AdLib OPL3 mode';
      Kind: sgokCheckbox;
      IniKey: 'opl3_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'elvira1|elvira2|simon1[25th anniversary edition,cd,cd demo,floppy,floppy demo,infocom cd,infocom floppy]|simon1[]|tot|waxworks'
    ),
    (
      Caption: 'Backported music from C64 releases (AdLib)';
      Kind: sgokCheckbox;
      IniKey: 'opl_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster[demo,virtual worlds]|darkside|driller[]|totaleclipse[]'
    ),
    (
      Caption: 'Enable the original GUI and Menu';
      Kind: sgokCheckbox;
      IniKey: 'original_gui';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'activity|atlantis|brstorm|comi|dig|fbear[he 62]|fbpack|ft|funpack|indy3|indyloom|indyzak|loom[demo,ega,fm-towns,mac,no adlib,steam,vga]|maniac|monkey|monkey2[]|monkey2[amiga,fm-towns,mac,se,se talkie]|pass|puttmoon[]|puttmoon[demo]|puttputt|samnmax|tentacle|zak|zakloom'
    ),
    (
      Caption: 'Use original Macintosh menus (experimental)';
      Kind: sgokCheckbox;
      IniKey: 'original_mac_menus';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular[]'
    ),
    (
      Caption: 'Use original save/load screens';
      Kind: sgokCheckbox;
      IniKey: 'original_menus';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'chewy|nebular'
    ),
    (
      Caption: 'Use original save/load screens';
      Kind: sgokCheckbox;
      IniKey: 'originalsaveload';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|bc|camelot|castlebrain|clandestiny[]|ddp|ecoquest|ecoquest2|fairytales|freddypharkas|gk1|gk2[]|goldrush|hoyle1|hoyle2|hoyle3|hoyle4|hoyle5|iceman|islandbrain|kq1|kq1sci|kq2|kq3|kq4|kq4sci|kq5|kq6|laurabow|laurabow2|lighthouse[]|longbow|lsl1|lsl1sci|lsl2|lsl3|lsl5|lsl6|lsl6hires|lsl7[]|lsl7[fargus,softclub]|mh1|mh2|mickey|mixedup|mothergoose|mothergoose256|neverhood|pepper|phantasmagoria2|pq1|pq1sci|pq2|pq3|pq4|qfg1|qfg1vga|qfg2|qfg3|qfg4|rama[]|rosetattoo|scalpel|slater|sq1|sq1sci|sq2|sq3|sq4|sq5|sq6[]|t7g[25th anniversary edition]|t7g[]|toltecs|torin[]|tot|troll|ultima8|winnie'
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
      Caption: 'Play the Myst fly by movie';
      Kind: sgokCheckbox;
      IniKey: 'playmystflyby';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'myst[]|myst[masterpiece edition]'
    ),
    (
      Caption: 'Show character portraits';
      Kind: sgokCheckbox;
      IniKey: 'portraits_on';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scalpel'
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
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|castlebrain|ecoquest|ecoquest2|elvira2|fairytales|freddypharkas|hoyle1|hoyle2|hoyle3|hoyle4|iceman|islandbrain|jones|kq1sci|kq4sci|kq5|kq6|laurabow|laurabow2|longbow|lsl1sci|lsl2|lsl3|lsl5|lsl6|mothergoose|mothergoose256|pepper|pq1sci|pq2|pq3|qfg1|qfg1vga|qfg2|qfg3|slater|sq1sci|sq3|sq4|sq5|waxworks'
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
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rebel2[]|rebel2[demo]'
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
      Caption: 'Repeat useful Willie''s hint';
      Kind: sgokCheckbox;
      IniKey: 'repeatwilliehint';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'neverhood'
    ),
    (
      Caption: 'Use RGB rendering';
      Kind: sgokCheckbox;
      IniKey: 'rgb_rendering';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'astrochicken|camelot|castlebrain|ecoquest|ecoquest2|fairytales|freddypharkas|hoyle1|hoyle2|hoyle3|hoyle4|iceman|islandbrain|jones|kq1sci|kq4sci|kq5|kq6|kquestions|laurabow|laurabow2|longbow|lsl1sci|lsl2|lsl3|lsl5|lsl6|mothergoose|mothergoose256|pepper|pq1sci|pq2|pq3|qfg1|qfg1vga|qfg2|qfg3|slater|sq1sci|sq3|sq4|sq5'
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
      Caption: 'Scale the making of videos to full screen';
      Kind: sgokCheckbox;
      IniKey: 'scalemakingofvideos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'neverhood'
    ),
    (
      Caption: 'Show scanlines';
      Kind: sgokCheckbox;
      IniKey: 'scanlines';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hires1'
    ),
    (
      Caption: 'Show wait cursor when paused';
      Kind: sgokCheckbox;
      IniKey: 'sega_cd_wait_cursor_when_paused';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'monkey[sega]'
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
      Caption: 'SFX mode';
      Kind: sgokInteger;
      IniKey: 'sfx_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'darkseed'
    ),
    (
      Caption: 'Shorty mode';
      Kind: sgokCheckbox;
      IniKey: 'shorty';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[]|bladerunner[game not implemented]'
    ),
    (
      Caption: 'Show FPS';
      Kind: sgokCheckbox;
      IniKey: 'show_fps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'grim|monkey4'
    ),
    (
      Caption: 'Use silver cursors';
      Kind: sgokCheckbox;
      IniKey: 'silver_cursors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sq4[cd]'
    ),
    (
      Caption: 'Use lower quality single speed CD-ROM video';
      Kind: sgokCheckbox;
      IniKey: 'single_speed_videos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cpatrol|dwars|johnroc|lbhunter|maddog2|spirates'
    ),
    (
      Caption: 'Sitcom mode';
      Kind: sgokCheckbox;
      IniKey: 'sitcom';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[]|bladerunner[game not implemented]'
    ),
    (
      Caption: 'Skip support';
      Kind: sgokCheckbox;
      IniKey: 'skip_support';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra3'
    ),
    (
      Caption: 'Skip the Hall of Records storyboard scenes';
      Kind: sgokCheckbox;
      IniKey: 'skiphallofrecordsscenes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'neverhood'
    ),
    (
      Caption: 'Slim Left/Right Hotspots';
      Kind: sgokCheckbox;
      IniKey: 'slim_hotspots';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'clandestiny|t7g|tlc|unclehenry'
    ),
    (
      Caption: 'Smoother movement';
      Kind: sgokCheckbox;
      IniKey: 'smooth_movement';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Enable smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'smooth_scroll';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'atlantis[fm-towns]|indy3[fm-towns]|indyloom|indyzak|loom[fm-towns]|monkey2[fm-towns]|zak[fm-towns]|zakloom'
    ),
    (
      Caption: 'Smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'smooth_scrolling';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lol'
    ),
    (
      Caption: 'Speedrun Mode';
      Kind: sgokCheckbox;
      IniKey: 'speedrun_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'clandestiny|t7g|tlc|unclehenry'
    ),
    (
      Caption: 'Studio audience';
      Kind: sgokCheckbox;
      IniKey: 'studio_audience';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra3'
    ),
    (
      Caption: 'Text language';
      Kind: sgokInteger;
      IniKey: 'subtitles_language_override';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sword1[25th anniversary,english speech,gog.com,rerelease,soldout rerelease,steam,tectoy]|sword1[]'
    ),
    (
      Caption: 'Enable jump to mouse position';
      Kind: sgokCheckbox;
      IniKey: 'targetedjump';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima8'
    ),
    (
      Caption: 'Transitions';
      Kind: sgokInteger;
      IniKey: 'transition_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'riven'
    ),
    (
      Caption: 'Transitions Enabled';
      Kind: sgokCheckbox;
      IniKey: 'transition_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'myst'
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
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'rosetattoo'
    ),
    (
      Caption: 'Trim FM-TOWNS games to 200 pixels height';
      Kind: sgokCheckbox;
      IniKey: 'trim_fmtowns_to_200_pixels';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'atlantis[fm-towns]|indy3[fm-towns]|indyloom|indyzak|monkey2[fm-towns]|zak[fm-towns]|zakloom'
    ),
    (
      Caption: 'Enable Text to Speech';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'activity|airport|arttime|astrochicken|atlantis|balloon|baseball|baseball2003|basketball|bc|blues123time|bluesabctime|bluesbirthday|bluestreasurehunt|brstorm|camelot|castlebrain|catalog|chase|cloudsofxeen|comi|cruise|darksideofxeen|ddp|dig|dog|drascula|ecoquest2|ecoquest[demo,floppy]|efh|fairytales|farm|fbear|fbpack|freddi|freddi2|freddi3|freddi4|freddicove|freddisfunshop|freddypharkas[]|freddypharkas[demo,floppy]|ft|funpack|gk1[]|goldrush|got|griffon|hires1|hoyle1|hoyle2|hoyle3|hoyle4[demo]|hugo1|hugo2|hugo3|iceman|indy3|indyloom|indyzak|islandbrain[demo]|jones[]|jones[ega]|jungle|kq1|kq1sci|kq2|kq3|kq4|kq4sci|kq5[]|kq5[ega]|kq6[]|kq6[demo]|laurabow|laurabow2[]|laurabow2[demo]|longbow|loom|lost|lsl1|lsl1sci|lsl2|lsl3|lsl5|lsl6[]|maniac|maze|mh1|mh2|mickey|mixedup|mm1|monkey|monkey2|mortevielle|mothergoose|mothergoose256[]|mothergoose256[demo]|msn1|msn2|mustard|nippon|pajama|pajama2' +
               '|pajama3|pass|pepper|pjgames|pq1|pq1sci|pq2|pq3|pq4[]|puttcircus|puttmoon|puttputt|puttrace|puttsfunshop|putttime|puttzoo|qfg1[]|qfg1[demo]|qfg1vga|qfg2|qfg3|qfg4[]|readtime|samnmax|samsfunshop|soccer|soccer2004|soccermls|socks|soltys|spyfox|spyfox2|spyozon|sq1|sq1sci|sq2|sq3|sq4[]|sq4[ega]|sq5|swordsofxeen|tentacle|thinker1|thinkerk|troll|water|winnie|worldofxeen|zak|zakloom'
    ),
    (
      Caption: 'Enable Text to Speech for Missing Voiceovers';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_missing_voice';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'prince'
    ),
    (
      Caption: 'Enable Text to Speech for Objects and Options';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_objects';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'draci|prince|sfinx|teenagent'
    ),
    (
      Caption: 'Enable Text to Speech for Subtitles';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_speech';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'draci|prince[]|sfinx[demo,freeware v0.3]|teenagent[]|teenagent[alt demo,alt version,demo]'
    ),
    (
      Caption: 'TTS Narrator';
      Kind: sgokCheckbox;
      IniKey: 'tts_narrator';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lure[ega,konami vga,vga]|nebular[]|nebular[floppy]|scalpel'
    ),
    (
      Caption: 'Use CD audio';
      Kind: sgokCheckbox;
      IniKey: 'use_cdaudio';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'jones[cd]'
    ),
    (
      Caption: 'Show subtitles during text crawl';
      Kind: sgokCheckbox;
      IniKey: 'use_crawl_subs';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner[]|bladerunner[game not implemented]'
    ),
    (
      Caption: 'Use floppy version music';
      Kind: sgokCheckbox;
      IniKey: 'use_floppy_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'darkseed'
    ),
    (
      Caption: 'Use Pro Audio Spectrum 16 instead of AdLib';
      Kind: sgokCheckbox;
      IniKey: 'use_pas';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nebular[]|nebular[demo,floppy]'
    ),
    (
      Caption: 'Use remastered audio';
      Kind: sgokCheckbox;
      IniKey: 'use_remastered_audio';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'monkey2[se]|monkey[se]|tentacle[remastered]'
    ),
    (
      Caption: 'Use original Acorn system cursor';
      Kind: sgokCheckbox;
      IniKey: 'use_system_cursor';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'simon1[cd,cd demo,floppy,floppy demo]'
    ),
    (
      Caption: 'Use Windows interface';
      Kind: sgokCheckbox;
      IniKey: 'use_windows_interface';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hugo1|hugo2|hugo3'
    ),
    (
      Caption: 'Enable high resolution';
      Kind: sgokCheckbox;
      IniKey: 'usehighres';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'remorse|ultima8'
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
      Caption: 'WASD controls';
      Kind: sgokCheckbox;
      IniKey: 'wasd_controls';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'castlemaster|totaleclipse|totaleclipse2'
    ),
    (
      Caption: 'Water Effect Enabled';
      Kind: sgokCheckbox;
      IniKey: 'water_effects';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'riven'
    ),
    (
      Caption: 'Slide dialogs into view';
      Kind: sgokCheckbox;
      IniKey: 'window_style';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scalpel'
    ),
    (
      Caption: 'Simulate the audio engine from the Windows executable';
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
      GameIds: 'ecoquest2[cd]|kq5[cd]|kq6[]|kq6[cd]|laurabow2[cd]|pepper[]|rodney|sq4[cd]'
    ),
    (
      Caption: 'Zip Mode Activated';
      Kind: sgokCheckbox;
      IniKey: 'zip_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'myst[]|myst[masterpiece edition]|riven'
    ),
    (
      Caption: 'scumm-enhancements';
      Kind: sgokSpecial;
      IniKey: 'enhancements';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'atlantis|comi|dig[]|dig[steam]|freddi3[]|freddi4|ft[]|ft[remastered]|indy3|loom[demo,ega,fm-towns,mac,no adlib,pcengine,vga]|maniac[apple ii,nes,remastered,v1,v2]|monkey2[]|monkey2[amiga,demo,fm-towns,mac,se]|monkey[cd,ega,fm-towns,mac,no adlib,se,sega,vga]|samnmax|tentacle|zak[fm-towns]'
    )
  );

type
  TScummVMGameIdVariantsDef = record
    GameId : String;
    Variants : String;
  end;

const
  ScummVMGameIdVariantMapCount = 158;
  ScummVMGameIdVariantMap : array[0..157] of TScummVMGameIdVariantsDef = (
    (
      GameId: '11h';
      Variants: 'Installed|Interactive Demo|Non-Interactive Demo'
    ),
    (
      GameId: 'adibou1';
      Variants: 'Adi Jnr|Adi Jnr.|ADIBOU 1 Environnement 4-7 ans'
    ),
    (
      GameId: 'anotherworld';
      Variants: 'Demo'
    ),
    (
      GameId: 'arthur';
      Variants: 'Demo|Demo v1.1|Super Living Books'
    ),
    (
      GameId: 'arthurbday';
      Variants: 'Demo'
    ),
    (
      GameId: 'atlantis';
      Variants: 'Amiga|Floppy|FM-TOWNS|Mac|Mac Floppy|Steam'
    ),
    (
      GameId: 'bc';
      Variants: 'updated'
    ),
    (
      GameId: 'beardark';
      Variants: '32-bit'
    ),
    (
      GameId: 'bladerunner';
      Variants: 'Game not implemented|Non-Interactive Demo'
    ),
    (
      GameId: 'bluesbirthday';
      Variants: 'Red|Yellow'
    ),
    (
      GameId: 'camelot';
      Variants: 'Demo'
    ),
    (
      GameId: 'carnival';
      Variants: 'Demo'
    ),
    (
      GameId: 'castlebrain';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'castlemaster';
      Variants: 'CD release|Demo|Domark PC Collection|Virtual Worlds'
    ),
    (
      GameId: 'clandestiny';
      Variants: 'Demo|Trailer'
    ),
    (
      GameId: 'comi';
      Variants: 'Demo'
    ),
    (
      GameId: 'create';
      Variants: 'Demo'
    ),
    (
      GameId: 'cruise';
      Variants: '16 colors|256 colors|Fanmade'
    ),
    (
      GameId: 'daniel';
      Variants: 'Demo'
    ),
    (
      GameId: 'darkseed';
      Variants: 'CD'
    ),
    (
      GameId: 'dig';
      Variants: 'Demo|Steam'
    ),
    (
      GameId: 'dreamweb';
      Variants: 'CD|Installer'
    ),
    (
      GameId: 'driller';
      Variants: 'Demo|Not implemented yet|Rolling Demo'
    ),
    (
      GameId: 'dw2';
      Variants: 'CD|Demo'
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
      GameId: 'elvira1';
      Variants: 'Floppy|Non-Interactive Demo'
    ),
    (
      GameId: 'elvira2';
      Variants: 'Floppy'
    ),
    (
      GameId: 'fairytales';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'fbear';
      Variants: 'HE 62|HE 70'
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
      Variants: 'CD|CD Demo|Demo|Floppy'
    ),
    (
      GameId: 'ft';
      Variants: 'Demo|Remastered'
    ),
    (
      GameId: 'gk1';
      Variants: 'CD'
    ),
    (
      GameId: 'gk2';
      Variants: 'Demo'
    ),
    (
      GameId: 'gob1';
      Variants: 'EGA|VGA'
    ),
    (
      GameId: 'gob2';
      Variants: 'v1.02|v1.03'
    ),
    (
      GameId: 'goldrush';
      Variants: 'updated'
    ),
    (
      GameId: 'grandma';
      Variants: 'Demo|Demo v1.0|Demo v1.1|Demo v1.2|v1.0|v1.1|v2.0'
    ),
    (
      GameId: 'greeneggs';
      Variants: '32-bit|Game not implemented'
    ),
    (
      GameId: 'grim';
      Variants: '7Wolf|Demo|ENPY|Fanmade|Fargus|Remastered'
    ),
    (
      GameId: 'harryhh';
      Variants: 'Demo|Super Living Books|v1.0|v1.1'
    ),
    (
      GameId: 'hires1';
      Variants: 'Malibu Microcomputing [A]|Malibu Microcomputing [B]|On-Line Systems [A]|On-Line Systems [B]|On-Line Systems [C]|Public Domain'
    ),
    (
      GameId: 'hopkins';
      Variants: 'Demo'
    ),
    (
      GameId: 'hoyle1';
      Variants: 'Demo'
    ),
    (
      GameId: 'hoyle3';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'hoyle4';
      Variants: 'Demo'
    ),
    (
      GameId: 'iceman';
      Variants: 'Debug Build|Demo'
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
      Variants: 'Demo'
    ),
    (
      GameId: 'ite';
      Variants: 'AGA Floppy|CD|ECS Floppy|Floppy|Floppy Packed'
    ),
    (
      GameId: 'jones';
      Variants: 'CD|EGA'
    ),
    (
      GameId: 'kq1';
      Variants: 'fixed|updated'
    ),
    (
      GameId: 'kq1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'kq2';
      Variants: 'fixed|updated'
    ),
    (
      GameId: 'kq4';
      Variants: 'Demo|updated'
    ),
    (
      GameId: 'kq4sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'kq5';
      Variants: 'CD|EGA'
    ),
    (
      GameId: 'kq6';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'kq7';
      Variants: 'Demo'
    ),
    (
      GameId: 'laurabow';
      Variants: 'Demo'
    ),
    (
      GameId: 'laurabow2';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'lbhunter';
      Variants: 'demo'
    ),
    (
      GameId: 'lighthouse';
      Variants: 'Demo|Glider Demo|Non-interactive Demo'
    ),
    (
      GameId: 'lilmonster';
      Variants: 'Demo'
    ),
    (
      GameId: 'lol';
      Variants: 'CD|Extracted'
    ),
    (
      GameId: 'longbow';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'loom';
      Variants: 'Demo|EGA|FM-TOWNS|Mac|No AdLib|pcengine|Steam|VGA'
    ),
    (
      GameId: 'lsl1';
      Variants: 'Demo'
    ),
    (
      GameId: 'lsl1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'lsl2';
      Variants: 'Demo'
    ),
    (
      GameId: 'lsl3';
      Variants: 'Demo'
    ),
    (
      GameId: 'lsl5';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'lsl6';
      Variants: 'CD'
    ),
    (
      GameId: 'lsl6hires';
      Variants: 'Hi-res'
    ),
    (
      GameId: 'lsl7';
      Variants: 'Demo|Fargus|Softclub'
    ),
    (
      GameId: 'lure';
      Variants: 'EGA|Konami VGA|VGA'
    ),
    (
      GameId: 'maniac';
      Variants: 'Apple II|C64|C64 Demo|NES|Remastered|V1|V1 Demo|V2|V2 Demo'
    ),
    (
      GameId: 'mh1';
      Variants: 'updated'
    ),
    (
      GameId: 'mh2';
      Variants: 'updated'
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
      Variants: 'CD Demo|Demo|Fanmade|Web Demo'
    ),
    (
      GameId: 'moonbase';
      Variants: 'Demo'
    ),
    (
      GameId: 'mothergoose';
      Variants: 'EGA'
    ),
    (
      GameId: 'mothergoose256';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'myst';
      Variants: 'Demo|Masterpiece Edition'
    ),
    (
      GameId: 'nebular';
      Variants: 'Demo|Fanmade|floppy'
    ),
    (
      GameId: 'neverhood';
      Variants: 'Big Demo|Demo|DR|Fargus|Stream'
    ),
    (
      GameId: 'newkid';
      Variants: 'Demo|Demo v1.0|Demo v1.1'
    ),
    (
      GameId: 'nippon';
      Variants: 'Demo|Multi-lingual|Multi-lingual alt'
    ),
    (
      GameId: 'noctropolis';
      Variants: 'Rerelease'
    ),
    (
      GameId: 'obsidian';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'pajama2';
      Variants: 'HE 99'
    ),
    (
      GameId: 'pepper';
      Variants: 'Demo'
    ),
    (
      GameId: 'phantasmagoria';
      Variants: 'Demo'
    ),
    (
      GameId: 'pq1';
      Variants: 'updated'
    ),
    (
      GameId: 'pq1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'pq2';
      Variants: 'Demo'
    ),
    (
      GameId: 'pq3';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'pq4';
      Variants: 'CD'
    ),
    (
      GameId: 'pqswat';
      Variants: 'demo'
    ),
    (
      GameId: 'prince';
      Variants: 'Ksiaze i Tchorz'
    ),
    (
      GameId: 'private-eye';
      Variants: 'Demo'
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
      GameId: 'qfg1';
      Variants: '16 Colors|8 Colors|Demo'
    ),
    (
      GameId: 'qfg1vga';
      Variants: 'VGA'
    ),
    (
      GameId: 'qfg2';
      Variants: 'Demo'
    ),
    (
      GameId: 'qfg3';
      Variants: 'Demo'
    ),
    (
      GameId: 'qfg4';
      Variants: 'CD'
    ),
    (
      GameId: 'queen';
      Variants: 'CD|GOG.com'
    ),
    (
      GameId: 'rama';
      Variants: 'Demo'
    ),
    (
      GameId: 'rebel2';
      Variants: 'Demo|PlayStation'
    ),
    (
      GameId: 'remorse';
      Variants: 'Demo|Fan Translation'
    ),
    (
      GameId: 'riven';
      Variants: '25th Anniversary|Demo|DVD'
    ),
    (
      GameId: 'rosetattoo';
      Variants: 'CD'
    ),
    (
      GameId: 'rtz';
      Variants: 'CD|Demo CD'
    ),
    (
      GameId: 'ruff';
      Variants: 'Demo'
    ),
    (
      GameId: 'samnmax';
      Variants: 'Floppy'
    ),
    (
      GameId: 'schizm';
      Variants: 'English CD|English Digital|English DVD|French Digital|German Digital|German DVD|Hungarian Digital|Italian Digital|Japanese DVD|Polish Digital|Polish DVD|Russian Digital|Spanish Digital'
    ),
    (
      GameId: 'seussabc';
      Variants: '32-bit|Demo'
    ),
    (
      GameId: 'sfinx';
      Variants: 'Demo|Freeware|Freeware v0.3|Freeware v1.0|Freeware v1.1'
    ),
    (
      GameId: 'shivers';
      Variants: 'CD Demo|Demo|Non-interactive Demo'
    ),
    (
      GameId: 'simon1';
      Variants: '25th Anniversary Edition|AGA Floppy|CD|CD Demo|CD32|CD32 Demo|Floppy|Floppy Demo|Infocom CD|Infocom Floppy|OCS Demo|OCS Floppy'
    ),
    (
      GameId: 'simon2';
      Variants: '25th Anniversary Edition|Amiga CD - Original Release|CD|CD Demo|CD Non-Interactive Demo|Floppy'
    ),
    (
      GameId: 'slater';
      Variants: 'Demo'
    ),
    (
      GameId: 'soltys';
      Variants: 'Freeware|Freeware v1.0|Game not implemented|Russian fan-translation v1.0|Russian fan-translation v1.1'
    ),
    (
      GameId: 'sq1';
      Variants: 'fixed|updated'
    ),
    (
      GameId: 'sq1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'sq2';
      Variants: 'updated'
    ),
    (
      GameId: 'sq3';
      Variants: 'Demo'
    ),
    (
      GameId: 'sq4';
      Variants: 'CD|EGA'
    ),
    (
      GameId: 'sq6';
      Variants: 'Demo'
    ),
    (
      GameId: 'stellaluna';
      Variants: '32-bit'
    ),
    (
      GameId: 'sword1';
      Variants: '25th Anniversary|Akella|Demo|English speech|English speech and DXA cutscenes|GOG.com|Mediahauz|Novy Disk|Rerelease|SoldOut rerelease|Steam|TecToy'
    ),
    (
      GameId: 't7g';
      Variants: '25th Anniversary Edition|demo'
    ),
    (
      GameId: 'teenagent';
      Variants: 'Alt Demo|Alt version|CD|Demo'
    ),
    (
      GameId: 'tentacle';
      Variants: 'Floppy|Remastered'
    ),
    (
      GameId: 'tlc';
      Variants: 'CD|Game not implemented'
    ),
    (
      GameId: 'toltecs';
      Variants: 'Demo'
    ),
    (
      GameId: 'torin';
      Variants: 'Demo'
    ),
    (
      GameId: 'tortoise';
      Variants: 'Demo|Demo v1.0|Demo v1.1|Super Living Books|Wanderful'
    ),
    (
      GameId: 'tot';
      Variants: 'Demo'
    ),
    (
      GameId: 'totaleclipse';
      Variants: 'Demo'
    ),
    (
      GameId: 'ultima8';
      Variants: 'Gold Edition'
    ),
    (
      GameId: 'voyeur';
      Variants: 'Demo|German Fan Made Version'
    ),
    (
      GameId: 'waxworks';
      Variants: 'Floppy|Non-Interactive Demo'
    ),
    (
      GameId: 'worldofxeen';
      Variants: 'CD|Monster Spawn Mod v1.0'
    ),
    (
      GameId: 'zak';
      Variants: 'FM-TOWNS|V1|V2'
    ),
    (
      GameId: 'zakloom';
      Variants: 'FM-TOWNS'
    )
  );

function ScummVMGameOptionKindToStr(const Kind : TScummVMGameOptionKind) : String;
begin
  case Kind of
    sgokCheckbox : Result := 'checkbox';
    sgokInteger : Result := 'integer';
    sgokSpecial : Result := 'special';
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
    if Token = Id + '[]' then begin
      if VarTok = '' then begin Result := True; Exit; end;
      Continue;
    end;
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
  VarTok : String;
begin
  Result := nil;
  SetLength(Result, 0);
  if Trim(GameId) = '' then Exit;
  VarTok := GetScummVMCanonicalVariant(GameId, Variant);
  N := 0;
  for I := 0 to ScummVMGameOptionTableCount - 1 do
    if OptionAppliesTo(ScummVMGameOptionTable[I].GameIds, GameId, VarTok) then Inc(N);
  SetLength(Result, N);
  N := 0;
  for I := 0 to ScummVMGameOptionTableCount - 1 do
    if OptionAppliesTo(ScummVMGameOptionTable[I].GameIds, GameId, VarTok) then begin
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

function FoldScummVMVariantKey(const S: String): String;
begin
  Result := LowerCase(StringReplace(Trim(S), '-', ' ', [rfReplaceAll]));
end;

function GetScummVMCanonicalVariant(const GameId, Variant : String) : String;
var
  St : TStringList;
  I : Integer;
  Want, WantFold : String;
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
    WantFold := FoldScummVMVariantKey(Want);
    for I := 0 to St.Count - 1 do
      if FoldScummVMVariantKey(St[I]) = WantFold then begin
        Result := St[I];
        Exit;
      end;
  finally
    St.Free;
  end;
end;

end.
