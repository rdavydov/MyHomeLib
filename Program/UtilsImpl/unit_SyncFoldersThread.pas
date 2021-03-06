﻿(* *****************************************************************************
  *
  * MyHomeLib
  *
  * Copyright (C) 2008-2010 Aleksey Penkov
  *
  * Author(s)           Aleksey Penkov (alex.penkov@gmail.com)
  *                     Nick Rymanov (nrymanov@gmail.com)
  * Created             20.08.2008
  * Description
  *
  * $Id$
  *
  * History
  *
  ****************************************************************************** *)

unit unit_SyncFoldersThread;

interface

uses
  Windows,
  Classes,
  SysUtils,
  unit_WorkerThread,
  unit_CollectionWorkerThread,
  unit_MHLArchiveHelpers,
  files_list;

type
  TSyncFoldersThread = class(TCollectionWorker)
  private
    FFiles: TFilesList;
    FList: TStringList;
    procedure OnFile(Sender: TObject; const F: TSearchRec);
    function FindNewFolder(const FileName: string): string;

  protected
    procedure WorkFunction; override;
  end;

implementation

uses
  jclCompression,
  unit_Consts,
  unit_MHL_strings,
  unit_Globals,
  unit_Interfaces;

resourcestring
  rstrBuildingFileList = 'Построение списка файлов ...';

{ TImportXMLThread }

function TSyncFoldersThread.FindNewFolder(const FileName: string): string;
var
  i: Integer;
begin
  Result := '*';
  for i := 0 to FList.Count - 1 do
    if Pos(FileName, FList[i]) <> 0 then
      Result := ExtractRelativePath(FCollectionRoot, ExtractFilePath(FList[i]));
end;

procedure TSyncFoldersThread.OnFile(Sender: TObject; const F: TSearchRec);
var
  Archiver: TJclZipDecompressArchive;
  Size: integer;
begin
  Size := 0;

  if not IsArchiveExt(F.Name) then
     FList.Add(FFiles.LastDir + F.Name + ' ' + IntToStr(F.Size))
  else
  begin
    Archiver := TJclZipDecompressArchive.Create(FFiles.LastDir + F.Name);
    try
      Archiver.ListFiles;
      if Archiver.ItemCount > 0 then
      begin
        Size := Integer(Archiver.Items[0].FileSize);
        FList.Add(FFiles.LastDir + F.Name + ' ' + IntToStr(Size));
      end;
    finally
      Archiver.Free;
    end;
  end;
end;

procedure TSyncFoldersThread.WorkFunction;
var
  BookIterator: IBookIterator;
  BookRecord: TBookRecord;
  NewFolder: string;
  FileName: string;
  BookFormat: TBookFormat;
  BookContainer: string;
begin
  Assert(Assigned(FSystemData));
  Assert(Assigned(FCollection));

  FList := TStringList.Create;
  try
    FProgressEngine.BeginOperation(-1, rstrBuildingFileList, rstrBuildingFileList);
    try
      FFiles := TFilesList.Create(nil);
      try
        FFiles.OnFile := OnFile;
        FFiles.TargetPath := FCollectionRoot;
        FFiles.Process;
      finally
        FFiles.Free;
      end;
    finally
      FProgressEngine.EndOperation;
    end;

    BookIterator := FCollection.GetBookIterator(bmAll, True);
    FProgressEngine.BeginOperation(BookIterator.RecordCount, rstrBookProcessedMsg1, rstrBookProcessedMsg2);
    try
      while BookIterator.Next(BookRecord) do
      begin
        if Canceled then
          Exit;

        FileName := BookRecord.GetBookFileName;
        if not FileExists(FileName)  then
        begin
          //
          // Попробуем найти файл с таким же именем и размером. Если нашли, то заменим старый путь к файлу новым.
          //
          NewFolder := FindNewFolder(ExtractFileName(FileName) + ' ' + IntToStr(BookRecord.Size));
          if NewFolder <> '*' then
          begin
            BookFormat := BookRecord.GetBookFormat;
            BookContainer := BookRecord.GetBookContainer;
            if BookFormat = bfFBD then
              BookRecord.Folder := NewFolder
            else if BookFormat = bfFb2Archive then
                   BookRecord.Folder := NewFolder + ExtractFileName(FileName)
                 else // bfFb2 or bfRaw
                    BookRecord.Folder := NewFolder;
            FCollection.SetFolder(BookRecord.BookKey, BookRecord.Folder);
          end;
        end;

        FProgressEngine.AddProgress;
      end;
    finally
      FProgressEngine.EndOperation;
    end;
  finally
    FList.Free;
  end;
end;

end.
