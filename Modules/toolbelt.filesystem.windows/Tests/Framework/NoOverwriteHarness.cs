using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Data.SqlTypes;
using System.Runtime.ExceptionServices;
using System.Text;
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

    // Nur das echte reine Providerpraedikat; kein Contextconnection-/Token-Nachweis.
    static void CallerAuthenticationPolicy()
    {
        MethodInfo policy=typeof(WindowsFilesystemProvider).GetMethod("IsWindowsAuthenticationScheme",BindingFlags.NonPublic|BindingFlags.Static);
        Check(policy!=null && policy.ReturnType==typeof(bool));
        foreach(string value in new string[]{"NTLM","KERBEROS","DIGEST","BASIC","NEGOTIATE"})
            Check((bool)policy.Invoke(null,new object[]{value}));
        foreach(object value in new object[]{null,DBNull.Value,"SQL","","ntlm"," NTLM","NTLM ","UNKNOWN",1,true})
            Check(!(bool)policy.Invoke(null,new object[]{value}));
    }
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
            CallerAuthenticationPolicy(); Run(); StreamingIdentityControls.Run(); success=true;
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
        Console.WriteLine("PASS FIXED_HELPER"+" CASES=9 STAGING_CREATE_ACTIONS="+stages+" SENTINEL_CREATE_ACTIONS="+sentinelCreates+" DISTINCT_OWN_PATHS="+Owned.Count+" MAX_SIMULTANEOUS_OWN_FILES="+maxSimultaneous+" ASSERTIONS="+assertions+" STREAMING_CASES="+StreamingIdentityControls.Cases+" STREAMING_ASSERTIONS="+StreamingIdentityControls.Assertions+" CLEANUP_VERIFIED=1 OFFLINE_ONLY");
        return 0;
    }
}

