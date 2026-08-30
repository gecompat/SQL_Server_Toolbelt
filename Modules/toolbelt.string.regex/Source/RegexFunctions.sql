SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexIsMatch]
(
      @Input   nvarchar(max)
    , @Pattern nvarchar(max)
    , @Flags   nvarchar(4) = N'c'
)
RETURNS bit
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME
    [Toolbelt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexIsMatch];
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexInstr]
(
      @Input        nvarchar(max)
    , @Pattern      nvarchar(max)
    , @Start        int = 1
    , @Occurrence   int = 1
    , @ReturnOption int = 0
    , @Flags        nvarchar(4) = N'c'
)
RETURNS int
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME
    [Toolbelt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexInstr];
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexCount]
(
      @Input   nvarchar(max)
    , @Pattern nvarchar(max)
    , @Start   int = 1
    , @Flags   nvarchar(4) = N'c'
)
RETURNS int
WITH CALLED ON NULL INPUT
AS EXTERNAL NAME
    [Toolbelt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexCount];
GO
