unit FMDOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, fileinfo, FileUtil, Forms, Graphics, LazFileUtils, LazUTF8;

type

  { TIniFileRun }

  TIniFileRun = class(IniFiles.TMemIniFile)
  private
    FCSLock: TRTLCriticalSection;
    FFileAge: LongInt;
    FRealFileName: String;
  public
    constructor Create(const AFileName: String; AEscapeLineFeeds: Boolean = False); overload; override;
    destructor Destroy; override;
    procedure UpdateFile; override;
  end;

  TFMDDo = (DO_NOTHING, DO_EXIT, DO_POWEROFF, DO_HIBERNATE, DO_UPDATE);

const
  UPDATE_URL = 'https://raw.githubusercontent.com/riderkick/FMD/master/update';
  CHANGELOG_URL = 'https://raw.githubusercontent.com/riderkick/FMD/master/changelog.txt';
  UPDATE_PACKAGE_NAME = 'updatepackage.7z';

  FMD_REVISION = '$WCREV$';
  FMD_INSTANCE = '_FreeMangaDownloaderInstance_';
  FMD_TARGETOS  = {$i %FPCTARGETOS%};
  FMD_TARGETCPU = {$i %FPCTARGETCPU%};

  EXPARAM_PATH = '%PATH%';
  EXPARAM_CHAPTER = '%CHAPTER%';
  DEFAULT_EXPARAM = '"' + EXPARAM_PATH + EXPARAM_CHAPTER + '"';

  DEFAULT_MANGA_CUSTOMRENAME = '%MANGA%';
  DEFAULT_CHAPTER_CUSTOMRENAME = '%CHAPTER%';
  DEFAULT_FILENAME_CUSTOMRENAME = '%FILENAME%';

  DATA_EXT = '.dat';
  DBDATA_EXT = '.db';
  DBDATA_SERVER_EXT = '.7z';
  UPDATER_EXE = 'updater.exe';
  OLD_UPDATER_EXE = 'old_' + UPDATER_EXE;
  ZIP_EXE = '7za.exe';
  RUN_EXE = '.run';


  SOCKHEARTBEATRATE = 500;
  {$IFDEF WINDOWS}
  {$IFDEF WIN32}
  MAX_TASKLIMIT = 16;
  MAX_CONNECTIONPERHOSTLIMIT = 64;
  {$ENDIF}
  {$IFDEF WIN64}
  MAX_TASKLIMIT = 64;
  MAX_CONNECTIONPERHOSTLIMIT = 256;
  {$ENDIF}
  {$ELSE}
  MAX_TASKLIMIT = 8;
  MAX_CONNECTIONPERHOSTLIMIT = 32;
  {$ENDIF}

