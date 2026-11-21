using System;
using System.Collections.Generic;
using System.IO;

namespace Toolbelt.Archive.ZipMemory
{
    public static partial class ZipEntryProvider
    {
        // The Windows consumer binds each relative path to its authorized root.
        // Inspect cannot mutate it. Publish must keep a file unpublished until
        // copy returns normally. Expected copy and I/O failures are returned as
        // controlled codes, including a failure after the published flag is set.
        public interface IExtractionDestination
        {
            string Inspect(string path, bool directory);
            string Publish(string path, bool directory, Action<Action<byte[], int>> copy, out bool published);
        }

        public sealed class ExtractionOutcome
        {
            internal ExtractionOutcome(int ordinal, ExtractionEntry entry, string status, long? bytesWritten, string errorCode)
            {
                Ordinal = ordinal;
                Entry = entry;
                Status = status;
                BytesWritten = bytesWritten;
                ErrorCode = errorCode;
            }

            public int Ordinal { get; private set; }
            public ExtractionEntry Entry { get; private set; }
            public string Status { get; private set; }
            public long? BytesWritten { get; private set; }
            public string ErrorCode { get; private set; }
        }

        public static IList<ExtractionOutcome> ExtractDirectory(ExtractionArchive archive, IExtractionDestination destination)
        {
            if (archive == null) throw new ArgumentNullException("archive");
            if (destination == null) throw new ArgumentNullException("destination");
            var manifest = archive.Entries;
            var paths = new string[manifest.Count];
            var planned = new List<ExtractionPath>(manifest.Count);
            var errors = new string[manifest.Count];
            var results = new List<ExtractionOutcome>(manifest.Count);

            for (int i = 0; i < manifest.Count; i++)
            {
                var entry = manifest[i];
                errors[i] = entry.ErrorCode;
                if (errors[i] != null) continue;
                errors[i] = PlanPath(entry.Name, entry.IsDirectory, out paths[i]);
                if (errors[i] == null)
                    planned.Add(new ExtractionPath
                    { Key = paths[i].Replace('\\', '\u0001'), Ordinal = i, Directory = entry.IsDirectory });
            }

            planned.Sort((a, b) => StringComparer.OrdinalIgnoreCase.Compare(a.Key, b.Key));
            int collision = FindCollision(planned, 0, planned.Count, 0, Int32.MaxValue);
            if (collision != Int32.MaxValue) errors[collision] = "PATH_COLLISION";

            for (int i = 0; i < manifest.Count; i++)
            {
                string error = errors[i];
                if (error == null)
                    error = destination.Inspect(paths[i], manifest[i].IsDirectory);
                if (error == null) continue;

                for (int j = 0; j < manifest.Count; j++)
                    results.Add(new ExtractionOutcome(j + 1, manifest[j],
                        j == i ? "failed" : "not_attempted", null, j == i ? error : null));
                return results.AsReadOnly();
            }

            bool stopped = false;
            for (int i = 0; i < manifest.Count; i++)
            {
                var entry = manifest[i];
                if (stopped)
                {
                    results.Add(new ExtractionOutcome(i + 1, entry, "not_attempted", null, null));
                    continue;
                }

                int index = i;
                long? bytes = null;
                bool published;
                string error = destination.Publish(paths[i], entry.IsDirectory, write =>
                {
                    bytes = archive.CopyVerified(index, write);
                }, out published);
                if ((published && !bytes.HasValue) || (!published && error == null))
                    throw new InvalidOperationException("ZIP_PUBLICATION_CONTRACT_FAILED");
                stopped = error != null;
                results.Add(new ExtractionOutcome(i + 1, entry, published ? "completed" : "failed",
                    published ? bytes : null, error));
            }
            return results.AsReadOnly();
        }

