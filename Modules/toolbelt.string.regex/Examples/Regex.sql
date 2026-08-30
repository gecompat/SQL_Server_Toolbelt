SELECT toolbelt_string.SVF_RegexIsMatch(
           N'order-2048', N'^order-\d+$', N'c') AS IsOrderKey;

SELECT toolbelt_string.SVF_RegexInstr(
           N'alpha 12 beta 34', N'\d+', 1, 2, 0, N'c') AS SecondNumberStart;

SELECT toolbelt_string.SVF_RegexCount(
           N'alpha 12 beta 34', N'\d+', 1, N'c') AS NumberCount;