// Sourcegebundene Sequenzkontrolle mit SQLTypes im Speicher und synthetischem
// Executor. Keine Windows-Token-, SQL-Stream- oder NTFS-Qualifikation.
static class StreamingIdentityControls
{
    public static int Cases, Assertions;
    static bool active;
    static int calls, restores, faultCall;
    static bool faultAfter;
    static void Check(bool value) { Assertions++; if(!value) throw new InvalidOperationException("STREAMING_ASSERT"); }
    static void Execute(Action action)
    {
        Check(!active); int call=++calls; active=true;
        try
        {
            if(call==faultCall&&!faultAfter) throw new InvalidOperationException("SYNTHETIC_FS_"+call);
            action();
            if(call==faultCall&&faultAfter) throw new InvalidOperationException("SYNTHETIC_FS_"+call);
        }
        finally { active=false; restores++; }
    }
    sealed class CheckedInput : Stream
    {
        readonly MemoryStream input;
        readonly bool fail;
        public Exception Raised;
        public int Reads, Lengths;
        public CheckedInput(byte[] bytes,bool failRead) { input=new MemoryStream(bytes,false);fail=failRead; }
        public override bool CanRead { get { return true; } }
        public override bool CanSeek { get { return true; } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { Check(!active);Lengths++;return input.Length; } }
        public override long Position { get { Check(!active);return input.Position; } set { Check(!active);input.Position=value; } }
        public override int Read(byte[] buffer,int offset,int count) { Check(!active);Check(count<=1024*1024);Reads++;if(fail){Raised=new InvalidOperationException("SYNTHETIC_READ");throw Raised;}return input.Read(buffer,offset,count); }
        public override long Seek(long offset,SeekOrigin origin) { Check(!active);return input.Seek(offset,origin); }
        public override void Flush() { throw new NotSupportedException(); }
        public override void SetLength(long value) { throw new NotSupportedException(); }
        public override void Write(byte[] buffer,int offset,int count) { throw new NotSupportedException(); }
        protected override void Dispose(bool disposing) { if(disposing)input.Dispose();base.Dispose(disposing); }
    }
    static object Invoke(MethodInfo method,object[] arguments)
    {
        try { return method.Invoke(null,arguments); }
        catch(TargetInvocationException exception) { if(exception.InnerException==null)throw;ExceptionDispatchInfo.Capture(exception.InnerException).Throw();throw; }
    }
    static void Case(bool text,bool readFailure,int failOperation,bool after,string expected)
    {
        Cases++;active=false;calls=0;restores=0;faultCall=failOperation;faultAfter=after;
        string temp=Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar);
        string directory=Path.GetFullPath(Path.Combine(temp,"ToolbeltStreamingFiles-"+Guid.NewGuid().ToString("N")));
        Check(String.Equals(Path.GetDirectoryName(directory),temp,StringComparison.Ordinal));
        Check(!Directory.Exists(directory)&&!File.Exists(directory));
        string target=Path.Combine(directory,"target.bin");bool own=false;FileStream seenOutput=null;
        byte[] payload=new byte[expected==null&&!text?2*1024*1024+3:4];for(int i=0;i<payload.Length;i++)payload[i]=(byte)(i%251);
        byte[] expectedBytes=payload;long written=-1;string error=null;Exception observed=null;
        Type provider=typeof(WindowsFilesystemProvider),rootType=provider.GetNestedType("Root",BindingFlags.NonPublic);
        object root=Activator.CreateInstance(rootType,true);
        rootType.GetField("RootPath",BindingFlags.Instance|BindingFlags.Public).SetValue(root,directory);
        rootType.GetField("WorkPath",BindingFlags.Instance|BindingFlags.Public).SetValue(root,null);
        MethodInfo atomic=provider.GetMethod("WriteAtomicallyScoped",BindingFlags.Static|BindingFlags.NonPublic);
        MethodInfo binary=provider.GetMethod("CopyBinaryContent",BindingFlags.Static|BindingFlags.NonPublic);
        MethodInfo textCopy=provider.GetMethod("CopyTextContent",BindingFlags.Static|BindingFlags.NonPublic);
        Check(atomic!=null&&binary!=null&&textCopy!=null);
        using(CheckedInput input=new CheckedInput(payload,readFailure))
        {
            try
            {
                Directory.CreateDirectory(directory);own=true;
                Action<FileStream> writer=delegate(FileStream output)
                {
                    Check(!active);seenOutput=output;
                    if(text)
                    {
                        Encoding encoding=new UTF8Encoding(true,true);char[] characters=new char[32769];for(int i=0;i<characters.Length;i++)characters[i]='a';
                        byte[] bytes=encoding.GetBytes(characters);byte[] bom=encoding.GetPreamble();expectedBytes=new byte[bom.Length+bytes.Length];Buffer.BlockCopy(bom,0,expectedBytes,0,bom.Length);Buffer.BlockCopy(bytes,0,expectedBytes,bom.Length,bytes.Length);
                        written=(long)Invoke(textCopy,new object[]{new SqlChars(characters),encoding,true,output,new Action<Action>(Execute)});
                    }
                    else written=(long)Invoke(binary,new object[]{new SqlBytes(input),output,new Action<Action>(Execute)});
                };
                try { Invoke(atomic,new object[]{root,target,false,writer,new Action<Action>(Execute)}); }
                catch(InvalidOperationException exception) { error=exception.Message;observed=exception; }
                Check(String.Equals(error,expected,StringComparison.Ordinal));Check(!active&&calls==restores);
                if(readFailure)
                {
                    Check(Object.ReferenceEquals(observed,input.Raised));
                    string[] secondary=observed.Data["Toolbelt.Filesystem.SecondaryFailures"] as string[];
                    Check(secondary!=null&&secondary.Length==1);
                    Check(secondary[0]==(failOperation==2?"DISPOSE_FAILED":"CLEANUP_FAILED"));
                }
                Check(Directory.GetDirectories(directory).Length==0);
                string[] files=Directory.GetFiles(directory);
                if(expected==null)
                {
                    Check(files.Length==1&&String.Equals(Path.GetFullPath(files[0]),target,StringComparison.Ordinal));
                    Check(written==expectedBytes.Length);byte[] actual=File.ReadAllBytes(target);Check(actual.Length==expectedBytes.Length);
                    bool same=true;for(int i=0;i<actual.Length;i++)if(actual[i]!=expectedBytes[i]){same=false;break;}Check(same);
                    if(!text)Check(input.Reads==3&&input.Lengths>=3);
                }
                else { Check(files.Length==0);Check(!File.Exists(target)); }
            }
            finally
            {
                // Nur eigene synthetische Handles/Pfade; fremde Dateien nie loeschen.
                if(seenOutput!=null)seenOutput.Dispose();
                if(own&&Directory.Exists(directory))
                {
                    string[] files=Directory.GetFiles(directory);Check(files.Length<=1);
                    foreach(string path in files){Check(String.Equals(Path.GetFullPath(path),target,StringComparison.Ordinal));File.Delete(path);}
                    Check(Directory.GetFiles(directory).Length==0&&Directory.GetDirectories(directory).Length==0);Directory.Delete(directory,false);
                }
            }
        }
    }
    public static void Run()
    {
        Case(false,false,0,false,null);
        Case(true,false,0,false,null);
        Case(false,true,2,true,"SYNTHETIC_READ"); // Disposefehler ersetzt Readfehler nicht.
        Case(false,false,2,false,"SYNTHETIC_FS_2"); // Write
        Case(false,false,3,false,"SYNTHETIC_FS_3"); // Flush
        Case(false,false,5,false,"SYNTHETIC_FS_5"); // Publication
        Case(false,true,3,true,"SYNTHETIC_READ"); // Cleanupfehler ersetzt Readfehler nicht.
        Check(Cases==7);Check(!active);
    }
}