        private static string PlanPath(string name, bool directory, out string path)
        {
            path = null;
            string local = name.Replace('/', '\\');
            if (directory) local = local.Substring(0, local.Length - 1);
            string[] components = local.Split('\\');
            foreach (string component in components)
            {
                if (!IsWindowsPathComponent(component)) return "UNSAFE_PATH";
                if (CouldBeGeneratedShortName(component)) return "SHORT_NAME_ALIAS_FORBIDDEN";
            }
            path = local;
            return null;
        }

        // The separator sorts before every allowed path character. Equal
        // components form a contiguous range with explicit entries first.
        // Keep only one key per archive entry, even for deeply nested paths.
        private static int FindCollision(List<ExtractionPath> paths, int from, int to, int position, int collision)
        {
            while (from < to - 1)
            {
                ExtractionPath first = paths[from];
                int end = SegmentEnd(first.Key, position);
                int length = end - position;
                int next = from + 1;
                ExtractionPath earliest = first;
                while (next < to)
                {
                    ExtractionPath current = paths[next];
                    if (SegmentEnd(current.Key, position) != end ||
                        String.Compare(first.Key, position, current.Key, position, length, StringComparison.OrdinalIgnoreCase) != 0)
                        break;
                    if (current.Ordinal < earliest.Ordinal) earliest = current;
                    next++;
                }

                bool earliestIsFile = earliest.Key.Length == end && !earliest.Directory;
                int explicitFirst = Int32.MaxValue;
                int children = from;
                for (int i = from; i < next; i++)
                {
                    ExtractionPath current = paths[i];
                    bool leaf = current.Key.Length == end;
                    if (leaf)
                    {
                        children = i + 1;
                        collision = Math.Min(collision, Math.Max(explicitFirst, current.Ordinal));
                        explicitFirst = Math.Min(explicitFirst, current.Ordinal);
                    }
                    if (current.Ordinal != earliest.Ordinal &&
                        (earliestIsFile || (leaf && !current.Directory) ||
                         String.CompareOrdinal(earliest.Key, position, current.Key, position, length) != 0))
                        collision = Math.Min(collision, current.Ordinal);
                }
                if (next - children > 1)
                    collision = FindCollision(paths, children, next, end + 1, collision);
                from = next;
            }
            return collision;
        }

        private static int SegmentEnd(string path, int start)
        {
            int separator = path.IndexOf('\u0001', start);
            return separator < 0 ? path.Length : separator;
        }

        private static bool CouldBeGeneratedShortName(string component)
        {
            int dot = component.IndexOf('.');
            int stemEnd = dot < 0 ? component.Length : dot;
            if (stemEnd > 8 || stemEnd < 3 ||
                (dot >= 0 && (component.Length - dot > 4 || component.IndexOf('.', dot + 1) >= 0)))
                return false;
            int tilde = component.LastIndexOf('~', stemEnd - 1);
            if (tilde < 1 || tilde == stemEnd - 1) return false;
            for (int i = tilde + 1; i < stemEnd; i++)
                if (component[i] < '0' || component[i] > '9') return false;
            return true;
        }

        public static bool IsWindowsPathComponent(string name)
        {
            if (name.Length == 0 || name.Length > 255 || name.EndsWith(".", StringComparison.Ordinal) ||
                name.EndsWith(" ", StringComparison.Ordinal)) return false;
            foreach (char character in name)
                if (character < 32 || "<>:\"|?*/\\".IndexOf(character) >= 0) return false;
            string stem = name.Split('.')[0].TrimEnd(' ').ToUpperInvariant();
            if (stem == "CON" || stem == "PRN" || stem == "AUX" || stem == "NUL" ||
                stem == "CONIN$" || stem == "CONOUT$") return false;
            return stem.Length != 4 ||
                (stem.Substring(0, 3) != "COM" && stem.Substring(0, 3) != "LPT") ||
                "123456789¹²³".IndexOf(stem[3]) < 0;
        }

        private struct ExtractionPath
        {
            public string Key;
            public int Ordinal;
            public bool Directory;
        }
    }
}