var
  FMD_VERSION_NUMBER: TProgramVersion;
  FMD_VERSION_STRING,
  FMD_DIRECTORY,
  FMD_EXENAME,
  CURRENT_UPDATER_EXE,
  OLD_CURRENT_UPDATER_EXE,
  CURRENT_ZIP_EXE,
  APPDATA_DIRECTORY,
  DEFAULT_PATH,
  WORK_FOLDER,
  WORK_FILE,
  WORK_FILEDB,
  DOWNLOADEDCHAPTERS_FILE,
  DOWNLOADEDCHAPTERSDB_FILE,
  FAVORITES_FILE,
  FAVORITESDB_FILE,
  CONFIG_FOLDER,
  CONFIG_FILE,
  CONFIG_ADVANCED,
  REVISION_FILE,
  UPDATE_FILE,
  MANGALIST_FILE,
  ACCOUNTS_FILE,
  WEBSITE_CONFIG_FILE,
  DATA_FOLDER,
  IMAGE_FOLDER,
  LANGUAGE_FILE,
  CHANGELOG_FILE,
  DEFAULT_LOG_FILE,
  README_FILE,
  EXTRAS_FOLDER,
  MANGAFOXTEMPLATE_FOLDER,
  LUA_WEBSITEMODULE_FOLDER,
  LUA_WEBSITEMODULE_REPOS: String;
  DEFAULT_SELECTED_WEBSITES: String = 'MangaFox,MangaHere,MangaInn,MangaReader';

  // ini files
  revisionfile,
  updatesfile: TIniFile;
  configfile,
  advancedfile: TIniFileRun;

  // db data download url
  DBDownloadURL: String = 'https://sourceforge.net/projects/newfmd/files/data/<website>.7z/download';

  currentWebsite: String;

  // available website
  AvailableWebsites: TStringList;

  // general
  OptionLetFMDDo: TFMDDo = DO_NOTHING;
  OptionDeleteCompletedTasksOnClose: Boolean = False;

  // saveto
  OptionChangeUnicodeCharacter: Boolean = False;
  OptionChangeUnicodeCharacterStr: String = '_';
  OptionGenerateMangaFolder: Boolean = False;
  OptionMangaCustomRename: String;
  OptionGenerateChapterFolder: Boolean = True;
  OptionChapterCustomRename: String;
  OptionFilenameCustomRename: String;

  OptionConvertDigitVolume: Boolean;
  OptionConvertDigitChapter: Boolean;
  OptionConvertDigitVolumeLength: Integer;
  OptionConvertDigitChapterLength: Integer;

  OptionPDFQuality: Cardinal = 95;

  OptionWebPSaveAs: Integer = 1;
  OptionPNGCompressionLevel: Integer = 1;
  OptionJPEGQuality: Integer = 80;

  // connections
  OptionMaxParallel: Integer = 1;
  OptionMaxThreads: Integer = 1;
  OptionMaxRetry: Integer = 5;
  OptionConnectionTimeout: Integer = 30;
  OptionRetryFailedTask: Integer = 1;
  OptionAlwaysStartTaskFromFailedChapters: Boolean = True;

  // view
  OptionEnableLoadCover: Boolean = False;
  OptionShowBalloonHint: Boolean = True;

  // updates
  OptionAutoCheckLatestVersion: Boolean = True;
  OptionAutoCheckFavStartup: Boolean = True;
  OptionAutoCheckFavInterval: Boolean = True;
  OptionAutoCheckFavIntervalMinutes: Cardinal = 60;
  OptionNewMangaTime: Integer = 1;
  OptionJDNNewMangaTime: Integer = MaxInt;
  OptionAutoCheckFavDownload: Boolean = False;
  OptionAutoCheckFavRemoveCompletedManga: Boolean = False;
  OptionUpdateListNoMangaInfo: Boolean = False;
  OptionUpdateListRemoveDuplicateLocalData: Boolean = False;

  // modules
  OptionModulesUpdaterShowUpdateWarning: Boolean = True;
  OptionModulesUpdaterAutoRestart: Boolean = False;

  OptionHTTPUseGzip: Boolean = True;

  OptionRemoveMangaNameFromChapter: Boolean = False;

  OptionRestartFMD: Boolean = False;

  //custom color
  //basiclist
  CL_BSNormalText: TColor = clWindowText;
  CL_BSFocusedSelectionText: TColor = clHighlightText;
  CL_BSUnfocesedSelectionText: TColor = clWindowText;
  CL_BSOdd: TColor = clBtnFace;
  CL_BSEven: TColor = clWindow;
  CL_BSSortedColumn: TColor = $F8E6D6;

  //mangalist color
  CL_MNNewManga: TColor = $FDC594;
  CL_MNCompletedManga: TColor = $B8FFB8;

  //favoritelist color
  CL_FVBrokenFavorite: TColor = $8080FF;
  CL_FVChecking: TColor = $80EBFE;
  CL_FVNewChapterFound: TColor = $FDC594;
  CL_FVCompletedManga: TColor = $B8FFB8;
  CL_FVEmptyChapters: TColor = $CCDDFF;

  //chapterlist color
  CL_CHDownloaded: TColor = $B8FFB8;

// set base directory
procedure SetFMDdirectory(const ADir: String);
procedure SetAppDataDirectory(const ADir: String);

procedure RestartFMD;
procedure DoRestartFMD;

implementation

uses FMDVars, UTF8Process;

{ TIniFileRun }

constructor TIniFileRun.Create(const AFileName: String; AEscapeLineFeeds: Boolean);
begin
  FRealFileName := AFileName;
  if FileExistsUTF8(AFileName + RUN_EXE) then
    DeleteFileUTF8(RUN_EXE);
  if FileExistsUTF8(AFileName) then
    CopyFile(AFileName, AFileName + RUN_EXE);
  InitCriticalSection(FCSLock);
  if FileExistsUTF8(AFileName) then
    FFileAge := FileAgeUTF8(AFileName)
  else
    FFileAge := 0;
  inherited Create(AFileName + RUN_EXE, AEscapeLineFeeds);
end;

destructor TIniFileRun.Destroy;
begin
  inherited Destroy;
  DoneCriticalsection(FCSLock);
  if FileExistsUTF8(FileName) then
    DeleteFileUTF8(FileName);
end;

procedure TIniFileRun.UpdateFile;
begin
  if CacheUpdates and (Dirty = False) then Exit;
  inherited UpdateFile;
  try
    CopyFile(FileName, FRealFileName, [cffOverwriteFile, cffPreserveTime, cffCreateDestDirectory]);
  except
  end;
end;

procedure FreeNil(var Obj);
begin
  if Pointer(Obj) <> nil then
    TObject(Obj).Free;
  Pointer(Obj) := nil;
end;

