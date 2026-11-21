"""Exact reviewed functional deltas; these are NOT historical runtime reuse.

The component gate separately proves unchanged files and these specific source
changes. New behavior still requires current native qualification. No arbitrary
normalization, changed-source hash acceptance or evidence repinning is allowed.
"""

URI = 'Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql'
JSON_PATH = 'Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql'
IDENTIFIER = 'Modules/toolbelt.metadata.identifier/Source/TVF_ParseMultipartName.sql'
TRIM_N = 'Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalNvarchar.sql'
TRIM_V = 'Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalVarchar.sql'
SSIS_LOOKUP = 'Modules/toolbelt.tsql.ssis-debug/Clr/Translator.cs'
PATHS = frozenset((URI, JSON_PATH, IDENTIFIER, TRIM_N, TRIM_V, SSIS_LOOKUP))


def replace_exact(text, old, new, count=1):
    if text.count(old) != count:
        raise ValueError('CURRENT_SOURCE_DELTA_ANCHOR')
    return text.replace(old, new)


def apply(original, path):
    """Transform only the immutable original business source, never current SQL."""
    text = original.decode('utf-8').replace('\r\n', '\n')
    if path == URI:
        anchor = '    DECLARE @Output nvarchar(max),@Valid bit,@Code tinyint;'
        guard = '''    -- Procedural return before any HexValue/BinaryData evaluation.
    -- A CASE status later in the query cannot guard an eager CONVERT.
    IF EXISTS
    (
        SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesBigInt
            (1,CONVERT(bigint,DATALENGTH(@Value)/2),1) positions
        WHERE UNICODE(SUBSTRING(@Value COLLATE Latin1_General_100_BIN2,positions.Value,1))>127
    )
    BEGIN INSERT @Result VALUES(NULL,0,10,'INVALID'); RETURN; END;
'''
        text = replace_exact(text, anchor, guard + anchor)
    elif path == JSON_PATH:
        text = replace_exact(text,
            '\n                    @Token COLLATE Latin1_General_100_BIN2',
            '\n                    @Token COLLATE Latin1_General_100_BIN2\n'
            '                AND DATALENGTH(child.[key])=DATALENGTH(@Token)', 2)
        # Raw JSON grammar is literal ASCII. Linguistic/width equivalence must
        # not turn a fullwidth quote inside a string into a structural quote.
        text = replace_exact(text, "@RawUnit=N'\\'", "@RawUnit COLLATE Latin1_General_100_BIN2=N'\\'")
        text = replace_exact(text, '@RawUnit=N\'"\'', '@RawUnit COLLATE Latin1_General_100_BIN2=N\'"\'', 2)
        text = replace_exact(text, "@RawUnit IN(N'[',N'{')", "@RawUnit COLLATE Latin1_General_100_BIN2 IN(N'[',N'{')")
        text = replace_exact(text, "@RawUnit IN(N']',N'}')", "@RawUnit COLLATE Latin1_General_100_BIN2 IN(N']',N'}')")
    elif path == IDENTIFIER:
        text = replace_exact(text,
            '         * Das angehängte Zeichen verhindert, dass LEN nachgestellte\n'
            '         * Leerzeichen aus der Eingabelänge entfernt.',
            '         * Physische UTF16-Codeeinheiten einschließlich nachgestellter\n'
            '         * Spaces; dieselbe Einheit wie die binären SUBSTRING-Schritte.')
        text = replace_exact(text, "LEN(@MultipartName + N'#') - 1", 'DATALENGTH(@MultipartName) / 2')
        text = replace_exact(text, "LEN(@CurrentPart + N'#') - 1", 'DATALENGTH(@CurrentPart) / 2')
        text = replace_exact(text, 'SUBSTRING(@MultipartName,', 'SUBSTRING(@MultipartName COLLATE Latin1_General_100_BIN2,', 2)
        # Delimiters are literal ASCII; width/linguistic equivalence is not SQL
        # identifier tokenization. Equality alone still pads trailing spaces,
        # so emptiness is always a byte-length decision.
        text = replace_exact(text, 'IF @Character =', 'IF @Character COLLATE Latin1_General_100_BIN2 =', 4)
        text = replace_exact(text, "@Character <> N'.'", "@Character COLLATE Latin1_General_100_BIN2 <> N'.'")
        text = replace_exact(text, "@NextCharacter = N']'", "@NextCharacter COLLATE Latin1_General_100_BIN2 = N']'")
        text = replace_exact(text, "NULLIF(@CurrentPart, N'')", 'CASE WHEN DATALENGTH(@CurrentPart)=0 THEN NULL ELSE @CurrentPart END', 2)
        text = replace_exact(text, "CASE WHEN @CurrentPart = N'' THEN", 'CASE WHEN DATALENGTH(@CurrentPart)=0 THEN')
        text = replace_exact(text, "WHEN @AfterDelimited = 0 AND @CurrentPart = N'' THEN", 'WHEN @AfterDelimited = 0 AND DATALENGTH(@CurrentPart)=0 THEN')
        text = replace_exact(text, "@CurrentPart <> N''", 'DATALENGTH(@CurrentPart)>0')
        text = replace_exact(text, "ISNULL(PartValue, N'') = N''", "DATALENGTH(ISNULL(PartValue, N''))=0")
        text = replace_exact(text, 'LEFT(PartValue, 1)', 'LEFT(PartValue COLLATE Latin1_General_100_BIN2, 1)')
        text = replace_exact(text, 'RIGHT(PartValue, 1)', 'RIGHT(PartValue COLLATE Latin1_General_100_BIN2, 1)')
    elif path in (TRIM_N, TRIM_V):
        # Keep installation-collation positions for both NUL and membership.
        # Physical bounds can overshoot actual positions under SC/UTF8.
        text = replace_exact(text, '@Value COLLATE Latin1_General_100_BIN2, positions.Value, 1',
                             '@Value, positions.Value, 1')
        text = replace_exact(text, '        WHERE CASE\n',
            '        CROSS APPLY (VALUES (SUBSTRING(@Value, positions.Value, 1))) AS character_at_position(CharacterValue)\n'
            '        WHERE CASE\n'
            '            WHEN DATALENGTH(character_at_position.CharacterValue) = 0 THEN 1\n')
        text = replace_exact(text,
            '= 0 THEN 1\n            WHEN '+('UNICODE' if path == TRIM_N else 'ASCII')+'(SUBSTRING(@Value, positions.Value, 1))',
            '= 0 THEN 1\n            WHEN '+('UNICODE' if path == TRIM_N else 'ASCII')+'(character_at_position.CharacterValue)')
        text = replace_exact(text, 'CHARINDEX(SUBSTRING(@Value, positions.Value, 1), @Characters)',
                             'CHARINDEX(character_at_position.CharacterValue, @Characters)')
    elif path == SSIS_LOOKUP:
        text = replace_exact(text,
            '        internal string PlanSaltState, PlanSaltOwner, PlanHash;\n'
            '        internal bool FreshPerExecution;\n'
            '        internal readonly List<StageColumn> Columns = new List<StageColumn>();\n',
            '        internal string PlanSaltState, PlanSaltOwner, PlanHash;\n'
            '        internal bool FreshPerExecution, PreserveTextKeyLength;\n'
            '        internal readonly List<StageColumn> Columns = new List<StageColumn>();\n')
        text = replace_exact(text,
            '            string suffix = runToken + "_" + lookupIds[c.Id];\n'
            '            var cache = new LookupCache { Name = "#tbx_SsisDebug_L_" + suffix, StateName = "#tbx_SsisDebug_S_" + suffix };\n'
            '            if (options.CatalogMode == "package") cache.Name = "lookup_reference_" + lookupIds[c.Id];\n'
            '            cache.Inputs.UnionWith(stage.ReferenceInputs);\n'
            '            var projections = new List<string>(); var partitions = new List<string>(); var joins = new List<string>(); int ordinal = 0;\n'
            '            foreach (Column key in keys)\n',
            '            string suffix = runToken + "_" + lookupIds[c.Id];\n'
            '            var cache = new LookupCache { Name = "#tbx_SsisDebug_L_" + suffix, StateName = "#tbx_SsisDebug_S_" + suffix,\n'
            '                PreserveTextKeyLength = options.CatalogMode == "package" && PackageReader.P(c.Properties, "CacheType", "0") == "0" };\n'
            '            if (options.CatalogMode == "package") cache.Name = "lookup_reference_" + lookupIds[c.Id];\n'
            '            cache.Inputs.UnionWith(stage.ReferenceInputs);\n'
            '            var projections = new List<string>(); var partitions = new List<string>(); int ordinal = 0;\n'
            '            foreach (Column key in keys)\n')
        text = replace_exact(text,
            '                ValidateCodePage(key, right.Collation);\n'
            '                string alias = Util.Id("k", ++ordinal), normalized = Normalize("ref." + Util.Q(name), left.Type), source = Normalize("m." + Util.Q(left.Alias), left.Type);\n'
            '                cache.Columns.Add(new StageColumn { Alias = alias, Name = alias, Id = key.Id, Type = left.Type, Nullable = true, Collation = bindings.Collation });\n'
            '                projections.Add(normalized + " AS " + Util.Q(alias)); partitions.Add(normalized); joins.Add(source + " = lk." + Util.Q(alias));\n'
            '            }\n',
            '                ValidateCodePage(key, right.Collation);\n'
            '                string alias = Util.Id("k", ++ordinal), normalized = Normalize("ref." + Util.Q(name), left.Type);\n'
            '                cache.Columns.Add(new StageColumn { Alias = alias, Name = alias, Id = key.Id, Type = left.Type, Nullable = true, Collation = bindings.Collation });\n'
            '                projections.Add(normalized + " AS " + Util.Q(alias)); partitions.Add(normalized);\n'
            '                if (cache.PreserveTextKeyLength && TextType(left.Type)) partitions.Add("DATALENGTH(" + normalized + ")");\n'
            '            }\n')
        text = replace_exact(text,
            '        {\n'
            '            var joins = keys.Select(k => { StageColumn left = Find(parent, k.Lineage); StageColumn right = cache.Columns.Single(x => x.Id == k.Id && x.Alias.StartsWith("k", StringComparison.Ordinal)); return Normalize("m." + Util.Q(left.Alias), left.Type) + " = lk." + Util.Q(right.Alias); }).ToList();\n'
            '            stage.Columns.AddRange(parent.Columns); var fields = parent.Columns.Select(x => "m." + Util.Q(x.Alias) + " AS " + Util.Q(x.Alias)).ToList();\n',
            '        {\n'
            '            var joins = new List<string>();\n'
            '            foreach (Column key in keys)\n'
            '            {\n'
            '                StageColumn left = Find(parent, key.Lineage);\n'
            '                StageColumn right = cache.Columns.Single(x => x.Id == key.Id && x.Alias.StartsWith("k", StringComparison.Ordinal));\n'
            '                string source = Normalize("m." + Util.Q(left.Alias), left.Type), reference = "lk." + Util.Q(right.Alias);\n'
            '                joins.Add(source + " = " + reference);\n'
            '                // SQL equality pads strings with spaces even under BIN2. Keep the\n'
            '                // same text-and-length tuple for lookup ranking and matching.\n'
            '                if (cache.PreserveTextKeyLength && TextType(left.Type))\n'
            '                    joins.Add("DATALENGTH(" + source + ") = DATALENGTH(" + reference + ")");\n'
            '            }\n'
            '            stage.Columns.AddRange(parent.Columns); var fields = parent.Columns.Select(x => "m." + Util.Q(x.Alias) + " AS " + Util.Q(x.Alias)).ToList();\n')
    else:
        raise ValueError('CURRENT_SOURCE_DELTA_UNKNOWN_PATH')
    return text.encode('utf-8')
