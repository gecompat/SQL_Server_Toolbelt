using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using Toolbelt.Filesystem.Windows;

// Ausschliesslich Offline-Helperpruefung; keine SQL-, Identitaets- oder NTFS-Qualifikation.
public static class NoOverwriteHarness
{
    static readonly byte[] Payload = new byte[] { 1, 2, 3, 4 };
    static readonly byte[] Sentinel = new byte[] { 9, 8, 7 };
    static readonly byte[] Empty = new byte[0];
    static readonly List<string> Owned = new List<string>();
    static string directory, target;
    static int assertions, stages, sentinelCreates, movesObserved, maxSimultaneous;
    static bool ownDirectoryCreated;
    static object root;
    static MethodInfo helper;

    static void Check(bool condition) { assertions++; if (!condition) throw new InvalidOperationException("FIXTURE_ASSERT"); }
    static bool Same(byte[] a, byte[] b) { if (a.Length != b.Length) return false; for (int i=0;i<a.Length;i++) if(a[i]!=b[i])return false; return true; }
    static void Own(string path)
    {
        string canonical=Path.GetFullPath(path);
        Check(String.Equals(Path.GetDirectoryName(canonical),directory,StringComparison.Ordinal));
        if (!Owned.Contains(canonical)) Owned.Add(canonical);
        Check(Owned.Count<=12);
    }
    static void AuditFiles()
    {
        string[] current=Directory.GetFiles(directory);
        Check(Directory.GetDirectories(directory).Length==0);
        Check(current.Length<=12);
        if (current.Length>maxSimultaneous) maxSimultaneous=current.Length;
        foreach(string path in current) Check(Owned.Contains(Path.GetFullPath(path)));
    }
    static void CreateSentinel()
    {
        Own(target);
        using(FileStream stream=new FileStream(target,FileMode.CreateNew,FileAccess.Write,FileShare.None)) stream.Write(Sentinel,0,Sentinel.Length);
        sentinelCreates++;
        AuditFiles();
    }
    static void CaptureStage(FileStream stream)
    {
        string path=Path.GetFullPath(stream.Name);
        string name=Path.GetFileName(path);
        Guid id;
        Check(name.Length==42 && name.StartsWith(".tbx-",StringComparison.Ordinal) && name.EndsWith(".part",StringComparison.Ordinal));
        Check(Guid.TryParseExact(name.Substring(5,32),"N",out id));
        Check(!Owned.Contains(path));
        Own(path); stages++;
        AuditFiles();
    }
    static void Invoke(bool overwrite,bool createDuringWrite,bool failWrite,bool empty,Type expectedException)
    {
        Action<FileStream> write=delegate(FileStream stream)
        {
            CaptureStage(stream);
            byte[] bytes=empty?Empty:Payload;
            stream.Write(bytes,0,bytes.Length);
            if(createDuringWrite) CreateSentinel();
            if(failWrite) throw new InvalidOperationException("SYNTHETIC_WRITE_FAILURE");
        };
        bool rejected=false;
        try
        {
            helper.Invoke(null,new object[]{root,target,overwrite,write});
        }
        catch(TargetInvocationException exception)
        {
            if(expectedException==null || exception.InnerException==null || exception.InnerException.GetType()!=expectedException) throw new InvalidOperationException("FIXTURE_UNEXPECTED_EXCEPTION");
            if(expectedException==typeof(InvalidOperationException) &&
               (!String.Equals(exception.InnerException.Message,"SYNTHETIC_WRITE_FAILURE",StringComparison.Ordinal) || exception.InnerException.InnerException!=null))
                throw new InvalidOperationException("FIXTURE_UNEXPECTED_SYNTHETIC_FAILURE");
            rejected=true;
        }
        Check(rejected==(expectedException!=null));
        AuditFiles();
        foreach(string path in Owned) if(!String.Equals(path,target,StringComparison.Ordinal)) Check(!File.Exists(path));
    }
    static void TargetEquals(byte[] expected)
    {
        Check(File.Exists(target)); Check(Same(File.ReadAllBytes(target),expected));
        movesObserved++;
    }
    static void ClearTarget()
    {
        AuditFiles();
        if(File.Exists(target))
        {
            byte[] bytes=File.ReadAllBytes(target);
            Check(Same(bytes,Payload)||Same(bytes,Sentinel)||Same(bytes,Empty));
            File.Delete(target);
        }
        Check(Directory.GetFiles(directory).Length==0);
    }
    static void Run()
    {
        // A/B: ein zeitlich garantierter Konkurrent im Writecallback, keine Timingwette.
        Invoke(false,true,false,false,typeof(IOException));
        TargetEquals(Sentinel); ClearTarget();
        Invoke(false,false,false,false,null); TargetEquals(Payload); ClearTarget();
        Invoke(false,false,false,true,null); TargetEquals(Empty); ClearTarget();
        // D ist nur Helperpruefung; der unveraenderte Public-precheck wird nicht ausgefuehrt.
        CreateSentinel(); Invoke(false,false,false,false,typeof(IOException));
        TargetEquals(Sentinel); ClearTarget();
        CreateSentinel(); Invoke(true,false,false,false,null); TargetEquals(Payload); ClearTarget();
        Invoke(true,false,false,false,null); TargetEquals(Payload); ClearTarget();
        Invoke(false,false,true,false,typeof(InvalidOperationException)); Check(!File.Exists(target)); ClearTarget();
        CreateSentinel(); Invoke(false,false,true,false,typeof(InvalidOperationException)); TargetEquals(Sentinel); ClearTarget();
        CreateSentinel(); Invoke(true,false,true,false,typeof(InvalidOperationException)); TargetEquals(Sentinel); ClearTarget();
        Check(stages==9); Check(sentinelCreates==5); Check(Owned.Count==10); Check(maxSimultaneous<=2);
    }
    public static int Main(string[] args)
    {
        bool success=false,cleanup=true;
        try
        {
            if(args.Length!=0) throw new InvalidOperationException("FIXTURE_ARGUMENT");
            string temp=Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar);
            directory=Path.GetFullPath(Path.Combine(temp,"ToolbeltNoOverwriteFiles-"+Guid.NewGuid().ToString("N")));
            Check(String.Equals(Path.GetDirectoryName(directory),temp,StringComparison.Ordinal));
            Check(!Directory.Exists(directory)&&!File.Exists(directory));
            Directory.CreateDirectory(directory); ownDirectoryCreated=true;
            target=Path.Combine(directory,"target.bin"); Own(target);
            Type provider=typeof(WindowsFilesystemProvider);
            Type rootType=provider.GetNestedType("Root",BindingFlags.NonPublic);
            root=Activator.CreateInstance(rootType,true);
            rootType.GetField("RootPath",BindingFlags.Instance|BindingFlags.Public).SetValue(root,directory);
            rootType.GetField("WorkPath",BindingFlags.Instance|BindingFlags.Public).SetValue(root,null);
            helper=provider.GetMethod("WriteAtomically",BindingFlags.Static|BindingFlags.NonPublic);
            Check(helper!=null && helper.GetParameters().Length==4);
            Run(); success=true;
        }
        catch { success=false; }
        finally
        {
            try
            {
                if(ownDirectoryCreated && directory!=null && Directory.Exists(directory))
                {
                    AuditFiles();
                    foreach(string path in Owned)
                    {
                        if(File.Exists(path))
                        {
                            byte[] bytes=File.ReadAllBytes(path);
                            if(!Same(bytes,Payload)&&!Same(bytes,Sentinel)&&!Same(bytes,Empty)) throw new InvalidOperationException("FIXTURE_CLEANUP_UNKNOWN_BYTES");
                            File.Delete(path);
                        }
                    }
                    Check(Directory.GetFiles(directory).Length==0 && Directory.GetDirectories(directory).Length==0);
                    Directory.Delete(directory,false);
                }
            }
            catch { cleanup=false; }
        }
        if(!success||!cleanup) { Console.WriteLine("FAILED OFFLINE_NO_OVERWRITE CLEANUP_VERIFIED="+(cleanup?"1":"0")); return 1; }
        Console.WriteLine("PASS FIXED_HELPER"+" CASES=9 STAGING_CREATE_ACTIONS="+stages+" SENTINEL_CREATE_ACTIONS="+sentinelCreates+" DISTINCT_OWN_PATHS="+Owned.Count+" MAX_SIMULTANEOUS_OWN_FILES="+maxSimultaneous+" ASSERTIONS="+assertions+" CLEANUP_VERIFIED=1 OFFLINE_ONLY");
        return 0;
    }
}