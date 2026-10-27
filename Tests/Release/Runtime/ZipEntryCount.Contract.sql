-- Direkte Resultsetprobe. Die Zeilenreihenfolge ist SQL-seitig nicht festgelegt;
-- das PowerShell-Orakel bindet deshalb jedes Tupel an sein EntryOrdinal.
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary
      @ZipArchive = @ZipArchive
    , @MaxEntries = @MaxEntries;
