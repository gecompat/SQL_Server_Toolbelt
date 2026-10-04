/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// Geänderter C#-Port durch Codex, 2026-10-04: feste externe Transformation, checked Outputquote, unveränderter Buchstabenkontext.
using System;
using System.Text;
namespace Toolbelt.String.Phonetic
{
    internal static class CologneKernel
    {
        // Punctuation bleibt im Lookahead; nur ein echter Buchstabe ersetzt lastChar.
        internal static string Encode(string text)
        {
            StringBuilder result = new StringBuilder();
            char lastCode = '/', lastChar = '-';
            for (int index = 0; index < text.Length; index++)
            {
                char current = text[index], next = index + 1 < text.Length ? text[index + 1] : '-';
                if (current < 'A' || current > 'Z') continue;
                if ("AEIJOUY".IndexOf(current) >= 0) Put(result, '0', ref lastCode);
                else if (current == 'B' || current == 'P' && next != 'H') Put(result, '1', ref lastCode);
                else if ((current == 'D' || current == 'T') && "CSZ".IndexOf(next) < 0) Put(result, '2', ref lastCode);
                else if ("FPVW".IndexOf(current) >= 0) Put(result, '3', ref lastCode);
                else if ("GKQ".IndexOf(current) >= 0) Put(result, '4', ref lastCode);
                else if (current == 'X' && "CKQ".IndexOf(lastChar) < 0) { Put(result, '4', ref lastCode); Put(result, '8', ref lastCode); }
                else if (current == 'S' || current == 'Z') Put(result, '8', ref lastCode);
                else if (current == 'C')
                {
                    if (result.Length == 0) Put(result, "AHKLOQRUX".IndexOf(next) >= 0 ? '4' : '8', ref lastCode);
                    else Put(result, "SZ".IndexOf(lastChar) >= 0 || "AHKOQUX".IndexOf(next) < 0 ? '8' : '4', ref lastCode);
                }
                else if ("DTX".IndexOf(current) >= 0) Put(result, '8', ref lastCode);
                else if (current == 'R') Put(result, '7', ref lastCode);
                else if (current == 'L') Put(result, '5', ref lastCode);
                else if (current == 'M' || current == 'N') Put(result, '6', ref lastCode);
                else if (current == 'H') Put(result, '-', ref lastCode);
                lastChar = current;
            }
            return result.ToString();
        }
        private static void Put(StringBuilder result, char code, ref char lastCode)
        {
            if (code != '-' && lastCode != code && (code != '0' || result.Length == 0))
            {
                if (checked(result.Length + 1) > PhoneticInput.MaximumCode) throw new PhoneticQuotaException();
                result.Append(code);
            }
            lastCode = code;
        }
    }
}