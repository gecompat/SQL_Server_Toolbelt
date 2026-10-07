-- Gemeinsames SQLCMD-Queryfragment der bestehenden File-Content-Procedures.
-- @NormalizedPath verwendet dieselbe Slash-Normalisierung wie RootPath unten.
-- Dieses Fragment legt kein SQL-Objekt an und enthält keinen Batchseparator.
SELECT 1
FROM [toolbelt_file].[FileContentRootAllowlist] AS roots
CROSS APPLY
(
    VALUES (REPLACE(REPLACE(roots.RootPath, N'\\', N'/'), N'\', N'/')
            COLLATE Latin1_General_100_BIN2)
) AS normalized(NormalizedRoot)
CROSS APPLY
(
    -- Cast vor Verkettung: 4000 UTF-16-Einheiten benötigen einen Präfix mit 4001.
    VALUES (CAST(normalized.NormalizedRoot AS nvarchar(max))
            + CASE WHEN RIGHT(normalized.NormalizedRoot, 1) = N'/'
                   THEN N'' ELSE N'/' END)
) AS boundary(DirectoryPrefix)
WHERE roots.IsActive = 1
  AND DATALENGTH(normalized.NormalizedRoot) > 0
  AND
  (
      (@NormalizedPath COLLATE Latin1_General_100_BIN2 = normalized.NormalizedRoot
       AND DATALENGTH(@NormalizedPath) = DATALENGTH(normalized.NormalizedRoot))
      OR
      (DATALENGTH(@NormalizedPath) >= DATALENGTH(boundary.DirectoryPrefix)
       AND LEFT(@NormalizedPath COLLATE Latin1_General_100_BIN2,
                CONVERT(int, DATALENGTH(boundary.DirectoryPrefix) / 2))
           = boundary.DirectoryPrefix COLLATE Latin1_General_100_BIN2)
  )
