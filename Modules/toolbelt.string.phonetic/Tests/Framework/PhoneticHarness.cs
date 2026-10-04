using System;
using System.Collections;
using System.Data.SqlTypes;
using System.Globalization;
using System.Reflection;

// Reiner Kandidatenkonsum: kein Providerbuild und kein SQL-/Trustzugriff.
public static class PhoneticHarness
{
 private static int assertions;
 private static Type bridge;
 private static void Need(bool value) { assertions++; if (!value) throw new InvalidOperationException("PHONETIC_HARNESS_ASSERT"); }
 private static object[] Row(string method,string text)
 {
  IEnumerable rows=(IEnumerable)bridge.GetMethod(method).Invoke(null,new object[]{text==null?SqlChars.Null:new SqlChars(text.ToCharArray())});
  Need(rows.GetType().IsArray); IEnumerator iterator=rows.GetEnumerator();
  Need(iterator.MoveNext());object row=iterator.Current;Need(row!=null);Need(!iterator.MoveNext());
  IDisposable disposable=iterator as IDisposable;if(disposable!=null)disposable.Dispose();
  return method=="EvaluateCologne"?new object[]{row,SqlString.Null,SqlInt32.Null}:new object[]{row,SqlString.Null,SqlString.Null,SqlInt32.Null};
 }
 private static void Cologne(string text,string expected,int error)
 {
  object[] row=Row("EvaluateCologne",text);bridge.GetMethod("FillCologneRow").Invoke(null,row);
  SqlString code=(SqlString)row[1];SqlInt32 status=(SqlInt32)row[2];Need(!status.IsNull&&status.Value==error);
  Need(expected==null?code.IsNull:!code.IsNull&&string.Equals(code.Value,expected,StringComparison.Ordinal));
 }
 private static void Double(string text,string primary,string alternate,int error)
 {
  object[] row=Row("EvaluateDoubleMetaphone",text);bridge.GetMethod("FillDoubleMetaphoneRow").Invoke(null,row);
  SqlString left=(SqlString)row[1],right=(SqlString)row[2];SqlInt32 status=(SqlInt32)row[3];Need(!status.IsNull&&status.Value==error);
  Need(primary==null?left.IsNull:!left.IsNull&&string.Equals(left.Value,primary,StringComparison.Ordinal));
  Need(alternate==null?right.IsNull:!right.IsNull&&string.Equals(right.Value,alternate,StringComparison.Ordinal));
 }
 public static int Main(string[] args)
 {
  try
  {
   if(args.Length!=2)throw new InvalidOperationException("PHONETIC_HARNESS_ARGS");
   CultureInfo.CurrentCulture=CultureInfo.GetCultureInfo(args[1]);CultureInfo.CurrentUICulture=CultureInfo.CurrentCulture;
   Assembly assembly=Assembly.LoadFrom(args[0]);bridge=assembly.GetType("Toolbelt.String.Phonetic.PhoneticBridge",true);
   Need(assembly.GetName().Name=="Toolbelt.String.Phonetic"&&assembly.GetName().Version.ToString()=="1.0.0.0");
   Cologne(null,null,0);Cologne("","",0);Cologne("x","48",0);Cologne("ax","048",0);
   Cologne("cx","48",0);Cologne("mn","6",0);Cologne("ß","8",0);Cologne("H","",0);
   Cologne("BABABABAB","11111",0);Cologne(new string('ß',4096),"8",0);
   Double(null,null,null,0);Double("","","",0);Double("the","0","T",0);
   Double("quick","KK","KK",0);Double("brown","PRN","PRN",0);Double("AJ","AJ","A ",0);
   Double("BABABABAB","PPPPP","PPPPP",0);Double("\u0000\tAJ\r\n","AJ","A ",0);
   foreach(string method in new[]{"EvaluateCologne","EvaluateDoubleMetaphone"})
   {
    bool cologne=method=="EvaluateCologne";
    foreach(string bad in new[]{"\uD800","\uDC00","é\uD800"}){if(cologne)Cologne(bad,null,1);else Double(bad,null,null,1);}
    foreach(string unsupported in new[]{"é","\uD83D\uDE00","\u0301"}){if(cologne)Cologne(unsupported,null,3);else Double(unsupported,null,null,3);}
    string quota=new string('A',4097)+"\uD800";if(cologne)Cologne(quota,null,2);else Double(quota,null,null,2);
    if(cologne)Cologne("ẞ",null,3);else Double("Ä",null,null,3);
    object[] wrong=cologne?new object[]{new object(),SqlString.Null,SqlInt32.Null}:new object[]{new object(),SqlString.Null,SqlString.Null,SqlInt32.Null};
    bool rejected=false;try{bridge.GetMethod(cologne?"FillCologneRow":"FillDoubleMetaphoneRow").Invoke(null,wrong);}catch(TargetInvocationException e){rejected=e.InnerException is InvalidOperationException;}Need(rejected);
   }
   Console.WriteLine("PASS PHONETIC_FRAMEWORK;ASSERTIONS="+assertions.ToString(CultureInfo.InvariantCulture));return 0;
  }
  catch{Console.Error.WriteLine("PHONETIC_FRAMEWORK_FAILED");return 1;}
 }
}