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
  ScummVMGameOptionTableCount = 191;
  ScummVMGameOptionTable : array[0..190] of TScummVMGameOptionDef = (
    (
      Caption: '32 Bits';
      Kind: sgokCheckbox;
      IniKey: '32_bits';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'alcachofa:aventuradecine'
    ),
    (
      Caption: 'More durable armor';
      Kind: sgokCheckbox;
      IniKey: 'DurableArmor';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mm:cloudsofxeen|mm:darksideofxeen|mm:swordsofxeen|mm:worldofxeen'
    ),
    (
      Caption: 'Hitpoint bars';
      Kind: sgokCheckbox;
      IniKey: 'ShowHpSpBars';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mm:cloudsofxeen|mm:darksideofxeen|mm:swordsofxeen|mm:worldofxeen'
    ),
    (
      Caption: 'Show item costs in standard inventory mode';
      Kind: sgokCheckbox;
      IniKey: 'ShowItemCosts';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mm:cloudsofxeen|mm:darksideofxeen|mm:swordsofxeen|mm:worldofxeen'
    ),
    (
      Caption: 'Faithful AD&D rules';
      Kind: sgokCheckbox;
      IniKey: 'addrules';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:eob|kyra:eob2'
    ),
    (
      Caption: 'Alternative intro';
      Kind: sgokCheckbox;
      IniKey: 'alt_intro';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'queen:queen|sky:sky'
    ),
    (
      Caption: 'Use an alternative palette';
      Kind: sgokCheckbox;
      IniKey: 'altamigapalette';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:bc[]|agi:ddp|agi:goldrush[]|agi:kq1[]|agi:kq2[]|agi:kq3|agi:lsl1[]|agi:mh1[]|agi:mh2[]|agi:mixedup|agi:pq1[]|agi:sq1[]|agi:sq2[]|agi:winnie'
    ),
    (
      Caption: 'Alternate timing';
      Kind: sgokCheckbox;
      IniKey: 'alternate_timing';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'pelrock:pelrock'
    ),
    (
      Caption: 'Animated game interface';
      Kind: sgokCheckbox;
      IniKey: 'animated_interface';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mads:nebular'
    ),
    (
      Caption: 'Annoying in-jokes';
      Kind: sgokCheckbox;
      IniKey: 'annoyingInJokes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp:twp'
    ),
    (
      Caption: 'Use checkered cursor';
      Kind: sgokCheckbox;
      IniKey: 'apple2e_cursor';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'adl:hires1'
    ),
    (
      Caption: 'Add speed menu';
      Kind: sgokCheckbox;
      IniKey: 'apple2gs_speedmenu';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:bc[]|agi:goldrush[]|agi:kq1[]|agi:kq2[]|agi:kq3|agi:kq4[]|agi:lsl1[]|agi:mixedup|agi:pq1[]|agi:sq1[]|agi:sq2[]'
    ),
    (
      Caption: 'Load modded audio';
      Kind: sgokCheckbox;
      IniKey: 'audio_override';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:activity|scumm:airport|scumm:arttime|scumm:balloon|scumm:baseball|scumm:baseball2001|scumm:blues123time|scumm:bluesabctime|scumm:bluesbirthday|scumm:bluestreasurehunt|scumm:brstorm|scumm:catalog|scumm:chase|scumm:dog|scumm:farm|scumm:fbear|scumm:fbpack|scumm:football|scumm:freddi|scumm:freddi2|scumm:freddi3|scumm:freddi4|scumm:freddicove|scumm:freddisfunshop|scumm:funpack|scumm:jungle|scumm:lost|scumm:maze|scumm:mustard|scumm:pajama|scumm:pajama2|scumm:pajama3|scumm:pjgames|scumm:puttcircus|scumm:puttmoon|scumm:puttputt|scumm:puttrace|scumm:puttsfunshop|scumm:putttime|scumm:puttzoo|scumm:readtime|scumm:samsfunshop|scumm:soccer|scumm:soccermls|scumm:socks|scumm:spyfox|scumm:spyfox2|scumm:spyozon|scumm:thinker1|scumm:thinkerk|scumm:water'
    ),
    (
      Caption: 'Repair speech audio';
      Kind: sgokCheckbox;
      IniKey: 'audio_popfix_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:gk1[cd]'
    ),
    (
      Caption: 'Auto Move';
      Kind: sgokCheckbox;
      IniKey: 'auto_move';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nancy:nancy10|nancy:nancy11|nancy:nancy12|nancy:nancy13|nancy:nancy14|nancy:nancy15|nancy:nancy6|nancy:nancy7|nancy:nancy8|nancy:nancy9'
    ),
    (
      Caption: 'Suggest save names';
      Kind: sgokCheckbox;
      IniKey: 'auto_savenames';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:lol'
    ),
    (
      Caption: 'Automap (ScummVM feature)';
      Kind: sgokCheckbox;
      IniKey: 'automap';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:eob|kyra:eob2'
    ),
    (
      Caption: 'Automatic drilling';
      Kind: sgokCheckbox;
      IniKey: 'automatic_drilling';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'freescape:driller'
    ),
    (
      Caption: 'Backported music from C64 releases';
      Kind: sgokCheckbox;
      IniKey: 'ay_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'freescape:castlemaster[]|freescape:totaleclipse|freescape:totaleclipse2'
    ),
    (
      Caption: 'Use PAL timing for SID audio';
      Kind: sgokCheckbox;
      IniKey: 'c64_sid_type';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:maniac[c64,c64 demo]'
    ),
    (
      Caption: 'Camera moves with Silencer';
      Kind: sgokCheckbox;
      IniKey: 'camera_on_player';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:remorse'
    ),
    (
      Caption: 'Simulate loading times of old CD drives';
      Kind: sgokCheckbox;
      IniKey: 'cdromdelay';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:myst'
    ),
    (
      Caption: 'Character Speech';
      Kind: sgokCheckbox;
      IniKey: 'character_speech';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nancy:nancy1|nancy:nancy2|nancy:nancy3|nancy:nancy4|nancy:nancy5|nancy:vampirediaries'
    ),
    (
      Caption: 'Enable cheats';
      Kind: sgokCheckbox;
      IniKey: 'cheat';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:remorse|ultima:ultima8'
    ),
    (
      Caption: 'Color graphics';
      Kind: sgokCheckbox;
      IniKey: 'color';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'adl:hires1'
    ),
    (
      Caption: 'Pause when entering commands';
      Kind: sgokCheckbox;
      IniKey: 'commandpromptwindow';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:bc|agi:ddp|agi:goldrush|agi:kq1|agi:kq2|agi:kq3|agi:kq4|agi:lsl1|agi:mh1|agi:mh2|agi:mickey|agi:mixedup|agi:pq1|agi:sq1|agi:sq2|agi:troll|agi:winnie'
    ),
    (
      Caption: 'Enable title and copy protection screens (if present)';
      Kind: sgokCheckbox;
      IniKey: 'copy_protection';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:goldrush|agos:simon1[aga floppy,floppy,infocom floppy,ocs floppy]|agos:simon2[floppy]|agos:waxworks[floppy]|awe:anotherworld|dreamweb:dreamweb|gob:adibou1|gob:gob1|gob:gob2|lure:lure|mads:nebular[]|mads:nebular[fanmade,floppy]|mm:cloudsofxeen|mm:darksideofxeen|mm:swordsofxeen|mm:worldofxeen|saga:ite|scumm:atlantis[amiga,floppy,mac floppy]|scumm:loom[demo,ega,mac,no adlib]|scumm:maniac[remastered,v1,v2]|scumm:monkey2[]|scumm:monkey2[amiga,mac,se]|scumm:monkey[mac,vga]|scumm:zak[v1,v2]|tot:tot[]|voyeur:voyeur'
    ),
    (
      Caption: 'Correct movie aspect ratio';
      Kind: sgokCheckbox;
      IniKey: 'correct_movie_aspect';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'tetraedge:amerzone|tetraedge:syberia|tetraedge:syberia2'
    ),
    (
      Caption: 'Remove Black Bars';
      Kind: sgokCheckbox;
      IniKey: 'crop_black_bars';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'tinsel:dw2'
    ),
    (
      Caption: 'Load user patch (unsupported)';
      Kind: sgokCheckbox;
      IniKey: 'datausr_load';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'grim:grim|grim:monkey4'
    ),
    (
      Caption: 'Enable low latency audio mode';
      Kind: sgokCheckbox;
      IniKey: 'dimuse_low_latency_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:comi|scumm:dig|scumm:ft'
    ),
    (
      Caption: 'Skip EGA dithering pass (full color backgrounds)';
      Kind: sgokCheckbox;
      IniKey: 'disable_dithering';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:astrochicken|sci:camelot|sci:fairytales[ega]|sci:hoyle1|sci:hoyle2|sci:hoyle3[ega]|sci:iceman|sci:kq1sci|sci:kq4sci|sci:laurabow|sci:lsl2|sci:lsl3|sci:mothergoose[ega]|sci:pq2|sci:qfg1|sci:qfg2|sci:sq3'
    ),
    (
      Caption: 'Disable fade-out effects';
      Kind: sgokCheckbox;
      IniKey: 'disable_fade_effects';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agos:simon1|agos:simon2'
    ),
    (
      Caption: 'Disable screensaver';
      Kind: sgokCheckbox;
      IniKey: 'disable_screensaver';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'pelrock:pelrock'
    ),
    (
      Caption: 'Disable McCoy''s quick stamina drain';
      Kind: sgokCheckbox;
      IniKey: 'disable_stamina_drain';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner:bladerunner[]|bladerunner:bladerunner[game not implemented]'
    ),
    (
      Caption: 'Show FPS';
      Kind: sgokCheckbox;
      IniKey: 'display_fps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ags:ashinaredwitch|ags:awakening|ags:blackwell1|ags:blackwell2|ags:blackwell3|ags:blackwell4|ags:blackwell5|ags:danewguys2|ags:dreamswitchhouse|ags:excavationhb|ags:footballgame|ags:forest|ags:four|ags:framed|ags:geminirue|ags:goldenwake|ags:jamesperis|ags:jamesperis2|ags:justignorethem|ags:kathyrain|ags:life|ags:maniacmansiondeluxe|ags:mybigsister|ags:mybigsisterrm|ags:oldskies|ags:one|ags:openquest|ags:primordia|ags:redbow|ags:resonance|ags:rosewater|ags:shadowgate|ags:shardlight|ags:shivah|ags:shivahkosher|ags:spacemadness|ags:sq45|ags:sqdote|ags:sqinc|ags:sqvsb|ags:strangeland|ags:sumatra|ags:technobabylon|ags:unavowed|ags:whispersofamachine'
    ),
    (
      Caption: 'Use DOS version music tempos';
      Kind: sgokCheckbox;
      IniKey: 'dos_music_tempos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agos:simon1[25th anniversary edition,cd,cd demo,floppy,infocom cd,infocom floppy]|agos:simon1[]'
    ),
    (
      Caption: 'Double FPS';
      Kind: sgokCheckbox;
      IniKey: 'doublefps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'zvision:zgi|zvision:znemesis'
    ),
    (
      Caption: 'Easier AI';
      Kind: sgokCheckbox;
      IniKey: 'easier_ai';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'groovie:clandestiny[]|groovie:t7g[25th anniversary edition]|groovie:t7g[]|groovie:unclehenry'
    ),
    (
      Caption: 'Enable bearded musicians';
      Kind: sgokCheckbox;
      IniKey: 'enable_bearded_musicians';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:sq1sci'
    ),
    (
      Caption: 'Enable black-lined video';
      Kind: sgokCheckbox;
      IniKey: 'enable_black_lined_video';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:gk2[]|sci:lighthouse[]|sci:lsl7[]|sci:lsl7[fargus,softclub]|sci:phantasmagoria|sci:phantasmagoria2|sci:pqswat[]|sci:rama|sci:shivers|sci:sq6[]|sci:torin[]'
    ),
    (
      Caption: 'Enable content censoring';
      Kind: sgokCheckbox;
      IniKey: 'enable_censoring';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:phantasmagoria2'
    ),
    (
      Caption: 'Color Blind Mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_color_blind';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cge2:sfinx|cge:soltys'
    ),
    (
      Caption: 'Enable demo/kiosk mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_demo_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:maniac[remastered,v1]'
    ),
    (
      Caption: 'Gore Mode';
      Kind: sgokCheckbox;
      IniKey: 'enable_gore';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hopkins:hopkins'
    ),
    (
      Caption: 'Enable high resolution graphics';
      Kind: sgokCheckbox;
      IniKey: 'enable_high_resolution_graphics';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:castlebrain[]|sci:freddypharkas[]|sci:gk1[cd]|sci:kq6[]|sci:kq6[cd]|sci:lsl1sci[sci]|sci:lsl5[]|sci:lsl6[]|sci:pq4[cd]|sci:qfg1vga[vga]|sci:sq1sci[sci]'
    ),
    (
      Caption: 'Use high-quality video scaling';
      Kind: sgokCheckbox;
      IniKey: 'enable_hq_video';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:gk1[cd]|sci:gk2|sci:kq7[]|sci:lighthouse|sci:lsl7[]|sci:lsl7[fargus,softclub]|sci:phantasmagoria|sci:phantasmagoria2|sci:pqswat[]|sci:qfg4[cd]|sci:rama|sci:shivers|sci:sq6[]|sci:torin[]'
    ),
    (
      Caption: 'Host games over LAN';
      Kind: sgokCheckbox;
      IniKey: 'enable_lan_broadcast';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:football2002|scumm:moonbase'
    ),
    (
      Caption: 'Use high-quality "LarryScale" cel scaling';
      Kind: sgokCheckbox;
      IniKey: 'enable_larryscale';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:lsl7'
    ),
    (
      Caption: 'Simulate Sega colors';
      Kind: sgokCheckbox;
      IniKey: 'enable_sega_shadow_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:monkey[sega]'
    ),
    (
      Caption: 'Enable connection to Multiplayer Server';
      Kind: sgokCheckbox;
      IniKey: 'enable_session_server';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:football2002|scumm:moonbase'
    ),
    (
      Caption: 'Upscale videos';
      Kind: sgokCheckbox;
      IniKey: 'enable_video_upscale';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:kq7[]|sci:pqswat[]'
    ),
    (
      Caption: 'Extended game resolution';
      Kind: sgokCheckbox;
      IniKey: 'extended_viewport';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bolt:carnival'
    ),
    (
      Caption: 'Pixellated scene transitions';
      Kind: sgokCheckbox;
      IniKey: 'fade_style';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sherlock:scalpel'
    ),
    (
      Caption: 'Fast movie speed';
      Kind: sgokCheckbox;
      IniKey: 'fast_movie_speed';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'groovie:t7g'
    ),
    (
      Caption: 'Extend endgame timer';
      Kind: sgokCheckbox;
      IniKey: 'final_timer';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nancy:nancy2'
    ),
    (
      Caption: 'Better fit for dialog balloons';
      Kind: sgokCheckbox;
      IniKey: 'fit_dialog_balloons';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'eem:eem2'
    ),
    (
      Caption: 'Fix audio pops/clicks';
      Kind: sgokCheckbox;
      IniKey: 'fix_audio_pops';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:arthur|mohawk:arthurbday|mohawk:beardark|mohawk:bearfight|mohawk:create|mohawk:daniel|mohawk:grandma|mohawk:greeneggs|mohawk:harryhh|mohawk:lilmonster|mohawk:newkid|mohawk:noah|mohawk:ruff|mohawk:seussabc|mohawk:sheila|mohawk:stellaluna|mohawk:tortoise'
    ),
    (
      Caption: 'Floating cursors';
      Kind: sgokCheckbox;
      IniKey: 'floating_cursors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:lol'
    ),
    (
      Caption: 'Enable font anti-aliasing';
      Kind: sgokCheckbox;
      IniKey: 'font_antialiasing';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:ultima8'
    ),
    (
      Caption: 'Enable font replacement';
      Kind: sgokCheckbox;
      IniKey: 'font_override';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:ultima8'
    ),
    (
      Caption: 'Play foot step sounds';
      Kind: sgokCheckbox;
      IniKey: 'footsteps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:ultima8'
    ),
    (
      Caption: 'Run in original 640 x 480 resolution';
      Kind: sgokCheckbox;
      IniKey: 'force_fmtowns_hires_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:atlantis[fm-towns]|scumm:indy3[fm-towns]|scumm:indyloom|scumm:indyzak|scumm:loom[fm-towns]|scumm:monkey2[fm-towns]|scumm:zak[fm-towns]|scumm:zakloom'
    ),
    (
      Caption: 'Force antialiased text';
      Kind: sgokCheckbox;
      IniKey: 'force_text_aa';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ags:ashinaredwitch|ags:awakening|ags:blackwell1|ags:blackwell2|ags:blackwell3|ags:blackwell4|ags:blackwell5|ags:danewguys2|ags:dreamswitchhouse|ags:excavationhb|ags:footballgame|ags:forest|ags:four|ags:framed|ags:geminirue|ags:goldenwake|ags:jamesperis|ags:jamesperis2|ags:justignorethem|ags:kathyrain|ags:life|ags:maniacmansiondeluxe|ags:mybigsister|ags:mybigsisterrm|ags:oldskies|ags:one|ags:openquest|ags:primordia|ags:redbow|ags:resonance|ags:rosewater|ags:shadowgate|ags:shardlight|ags:shivah|ags:shivahkosher|ags:spacemadness|ags:sq45|ags:sqdote|ags:sqinc|ags:sqvsb|ags:strangeland|ags:sumatra|ags:technobabylon|ags:unavowed|ags:whispersofamachine'
    ),
    (
      Caption: 'Enable frame limiting';
      Kind: sgokCheckbox;
      IniKey: 'frameLimit';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:remorse|ultima:ultima8'
    ),
    (
      Caption: 'Enable frame skipping';
      Kind: sgokCheckbox;
      IniKey: 'frameSkip';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:remorse|ultima:ultima8'
    ),
    (
      Caption: 'Max frames per second limit';
      Kind: sgokCheckbox;
      IniKey: 'frames_per_secondfl';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner:bladerunner'
    ),
    (
      Caption: 'Improve Selenitic Age puzzle accessibility';
      Kind: sgokCheckbox;
      IniKey: 'fuzzy_logic';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:myst[]|mohawk:myst[masterpiece edition]'
    ),
    (
      Caption: 'Generate random maps';
      Kind: sgokCheckbox;
      IniKey: 'generate_random_maps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:moonbase'
    ),
    (
      Caption: 'Enable saving via the GMM';
      Kind: sgokCheckbox;
      IniKey: 'gmm_save_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:astrochicken|sci:camelot|sci:castlebrain|sci:ecoquest|sci:ecoquest2|sci:fairytales|sci:freddypharkas|sci:gk1|sci:gk2|sci:hoyle1|sci:hoyle2|sci:hoyle3|sci:hoyle4|sci:hoyle5|sci:iceman|sci:islandbrain|sci:kq1sci|sci:kq4sci|sci:kq5|sci:kq6|sci:kq7|sci:laurabow|sci:laurabow2|sci:lighthouse[]|sci:longbow|sci:lsl1sci|sci:lsl2|sci:lsl3|sci:lsl5|sci:lsl6|sci:lsl6hires|sci:lsl7[]|sci:lsl7[fargus,softclub]|sci:mothergoose|sci:mothergoose256|sci:pepper|sci:phantasmagoria2|sci:pq1sci|sci:pq2|sci:pq3|sci:pq4|sci:pqswat|sci:qfg1[]|sci:qfg1[demo]|sci:qfg1vga|sci:qfg2|sci:qfg3|sci:qfg4|sci:shivers|sci:slater|sci:sq1sci|sci:sq3|sci:sq4|sci:sq5|sci:sq6|sci:torin'
    ),
    (
      Caption: 'Enable gore';
      Kind: sgokCheckbox;
      IniKey: 'gore';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'harvester:harvester'
    ),
    (
      Caption: 'Helium mode';
      Kind: sgokCheckbox;
      IniKey: 'helium_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:kyra3'
    ),
    (
      Caption: 'Don''t show hotspots when moving mouse';
      Kind: sgokCheckbox;
      IniKey: 'help_style';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sherlock:rosetattoo|sherlock:scalpel'
    ),
    (
      Caption: 'Use Hercules hires font';
      Kind: sgokCheckbox;
      IniKey: 'herculesfont';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:bc|agi:ddp|agi:goldrush|agi:kq1|agi:kq2|agi:kq3|agi:kq4|agi:lsl1|agi:mh1|agi:mh2|agi:mickey|agi:mixedup|agi:pq1|agi:sq1|agi:sq2|agi:troll|agi:winnie'
    ),
    (
      Caption: 'Hide the highlight boxes';
      Kind: sgokCheckbox;
      IniKey: 'hide_highlight_boxes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'eem:eem2'
    ),
    (
      Caption: 'High Quality';
      Kind: sgokCheckbox;
      IniKey: 'high_quality';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'alcachofa:aventuradecine'
    ),
    (
      Caption: 'Enable high quality panoramas';
      Kind: sgokCheckbox;
      IniKey: 'highquality';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'zvision:zgi|zvision:znemesis'
    ),
    (
      Caption: 'HP bar graphs';
      Kind: sgokCheckbox;
      IniKey: 'hpbargraphs';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:eob|kyra:eob2'
    ),
    (
      Caption: 'Classic Sentence';
      Kind: sgokCheckbox;
      IniKey: 'hudSentence';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp:twp'
    ),
    (
      Caption: 'Enable cheat mode';
      Kind: sgokCheckbox;
      IniKey: 'hypercheat';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hdb:hdb'
    ),
    (
      Caption: 'Improved mode';
      Kind: sgokCheckbox;
      IniKey: 'improved';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'supernova:msn1|supernova:msn2'
    ),
    (
      Caption: 'Easy mouse interface';
      Kind: sgokCheckbox;
      IniKey: 'interface_hotspots';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mads:dragonsphere|mads:nebular|mads:phantom'
    ),
    (
      Caption: 'Play a digital soundtrack during the opening movie';
      Kind: sgokCheckbox;
      IniKey: 'intro_music_digital';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'made:rtz'
    ),
    (
      Caption: 'Animated inventory items';
      Kind: sgokCheckbox;
      IniKey: 'inventory_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mads:nebular'
    ),
    (
      Caption: 'Invert verb colors';
      Kind: sgokCheckbox;
      IniKey: 'invertVerbHighlight';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp:twp'
    ),
    (
      Caption: 'Overture Timing';
      Kind: sgokInteger;
      IniKey: 'loom_overture_ticks';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:loom[demo,ega,mac,no adlib]'
    ),
    (
      Caption: 'Playback Adjust';
      Kind: sgokInteger;
      IniKey: 'loom_playback_adjustment';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:loom[vga]'
    ),
    (
      Caption: 'Intro Adjust';
      Kind: sgokInteger;
      IniKey: 'mi1_intro_adjustment';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:monkey[cd,fm-towns,sega]'
    ),
    (
      Caption: 'Outlook Adjust';
      Kind: sgokInteger;
      IniKey: 'mi1_outlook_adjustment';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:monkey[cd,fm-towns,sega]'
    ),
    (
      Caption: 'MIDI mode';
      Kind: sgokInteger;
      IniKey: 'midi_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agos:elvira1|sci:astrochicken|sci:camelot|sci:castlebrain|sci:ecoquest|sci:ecoquest2|sci:fairytales|sci:freddypharkas|sci:hoyle1|sci:hoyle2|sci:hoyle3|sci:hoyle4|sci:iceman|sci:islandbrain|sci:jones|sci:kq1sci|sci:kq4sci|sci:kq5|sci:kq6|sci:laurabow|sci:laurabow2|sci:longbow|sci:lsl1sci|sci:lsl2|sci:lsl3|sci:lsl5|sci:lsl6|sci:mothergoose|sci:mothergoose256|sci:pepper|sci:pq1sci|sci:pq2|sci:pq3|sci:qfg1|sci:qfg1vga|sci:qfg2|sci:qfg3|sci:slater|sci:sq1sci|sci:sq3|sci:sq4|sci:sq5'
    ),
    (
      Caption: 'Use NES Classic Palette';
      Kind: sgokCheckbox;
      IniKey: 'mm_nes_classic_palette';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:maniac[nes]'
    ),
    (
      Caption: 'Mono music';
      Kind: sgokCheckbox;
      IniKey: 'mono_sound';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kingdom:kingdom'
    ),
    (
      Caption: 'Always use sharp monochrome text';
      Kind: sgokCheckbox;
      IniKey: 'monotext';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'adl:hires1'
    ),
    (
      Caption: 'Fight Button L/R Swap';
      Kind: sgokCheckbox;
      IniKey: 'mousebtswap';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:eob|kyra:eob2'
    ),
    (
      Caption: 'Mouse support';
      Kind: sgokCheckbox;
      IniKey: 'mousesupport';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:bc|agi:ddp|agi:goldrush|agi:kq1|agi:kq2|agi:kq3|agi:kq4|agi:lsl1|agi:mh1|agi:mh2|agi:mickey|agi:mixedup|agi:pq1|agi:sq1|agi:sq2|agi:troll|agi:winnie'
    ),
    (
      Caption: 'Enhanced thrown weapon reload';
      Kind: sgokCheckbox;
      IniKey: 'mreload';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:eob|kyra:eob2'
    ),
    (
      Caption: 'Autosave at progress points';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_auto_save_at_checkpoints';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mtropolis:obsidian[cd]'
    ),
    (
      Caption: '16:9 widescreen mod';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_obsidian_widescreen';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mtropolis:obsidian'
    ),
    (
      Caption: 'Enable subtitles for important sound effects';
      Kind: sgokCheckbox;
      IniKey: 'mtropolis_mod_sound_gameplay_subtitles';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mtropolis:obsidian[cd]'
    ),
    (
      Caption: 'Naughty game mode';
      Kind: sgokCheckbox;
      IniKey: 'naughtiness';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mads:nebular'
    ),
    (
      Caption: 'Disable animation while turning';
      Kind: sgokCheckbox;
      IniKey: 'noanimwhileturning';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'zvision:zgi|zvision:znemesis'
    ),
    (
      Caption: 'Frame limiter high performance mode';
      Kind: sgokCheckbox;
      IniKey: 'nodelaymillisfl';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner:bladerunner'
    ),
    (
      Caption: 'Fix Ileria and Beohram NPCs';
      Kind: sgokCheckbox;
      IniKey: 'npcpatch';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:eob'
    ),
    (
      Caption: 'TV emulation';
      Kind: sgokCheckbox;
      IniKey: 'ntsc';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'adl:hires1'
    ),
    (
      Caption: 'Show Object Line';
      Kind: sgokCheckbox;
      IniKey: 'object_labels';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:comi'
    ),
    (
      Caption: 'Use ''high definition'' OGG music';
      Kind: sgokCheckbox;
      IniKey: 'ogg_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'access:noctropolis'
    ),
    (
      Caption: 'AdLib OPL3 mode';
      Kind: sgokCheckbox;
      IniKey: 'opl3_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agos:elvira1|agos:elvira2|agos:simon1[25th anniversary edition,cd,cd demo,floppy,floppy demo,infocom cd,infocom floppy]|agos:simon1[]|agos:waxworks|tot:tot'
    ),
    (
      Caption: 'Backported music from C64 releases (AdLib)';
      Kind: sgokCheckbox;
      IniKey: 'opl_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'freescape:castlemaster[demo,virtual worlds]|freescape:darkside|freescape:driller[]|freescape:totaleclipse[]'
    ),
    (
      Caption: 'Enable the original GUI and Menu';
      Kind: sgokCheckbox;
      IniKey: 'original_gui';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:activity|scumm:atlantis|scumm:brstorm|scumm:comi|scumm:dig|scumm:fbear[he 62]|scumm:fbpack|scumm:ft|scumm:funpack|scumm:indy3|scumm:indyloom|scumm:indyzak|scumm:loom[demo,ega,fm-towns,mac,no adlib,steam,vga]|scumm:maniac|scumm:monkey|scumm:monkey2[]|scumm:monkey2[amiga,fm-towns,mac,se,se talkie]|scumm:pass|scumm:puttmoon[]|scumm:puttmoon[demo]|scumm:puttputt|scumm:samnmax|scumm:tentacle|scumm:zak|scumm:zakloom'
    ),
    (
      Caption: 'Use original Macintosh menus (experimental)';
      Kind: sgokCheckbox;
      IniKey: 'original_mac_menus';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mads:nebular[]'
    ),
    (
      Caption: 'Use original save/load screens';
      Kind: sgokCheckbox;
      IniKey: 'original_menus';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'chewy:chewy|macs2:sis|mads:dragonsphere|mads:forest|mads:nebular|mads:phantom|pelrock:pelrock'
    ),
    (
      Caption: 'Use original save/load screens';
      Kind: sgokCheckbox;
      IniKey: 'originalsaveload';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:bc|agi:ddp|agi:goldrush|agi:kq1|agi:kq2|agi:kq3|agi:kq4|agi:lsl1|agi:mh1|agi:mh2|agi:mickey|agi:mixedup|agi:pq1|agi:sq1|agi:sq2|agi:troll|agi:winnie|groovie:clandestiny[]|groovie:t7g[25th anniversary edition]|groovie:t7g[]|nancy:nancy1|nancy:nancy10|nancy:nancy11|nancy:nancy12|nancy:nancy13|nancy:nancy14|nancy:nancy15|nancy:nancy2|nancy:nancy3|nancy:nancy4|nancy:nancy5|nancy:nancy6|nancy:nancy7|nancy:nancy8|nancy:nancy9|nancy:vampirediaries|neverhood:neverhood|sci:astrochicken|sci:camelot|sci:castlebrain|sci:ecoquest|sci:ecoquest2|sci:fairytales|sci:freddypharkas|sci:gk1|sci:gk2[]|sci:hoyle1|sci:hoyle2|sci:hoyle3|sci:hoyle4|sci:hoyle5|sci:iceman|sci:islandbrain|sci:kq1sci|sci:kq4sci|sci:kq5|sci:kq6|sci:laurabow|sci:laurabow2|sci:lighthouse[]|sci:longbow|sci:lsl1sci|sci:lsl2|sci:lsl3|sci:lsl5|sci:lsl6|sci:lsl6hires|sci:lsl7[]|sci:lsl7[fargus,softclub]|sci:mothergoose' +
               '|sci:mothergoose256|sci:pepper|sci:phantasmagoria2|sci:pq1sci|sci:pq2|sci:pq3|sci:pq4|sci:qfg1|sci:qfg1vga|sci:qfg2|sci:qfg3|sci:qfg4|sci:rama[]|sci:slater|sci:sq1sci|sci:sq3|sci:sq4|sci:sq5|sci:sq6[]|sci:torin[]|sherlock:rosetattoo|sherlock:scalpel|toltecs:toltecs|tot:tot|ultima:ultima8|zvision:zgi|zvision:znemesis'
    ),
    (
      Caption: 'Use per-resource modified palettes';
      Kind: sgokCheckbox;
      IniKey: 'palette_mods';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:lsl2|sci:sq3'
    ),
    (
      Caption: 'Play intro';
      Kind: sgokCheckbox;
      IniKey: 'play_intro';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'pelrock:pelrock'
    ),
    (
      Caption: 'Player Speech';
      Kind: sgokCheckbox;
      IniKey: 'player_speech';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nancy:nancy1|nancy:nancy2|nancy:nancy3|nancy:nancy4|nancy:nancy5|nancy:vampirediaries'
    ),
    (
      Caption: 'Play the Myst fly by movie';
      Kind: sgokCheckbox;
      IniKey: 'playmystflyby';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:myst[]|mohawk:myst[masterpiece edition]'
    ),
    (
      Caption: 'Show character portraits';
      Kind: sgokCheckbox;
      IniKey: 'portraits_on';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sherlock:scalpel'
    ),
    (
      Caption: 'Predictive Input Dialog on mouse click';
      Kind: sgokCheckbox;
      IniKey: 'predictivedlgonmouseclick';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agi:bc|agi:ddp|agi:goldrush|agi:kq1|agi:kq2|agi:kq3|agi:kq4|agi:lsl1|agi:mh1|agi:mh2|agi:mickey|agi:mixedup|agi:pq1|agi:sq1|agi:sq2|agi:troll|agi:winnie'
    ),
    (
      Caption: 'Prefer digital sound effects';
      Kind: sgokCheckbox;
      IniKey: 'prefer_digitalsfx';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agos:elvira2|agos:waxworks|sci:astrochicken|sci:camelot|sci:castlebrain|sci:ecoquest|sci:ecoquest2|sci:fairytales|sci:freddypharkas|sci:hoyle1|sci:hoyle2|sci:hoyle3|sci:hoyle4|sci:iceman|sci:islandbrain|sci:jones|sci:kq1sci|sci:kq4sci|sci:kq5|sci:kq6|sci:laurabow|sci:laurabow2|sci:longbow|sci:lsl1sci|sci:lsl2|sci:lsl3|sci:lsl5|sci:lsl6|sci:mothergoose|sci:mothergoose256|sci:pepper|sci:pq1sci|sci:pq2|sci:pq3|sci:qfg1|sci:qfg1vga|sci:qfg2|sci:qfg3|sci:slater|sci:sq1sci|sci:sq3|sci:sq4|sci:sq5'
    ),
    (
      Caption: 'Ransome *unbeeped* (DLC)';
      Kind: sgokCheckbox;
      IniKey: 'ransomeUnbeeped';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp:twp'
    ),
    (
      Caption: 'No damage';
      Kind: sgokCheckbox;
      IniKey: 'rebel1_no_damage';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:rebel1'
    ),
    (
      Caption: 'Unlock all levels';
      Kind: sgokCheckbox;
      IniKey: 'rebel1_unlock_all';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:rebel1'
    ),
    (
      Caption: 'High resolution mode';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_hires';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:rebel2[]|scumm:rebel2[demo da1.06,demo db1.03,demo dg1.15,demo special edition,demo v1.0]'
    ),
    (
      Caption: 'No damage';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_no_damage';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:rebel2'
    ),
    (
      Caption: 'Unlock all levels';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_unlock_all';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:rebel2'
    ),
    (
      Caption: 'Yoda mode';
      Kind: sgokCheckbox;
      IniKey: 'rebel2_yoda_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:rebel2'
    ),
    (
      Caption: 'Repeat useful Willie''s hint';
      Kind: sgokCheckbox;
      IniKey: 'repeatwilliehint';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'neverhood:neverhood'
    ),
    (
      Caption: 'Enable restored main menu content';
      Kind: sgokCheckbox;
      IniKey: 'restore_main_menu_content';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mads:phantom[]|mads:phantom[cd]'
    ),
    (
      Caption: 'Restore missing scenes';
      Kind: sgokCheckbox;
      IniKey: 'restore_scenes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'tetraedge:syberia[]'
    ),
    (
      Caption: 'Retro Fonts';
      Kind: sgokCheckbox;
      IniKey: 'retroFonts';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp:twp'
    ),
    (
      Caption: 'Retro Verbs';
      Kind: sgokCheckbox;
      IniKey: 'retroVerbs';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp:twp'
    ),
    (
      Caption: 'Use RGB rendering';
      Kind: sgokCheckbox;
      IniKey: 'rgb_rendering';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:astrochicken|sci:camelot|sci:castlebrain|sci:ecoquest|sci:ecoquest2|sci:fairytales|sci:freddypharkas|sci:hoyle1|sci:hoyle2|sci:hoyle3|sci:hoyle4|sci:iceman|sci:islandbrain|sci:jones|sci:kq1sci|sci:kq4sci|sci:kq5|sci:kq6|sci:kquestions|sci:laurabow|sci:laurabow2|sci:longbow|sci:lsl1sci|sci:lsl2|sci:lsl3|sci:lsl5|sci:lsl6|sci:mothergoose|sci:mothergoose256|sci:pepper|sci:pq1sci|sci:pq2|sci:pq3|sci:qfg1|sci:qfg1vga|sci:qfg2|sci:qfg3|sci:slater|sci:sq1sci|sci:sq3|sci:sq4|sci:sq5'
    ),
    (
      Caption: 'Enable rock travel';
      Kind: sgokCheckbox;
      IniKey: 'rock_travel';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'freescape:castlemaster'
    ),
    (
      Caption: 'Enable ScummVM save management';
      Kind: sgokCheckbox;
      IniKey: 'save_override';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ags:ashinaredwitch[steam]|ags:blackwell1[gog.com,steam]|ags:blackwell2[gog.com,steam]|ags:blackwell3[gog.com,steam]|ags:blackwell4[gog.com,steam]|ags:blackwell5[gog.com,steam]|ags:dreamswitchhouse[gog.com,steam]|ags:excavationhb|ags:geminirue[gog.com]|ags:kathyrain[amazon games,gog.com,steam]|ags:mybigsister[steam]|ags:mybigsisterrm|ags:oldskies[gog.com,steam]|ags:primordia[gog.com,steam]|ags:redbow[steam,switch]|ags:rosewater[gog.com,steam]|ags:shardlight[gog.com,steam]|ags:shivahkosher[gog.com,steam]|ags:strangeland|ags:technobabylon[gog.com,steam]|ags:unavowed|ags:whispersofamachine'
    ),
    (
      Caption: 'Scale the making of videos to full screen';
      Kind: sgokCheckbox;
      IniKey: 'scalemakingofvideos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'neverhood:neverhood'
    ),
    (
      Caption: 'Show scanlines';
      Kind: sgokCheckbox;
      IniKey: 'scanlines';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'adl:hires1'
    ),
    (
      Caption: 'Show wait cursor when paused';
      Kind: sgokCheckbox;
      IniKey: 'sega_cd_wait_cursor_when_paused';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:monkey[sega]'
    ),
    (
      Caption: 'Allow semi-smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'semi_smooth_scroll';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:loom[fm-towns]'
    ),
    (
      Caption: 'SFX mode';
      Kind: sgokInteger;
      IniKey: 'sfx_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'darkseed:darkseed'
    ),
    (
      Caption: 'Shorty mode';
      Kind: sgokCheckbox;
      IniKey: 'shorty';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner:bladerunner[]|bladerunner:bladerunner[game not implemented]'
    ),
    (
      Caption: 'Show CD change prompts';
      Kind: sgokCheckbox;
      IniKey: 'show_cd_change_prompts';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'harvester:harvester[]|harvester:harvester[european release]'
    ),
    (
      Caption: 'Show FPS';
      Kind: sgokCheckbox;
      IniKey: 'show_fps';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'grim:grim|grim:monkey4'
    ),
    (
      Caption: 'Use silver cursors';
      Kind: sgokCheckbox;
      IniKey: 'silver_cursors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:sq4[cd]'
    ),
    (
      Caption: 'Use lower quality single speed CD-ROM video';
      Kind: sgokCheckbox;
      IniKey: 'single_speed_videos';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'alg:cpatrol|alg:dwars|alg:johnroc|alg:lbhunter|alg:maddog2|alg:spirates'
    ),
    (
      Caption: 'Sitcom mode';
      Kind: sgokCheckbox;
      IniKey: 'sitcom';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner:bladerunner[]|bladerunner:bladerunner[game not implemented]'
    ),
    (
      Caption: 'Skip support';
      Kind: sgokCheckbox;
      IniKey: 'skip_support';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:kyra3'
    ),
    (
      Caption: 'Skip the Hall of Records storyboard scenes';
      Kind: sgokCheckbox;
      IniKey: 'skiphallofrecordsscenes';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'neverhood:neverhood'
    ),
    (
      Caption: 'Slim Left/Right Hotspots';
      Kind: sgokCheckbox;
      IniKey: 'slim_hotspots';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'groovie:clandestiny|groovie:t7g|groovie:tlc|groovie:unclehenry'
    ),
    (
      Caption: 'Smoother movement';
      Kind: sgokCheckbox;
      IniKey: 'smooth_movement';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'freescape:totaleclipse|freescape:totaleclipse2'
    ),
    (
      Caption: 'Enable smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'smooth_scroll';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:atlantis[fm-towns]|scumm:indy3[fm-towns]|scumm:indyloom|scumm:indyzak|scumm:loom[fm-towns]|scumm:monkey2[fm-towns]|scumm:zak[fm-towns]|scumm:zakloom'
    ),
    (
      Caption: 'Smooth scrolling';
      Kind: sgokCheckbox;
      IniKey: 'smooth_scrolling';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:lol'
    ),
    (
      Caption: 'Fix softlocks';
      Kind: sgokCheckbox;
      IniKey: 'softlocks_fix';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'nancy:nancy2|nancy:nancy5|nancy:nancy6|nancy:nancy7'
    ),
    (
      Caption: 'Speedrun Mode';
      Kind: sgokCheckbox;
      IniKey: 'speedrun_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'groovie:clandestiny|groovie:t7g|groovie:tlc|groovie:unclehenry'
    ),
    (
      Caption: 'Studio audience';
      Kind: sgokCheckbox;
      IniKey: 'studio_audience';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'kyra:kyra3'
    ),
    (
      Caption: 'Text language';
      Kind: sgokInteger;
      IniKey: 'subtitles_language_override';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sword1:sword1[25th anniversary,english speech,gog.com,rerelease,soldout rerelease,steam,tectoy]|sword1:sword1[]'
    ),
    (
      Caption: 'Enable jump to mouse position';
      Kind: sgokCheckbox;
      IniKey: 'targetedjump';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:ultima8'
    ),
    (
      Caption: 'Filter textures';
      Kind: sgokCheckbox;
      IniKey: 'tex_filter';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'alcachofa:aventuradecine|alcachofa:terror|alcachofa:vaqueros'
    ),
    (
      Caption: 'Toilet paper over';
      Kind: sgokCheckbox;
      IniKey: 'toiletPaperOver';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'twp:twp'
    ),
    (
      Caption: 'Transitions';
      Kind: sgokInteger;
      IniKey: 'transition_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:riven'
    ),
    (
      Caption: 'Transitions Enabled';
      Kind: sgokCheckbox;
      IniKey: 'transition_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:myst'
    ),
    (
      Caption: 'Disable scene transitions';
      Kind: sgokCheckbox;
      IniKey: 'transitions_disable';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'tot:tot'
    ),
    (
      Caption: 'Transparent windows';
      Kind: sgokCheckbox;
      IniKey: 'transparent_windows';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sherlock:rosetattoo'
    ),
    (
      Caption: 'Trim FM-TOWNS games to 200 pixels height';
      Kind: sgokCheckbox;
      IniKey: 'trim_fmtowns_to_200_pixels';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:atlantis[fm-towns]|scumm:indy3[fm-towns]|scumm:indyloom|scumm:indyzak|scumm:monkey2[fm-towns]|scumm:zak[fm-towns]|scumm:zakloom'
    ),
    (
      Caption: 'Enable Text to Speech';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'adl:hires1|agi:bc|agi:ddp|agi:goldrush|agi:kq1|agi:kq2|agi:kq3|agi:kq4|agi:lsl1|agi:mh1|agi:mh2|agi:mickey|agi:mixedup|agi:pq1|agi:sq1|agi:sq2|agi:troll|agi:winnie|cge:soltys|cruise:cruise|drascula:drascula|efh:efh|got:got|griffon:griffon|hugo:hugo1|hugo:hugo2|hugo:hugo3|macs2:sis|mm:cloudsofxeen|mm:darksideofxeen|mm:mm1|mm:swordsofxeen|mm:worldofxeen|mortevielle:mortevielle|parallaction:nippon|sci:astrochicken|sci:camelot|sci:castlebrain|sci:ecoquest2|sci:ecoquest[demo,floppy]|sci:fairytales|sci:freddypharkas[]|sci:freddypharkas[demo,floppy]|sci:gk1[]|sci:hoyle1|sci:hoyle2|sci:hoyle3|sci:hoyle4[demo]|sci:iceman|sci:islandbrain[demo]|sci:jones[]|sci:jones[ega]|sci:kq1sci|sci:kq4sci|sci:kq5[]|sci:kq5[ega]|sci:kq6[]|sci:kq6[demo]|sci:laurabow|sci:laurabow2[]|sci:laurabow2[demo]|sci:longbow|sci:lsl1sci|sci:lsl2|sci:lsl3|sci:lsl5|sci:lsl6[]|sci:mothergoose|sci:mothergoose256[]' +
               '|sci:mothergoose256[demo]|sci:pepper|sci:pq1sci|sci:pq2|sci:pq3|sci:pq4[]|sci:qfg1[]|sci:qfg1[demo]|sci:qfg1vga|sci:qfg2|sci:qfg3|sci:qfg4[]|sci:sq1sci|sci:sq3|sci:sq4[]|sci:sq4[ega]|sci:sq5|scumm:activity|scumm:airport|scumm:arttime|scumm:atlantis|scumm:balloon|scumm:baseball|scumm:baseball2003|scumm:basketball|scumm:blues123time|scumm:bluesabctime|scumm:bluesbirthday|scumm:bluestreasurehunt|scumm:brstorm|scumm:catalog|scumm:chase|scumm:comi|scumm:dig|scumm:dog|scumm:farm|scumm:fbear|scumm:fbpack|scumm:freddi|scumm:freddi2|scumm:freddi3|scumm:freddi4|scumm:freddicove|scumm:freddisfunshop|scumm:ft|scumm:funpack|scumm:indy3|scumm:indyloom|scumm:indyzak|scumm:jungle|scumm:loom|scumm:lost|scumm:maniac|scumm:maze|scumm:monkey|scumm:monkey2|scumm:mustard|scumm:pajama|scumm:pajama2|scumm:pajama3|scumm:pass|scumm:pjgames|scumm:puttcircus|scumm:puttmoon|scumm:puttputt|scumm:puttrace' +
               '|scumm:puttsfunshop|scumm:putttime|scumm:puttzoo|scumm:readtime|scumm:samnmax|scumm:samsfunshop|scumm:soccer|scumm:soccer2004|scumm:soccermls|scumm:socks|scumm:spyfox|scumm:spyfox2|scumm:spyozon|scumm:tentacle|scumm:thinker1|scumm:thinkerk|scumm:water|scumm:zak|scumm:zakloom|supernova:msn1|supernova:msn2'
    ),
    (
      Caption: 'Enable Text to Speech for Missing Voiceovers';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_missing_voice';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'prince:prince'
    ),
    (
      Caption: 'Enable Text to Speech for Objects and Options';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_objects';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cge2:sfinx|draci:draci|prince:prince|teenagent:teenagent'
    ),
    (
      Caption: 'Enable Text to Speech for Subtitles';
      Kind: sgokCheckbox;
      IniKey: 'tts_enabled_speech';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'cge2:sfinx[demo,freeware v0.3]|draci:draci|prince:prince[]|teenagent:teenagent[]|teenagent:teenagent[alt demo,alt version,demo]'
    ),
    (
      Caption: 'TTS Narrator';
      Kind: sgokCheckbox;
      IniKey: 'tts_narrator';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'lure:lure[ega,konami vga,vga]|mads:nebular[]|mads:nebular[floppy]|sherlock:scalpel'
    ),
    (
      Caption: 'Use CD audio';
      Kind: sgokCheckbox;
      IniKey: 'use_cdaudio';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sci:jones[cd]'
    ),
    (
      Caption: 'Show subtitles during text crawl';
      Kind: sgokCheckbox;
      IniKey: 'use_crawl_subs';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'bladerunner:bladerunner[]|bladerunner:bladerunner[game not implemented]'
    ),
    (
      Caption: 'Use floppy version music';
      Kind: sgokCheckbox;
      IniKey: 'use_floppy_music';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'darkseed:darkseed'
    ),
    (
      Caption: 'Use Italian speech pack';
      Kind: sgokCheckbox;
      IniKey: 'use_it_voices';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'wintermute:sotv1|wintermute:sotv2'
    ),
    (
      Caption: 'Use Pro Audio Spectrum 16 instead of AdLib';
      Kind: sgokCheckbox;
      IniKey: 'use_pas';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mads:dragonsphere[]|mads:dragonsphere[cd,demo]|mads:nebular[]|mads:nebular[demo,floppy]|mads:phantom[]|mads:phantom[cd,demo]'
    ),
    (
      Caption: 'Use remastered audio';
      Kind: sgokCheckbox;
      IniKey: 'use_remastered_audio';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:monkey2[se]|scumm:monkey[se]|scumm:tentacle[remastered]'
    ),
    (
      Caption: 'Run SD version (1280x800)';
      Kind: sgokCheckbox;
      IniKey: 'use_sd_assets';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'wintermute:sotv1|wintermute:sotv2'
    ),
    (
      Caption: 'Use original Acorn system cursor';
      Kind: sgokCheckbox;
      IniKey: 'use_system_cursor';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'agos:simon1[cd,cd demo,floppy,floppy demo]'
    ),
    (
      Caption: 'Use Windows interface';
      Kind: sgokCheckbox;
      IniKey: 'use_windows_interface';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hugo:hugo1|hugo:hugo2|hugo:hugo3'
    ),
    (
      Caption: 'Enable high resolution';
      Kind: sgokCheckbox;
      IniKey: 'usehighres';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'ultima:remorse|ultima:ultima8'
    ),
    (
      Caption: 'Faster video decoder (lower quality)';
      Kind: sgokCheckbox;
      IniKey: 'vcruise_fast_video_decoder';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'vcruise:schizm'
    ),
    (
      Caption: 'Enable Venus';
      Kind: sgokCheckbox;
      IniKey: 'venusenabled';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'zvision:znemesis'
    ),
    (
      Caption: 'WASD controls';
      Kind: sgokCheckbox;
      IniKey: 'wasd_controls';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'freescape:castlemaster|freescape:totaleclipse|freescape:totaleclipse2'
    ),
    (
      Caption: 'Water Effect Enabled';
      Kind: sgokCheckbox;
      IniKey: 'water_effects';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:riven'
    ),
    (
      Caption: 'Underwater base shooter enhancements';
      Kind: sgokCheckbox;
      IniKey: 'wbase_enhancements';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hopkins:hopkins[]'
    ),
    (
      Caption: 'Underwater base shooter Forced Autoplay';
      Kind: sgokCheckbox;
      IniKey: 'wbase_forced_autoplay';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'hopkins:hopkins[]'
    ),
    (
      Caption: 'Enable widescreen support';
      Kind: sgokCheckbox;
      IniKey: 'widescreen';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'zvision:zgi|zvision:znemesis'
    ),
    (
      Caption: 'Slide dialogs into view';
      Kind: sgokCheckbox;
      IniKey: 'window_style';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sherlock:scalpel'
    ),
    (
      Caption: 'Simulate the audio engine from the Windows executable';
      Kind: sgokCheckbox;
      IniKey: 'windows_audio_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'sword1:sword1'
    ),
    (
      Caption: 'Use Windows cursors';
      Kind: sgokCheckbox;
      IniKey: 'windows_cursors';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'made:rodney|sci:ecoquest2[cd]|sci:kq5[cd]|sci:kq6[]|sci:kq6[cd]|sci:laurabow2[cd]|sci:pepper[]|sci:sq4[cd]'
    ),
    (
      Caption: 'Zip Mode Activated';
      Kind: sgokCheckbox;
      IniKey: 'zip_mode';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'mohawk:myst[]|mohawk:myst[masterpiece edition]|mohawk:riven'
    ),
    (
      Caption: 'macs2-enhancements';
      Kind: sgokSpecial;
      IniKey: 'enhancements';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'macs2:sis'
    ),
    (
      Caption: 'scumm-enhancements';
      Kind: sgokSpecial;
      IniKey: 'enhancements';
      DefaultBool: False;
      DefaultInt: 0;
      GameIds: 'scumm:atlantis|scumm:comi|scumm:dig[]|scumm:dig[steam]|scumm:freddi3[]|scumm:freddi4|scumm:ft[]|scumm:ft[remastered]|scumm:indy3|scumm:loom[demo,ega,fm-towns,mac,no adlib,pcengine,vga]|scumm:maniac[apple ii,nes,remastered,v1,v2]|scumm:monkey2[]|scumm:monkey2[amiga,demo,fm-towns,mac,se]|scumm:monkey[cd,ega,fm-towns,mac,no adlib,se,sega,vga]|scumm:rebel1[demo]|scumm:rebel2[demo da1.06,demo v1.0]|scumm:samnmax|scumm:tentacle|scumm:zak[fm-towns]'
    )
  );

