using System;
using System.IO;
namespace Toolbelt.JsonConstructors {
public sealed class TransportState {
 public readonly bool Mode;public readonly byte Class;public readonly VState Valid;public readonly FaultState Fault;
 public TransportState(VState valid){FaultCodec.Need(valid!=null);Valid=valid;Mode=valid.ObjectMode;Class=4;}
 public TransportState(FaultState fault){FaultCodec.Need(fault!=null&&fault.Class<=3&&fault.Mode<=1);Fault=fault;Mode=fault.Mode==1;Class=fault.Class;}
}
public sealed class HeaderReplayStream : Stream {
 readonly Stream body;readonly byte[] header;int used;
 public HeaderReplayStream(Stream source,byte[] bytes){FaultCodec.Need(source!=null&&bytes!=null&&bytes.Length==112);body=source;header=bytes;}
 public override int Read(byte[] b,int o,int n){if(used<header.Length){int got=Math.Min(n,header.Length-used);Array.Copy(header,used,b,o,got);used+=got;return got;}return body.Read(b,o,n);}
 public override bool CanRead{get{return true;}}public override bool CanWrite{get{return false;}}public override bool CanSeek{get{return false;}}
 public override long Length{get{throw new NotSupportedException();}}public override long Position{get{throw new NotSupportedException();}set{throw new NotSupportedException();}}
 public override void Flush(){throw new NotSupportedException();}public override long Seek(long o,SeekOrigin s){throw new NotSupportedException();}public override void SetLength(long n){throw new NotSupportedException();}public override void Write(byte[] b,int o,int n){throw new NotSupportedException();}
 // Callerstream nicht besitzen; Dispose beendet nur diesen lokalen Replaywrapper.
 protected override void Dispose(bool disposing){base.Dispose(disposing);}
}
public static class Dispatcher {
 public static TransportState Read(Stream stream,bool expectedMode){FaultCodec.Need(stream!=null&&BitConverter.IsLittleEndian);byte[] header=FaultCodec.Exact(stream,112);FaultHeader h=FaultCodec.Parse(header,expectedMode);
  if(h.Class==4){using(HeaderReplayStream replay=new HeaderReplayStream(stream,header))return new TransportState(ValidCodec.Read(replay,expectedMode));}
  return new TransportState(FaultCodec.ReadBody(stream,header,h));
 }
 public static byte[] Write(TransportState state){FaultCodec.Need(state!=null);if(state.Class==4){FaultCodec.Need(state.Valid!=null&&state.Fault==null&&state.Valid.ObjectMode==state.Mode);return ValidCodec.Write(state.Valid);}FaultCodec.Need(state.Fault!=null&&state.Valid==null&&(state.Fault.Mode==1)==state.Mode&&state.Fault.Class==state.Class);return FaultCodec.Write(state.Fault);}
 public static void ReadInto(ref TransportState live,Stream stream,bool expectedMode){FaultCodec.Need(live!=null&&live.Mode==expectedMode);TransportState fresh=Read(stream,expectedMode);live=fresh;}
}

}