procedure FreeIniFiles;
begin
  FreeNil(configfile);
  FreeNil(advancedfile);
end;

procedure SetIniFiles;
begin
  FreeIniFiles;
  configfile := TIniFileRun.Create(CONFIG_FILE);
  advancedfile := TIniFileRun.Create(CONFIG_ADVANCED);
end;

procedure SetFMDdirectory(const ADir: String);
begin
  FMD_DIRECTORY := CleanAndExpandDirectory(ADir);
  FMD_EXENAME := ExtractFileNameOnly(Application.ExeName);

  CONFIG_FOLDER := FMD_DIRECTORY + 'config' + PathDelim;
  REVISION_FILE := CONFIG_FOLDER + 'revision.ini';
  UPDATE_FILE := CONFIG_FOLDER + 'updates.ini';
  MANGALIST_FILE := CONFIG_FOLDER + 'mangalist.ini';

  IMAGE_FOLDER := FMD_DIRECTORY + 'images' + PathDelim;
  LANGUAGE_FILE := FMD_DIRECTORY + 'languages.ini';
  CHANGELOG_FILE := FMD_DIRECTORY + 'changelog.txt';
  README_FILE := FMD_DIRECTORY + 'readme.rtf';
  EXTRAS_FOLDER := FMD_DIRECTORY + 'extras' + PathDelim;
  MANGAFOXTEMPLATE_FOLDER := EXTRAS_FOLDER + 'mangafoxtemplate' + PathDelim;
  DEFAULT_LOG_FILE := FMD_DIRECTORY + FMD_EXENAME + '.log';
  CURRENT_UPDATER_EXE := FMD_DIRECTORY + UPDATER_EXE;
  OLD_CURRENT_UPDATER_EXE := FMD_DIRECTORY + OLD_UPDATER_EXE;
  CURRENT_ZIP_EXE := FMD_DIRECTORY + ZIP_EXE;

  LUA_WEBSITEMODULE_FOLDER := FMD_DIRECTORY + 'lua' + PathDelim + 'modules' + PathDelim;
  LUA_WEBSITEMODULE_REPOS := CONFIG_FOLDER + 'luamodules.json';
end;

procedure SetAppDataDirectory(const ADir: String);
begin
  APPDATA_DIRECTORY := CleanAndExpandDirectory(ADir);

  DEFAULT_PATH := 'downloads' + PathDelim;

  CONFIG_FOLDER := APPDATA_DIRECTORY + 'config' + PathDelim;
  CONFIG_FILE := CONFIG_FOLDER + 'config.ini';
  CONFIG_ADVANCED := CONFIG_FOLDER + 'advanced.ini';
  ACCOUNTS_FILE := CONFIG_FOLDER + 'accounts.db';
  WEBSITE_CONFIG_FILE := CONFIG_FOLDER + 'websiteconfig.ini';

  DATA_FOLDER := APPDATA_DIRECTORY + 'data' + PathDelim;

  WORK_FOLDER := APPDATA_DIRECTORY + 'works' + PathDelim;
  WORK_FILE := WORK_FOLDER + 'works.ini';
  WORK_FILEDB := WORK_FOLDER + 'downloads.db';
  DOWNLOADEDCHAPTERS_FILE := WORK_FOLDER + 'downloadedchapters.ini';
  DOWNLOADEDCHAPTERSDB_FILE := WORK_FOLDER + 'downloadedchapters.db';
  FAVORITES_FILE := WORK_FOLDER + 'favorites.ini';
  FAVORITESDB_FILE := WORK_FOLDER + 'favorites.db';

  SetIniFiles;
end;

procedure RestartFMD;
begin
  OptionRestartFMD := True;
  FormMain.Close;
end;

procedure DoRestartFMD;
var
  p: TProcessUTF8;
  i: Integer;
begin
  p := TProcessUTF8.Create(nil);
  try
    p.InheritHandles := False;
    p.CurrentDirectory := ExtractFilePath(Application.ExeName);
    p.Executable := Application.ExeName;
    for i := 1 to ParamCount do
      p.Parameters.Add(ParamStrUTF8(i));
    p.Execute;
  finally
    p.Free;
  end;
end;

procedure doInitialization;
begin
  GetProgramVersion(FMD_VERSION_NUMBER);
  FMD_VERSION_STRING := ProgramversionToStr(FMD_VERSION_NUMBER);
  AvailableWebsites := TStringList.Create;
  AvailableWebsites.Sorted := False;
  SetFMDdirectory(ExtractFilePath(Application.ExeName));
  SetAppDataDirectory(FMD_DIRECTORY);
end;

procedure doFinalization;
begin
  FreeIniFiles;
  AvailableWebsites.Free;
end;

initialization
  doInitialization;

finalization
  doFinalization;

end.
