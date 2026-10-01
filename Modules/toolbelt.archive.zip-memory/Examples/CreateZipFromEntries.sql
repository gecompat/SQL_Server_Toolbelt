-- Ausschließlich synthetische Daten.
CREATE TABLE #ZipInput(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ZipInput VALUES(1,N'hello.txt',0x48656C6C6F),(9,N'empty.txt',0x);
EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput';
EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@CompressionMethod='Deflate';
DROP TABLE #ZipInput;
