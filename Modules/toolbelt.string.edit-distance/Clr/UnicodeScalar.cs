using System;

namespace Toolbelt.String.Unicode
{
    // Einziger interner Scalar-Decoder für Distanz und Jaro; keine Normalisierung.
    internal static class UnicodeScalar
    {
        public static int CountStrict(string text)
        {
            int count = 0;
            for (int i=0; i<text.Length; i++,count++)
            {
                char ch=text[i];
                if (Char.IsHighSurrogate(ch))
                {
                    if (i+1==text.Length || !Char.IsLowSurrogate(text[i+1])) throw new ArgumentException("UTF16");
                    i++;
                }
                else if (Char.IsLowSurrogate(ch)) throw new ArgumentException("UTF16");
            }
            return count;
        }

        public static int[] DecodeValidated(string text,int count)
        {
            int[] values=new int[count]; int j=0;
            for(int i=0;i<text.Length;i++)
            {
                values[j++]=Char.ConvertToUtf32(text,i);
                if(Char.IsHighSurrogate(text[i])) i++;
            }
            return values;
        }
    }
}
