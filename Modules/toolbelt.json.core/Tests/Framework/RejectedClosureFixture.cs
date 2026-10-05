using System;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Collections.Generic;

[assembly: AssemblyVersion("1.0.0.0")]
namespace Toolbelt.JsonCore
{
    // Ausschließlich IL-Negativfixture. Keine Methode wird jemals ausgeführt.
    public sealed class ClosureProbe
    {
#if FILE
        public static string Probe() { return System.IO.File.ReadAllText("contoso.txt"); }
#elif THREAD
        public static void Probe() { System.Threading.Thread.Sleep(1); }
#elif NETWORK
        public static string Probe() { return new System.Net.WebClient().DownloadString("https://example.com"); }
#elif CONTEXT
        public static bool Probe() { return Microsoft.SqlServer.Server.SqlContext.IsAvailable; }
#elif REFLECTION
        public static Assembly Probe() { return Assembly.Load("Contoso"); }
#elif GENERIC
        public static int Probe() { return new List<Guid>().Count; }
#elif MUTABLE
        public static int State;
        public static int Probe() { return State; }
#elif PINVOKE
        [DllImport("Contoso")]
        public static extern int Probe();
#else
#error A single rejected fixture mode is required.
#endif
    }
}