type
  TScummVMGameIdVariantsDef = record
    GameId : String;
    Variants : String;
  end;

const
  ScummVMGameIdVariantMapCount = 200;
  ScummVMGameIdVariantMap : array[0..199] of TScummVMGameIdVariantsDef = (
    (
      GameId: 'access:noctropolis';
      Variants: 'Rerelease'
    ),
    (
      GameId: 'adl:hires1';
      Variants: 'Malibu Microcomputing [A]|Malibu Microcomputing [B]|On-Line Systems [A]|On-Line Systems [B]|On-Line Systems [C]|Public Domain'
    ),
    (
      GameId: 'agi:bc';
      Variants: 'updated'
    ),
    (
      GameId: 'agi:goldrush';
      Variants: 'updated'
    ),
    (
      GameId: 'agi:kq1';
      Variants: 'fixed|updated'
    ),
    (
      GameId: 'agi:kq2';
      Variants: 'fixed|updated'
    ),
    (
      GameId: 'agi:kq4';
      Variants: 'Demo|updated'
    ),
    (
      GameId: 'agi:lsl1';
      Variants: 'Demo'
    ),
    (
      GameId: 'agi:mh1';
      Variants: 'updated'
    ),
    (
      GameId: 'agi:mh2';
      Variants: 'updated'
    ),
    (
      GameId: 'agi:pq1';
      Variants: 'updated'
    ),
    (
      GameId: 'agi:sq1';
      Variants: 'fixed|updated'
    ),
    (
      GameId: 'agi:sq2';
      Variants: 'updated'
    ),
    (
      GameId: 'agos:elvira1';
      Variants: 'Floppy|Non-Interactive Demo'
    ),
    (
      GameId: 'agos:elvira2';
      Variants: 'Floppy'
    ),
    (
      GameId: 'agos:simon1';
      Variants: '25th Anniversary Edition|AGA Floppy|CD|CD Demo|CD32|CD32 Demo|Floppy|Floppy Demo|Infocom CD|Infocom Floppy|OCS Demo|OCS Floppy'
    ),
    (
      GameId: 'agos:simon2';
      Variants: '25th Anniversary Edition|Amiga CD - Original Release|CD|CD Demo|CD Non-Interactive Demo|Floppy'
    ),
    (
      GameId: 'agos:waxworks';
      Variants: 'Floppy|Non-Interactive Demo'
    ),
    (
      GameId: 'ags:ashinaredwitch';
      Variants: 'Demo|Steam'
    ),
    (
      GameId: 'ags:blackwell1';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:blackwell2';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:blackwell3';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:blackwell4';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:blackwell5';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:danewguys2';
      Variants: 'Demo'
    ),
    (
      GameId: 'ags:dreamswitchhouse';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:excavationhb';
      Variants: 'GOG.com|Steam'
    ),
    (
      GameId: 'ags:footballgame';
      Variants: 'Steam|Switch'
    ),
    (
      GameId: 'ags:geminirue';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:gobliiins5-1';
      Variants: 'Steam'
    ),
    (
      GameId: 'ags:goldenwake';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:jamesperis2';
      Variants: 'Demo'
    ),
    (
      GameId: 'ags:justignorethem';
      Variants: 'Demo|Steam'
    ),
    (
      GameId: 'ags:kathyrain';
      Variants: 'Amazon Games|Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:mybigsister';
      Variants: 'Demo|Steam|Switch'
    ),
    (
      GameId: 'ags:mybigsisterrm';
      Variants: 'Steam'
    ),
    (
      GameId: 'ags:oldskies';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:primordia';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:redbow';
      Variants: 'Demo|Steam|Switch'
    ),
    (
      GameId: 'ags:resonance';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:rosewater';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:shardlight';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:shivah';
      Variants: 'Demo|MAGS'
    ),
    (
      GameId: 'ags:shivahkosher';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:strangeland';
      Variants: 'GOG.com|Steam'
    ),
    (
      GameId: 'ags:sumatra';
      Variants: 'GOG.com|Steam|Switch'
    ),
    (
      GameId: 'ags:technobabylon';
      Variants: 'Demo|GOG.com|Steam'
    ),
    (
      GameId: 'ags:unavowed';
      Variants: 'GOG.com|Steam'
    ),
    (
      GameId: 'ags:whispersofamachine';
      Variants: 'Amazon Games|GOG.com|Steam'
    ),
    (
      GameId: 'alg:lbhunter';
      Variants: 'demo'
    ),
    (
      GameId: 'awe:anotherworld';
      Variants: 'Demo'
    ),
    (
      GameId: 'bladerunner:bladerunner';
      Variants: 'Game not implemented|Non-Interactive Demo'
    ),
    (
      GameId: 'bolt:carnival';
      Variants: 'Demo'
    ),
    (
      GameId: 'cge2:sfinx';
      Variants: 'Demo|Freeware|Freeware v0.3|Freeware v1.0|Freeware v1.1'
    ),
    (
      GameId: 'cge:soltys';
      Variants: 'Freeware|Freeware v1.0|Game not implemented|Russian fan-translation v1.0|Russian fan-translation v1.1'
    ),
    (
      GameId: 'cruise:cruise';
      Variants: '16 colors|256 colors|Fanmade'
    ),
    (
      GameId: 'darkseed:darkseed';
      Variants: 'CD'
    ),
    (
      GameId: 'dreamweb:dreamweb';
      Variants: 'CD|Installer'
    ),
    (
      GameId: 'eem:eem2';
      Variants: 'CD'
    ),
    (
      GameId: 'freescape:castlemaster';
      Variants: 'CD release|Demo|Domark PC Collection|Virtual Worlds'
    ),
    (
      GameId: 'freescape:driller';
      Variants: 'Demo|Not implemented yet|Rolling Demo'
    ),
    (
      GameId: 'freescape:totaleclipse';
      Variants: 'Demo'
    ),
    (
      GameId: 'gob:adibou1';
      Variants: 'Adi Jnr|Adi Jnr.|ADIBOU 1 Environnement 4-7 ans'
    ),
    (
      GameId: 'gob:gob1';
      Variants: 'EGA|VGA'
    ),
    (
      GameId: 'gob:gob2';
      Variants: 'v1.02|v1.03'
    ),
    (
      GameId: 'grim:grim';
      Variants: '7Wolf|Demo|ENPY|Fanmade|Fargus|Remastered'
    ),
    (
      GameId: 'grim:monkey4';
      Variants: 'CD Demo|Demo|Fanmade|Web Demo'
    ),
    (
      GameId: 'groovie:11h';
      Variants: 'Installed|Interactive Demo|Non-Interactive Demo'
    ),
    (
      GameId: 'groovie:clandestiny';
      Variants: 'Demo|Trailer'
    ),
    (
      GameId: 'groovie:t7g';
      Variants: '25th Anniversary Edition|demo'
    ),
    (
      GameId: 'groovie:tlc';
      Variants: 'CD|Game not implemented'
    ),
    (
      GameId: 'harvester:harvester';
      Variants: 'Demo|European Release'
    ),
    (
      GameId: 'hdb:hdb';
      Variants: 'Demo|Handango Demo'
    ),
    (
      GameId: 'hopkins:hopkins';
      Variants: 'Demo'
    ),
    (
      GameId: 'kyra:lol';
      Variants: 'CD|Extracted'
    ),
    (
      GameId: 'lure:lure';
      Variants: 'EGA|Konami VGA|VGA'
    ),
    (
      GameId: 'macs2:sis';
      Variants: 'Demo'
    ),
    (
      GameId: 'made:rtz';
      Variants: 'CD|Demo CD'
    ),
    (
      GameId: 'mads:dragonsphere';
      Variants: 'CD|CD Installer|Demo'
    ),
    (
      GameId: 'mads:nebular';
      Variants: 'Demo|Fanmade|floppy'
    ),
    (
      GameId: 'mads:phantom';
      Variants: 'CD|CD Installer|Demo'
    ),
    (
      GameId: 'mm:worldofxeen';
      Variants: 'CD|Monster Spawn Mod v1.0'
    ),
    (
      GameId: 'mohawk:arthur';
      Variants: 'Demo|Demo v1.1|Super Living Books'
    ),
    (
      GameId: 'mohawk:arthurbday';
      Variants: 'Demo'
    ),
    (
      GameId: 'mohawk:beardark';
      Variants: '32-bit'
    ),
    (
      GameId: 'mohawk:create';
      Variants: 'Demo'
    ),
    (
      GameId: 'mohawk:daniel';
      Variants: 'Demo'
    ),
    (
      GameId: 'mohawk:grandma';
      Variants: 'Demo|Demo v1.0|Demo v1.1|Demo v1.2|v1.0|v1.1|v2.0'
    ),
    (
      GameId: 'mohawk:greeneggs';
      Variants: '32-bit|Game not implemented'
    ),
    (
      GameId: 'mohawk:harryhh';
      Variants: 'Demo|Super Living Books|v1.0|v1.1'
    ),
    (
      GameId: 'mohawk:lilmonster';
      Variants: 'Demo'
    ),
    (
      GameId: 'mohawk:myst';
      Variants: 'Demo|Masterpiece Edition'
    ),
    (
      GameId: 'mohawk:newkid';
      Variants: 'Demo|Demo v1.0|Demo v1.1'
    ),
    (
      GameId: 'mohawk:riven';
      Variants: '25th Anniversary|Demo|DVD'
    ),
    (
      GameId: 'mohawk:ruff';
      Variants: 'Demo'
    ),
    (
      GameId: 'mohawk:seussabc';
      Variants: '32-bit|Demo'
    ),
    (
      GameId: 'mohawk:stellaluna';
      Variants: '32-bit'
    ),
    (
      GameId: 'mohawk:tortoise';
      Variants: 'Demo|Demo v1.0|Demo v1.1|Super Living Books|Wanderful'
    ),
    (
      GameId: 'mtropolis:obsidian';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'neverhood:neverhood';
      Variants: 'Big Demo|Demo|DR|Fargus|Stream'
    ),
    (
      GameId: 'parallaction:nippon';
      Variants: 'Demo|Multi-lingual|Multi-lingual alt'
    ),
    (
      GameId: 'prince:prince';
      Variants: 'Ksiaze i Tchorz'
    ),
    (
      GameId: 'private:private-eye';
      Variants: 'Demo'
    ),
    (
      GameId: 'queen:queen';
      Variants: 'CD|GOG.com'
    ),
    (
      GameId: 'saga:ite';
      Variants: 'AGA Floppy|CD|ECS Floppy|Floppy|Floppy Packed'
    ),
    (
      GameId: 'sci:camelot';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:castlebrain';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'sci:ecoquest';
      Variants: 'CD|Demo|Floppy'
    ),
    (
      GameId: 'sci:ecoquest2';
      Variants: 'CD|Demo|Floppy'
    ),
    (
      GameId: 'sci:fairytales';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'sci:freddypharkas';
      Variants: 'CD|CD Demo|Demo|Floppy'
    ),
    (
      GameId: 'sci:gk1';
      Variants: 'CD'
    ),
    (
      GameId: 'sci:gk2';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:hoyle1';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:hoyle3';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'sci:hoyle4';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:iceman';
      Variants: 'Debug Build|Demo'
    ),
    (
      GameId: 'sci:islandbrain';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:jones';
      Variants: 'CD|EGA'
    ),
    (
      GameId: 'sci:kq1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'sci:kq4sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'sci:kq5';
      Variants: 'CD|EGA'
    ),
    (
      GameId: 'sci:kq6';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'sci:kq7';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:laurabow';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:laurabow2';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'sci:lighthouse';
      Variants: 'Demo|Glider Demo|Non-interactive Demo'
    ),
    (
      GameId: 'sci:longbow';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'sci:lsl1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'sci:lsl2';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:lsl3';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:lsl5';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'sci:lsl6';
      Variants: 'CD'
    ),
    (
      GameId: 'sci:lsl6hires';
      Variants: 'Hi-res'
    ),
    (
      GameId: 'sci:lsl7';
      Variants: 'Demo|Fargus|Softclub'
    ),
    (
      GameId: 'sci:mothergoose';
      Variants: 'EGA'
    ),
    (
      GameId: 'sci:mothergoose256';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'sci:pepper';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:phantasmagoria';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:pq1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'sci:pq2';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:pq3';
      Variants: 'Demo|EGA'
    ),
    (
      GameId: 'sci:pq4';
      Variants: 'CD'
    ),
    (
      GameId: 'sci:pqswat';
      Variants: 'demo'
    ),
    (
      GameId: 'sci:qfg1';
      Variants: '16 Colors|8 Colors|Demo'
    ),
    (
      GameId: 'sci:qfg1vga';
      Variants: 'VGA'
    ),
    (
      GameId: 'sci:qfg2';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:qfg3';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:qfg4';
      Variants: 'CD'
    ),
    (
      GameId: 'sci:rama';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:shivers';
      Variants: 'CD Demo|Demo|Non-interactive Demo'
    ),
    (
      GameId: 'sci:slater';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:sq1sci';
      Variants: 'SCI'
    ),
    (
      GameId: 'sci:sq3';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:sq4';
      Variants: 'CD|EGA'
    ),
    (
      GameId: 'sci:sq6';
      Variants: 'Demo'
    ),
    (
      GameId: 'sci:torin';
      Variants: 'Demo'
    ),
    (
      GameId: 'scumm:atlantis';
      Variants: 'Amiga|Floppy|FM-TOWNS|Mac|Mac Floppy|Steam'
    ),
    (
      GameId: 'scumm:bluesbirthday';
      Variants: 'Red|Yellow'
    ),
    (
      GameId: 'scumm:comi';
      Variants: 'Demo'
    ),
    (
      GameId: 'scumm:dig';
      Variants: 'Demo|Steam'
    ),
    (
      GameId: 'scumm:fbear';
      Variants: 'HE 62|HE 70'
    ),
    (
      GameId: 'scumm:freddi';
      Variants: 'HE 71|HE 73'
    ),
    (
      GameId: 'scumm:freddi3';
      Variants: 'HE 99'
    ),
    (
      GameId: 'scumm:freddi4';
      Variants: 'HE 99|unenc'
    ),
    (
      GameId: 'scumm:freddicove';
      Variants: 'HE 100|unenc'
    ),
    (
      GameId: 'scumm:ft';
      Variants: 'Demo|Remastered'
    ),
    (
      GameId: 'scumm:indy3';
      Variants: 'EGA|FM-TOWNS|Mac|No AdLib|Steam|VGA'
    ),
    (
      GameId: 'scumm:indyloom';
      Variants: 'FM-TOWNS'
    ),
    (
      GameId: 'scumm:indyzak';
      Variants: 'FM-TOWNS'
    ),
    (
      GameId: 'scumm:loom';
      Variants: 'Demo|EGA|FM-TOWNS|Mac|No AdLib|pcengine|Steam|VGA'
    ),
    (
      GameId: 'scumm:maniac';
      Variants: 'Apple II|C64|C64 Demo|NES|Remastered|V1|V1 Demo|V2|V2 Demo'
    ),
    (
      GameId: 'scumm:monkey';
      Variants: 'CD|Demo|EGA|FM-TOWNS|Mac|No AdLib|SE|SE Talkie|SEGA|VGA|VGA Demo'
    ),
    (
      GameId: 'scumm:monkey2';
      Variants: 'Amiga|Demo|FM-TOWNS|Mac|SE|SE Talkie'
    ),
    (
      GameId: 'scumm:moonbase';
      Variants: 'Demo'
    ),
    (
      GameId: 'scumm:pajama2';
      Variants: 'HE 99'
    ),
    (
      GameId: 'scumm:puttmoon';
      Variants: 'Demo|HE 70'
    ),
    (
      GameId: 'scumm:puttputt';
      Variants: 'Demo|HE 60|HE 61|HE 62'
    ),
    (
      GameId: 'scumm:puttrace';
      Variants: 'HE 98|HE 99'
    ),
    (
      GameId: 'scumm:puttzoo';
      Variants: 'HE 100|HE 72|HE 99'
    ),
    (
      GameId: 'scumm:rebel1';
      Variants: 'Demo|Demo v1.0|Demo v1.02c|Demo v1.5|Demo v1.51'
    ),
    (
      GameId: 'scumm:rebel2';
      Variants: 'Demo DA1.06|Demo DB1.03|Demo DG1.15|Demo Special Edition|Demo v1.0|PlayStation'
    ),
    (
      GameId: 'scumm:samnmax';
      Variants: 'Floppy'
    ),
    (
      GameId: 'scumm:tentacle';
      Variants: 'Floppy|Remastered'
    ),
    (
      GameId: 'scumm:zak';
      Variants: 'FM-TOWNS|V1|V2'
    ),
    (
      GameId: 'scumm:zakloom';
      Variants: 'FM-TOWNS'
    ),
    (
      GameId: 'sherlock:rosetattoo';
      Variants: 'CD'
    ),
    (
      GameId: 'sword1:sword1';
      Variants: '25th Anniversary|Akella|Demo|English speech|English speech and DXA cutscenes|GOG.com|Mediahauz|Novy Disk|Rerelease|SoldOut rerelease|Steam|TecToy'
    ),
    (
      GameId: 'teenagent:teenagent';
      Variants: 'Alt Demo|Alt version|CD|Demo'
    ),
    (
      GameId: 'tetraedge:syberia';
      Variants: 'Extracted'
    ),
    (
      GameId: 'tetraedge:syberia2';
      Variants: 'Extracted'
    ),
    (
      GameId: 'tinsel:dw2';
      Variants: 'CD|Demo'
    ),
    (
      GameId: 'toltecs:toltecs';
      Variants: 'Demo'
    ),
    (
      GameId: 'tot:tot';
      Variants: 'Demo'
    ),
    (
      GameId: 'ultima:remorse';
      Variants: 'Demo|Fan Translation'
    ),
    (
      GameId: 'ultima:ultima8';
      Variants: 'Gold Edition'
    ),
    (
      GameId: 'vcruise:schizm';
      Variants: 'English CD|English Digital|English DVD|French Digital|German Digital|German DVD|Hungarian Digital|Italian Digital|Japanese DVD|Polish Digital|Polish DVD|Russian Digital|Spanish Digital'
    ),
    (
      GameId: 'voyeur:voyeur';
      Variants: 'Demo|German Fan Made Version'
    ),
    (
      GameId: 'zvision:zgi';
      Variants: 'CD|Demo|DVD'
    ),
    (
      GameId: 'zvision:znemesis';
      Variants: 'Demo|Game not implemented'
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

procedure SplitScummVMGameToken(const S: String; out Eng, Bare, Inside: String; out HasBr: Boolean);
var
  T: String;
  PColon, PBr: Integer;
begin
  Eng := '';
  Bare := '';
  Inside := '';
  HasBr := False;
  T := LowerCase(Trim(S));
  PBr := Pos('[', T);
  if PBr > 0 then begin
    HasBr := True;
    if (Length(T) > 0) and (T[Length(T)] = ']') then
      Inside := Copy(T, PBr + 1, Length(T) - PBr - 1)
    else
      Inside := Copy(T, PBr + 1, MaxInt);
    T := Copy(T, 1, PBr - 1);
  end;
  PColon := Pos(':', T);
  if PColon > 0 then begin
    Eng := Copy(T, 1, PColon - 1);
    Bare := Copy(T, PColon + 1, MaxInt);
  end else
    Bare := T;
end;

function ScummVMEngineAndIdMatch(const TokEng, TokBare, QEng, QBare: String): Boolean;
begin
  Result := False;
  if TokBare <> QBare then Exit;
  if (QEng <> '') and (TokEng <> '') and (QEng <> TokEng) then Exit;
  Result := True;
end;

function OptionAppliesTo(const GameIds, GameId, Variant : String) : Boolean;
var
  QEng, QBare, QInside, TokEng, TokBare, TokInside, VarTok, Token, List: String;
  QHasBr, TokHasBr: Boolean;
  P: Integer;
begin
  SplitScummVMGameToken(GameId, QEng, QBare, QInside, QHasBr);
  VarTok := LowerCase(Trim(Variant));
  Result := False;
  if QBare = '' then Exit;
  List := GameIds;
  while List <> '' do begin
    P := Pos('|', List);
    if P = 0 then begin Token := List; List := ''; end
    else begin Token := Copy(List, 1, P - 1); Delete(List, 1, P); end;
    Token := Trim(Token);
    if Token = '' then Continue;
    SplitScummVMGameToken(Token, TokEng, TokBare, TokInside, TokHasBr);
    if not ScummVMEngineAndIdMatch(TokEng, TokBare, QEng, QBare) then Continue;
    if not TokHasBr then begin Result := True; Exit; end;
    if TokInside = '' then begin
      if VarTok = '' then begin Result := True; Exit; end;
      Continue;
    end;
    if VarTok = '' then Continue;
    TokInside := ',' + TokInside + ',';
    if Pos(',' + VarTok + ',', TokInside) > 0 then begin
      Result := True; Exit;
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
  QEng, QBare, QInside, MEng, MBare, MInside, List, One : String;
  QHasBr, MHasBr : Boolean;
  Tmp : TStringList;
begin
  if Dest = nil then Exit;
  Dest.Clear;
  SplitScummVMGameToken(GameId, QEng, QBare, QInside, QHasBr);
  if QBare = '' then Exit;
  Tmp := TStringList.Create;
  try
    Tmp.Sorted := True;
    Tmp.Duplicates := dupIgnore;
    for I := 0 to ScummVMGameIdVariantMapCount - 1 do begin
      SplitScummVMGameToken(ScummVMGameIdVariantMap[I].GameId, MEng, MBare, MInside, MHasBr);
      if not ScummVMEngineAndIdMatch(MEng, MBare, QEng, QBare) then Continue;
      List := ScummVMGameIdVariantMap[I].Variants;
      while List <> '' do begin
        P := Pos('|', List);
        if P = 0 then begin One := List; List := ''; end
        else begin One := Copy(List, 1, P - 1); Delete(List, 1, P); end;
        One := Trim(One);
        if One <> '' then
          Tmp.Add(One);
      end;
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
