using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Toolbelt.Ssis.Exchange
{
    /// <summary>Immutable, per-analysis size/time policy shared by the neutral model and CLR.</summary>
    public sealed class ResourceLimits
    {
        private static readonly string[] Names = {
            "packageBytes", "xmlCharacters", "xmlNodes", "modelNodes", "modelEdges", "components", "paths", "columns", "inputs",
            "jsonDocumentBytes", "allJsonBytes", "jsonNodes",
            "expressionBytes", "expressionTokens", "expressionNodes", "planUnits", "catalogObjects", "catalogQueries", "parserCalls",
            "artifacts", "diagnostics", "sqlArtifactBytes", "totalOutputBytes", "analysisMilliseconds"
        };
        private readonly Dictionary<string, long> values;
        private readonly HashSet<string> unlimitedCounters;
        public string Preset { get; private set; }
        public bool IsV2 { get; private set; }
        public bool IsUnlimited { get; private set; }
        internal bool DetailedDiagnostics { get; private set; }
        public string PolicyHash { get; private set; }
        public static IEnumerable<string> CounterNames { get { return Array.AsReadOnly((string[])Names.Clone()); } }

        private ResourceLimits(string preset, bool v2, Dictionary<string, long> limits, HashSet<string> unlimited, bool detailedDiagnostics = false)
        {
            Preset = preset; IsV2 = v2; unlimitedCounters = new HashSet<string>(unlimited, StringComparer.Ordinal); IsUnlimited = unlimitedCounters.Count == Names.Length; DetailedDiagnostics = detailedDiagnostics; values = new Dictionary<string, long>(limits, StringComparer.Ordinal);
            string canonical = preset + "\n" + String.Join("\n", Names.Select(n => n + "=" + (unlimitedCounters.Contains(n) ? "unlimited" : "finite:" + limits[n].ToString(CultureInfo.InvariantCulture))));
            using (var sha = SHA256.Create()) PolicyHash = BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(canonical))).Replace("-", "").ToLowerInvariant();
        }

        public static ResourceLimits Create(string preset, bool v2, IDictionary<string, string> overrides = null)
        {
            if (preset != "large10x" && preset != "unlimited") throw new ArgumentException("RESOURCE_PRESET");
            var unlimited = new HashSet<string>(StringComparer.Ordinal);
            var limits = Defaults(v2, preset == "unlimited", unlimited);
            if (overrides != null)
            {
                foreach (var pair in overrides)
                {
                    if (!Names.Contains(pair.Key, StringComparer.Ordinal)) throw new ArgumentException("RESOURCE_COUNTER");
                    long n;
                    if (pair.Value == "unlimited") { limits[pair.Key] = Int64.MaxValue; unlimited.Add(pair.Key); }
                    else if (!Int64.TryParse(pair.Value, NumberStyles.None, CultureInfo.InvariantCulture, out n) || n <= 0) throw new ArgumentException("RESOURCE_LIMIT_VALUE");
                    else { limits[pair.Key] = n; unlimited.Remove(pair.Key); }
                }
            }
            return new ResourceLimits(preset, v2, limits, unlimited);
        }

        /// <summary>Erzeugt das aktuelle Standardprofil aus benannten SQL-Grenzen; 0 steht für unbegrenzt.</summary>
        public static ResourceLimits CreateCurrent(IDictionary<string, long> sqlLimits = null)
        {
            var unlimited = new HashSet<string>(StringComparer.Ordinal);
            var limits = Defaults(true, false, unlimited);
            limits["analysisMilliseconds"] = Int64.MaxValue;
            unlimited.Add("analysisMilliseconds");
            if (sqlLimits != null)
            {
                foreach (var pair in sqlLimits)
                {
                    if (!Names.Contains(pair.Key, StringComparer.Ordinal)) throw new ArgumentException("RESOURCE_COUNTER");
                    if (pair.Value < 0) throw new ArgumentException("RESOURCE_LIMIT_VALUE");
                    if (pair.Value == 0) { limits[pair.Key] = Int64.MaxValue; unlimited.Add(pair.Key); }
                    else { limits[pair.Key] = pair.Value; unlimited.Remove(pair.Key); }
                }
            }
            return new ResourceLimits("current", true, limits, unlimited);
        }

        public static ResourceLimits Legacy { get { return new ResourceLimits("legacy-v1", false, Defaults(false, false, null), new HashSet<string>(StringComparer.Ordinal)); } }
        internal static ResourceLimits LegacyProbe { get { return new ResourceLimits("legacy-v1", false, Defaults(false, false, null), new HashSet<string>(StringComparer.Ordinal), true); } }
        public long Maximum(string counter) { long value; return values.TryGetValue(counter, out value) ? value : throw new ArgumentOutOfRangeException("counter"); }
        public bool IsUnlimitedCounter(string counter) { return unlimitedCounters.Contains(counter); }
        public Dictionary<string, object> Metadata()
        {
            var effective = new Dictionary<string, object>(StringComparer.Ordinal);
            foreach (string name in Names) effective.Add(name, unlimitedCounters.Contains(name) ? (object)"unlimited" : values[name]);
            return new Dictionary<string, object>(StringComparer.Ordinal) {
                {"schemaVersion",1}, {"preset",Preset}, {"unlimited",IsUnlimited}, {"effectiveLimits",effective}, {"resourcePolicyHash",PolicyHash}
            };
        }
        public void Check(string counter, long actual)
        {
            long maximum = Maximum(counter);
            if (actual > maximum) throw new ResourceLimitException(counter, actual, maximum, Preset);
        }

        private static Dictionary<string, long> Defaults(bool v2, bool unlimited, HashSet<string> unlimitedCounters)
        {
            long open = Int64.MaxValue;
            var d = new Dictionary<string, long>(StringComparer.Ordinal) {
                {"packageBytes",v2?134217728:16777216}, {"xmlCharacters",v2?134217728:16777216}, {"xmlNodes",v2?1048576:262144},
                {"modelNodes",v2?262144:20000}, {"modelEdges",v2?1048576:50000}, {"components",v2?4096:512}, {"paths",v2?8192:2048}, {"columns",v2?65536:8192}, {"inputs",v2?8192:2048},
            {"jsonDocumentBytes",v2?4194304:4194304}, {"allJsonBytes",v2?8388608:8388608}, {"jsonNodes",v2?131072:131072},
                {"expressionBytes",v2?4194304:16384}, {"expressionTokens",v2?262144:16384}, {"expressionNodes",v2?131072:4096}, {"planUnits",v2?8192:32},
                {"catalogObjects",v2?4096:256}, {"catalogQueries",v2?4096:128}, {"parserCalls",v2?32768:128}, {"artifacts",v2?65536:10000}, {"diagnostics",v2?16384:1000},
                {"sqlArtifactBytes",2097152}, {"totalOutputBytes",v2?134217728:8388608}, {"analysisMilliseconds",30000}
            };
            if (unlimited) foreach (string name in Names) { d[name] = open; unlimitedCounters.Add(name); }
            return d;
        }
    }

    public sealed class ResourceLimitException : Exception
    {
        public string Counter { get; private set; }
        public long Actual { get; private set; }
        public bool ActualIsLowerBound { get; private set; }
        public long Maximum { get; private set; }
        public string Preset { get; private set; }
        internal ResourceLimitException(string counter, long actual, long maximum, string preset, bool actualIsLowerBound = false) : base("RESOURCE_LIMIT")
        { Counter = counter; Actual = actual; ActualIsLowerBound = actualIsLowerBound; Maximum = maximum; Preset = preset; }
    }
}
