using System;
using System.Collections;
using System.Data.SqlTypes;
using System.Reflection;
using Microsoft.SqlServer.Server;
using Toolbelt.Xlsx.Qualification;
internal static class TransportHarness
{
    private static int checks;
    private static void Assert(bool value) { checks++; if (!value) throw new Exception("TRANSPORT_ASSERT"); }
    private static SqlChars C(string value) { return value == null ? SqlChars.Null : new SqlChars(value.ToCharArray()); }
    private static void Case(SqlChars stored, SqlBoolean present, SqlChars raw, SqlChars text,
        SqlChars target, SqlChars format, SqlBoolean date1904, SqlChars culture, int expected, string display)
    {
        IEnumerable values = XlsxCellDisplayBridge.Evaluate(stored,present,raw,text,target,format,date1904,culture);
        IEnumerator iterator = values.GetEnumerator();
        try {
            Assert(iterator.MoveNext()); object row = iterator.Current;
            for (int i=0;i<2;i++) {
                SqlChars output; SqlInt32 status;
                XlsxCellDisplayBridge.FillRow(row,out output,out status);
                Assert(!status.IsNull && status.Value==expected);
                Assert(display==null ? output.IsNull : !output.IsNull && new string(output.Value)==display);
            }
            Assert(!iterator.MoveNext());
        } finally { var disposable=iterator as IDisposable; if(disposable!=null) disposable.Dispose(); }
    }
    private static int Main()
    {
        try {
            MethodInfo evaluate=typeof(XlsxCellDisplayBridge).GetMethod("Evaluate");
            var attribute=(SqlFunctionAttribute)Attribute.GetCustomAttribute(evaluate,typeof(SqlFunctionAttribute));
            Assert(attribute!=null && attribute.FillRowMethodName=="FillRow"
                && attribute.TableDefinition=="DisplayText nvarchar(max), StatusCode int"
                && attribute.DataAccess==DataAccessKind.None && attribute.SystemDataAccess==SystemDataAccessKind.None
                && attribute.IsPrecise && attribute.IsDeterministic);
            Type[] input={typeof(SqlChars),typeof(SqlBoolean),typeof(SqlChars),typeof(SqlChars),typeof(SqlChars),typeof(SqlChars),typeof(SqlBoolean),typeof(SqlChars)};
            Assert(evaluate.ReturnType==typeof(IEnumerable)); var ps=evaluate.GetParameters(); Assert(ps.Length==input.Length);
            for(int i=0;i<input.Length;i++) Assert(ps[i].ParameterType==input[i]);
            var fill=typeof(XlsxCellDisplayBridge).GetMethod("FillRow"); ps=fill.GetParameters();
            Assert(fill.ReturnType==typeof(void) && ps.Length==3 && ps[0].ParameterType==typeof(object)
                && ps[1].IsOut && ps[1].ParameterType==typeof(SqlChars).MakeByRefType()
                && ps[2].IsOut && ps[2].ParameterType==typeof(SqlInt32).MakeByRefType());
            Case(C(null),SqlBoolean.Null,C(null),C(null),C(null),C(null),SqlBoolean.Null,C(null),1,null);
            Case(C("n"),true,C("99999999999999999999999999999999999999"),C(null),C("number"),C("0%"),SqlBoolean.Null,C("en-US"),0,"9999999999999999999999999999999999999900%");
            Case(C("s"),true,C("0"),C(new string('a',32733)),C("text"),C("@"),SqlBoolean.Null,C("en-US"),0,new string('a',32733));
            Case(C("s"),true,C("0"),C(new string('a',32734)),C("text"),C("@"),SqlBoolean.Null,C("en-US"),3,null);
            Case(C("inlineStr"),false,C(null),C(""),C(null),C("@"),SqlBoolean.Null,C("en-US"),0,"");
            Case(C("n"),true,C("1"),C(null),C("number"),C("0"),SqlBoolean.Null,C("\ud800"),4,null);
            Case(C("n"),true,C(new string('1',65537)),C(null),C("number"),C("0"),SqlBoolean.Null,C("\ud800"),3,null);
            bool rejected=false;try{SqlChars d;SqlInt32 s;XlsxCellDisplayBridge.FillRow(new object(),out d,out s);}catch(InvalidOperationException){rejected=true;}
            Assert(rejected);Console.WriteLine("PASS TRANSPORT ASSERTIONS="+checks);return 0;
        } catch(Exception error) { Console.Error.WriteLine(error.Message); return 1; }
    }
}
