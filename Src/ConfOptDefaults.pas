unit ConfOptDefaults;
interface

Const DefaultValuesResolutionFullscreen='original,320x200,320x240,640x432,640x480,720x480,800x600,1024x768,1152x864,1280x720,1280x768,1280x960,1280x1024,1366x760,1366x768,1600x1200,1680x1050,1920x1080,1920x1200,0x0';
      DefaultValuesResolutionWindow='original,320x200,320x240,640x432,640x480,720x480,800x600,1024x768,1152x864,1280x720,1280x768,1280x960,1280x1024,1366x760,1366x768,1600x1200,1920x1080,1920x1200';
      DefaultValuesJoysticks='none,auto,2axis,4axis,4axis_2,fcs,ch';
      DefaultValuesScale='No Scaling (none),Nearest neighbor upscaling with factor 2 (normal2x),Nearest neighbor upscaling with factor 3 (normal3x),'+
                         'Advanced upscaling with factor 2 (advmame2x),Advanced upscaling with factor 3 (advmame3x),'+
                         'high quality with factor 2 (hq2x), high quality with factor 3 (hq3x),2xsai (2xsai), super2xsai (super2xsai), supereagle (supereagle),'+
                         'Advanced interpoling with factor 2 (advinterp2x),Advanced interpoling with factor 3 (advinterp3x),'+
                         'Advanced upscaling with sharpening with factor 2 (tv2x),Advanced upscaling with sharpening with factor 3 (tv3x),Simulates the phopsphors on a dot trio CRT with factor 2 (rgb2x),Simulates the phopsphors on a dot trio CRT with factor 3 (rgb3x),'+
                         'Nearest neighbor with black lines with factor 2 (scan2x),Nearest neighbor with black lines with factor 3 (scan3x)';
      DefaultValueRender='surface,overlay,opengl,openglnb,ddraw,direct3d';
      DefaultValueRenderStaging='opengl,texture,texturenb';
      DefaultValueRenderX='default,surface,ttf,opengl,openglnb,openglhq,openglpp,direct3d,direct3d11';
      DefaultValueVSyncStaging='off,on,fullscreen-only';
      DefaultValueVSyncStagingOld='auto,on,adaptive,off,yield';
      DefaultValueVSyncX='off,on,force,host';
      DefaultValueVSyncPure='off,Force 60fps';
      DefaultValuePresentationModeStaging='auto,dos-rate,host-rate';
      DefaultValueDosRateStaging='default,host,50,60,70,72,75,90,100,120,144,165,240';
      DefaultValuesDeinterlacingStaging='off,on,light,medium,strong,full';
      DefaultValuesDeditheringStaging='off,on';
      DefaultValuesCrtColorProfileStaging='auto,none,ebu,p22,smpte-c,philips,trinitron';
      DefaultValuesColorSpaceStaging='srgb,display-p3,dci-p3,dci-p3-d65,modern-p3,adobe-rgb,rec-2020';
      DefaultValuesIntegerScalingStaging='auto,vertical,horizontal,off';
      DefaultValuesColorTemperatureStaging='auto,3000,4000,5000,5500,6500,7500,9300,10000';
      DefaultValuesDiskSpeedStaging='maximum,fast,medium,slow';
      DefaultValuesDiskNoiseStaging='off,seek-only,on';
      DefaultValueScalePure='default,nearest,bilinear,integer';
      DefaultValueShaderPure='scanline,blur,mask,curvature,corner';
      DefaultValueCycles='auto,max,500,1000,1500,2000,2500,3000,3500,4000,4500,5000,6000,7000,8000,9000,10000,11000,12000,12000,13000,14000,15000,16000,17000,18000,19000,20000';
      DefaultValuesVideo='hercules (Hercules Graphics Card),cga (Color Graphics Adapter),tandy (Tandy),pcjr (IBM PCjr),'+
                         'PC98,DOS/V,olivetti (Olivetti M24 / AT&T 6300),pc3270 (IBM 3270 PC),'+
                         'ega (Enhanced Graphics Adapter),'+
                         'vgaonly (Video Graphics Array), svga_s3 (VESA 2.0 compatible S3 SuperVGA card), svga_et3000 (Tseng ET3000 SuperVGA card),'+
                         'svga_et4000 (Tseng ET4000 SuperVGA card),svga_paradise (Paradise PVGA1A SuperVGA card),vesa_nolfb (VESA 2.0 compatible S3 SuperVGA card),'+
                         'vesa_oldvbe (VESA 1.2 compatible S3 SuperVGA card)';
      DefaultValuesMemory='1,2,4,8,16,32,63';
      DefaultValuesFrameSkip='0,1,2,3,4,5,6,7,8,9,10';
      DefaultValuesCore='auto,normal,dynamic,simple';
      DefaultValuesSBlaster='none,sb1,sb2,sbpro1,sbpro2,sb16,gb';
      DefaultValuesSBlasterStaging='gb,sb1,sb2,sbpro1,sbpro2,sb16,ess,none';
      DefaultValuesSBlasterX='sb1,sb1.0,sb1.5,sb2,sb2.0,sb2.01,sbpro1,sbpro2,sb16,sb16vibra,gb,ess688,ess1688,reveal_sc400,pas,pasplus,pas16,none';
      DefaultValuesOPLModes='auto,cms,opl2,dualopl2,opl3,none';
      DefaultValuesOPLModesStaging='auto,cms,opl2,dualopl2,opl3,opl3gold,esfm,none';
      DefaultValuesOPLModesX='auto,opl2,dualopl2,opl3,opl3gold,hardware,hardwaregb,esfm,none';
      DefaultValuesKeyboardLayout='default,none,Albania (SQ),Albania (SQ448),Argentina (LA),Armenia (HY),Australia (US),Austria (DE),Austria (DE453),Azerbaijan (AZ),'+
                                  'Belarus (BY),Belgium (BE),Bosnia & Herzegovina (BA),Brazil (BR),Brazil (BR274),Bulgaria (BG),Bulgaria (BG241),'+
                                  'Canada (CA),Canada (CA445),Canada (CF501),Chile (LA),Colombia (LA),Croatia (HR),Czech Republic (CZ),Czech Republic (CZ243),'+
                                  'Denmark (DK),Ecuador (LA),Estonia (EE),Faeroe Islands (FO),Finland (FI),France (FR),France (FR120),Georgia (KA),Germany (DE),Germany (DE453),'+
                                  'Greece (GK),Greece (GK220),Greece (GK459),Hungary (HU),Hungary (HU208),Iceland (IS),Iceland (IS161),Ireland (UK),Ireland (UK168),'+
                                  'Italy (IT),Italy (IT142),Kazakhstan (KK),Kyrgyzstan (KY),Latin-American-Spanish (LA),Latvia (LV),Latvia (LV455),'+
                                  'Lithuania (LT),Lithuania (LT210),Lithuania (LT211),Lithuania (LT221),Lithuania (LT456),Macedonia (MK),Malta (MT),Malta (MT47),Mexico (LA),'+
                                  'Mongolia (MN),Netherlands (NL),New Zealand (US),Norway (NO),Philippines (PH),Poland (PL),Poland (PL214),Portugal (PO),Romania (RO),Romania (RO446),'+
                                  'Russia (RU),Russia (RU443),Serbia & Montenegro (SR),Serbia & Montenegro (SR450),Slovakia (SK),Slovenia (SI),South Africa (US),Spain (ES),'+
                                  'Sweden (SV),Switzerland - French (SF),Switzerland - German (SD),Turkmenistan (TM),Turkey (TR),Turkey (TR440),Ukraine (UA),Ukraine (UA465),'+
                                  'United Kingdom (UK),United Kingdom (UK168),US (US),US International (UX),US Dvorak (DV),US Left-Hand Dvorak (LH),US Right-Hand Dvorak (RH),'+
                                  'Uzbekistan (UZ),Venezuela (LA),Yugoslavia (YU)';
      DefaultValuesCodepage='default,113 (Yugoslavian),437 (United States),667 (Polish),668 (Polish),737 (Greek-2),770 (Baltic),771 (Lithuanian and Russian KBL),'+
                            '772 (Lithuanian and Russian),773 (Latin-7 Baltic - old standard),774 (Lithuanian),775 (Latin-7 Baltic),777 (Accented Lithuanian),'+
                            '778 (Accented Lithuanian),790 (Polish Mazovia),808 (Cyrillic-2 with Euro),848 (Cyrillic Ukrainian with Euro),849 (Cyrillic Belarusian with Euro),'+
                            '850 (Latin-1),851 (Greek),852 (Latin-2 Eastern European),853 (Latin-3 Southern European),855 (Cyrillic-1),857 (Latin-5 Turkish),'+
                            '858 (Latin-1 with Euro),859 (Latin-9; 858 plus full french and estonian),860 (Portugal),861 (Icelandic),863 (Canadian French),'+
                            '865 (Nordic),866 (Cyrillic-2 Russian),867 (Czech Kamenicky),869 (Greek),872 (Cyrillic-1 with Euro),899 (Armenian),991 (Polish Mazovia with Zloty sign),'+
                            '1116 (Estonian),1117 (Latvian),1125 (Cyrillic Ukrainian),1131 (Cyrillic Belarusian),57781 (Hungarian),58152 (Cyrillic Kazakh with Euro),'+
                            '58210 (Cyrillic Azeri Cyrillic),59234 (Cyrillic Tatar),59829 (Georgian),60258 (Cyrillic Azeri Latin),60853 (Georgian with capital letters),'+
                            '61282 (Latvian and Russian "RusLat"),62306 (Cyrillic Uzbek)';
      DefaultValuesReportedDOSVersion='default,6.22,6.2,6.0,5.0,4.0,3.3';
      DefaultValuesMIDIDevice='default,alsa,oss,win32,coreaudio,mt32,none';
      DefaultValuesMIDIDeviceStaging='port,soundfont,mt32,soundcanvas,none';
      DefaultValuesMIDIDeviceStagingOld='auto,win32,soundfont,mt32,none';
      DefaultValuesMIDIDeviceX='default,win32,soundfont,mt32,timidity,none';
      DefaultValuesMIDIDevicePure='system,mt32,soundfont,none';
      { Staging [mt32] model Set_values (staging + 83rc). }
      DefaultValuesMT32ModelStaging=
        'auto,cm32l,cm32l_102,cm32l_100,cm32ln_100,mt32,mt32_old,mt32_107,mt32_106,'+
        'mt32_105,mt32_104,mt32_bluer,mt32_new,mt32_207,mt32_206,mt32_204,mt32_203';
      { DOSBox-X mt32.model Set_values. }
      DefaultValuesMT32ModelX='auto,cm32l,mt32';
      DefaultValuesSoundCanvasModelStaging=
        'auto,sc55,sc55_121,sc55_120,sc55_110,sc55_100,sc55_200,sc55mk2,sc55mk2_100,sc55mk2_101';
      DefaultValuesBlocksize='512,1024,2048,3072,4096,8192';
      DefaultValuesCyclesDown='20,50,100,500,1000,2000,5000,10000';
      DefaultValuesCyclesUp='20,50,100,500,1000,2000,5000,10000';
      DefaultValuesDMA='0,1,3,5,6,7';
      DefaultValuesDMA1='0,1,3,5,6,7';
      DefaultValuesGUSBase='220,240,260,280,2a0,2c0,2e0,300';
      DefaultValuesGUSRate='8000,11025,22050,32000,44100,48000,49716';
      DefaultValuesHDMA='0,1,3,5,6,7';
      DefaultValuesIRQ='3,5,7,10,11';
      DefaultValuesIRQ1='3,5,7,10,11';
      DefaultValuesMPU401='none,intelligent,uart';
      DefaultValuesOPLRate='8000,11025,22050,32000,44100,48000,49716';
      DefaultValuesPCRate='8000,11025,22050,32000,44100,48000,49716';
      DefaultValuesRate='8000,11025,22050,32000,44100,48000,49716';
      DefaultValuesSBBase='220,240,260,280,2a0,2c0,2e0,300';
      DefaultValuesMouseSensitivity='10,20,30,40,50,60,70,80,90,100,125,150,175,200,250,300,350,400,450,500,550,600,700,800,900,1000';
      DefaultValuesMouseDriverModelStaging='2button,3button,wheel';
      DefaultValuesMouseMoveThresholdStaging='1,2,3,4,5,6,7,8,9';
      DefaultValuesPs2MouseModelStaging='standard,intellimouse,explorer';
      DefaultValuesPs2MouseModelX='2button,3button,intellimouse,intellimouse45';
      DefaultValuesPs2ReportRateStaging='40,60,80,100,125,160,200,250,330,500';
      DefaultValuesPs2ReportRateX='auto,40,60,80,100,125,200';
      DefaultValuesTandyRate='8000,11025,16000,22050,32000,44100,48000,49716';
      DefaultValuesScummVMFilter='No filtering. no scaling. Fastest (1x),No filtering. factor 2x. default for non 640x480 games (2x),No filtering. factor 3x (3x),2xSAI filter. factor 2x (2xsai),Enhanced 2xSAI filtering. factor 2x (super2xsai),'+
                                 'Less blurry than 2xSAI but slower. Factor 2x (supereagle),Doesn''t rely on blurring like 2xSAI. fast. Factor 2x (advmame2x),Doesn''t rely on blurring like 2xSAI. fast. Factor 3x (advmame3x),Very nice high quality filter but slow. Factor 2x (hq2x),'+
                                 'Very nice high quality filter but slow. Factor 3x (hq3x),Interlace filter. Tries to emulate a TV. Factor 2x (tv2x),Dot matrix effect. Factor 2x (dotmatrix),'+
                                 'No filtering. factor 4x (4x),Doesn''t rely on blurring like 2xSAI. fast. Factor 4x (advmame4x),Edge-directed interpolation. Factor 2x (edge2x),Edge-directed interpolation. Factor 3x (edge3x),Smoother diagonals and rounded edges. Factor 2x (pm2x)';
      DefaultValuesScummVMMusicDriver='No music (null),Automatic (auto),Adlib emulation (adlib),FluidSynth MIDI emulation (fluidsynth),MT-32 emulation (mt32),PCjr emulation (only usable in SCUMM games) (pcjr),PC Speaker emulation (pcspk),'+
                                      'FM-TOWNS YM2612 emulation (only usable in SCUMM FM-TOWNS games) (towns),Windows MIDI (windows),'+
                                      'Creative Music System (cms),C64 Audio (C64),PC-98 Audio (pc98),SegaCD Audio (segacd),Apple Macintosh Audio (mac),Amiga Audio (amiga),Apple IIgs Audio (appleIIgs)';
      DefaultValuesScummVMOplDriver='default,MAME OPL emulator (mame),DOSBox OPL emulator (db),Nuked OPL emulator (nuked)';
      DefaultValuesVGAChipsets='s3,et4000,et4000new,et3000,pvga1a,none';
      DefaultValuesVGAVideoRAM='512,1024,2048,4096,8192';
      DefaultValuesScummVMRenderMode='default,CGA,EGA,Hercules green,Hercules amber,Amiga,'+
                                      'VGA,CGA Composite,CGA b/w,FM-TOWNS,PC-9821 256 Colors,PC-9801 16 Colors,PC-9801 8 Colors,'+
                                      'Apple IIgs,Atari ST,Macintosh,Macintosh b/w,Amstrad CPC,ZX Spectrum,Commodore 64,VGA Grey Scale,Windows 256 Colors,Windows 16 Colors';
      DefaultValuesScummVMGfxMode='default,OpenGL,SDL Surface';
      DefaultValuesScummVMScaler='default,Normal (normal),HQ (hq),Edge (edge),AdvMAME (advmame),SAI (sai),SuperSAI (supersai),SuperEagle (supereagle),PM (pm),DotMatrix (dotmatrix),TV (tv)';
      DefaultValuesScummVMScaleFactor='default,1,2,3,4';
      DefaultValuesScummVMStretchMode='default,Center,Pixel-perfect scaling,Even pixels scaling,Fit to window,Stretch to window,Fit to window 4:3';
      DefaultValuesScummVMShader='None';
      DefaultValuesScummVMRenderer='default,OpenGL,OpenGL with shaders,Software';
      DefaultValuesScummVMAntialiasing='default,None,2x,4x,8x';
      DefaultValuesScummVMPlatform='auto,2gs,apple2,3do,acorn,amiga,atari8,atari,c64,cpc,pc,pc98,wii,coco,coco3,fmtowns,linux,macintosh,pce,nes,segacd,windows,playstation,playstation2,playstation3,xbox,cdi,ios,android,os2,beos,ppc,megadrive,saturn,pippin,macintosh2,shockwave,zx,ti994,switch';
      DefaultValuesScummVMLanguages='maniac:en-de-fr-it-es,zak:en-de-fr-it-es,dig_jp-zh-kr,comi:en-de-fr-it-pt-es-jp-zh-kr,sky:gb-en-de-fr-it-pt-es-se,sword1:en-de-fr-it-es-pt-cz,simon1:en-de-fr-it-es-hb-pl-ru,simon2:en-de-fr-it-es-hb-pl-ru';
      DefaultValuesCPUType='auto,386,386_slow,486_slow,pentium_slow,386_prefetch';
      DefaultValuesCPUTypeStaging='auto,386,386_fast,386_prefetch,486,pentium,pentium_mmx';
      DefaultValuesCPUTypeX='auto,8086,8086_prefetch,80186,80186_prefetch,286,286_prefetch,386,386_prefetch,486old,486old_prefetch,486,486_prefetch,pentium,pentium_mmx,ppro_slow,pentium_ii,pentium_iii,experimental';
      DefaultValuesCPUTypePure='auto,386,386_slow,486_slow,pentium_slow,pentium_mmx,386_prefetch';
      DefaultValuesOplEmu='default,compat,fast,old';
      DefaultValuesOplEmuX='default,compat,fast,nuked,mame,opl2board,opl3duoboard,retrowave_opl3,esfmu,cqm';
      DefaultValuesOplEmuPure='default,nuked';
      DefaultValuesPCSpeakerStaging='impulse,discrete,none';
      DefaultValuesLptDacStaging='disney,covox,ston1,off';
      DefaultValuesSBFilterStaging='auto,sb1,sb2,sbpro1,sbpro2,sb16,modern,off';
      DefaultValuesGUSFilterStaging='on,off';
      DefaultValuesGUSMemSizeX='256,512,1024,2048,4096,8192';
      DefaultValuesGUSTypeX='classic,classic37,max,interwave';
      DefaultValuesGUSMasterVolumeX='6,0,-3,-6,-12,-24';
      DefaultValuesCrossfeedStaging='off,on,light,normal,strong';
      DefaultValuesReverbStaging='off,on,tiny,small,medium,large,huge';
      DefaultValuesChorusStaging='off,on,light,normal,strong';
      DefaultValuesPCSpeakerFilterStaging='on,off';
      DefaultValuesLptDacFilterStaging='on,off';
      DefaultValuesPS1AudioX='on,off';
      DefaultValuesFluidChorusStaging='auto,on,off';
      DefaultValuesFluidReverbStaging='auto,on,off';
      DefaultValuesFluidFilterStaging='on,off';
      DefaultValuesFluidChorusX='yes,no';
      DefaultValuesFluidReverbX='yes,no';
      DefaultValuesFluidDriverX='default,dsound,wasapi,winmm,portaudio,pulseaudio,alsa,oss,coreaudio,sndman,jack,file';
      DefaultValuesMIDIBaseX='0,300,310,320,330,332,334,336,340,360,c0d0,c8d0,d0d0,d8d0,e0d0,e8d0,f0d0,f8d0,80d2,80d4,80d6,80d8,80da,80dc,80de';
      DefaultValuesMIDIIRQX='-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15';
      DefaultValuesMIDISampleRateX='49716,48000,44100,32000,22050,16000,11025,8000';
      DefaultValuesReelMagic='off,cardonly,on';
      DefaultValuesReelMagicKey='auto,common,thehorde';
      DefaultValuesReelMagicFCode='0,1,2,3,4,5,6,7';
      { Glide / Voodoo — Default = shared by all kinds that use the control;
        kind-specific suffix when value sets differ (X, NewStaging, Pure). }
      DefaultValuesGlideEmulation='false,true,emu';
      DefaultValuesGlideEmulationPort='400,500,600';
      DefaultValuesGlideEmulationLFB='full,read,write,none';
      DefaultValuesGlideEmulationLFBX='full_noaux,full,read_noaux,read,write_noaux,write,none';
      { Memory: X maxmem + Staging voodoo_memsize share 4|12; Pure also has 8. }
      DefaultValuesGlideVoodooMem='4,12';
      DefaultValuesGlideVoodooMemPure='4,8,12';
      { Card / performance: X voodoo_card vs Pure dosbox_pure_voodoo_perf. }
      DefaultValuesGlideVoodooCardX='false,software,opengl,auto';
      DefaultValuesGlideVoodooPerfPure='auto,0,1,2,3,4';
      { Staging 0.83+ only. }
      DefaultValuesGlideVoodooThreads='auto,1,2,4,8,16';
      DefaultValuesGlideVoodooBilinear='true,false';
      { Pure only. }
      DefaultValuesGlideVoodooScale='1,2,3,4,5,6,7,8';
      DefaultValuesGlideVoodooGamma='-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,999';
      DefaultValuesInnovaEmulationSampleRate='44100,48000,32000,22050,16000,11025,8000,49716';
      DefaultValuesInnovaEmulationBaseAddress='240,220,260,280,2a0,2c0,2e0,300';
      DefaultValuesInnovaEmulationQuality='0,1,2,3';
      DefaultValuesNE2000EmulationBaseAddress='300,400,500';
      DefaultValuesNE2000EmulationInterrupt='3,5,7,10,11';
      DefaultValuesMT32ReverbMode='0,1,2,3,auto';
      DefaultValuesMT32ReverbTime='0,1,2,3,4,5,6,7';
      DefaultValuesMT32ReverbLevel='0,1,2,3,4,5,6,7';

implementation
end.
