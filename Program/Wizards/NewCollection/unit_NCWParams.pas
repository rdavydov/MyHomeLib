{******************************************************************************}
{                                                                              }
{ MyHomeLib                                                                    }
{                                                                              }
{ Version 0.9                                                                  }
{ 20.08.2008                                                                   }
{ Copyright (c) Aleksey Penkov  alex.penkov@gmail.com                          }
{                                                                              }
{ @author Nick Rymanov nrymanov@gmail.com                                      }
{                                                                              }
{******************************************************************************}

unit unit_NCWParams;

interface

uses unit_globals;

type
  TNCWOperation = (otNew, otExisting, otInpx, otDownload);
  TNCWCollectionType = (ltEmpty, ltLRELocal, ltLREOnline, ltUserFB2, ltUserAny);
  TNCWFileTypes = (ftFB2, ftAny);

  TNCWParams = record
    Operation: TNCWOperation;
    CollectionType: TNCWCollectionType;
    FileTypes: TNCWFileTypes;
    DefaultGenres: Boolean;
    GenreFile: string;
    DisplayName: string;
    CollectionFile: string;
    CollectionRoot: string;
    RelativePaths: Boolean;
    INPXFile: string;
    Code: Integer;
    Notes: string;
    URL: string;
    Script: string;
    INPXUrl: string;
    //
    // �������� ��� ���������
    //
    CollectionCode: COLLECTION_TYPE;
  end;
  PNCWParams = ^TNCWParams;

implementation

end.

