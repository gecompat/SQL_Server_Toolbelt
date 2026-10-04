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
// Geänderter C#-Port durch Codex, 2026-10-04: geschlossenes Alphabet extern; vollständiger Scanner ohne Default4/Clamp.
using System;
using System.Text;
namespace Toolbelt.String.Phonetic
{
    internal static class DoubleMetaphoneKernel
    {
        // Kontextprüfung ist ordinal und behält auch Kontroll-/Satzzeichen im Text.
        private static bool contains(string value, int start, int length, params string[] criteria)
        {
            if (start < 0 || length < 0 || start > value.Length - length) return false;
            foreach (string candidate in criteria)
                if (candidate.Length == length && string.CompareOrdinal(value, start, candidate, 0, length) == 0) return true;
            return false;
        }
        private static bool isSilentStart(string value) { return contains(value, 0, 2, "GN", "KN", "PN", "WR", "PS"); }
        private static bool isSlavoGermanic(string value) { return value.IndexOf('W') >= 0 || value.IndexOf('K') >= 0 || value.IndexOf("CZ", StringComparison.Ordinal) >= 0 || value.IndexOf("WITZ", StringComparison.Ordinal) >= 0; }
        private static bool isVowel(char value) { return "AEIOUY".IndexOf(value) >= 0; }
        // Kein Clamp: ein Append ist vollständig oder wirft die deklarierte Quote.
        internal sealed class DoubleMetaphoneResult
        {
            private readonly StringBuilder primary = new StringBuilder();
            private readonly StringBuilder alternate = new StringBuilder();
            internal string Primary { get { return primary.ToString(); } }
            internal string Alternate { get { return alternate.ToString(); } }
            private static void Add(StringBuilder target, string value)
            {
                if (checked(target.Length + value.Length) > PhoneticInput.MaximumCode) throw new PhoneticQuotaException();
                target.Append(value);
            }
            internal void append(char value) { append(value, value); }
            internal void append(char left, char right) { appendPrimary(left); appendAlternate(right); }
            internal void append(string value) { append(value, value); }
            internal void append(string left, string right) { appendPrimary(left); appendAlternate(right); }
            internal void appendPrimary(char value) { Add(primary, value.ToString()); }
            internal void appendAlternate(char value) { Add(alternate, value.ToString()); }
            internal void appendPrimary(string value) { Add(primary, value); }
            internal void appendAlternate(string value) { Add(alternate, value); }
        }
internal static DoubleMetaphoneResult Encode(string value) {


        bool slavoGermanic = isSlavoGermanic(value);
        int index = isSilentStart(value) ? 1 : 0;

        DoubleMetaphoneResult result = new DoubleMetaphoneResult();

        while (index <= value.Length - 1) {
            switch (value[index]) {
            case 'A':
            case 'E':
            case 'I':
            case 'O':
            case 'U':
            case 'Y':
                index = handleAEIOUY(result, index);
                break;
            case 'B':
                result.append('P');
                index = charAt(value, index + 1) == 'B' ? index + 2 : index + 1;
                break;
            case '\u00C7':
                
                result.append('S');
                index++;
                break;
            case 'C':
                index = handleC(value, result, index);
                break;
            case 'D':
                index = handleD(value, result, index);
                break;
            case 'F':
                result.append('F');
                index = charAt(value, index + 1) == 'F' ? index + 2 : index + 1;
                break;
            case 'G':
                index = handleG(value, result, index, slavoGermanic);
                break;
            case 'H':
                index = handleH(value, result, index);
                break;
            case 'J':
                index = handleJ(value, result, index, slavoGermanic);
                break;
            case 'K':
                result.append('K');
                index = charAt(value, index + 1) == 'K' ? index + 2 : index + 1;
                break;
            case 'L':
                index = handleL(value, result, index);
                break;
            case 'M':
                result.append('M');
                index = conditionM0(value, index) ? index + 2 : index + 1;
                break;
            case 'N':
                result.append('N');
                index = charAt(value, index + 1) == 'N' ? index + 2 : index + 1;
                break;
            case '\u00D1':
                
                result.append('N');
                index++;
                break;
            case 'P':
                index = handleP(value, result, index);
                break;
            case 'Q':
                result.append('K');
                index = charAt(value, index + 1) == 'Q' ? index + 2 : index + 1;
                break;
            case 'R':
                index = handleR(value, result, index, slavoGermanic);
                break;
            case 'S':
                index = handleS(value, result, index, slavoGermanic);
                break;
            case 'T':
                index = handleT(value, result, index);
                break;
            case 'V':
                result.append('F');
                index = charAt(value, index + 1) == 'V' ? index + 2 : index + 1;
                break;
            case 'W':
                index = handleW(value, result, index);
                break;
            case 'X':
                index = handleX(value, result, index);
                break;
            case 'Z':
                index = handleZ(value, result, index, slavoGermanic);
                break;
            default:
                index++;
                break;
            }
        }

        return result;
    }
private static bool conditionC0(string value, int index) {
        if (contains(value, index, 4, "CHIA")) {
            return true;
        }
        if (index <= 1) {
            return false;
        }
        if (isVowel(charAt(value, index - 2))) {
            return false;
        }
        if (!contains(value, index - 1, 3, "ACH")) {
            return false;
        }
        char c = charAt(value, index + 2);
        return c != 'I' && c != 'E' ||
                contains(value, index - 2, 6, "BACHER", "MACHER");
    }

private static bool conditionCH0(string value, int index) {
        if (index != 0) {
            return false;
        }
        if (!contains(value, index + 1, 5, "HARAC", "HARIS") &&
                   !contains(value, index + 1, 3, "HOR", "HYM", "HIA", "HEM")) {
            return false;
        }
        return !contains(value, 0, 5, "CHORE");
    }

private static bool conditionCH1(string value, int index) {
        return contains(value, 0, 4, "VAN ", "VON ") || contains(value, 0, 3, "SCH") ||
                contains(value, index - 2, 6, "ORCHES", "ARCHIT", "ORCHID") ||
                contains(value, index + 2, 1, "T", "S") ||
                (contains(value, index - 1, 1, "A", "O", "U", "E") || index == 0) &&
                 (contains(value, index + 2, 1, "L", "R", "N", "M", "B", "H", "F", "V", "W", " ") || index + 1 == value.Length - 1);
    }

private static bool conditionL0(string value, int index) {
        if (index == value.Length - 3 &&
            contains(value, index - 1, 4, "ILLO", "ILLA", "ALLE")) {
            return true;
        }
        return (contains(value, value.Length - 2, 2, "AS", "OS") ||
                contains(value, value.Length - 1, 1, "A", "O")) &&
                contains(value, index - 1, 4, "ALLE");
    }

private static bool conditionM0(string value, int index) {
        if (charAt(value, index + 1) == 'M') {
            return true;
        }
        return contains(value, index - 1, 3, "UMB") &&
               (index + 1 == value.Length - 1 || contains(value, index + 2, 2, "ER"));
    }

private static int handleAEIOUY(DoubleMetaphoneResult result, int index) {
        if (index == 0) {
            result.append('A');
        }
        return index + 1;
    }

private static int handleC(string value, DoubleMetaphoneResult result, int index) {
        if (conditionC0(value, index)) {  
            result.append('K');
            index += 2;
        } else if (index == 0 && contains(value, index, 6, "CAESAR")) {
            result.append('S');
            index += 2;
        } else if (contains(value, index, 2, "CH")) {
            index = handleCH(value, result, index);
        } else if (contains(value, index, 2, "CZ") &&
                   !contains(value, index - 2, 4, "WICZ")) {
            
            result.append('S', 'X');
            index += 2;
        } else if (contains(value, index + 1, 3, "CIA")) {
            
            result.append('X');
            index += 3;
        } else if (contains(value, index, 2, "CC") &&
                   !(index == 1 && charAt(value, 0) == 'M')) {
            
            return handleCC(value, result, index);
        } else if (contains(value, index, 2, "CK", "CG", "CQ")) {
            result.append('K');
            index += 2;
        } else if (contains(value, index, 2, "CI", "CE", "CY")) {
            
            if (contains(value, index, 3, "CIO", "CIE", "CIA")) {
                result.append('S', 'X');
            } else {
                result.append('S');
            }
            index += 2;
        } else {
            result.append('K');
            if (contains(value, index + 1, 2, " C", " Q", " G")) {
                
                index += 3;
            } else if (contains(value, index + 1, 1, "C", "K", "Q") &&
                       !contains(value, index + 1, 2, "CE", "CI")) {
                index += 2;
            } else {
                index++;
            }
        }

        return index;
    }

private static int handleCC(string value, DoubleMetaphoneResult result, int index) {
        if (contains(value, index + 2, 1, "I", "E", "H") &&
            !contains(value, index + 2, 2, "HU")) {
            
            if (index == 1 && charAt(value, index - 1) == 'A' ||
                contains(value, index - 1, 5, "UCCEE", "UCCES")) {
                
                result.append("KS");
            } else {
                
                result.append('X');
            }
            index += 3;
        } else {    
            result.append('K');
            index += 2;
        }

        return index;
    }

private static int handleCH(string value, DoubleMetaphoneResult result, int index) {
        if (index > 0 && contains(value, index, 4, "CHAE")) {   
            result.append('K', 'X');
            return index + 2;
        }
        if (conditionCH0(value, index)) {
            
            result.append('K');
            return index + 2;
        }
        if (conditionCH1(value, index)) {
            
            result.append('K');
            return index + 2;
        }
        if (index > 0) {
            if (contains(value, 0, 2, "MC")) {
                result.append('K');
            } else {
                result.append('X', 'K');
            }
        } else {
            result.append('X');
        }
        return index + 2;
    }

private static int handleD(string value, DoubleMetaphoneResult result, int index) {
        if (contains(value, index, 2, "DG")) {
            
            if (contains(value, index + 2, 1, "I", "E", "Y")) {
                result.append('J');
                index += 3;
                
            } else {
                result.append("TK");
                index += 2;
            }
        } else if (contains(value, index, 2, "DT", "DD")) {
            result.append('T');
            index += 2;
        } else {
            result.append('T');
            index++;
        }
        return index;
    }

private static int handleG(string value, DoubleMetaphoneResult result, int index,
                        bool slavoGermanic) {
        if (charAt(value, index + 1) == 'H') {
            index = handleGH(value, result, index);
        } else if (charAt(value, index + 1) == 'N') {
            if (index == 1 && isVowel(charAt(value, 0)) && !slavoGermanic) {
                result.append("KN", "N");
            } else if (!contains(value, index + 2, 2, "EY") &&
                       charAt(value, index + 1) != 'Y' && !slavoGermanic) {
                result.append("N", "KN");
            } else {
                result.append("KN");
            }
            index += 2;
        } else if (contains(value, index + 1, 2, "LI") && !slavoGermanic) {
            result.append("KL", "L");
            index += 2;
        } else if (index == 0 &&
                   (charAt(value, index + 1) == 'Y' ||
                    contains(value, index + 1, 2, "ES", "EP", "EB", "EL", "EY", "IB", "IL", "IN", "IE", "EI", "ER"))) {
            
            result.append('K', 'J');
            index += 2;
        } else if ((contains(value, index + 1, 2, "ER") ||
                    charAt(value, index + 1) == 'Y') &&
                   !contains(value, 0, 6, "DANGER", "RANGER", "MANGER") &&
                   !contains(value, index - 1, 1, "E", "I") &&
                   !contains(value, index - 1, 3, "RGY", "OGY")) {
            
            result.append('K', 'J');
            index += 2;
        } else if (contains(value, index + 1, 1, "E", "I", "Y") ||
                   contains(value, index - 1, 4, "AGGI", "OGGI")) {
            
            if (contains(value, 0, 4, "VAN ", "VON ") ||
                contains(value, 0, 3, "SCH") ||
                contains(value, index + 1, 2, "ET")) {
                
                result.append('K');
            } else if (contains(value, index + 1, 3, "IER")) {
                result.append('J');
            } else {
                result.append('J', 'K');
            }
            index += 2;
        } else {
            if (charAt(value, index + 1) == 'G') {
                index += 2;
            } else {
                index++;
            }
            result.append('K');
        }
        return index;
    }

private static int handleGH(string value, DoubleMetaphoneResult result, int index) {
        if (index > 0 && !isVowel(charAt(value, index - 1))) {
            result.append('K');
            index += 2;
        } else if (index == 0) {
            if (charAt(value, index + 2) == 'I') {
                result.append('J');
            } else {
                result.append('K');
            }
            index += 2;
        } else if (index > 1 && contains(value, index - 2, 1, "B", "H", "D") ||
                   index > 2 && contains(value, index - 3, 1, "B", "H", "D") ||
                   index > 3 && contains(value, index - 4, 1, "B", "H")) {
            
            index += 2;
        } else {
            if (index > 2 && charAt(value, index - 1) == 'U' &&
                contains(value, index - 3, 1, "C", "G", "L", "R", "T")) {
                
                result.append('F');
            } else if (index > 0 && charAt(value, index - 1) != 'I') {
                result.append('K');
            }
            index += 2;
        }
        return index;
    }

private static int handleH(string value, DoubleMetaphoneResult result, int index) {
        
        if ((index == 0 || isVowel(charAt(value, index - 1))) &&
            isVowel(charAt(value, index + 1))) {
            result.append('H');
            index += 2;
            
        } else {
            index++;
        }
        return index;
    }

private static int handleJ(string value, DoubleMetaphoneResult result, int index,
                        bool slavoGermanic) {
        if (contains(value, index, 4, "JOSE") || contains(value, 0, 4, "SAN ")) {
                
                if (index == 0 && charAt(value, index + 4) == ' ' ||
                     value.Length == 4 || contains(value, 0, 4, "SAN ")) {
                    result.append('H');
                } else {
                    result.append('J', 'H');
                }
                index++;
            } else {
                if (index == 0 && !contains(value, index, 4, "JOSE")) {
                    result.append('J', 'A');
                } else if (isVowel(charAt(value, index - 1)) && !slavoGermanic &&
                           (charAt(value, index + 1) == 'A' || charAt(value, index + 1) == 'O')) {
                    result.append('J', 'H');
                } else if (index == value.Length - 1) {
                    result.append('J', ' ');
                } else if (!contains(value, index + 1, 1, "L", "T", "K", "S", "N", "M", "B", "Z") &&
                           !contains(value, index - 1, 1, "S", "K", "L")) {
                    result.append('J');
                }

                if (charAt(value, index + 1) == 'J') {
                    index += 2;
                } else {
                    index++;
                }
            }
        return index;
    }

private static int handleL(string value, DoubleMetaphoneResult result, int index) {
        if (charAt(value, index + 1) == 'L') {
            if (conditionL0(value, index)) {
                result.appendPrimary('L');
            } else {
                result.append('L');
            }
            index += 2;
        } else {
            index++;
            result.append('L');
        }
        return index;
    }

private static int handleP(string value, DoubleMetaphoneResult result, int index) {
        if (charAt(value, index + 1) == 'H') {
            result.append('F');
            index += 2;
        } else {
            result.append('P');
            index = contains(value, index + 1, 1, "P", "B") ? index + 2 : index + 1;
        }
        return index;
    }

private static int handleR(string value, DoubleMetaphoneResult result, int index,
                        bool slavoGermanic) {
        if (index == value.Length - 1 && !slavoGermanic &&
            contains(value, index - 2, 2, "IE") &&
            !contains(value, index - 4, 2, "ME", "MA")) {
            result.appendAlternate('R');
        } else {
            result.append('R');
        }
        return charAt(value, index + 1) == 'R' ? index + 2 : index + 1;
    }

private static int handleS(string value, DoubleMetaphoneResult result, int index,
                        bool slavoGermanic) {
        if (contains(value, index - 1, 3, "ISL", "YSL")) {
            
            index++;
        } else if (index == 0 && contains(value, index, 5, "SUGAR")) {
            
            result.append('X', 'S');
            index++;
        } else if (contains(value, index, 2, "SH")) {
            if (contains(value, index + 1, 4, "HEIM", "HOEK", "HOLM", "HOLZ")) {
                
                result.append('S');
            } else {
                result.append('X');
            }
            index += 2;
        } else if (contains(value, index, 3, "SIO", "SIA") || contains(value, index, 4, "SIAN")) {
            
            if (slavoGermanic) {
                result.append('S');
            } else {
                result.append('S', 'X');
            }
            index += 3;
        } else if (index == 0 && contains(value, index + 1, 1, "M", "N", "L", "W") ||
                   contains(value, index + 1, 1, "Z")) {
            
            
            
            
            result.append('S', 'X');
            index = contains(value, index + 1, 1, "Z") ? index + 2 : index + 1;
        } else if (contains(value, index, 2, "SC")) {
            index = handleSC(value, result, index);
        } else {
            if (index == value.Length - 1 && contains(value, index - 2, 2, "AI", "OI")) {
                
                result.appendAlternate('S');
            } else {
                result.append('S');
            }
            index = contains(value, index + 1, 1, "S", "Z") ? index + 2 : index + 1;
        }
        return index;
    }

private static int handleSC(string value, DoubleMetaphoneResult result, int index) {
        if (charAt(value, index + 2) == 'H') {
            
            if (contains(value, index + 3, 2, "OO", "ER", "EN", "UY", "ED", "EM")) {
                
                if (contains(value, index + 3, 2, "ER", "EN")) {
                    
                    result.append("X", "SK");
                } else {
                    result.append("SK");
                }
            } else if (index == 0 && !isVowel(charAt(value, 3)) && charAt(value, 3) != 'W') {
                result.append('X', 'S');
            } else {
                result.append('X');
            }
        } else if (contains(value, index + 2, 1, "I", "E", "Y")) {
            result.append('S');
        } else {
            result.append("SK");
        }
        return index + 3;
    }

private static int handleT(string value, DoubleMetaphoneResult result, int index) {
        if (contains(value, index, 4, "TION") || contains(value, index, 3, "TIA", "TCH")) {
            result.append('X');
            index += 3;
        } else if (contains(value, index, 2, "TH") || contains(value, index, 3, "TTH")) {
            if (contains(value, index + 2, 2, "OM", "AM") ||
                
                contains(value, 0, 4, "VAN ", "VON ") ||
                contains(value, 0, 3, "SCH")) {
                result.append('T');
            } else {
                result.append('0', 'T');
            }
            index += 2;
        } else {
            result.append('T');
            index = contains(value, index + 1, 1, "T", "D") ? index + 2 : index + 1;
        }
        return index;
    }

private static int handleW(string value, DoubleMetaphoneResult result, int index) {
        if (contains(value, index, 2, "WR")) {
            
            result.append('R');
            index += 2;
        } else if (index == 0 && (isVowel(charAt(value, index + 1)) ||
                           contains(value, index, 2, "WH"))) {
            if (isVowel(charAt(value, index + 1))) {
                
                result.append('A', 'F');
            } else {
                
                result.append('A');
            }
            index++;
        } else if (index == value.Length - 1 && isVowel(charAt(value, index - 1)) ||
                   contains(value, index - 1, 5, "EWSKI", "EWSKY", "OWSKI", "OWSKY") ||
                   contains(value, 0, 3, "SCH")) {
            
            result.appendAlternate('F');
            index++;
        } else if (contains(value, index, 4, "WICZ", "WITZ")) {
            
            result.append("TS", "FX");
            index += 4;
        } else {
            index++;
        }
        return index;
    }

private static int handleX(string value, DoubleMetaphoneResult result, int index) {
        if (index == 0) {
            result.append('S');
            index++;
        } else {
            if (!(index == value.Length - 1 &&
                  (contains(value, index - 3, 3, "IAU", "EAU") ||
                   contains(value, index - 2, 2, "AU", "OU")))) {
                
                result.append("KS");
            }
            index = contains(value, index + 1, 1, "C", "X") ? index + 2 : index + 1;
        }
        return index;
    }

private static int handleZ(string value, DoubleMetaphoneResult result, int index,
                        bool slavoGermanic) {
        if (charAt(value, index + 1) == 'H') {
            
            result.append('J');
            index += 2;
        } else {
            if (contains(value, index + 1, 2, "ZO", "ZI", "ZA") ||
                slavoGermanic && index > 0 && charAt(value, index - 1) != 'T') {
                result.append("S", "TS");
            } else {
                result.append('S');
            }
            index = charAt(value, index + 1) == 'Z' ? index + 2 : index + 1;
        }
        return index;
    }

private static char charAt(string value, int index) {
        if (index < 0 || index >= value.Length) {
            return '\0';
        }
        return value[index];
    }
    }
}
