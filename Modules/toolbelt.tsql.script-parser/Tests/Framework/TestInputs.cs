using System;
using System.Text;
internal static class TestInputs {
 internal static string Make(string name,int n) {
  switch(name){
   case "unary":return "SELECT "+new string('~',n)+"1;";
   case "binary":return "SELECT 1"+Repeat("+1",n)+";";
   case "not":return "SELECT 1 WHERE "+Repeat("NOT ",n)+"1=1;";
   case "paren":return "SELECT "+new string('(',n)+"1"+new string(')',n)+";";
   case "comment":return Repeat("/*",n)+"synthetic"+Repeat("*/",n)+" SELECT 1;";
   case "case":return "SELECT "+Repeat("CASE WHEN 1=1 THEN ",n)+"1"+Repeat(" ELSE 0 END",n)+";";
   case "begin":return Repeat("BEGIN ",n)+"SELECT 1;"+Repeat(" END",n);
   case "union":return "SELECT 1"+Repeat(" UNION ALL SELECT 1",n)+";";
   case "subquery":return "SELECT "+Repeat("(SELECT ",n)+"1"+new string(')',n)+";";
   case "batches":return Repeat("SELECT 1;\r\nGO\r\n",n);
   case "semicolons":return "BEGIN "+Repeat("SELECT 1;",n)+" END";
   case "trivia":return Repeat("-- synthetic\n",n)+"SELECT 1;";
   case "spaces":return new string(' ',n)+"SELECT 1;";
   case "quoted":return "SELECT N'GO; BEGIN CASE END -- /* ((( '' synthetic', [GO;]]BEGIN], \"END\"\"CASE\";";
   case "unclosed":return "SELECT 'synthetic GO ; /* ((((";
   case "unclosedcomment":return "SELECT 1 /* synthetic";
   case "numericrun":return "SELECT "+new string('1',n)+";";
      case "mixed":return Repeat("BEGIN ",16)+"SELECT "+new string('(',8+n)+Repeat("CASE WHEN 1=1 THEN ",8)+"1"+Repeat(" ELSE 0 END",8)+new string(')',8+n)+";"+Repeat(" END",16);
   case "mixedunary":return "SELECT CASE WHEN 1=1 THEN "+new string('~',n)+"1 ELSE 0 END;";
   case "commentmarkers":return "/* ' \\\" [ GO ; /* nested */ */ SELECT 1;";
   case "linemarkers":return "-- ' \\\" [ /* BEGIN ( GO ;\nSELECT 1;";
   case "unicode":return "SELECT [\uD83D\uDE00], N'\u00C4\u00D6\uD83D\uDE00'; SELECT \u03A9 FROM dbo.\u03A9;";
   case "surrogate":return "SELECT \uD83D\uDE00;";
   case "quotedbytes":return "SELECT '"+new string('x',n)+"';";
      case "exponents":return "SELECT "+Repeat("1e1 ",n)+"1;";
   case "dotted":return "SELECT "+Repeat("1.2 ",n)+"1;";
   case "symbols":return "SELECT "+Repeat("@#$",n)+"1;";
   case "combining":return "SELECT "+Repeat("a\u0301_1 ",n)+"1;";
   case "commentpriority":return new string(' ',8159)+Repeat("/*",17);
   case "width":return "SELECT 1"+Repeat(",1",n)+";";
   default:throw new Exception("unknown synthetic case");
  }
 }
 static string Repeat(string value,int n){var sb=new StringBuilder();for(int i=0;i<n;i++)sb.Append(value);return sb.ToString();}
}
