using System;
using System.Collections.Generic;
using Toolbelt.JsonCore;

namespace Toolbelt.JsonSchema
{
    internal sealed class SchemaNode
    {
        internal readonly int Id;
        internal readonly string Path;
        internal readonly Dictionary<string, int> Keywords;
        internal readonly Dictionary<string, ExactJsonNumber> Bounds;
        internal readonly List<int> Edges;
        internal bool IsBoolean, BooleanValue;
        internal int TypeMask, Reference = -1;
        internal SchemaNode(int id, string path, JsonOrdinalComparer ordinal, JsonWorkBudget work, int count)
        {
            work.Spend(checked(2L * count + 5));
            Id = id; Path = path;
            Keywords = new Dictionary<string, int>(count, ordinal);
            Bounds = new Dictionary<string, ExactJsonNumber>(count, ordinal);
            Edges = new List<int>();
        }
        internal void Edge(int id, JsonWorkBudget work)
        {
            if (Edges.Count == Edges.Capacity)
            {
                int capacity = Edges.Capacity == 0 ? 4 : checked(Edges.Capacity * 2);
                work.Spend((long)capacity + Edges.Count);
                Edges.Capacity = capacity;
            }
            work.Spend(1); Edges.Add(id);
        }
    }

    /// <summary>Alle Schemaorte und danach der gesamte Containment-/Refgraph.</summary>
    internal sealed class SchemaPreflight
    {
        internal readonly SchemaTree Tree;
        internal readonly Dictionary<int, SchemaNode> Nodes;
        private readonly SortedDictionary<string, int> pending;
        private readonly List<int> order;
        internal SchemaPreflight(SchemaTree tree)
        {
            Tree = tree;
            tree.Work.Spend(checked(2L * tree.Document.Count + 3));
            Nodes = new Dictionary<int, SchemaNode>(tree.Document.Count);
            pending = new SortedDictionary<string, int>(tree.Ordinal);
            order = new List<int>(tree.Document.Count);
        }

        internal void Run()
        {
            Add(0, null);
            while (pending.Count > 0)
            {
                Tree.Work.Spend(1);
                var enumerator = pending.GetEnumerator();
                enumerator.MoveNext();
                int id = enumerator.Current.Value;
                string path = enumerator.Current.Key;
                enumerator.Dispose();
                pending.Remove(path);
                Check(Nodes[id]);
                order.Add(id);
            }
            foreach (int id in order)
            {
                SchemaNode node = Nodes[id];
                int reference;
                if (!node.Keywords.TryGetValue("$ref", out reference)) continue;
                int target = LocalSchemaReference.Resolve(Tree, reference);
                if (target < 0 || !Nodes.ContainsKey(target)) Tree.Fail("INVALID_SCHEMA", "REF_TARGET", reference, "$ref");
                node.Reference = target;
                node.Edge(target, Tree.Work);
            }
            CheckCycles();
        }

        private void Add(int id, SchemaNode owner)
        {
            Tree.Work.Spend(1);
            if (!Nodes.ContainsKey(id))
            {
                JsonToken token = Tree.Document.Get(id);
                if (token.Kind != JsonValueKind.Object && token.Kind != JsonValueKind.Boolean)
                    Tree.Fail("INVALID_SCHEMA", "SCHEMA_FORM", id, null);
                string path = Tree.Path(id);
                int count = token.Kind == JsonValueKind.Object ? Tree.Children(id, false).Count : 0;
                var node = new SchemaNode(id, path, Tree.Ordinal, Tree.Work, count);
                Nodes.Add(id, node);
                Tree.Work.Spend(1); pending.Add(path, id);
            }
            if (owner != null) owner.Edge(id, Tree.Work);
        }

        private void Check(SchemaNode node)
        {
            JsonToken schema = Tree.Document.Get(node.Id);
            if (schema.Kind == JsonValueKind.Boolean)
            {
                node.IsBoolean = true;
                node.BooleanValue = Tree.Document.RawText(node.Id) == "true";
                return;
            }
            foreach (int id in Tree.Children(node.Id, true))
            {
                JsonToken value = Tree.Document.Get(id);
                string key = value.Key;
                Tree.Work.Spend(key.Length + 1L);
                node.Keywords.Add(key, id);
                switch (key)
                {
                    case "$schema":
                        Require(id, JsonValueKind.String, key);
                        if (Tree.Ordinal.Compare(value.StringValue, "https://json-schema.org/draft/2020-12/schema") != 0)
                            Tree.Fail("UNSUPPORTED", "DRAFT", id, key);
                        break;
                    case "$ref": case "title": case "description": case "$comment":
                        Require(id, JsonValueKind.String, key); break;
                    case "$defs": case "properties":
                        Require(id, JsonValueKind.Object, key);
                        foreach (int child in Tree.Children(id, true)) Add(child, node);
                        break;
                    case "items": case "additionalProperties": Add(id, node); break;
                    case "prefixItems":
                        Require(id, JsonValueKind.Array, key);
                        List<int> prefix = Tree.Children(id, false);
                        if (prefix.Count == 0) Tree.Fail("INVALID_SCHEMA", "KEYWORD_FORM", id, key);
                        foreach (int child in prefix) Add(child, node);
                        break;
                    case "required": CheckNames(id, key); break;
                    case "type": CheckTypes(node, id); break;
                    case "minItems": case "maxItems": case "minProperties": case "maxProperties":
                    case "minLength": case "maxLength":
                        Require(id, JsonValueKind.Number, key);
                        ExactJsonNumber count = ExactJsonNumber.FromToken(Tree.Document, id, Tree.Work);
                        if (!count.IsInteger(Tree.Work) || !count.IsNonNegative(Tree.Work))
                            Tree.Fail("INVALID_SCHEMA", "KEYWORD_FORM", id, key);
                        node.Bounds.Add(key, count); break;
                    case "minimum": case "maximum": case "exclusiveMinimum": case "exclusiveMaximum":
                        Require(id, JsonValueKind.Number, key);
                        node.Bounds.Add(key, ExactJsonNumber.FromToken(Tree.Document, id, Tree.Work)); break;
                    default: Tree.Fail("UNSUPPORTED", "KEYWORD_UNSUPPORTED", id, key); break;
                }
            }
        }

        private void Require(int id, JsonValueKind kind, string keyword)
        {
            if (Tree.Document.Get(id).Kind != kind) Tree.Fail("INVALID_SCHEMA", "KEYWORD_FORM", id, keyword);
        }

        private void CheckNames(int id, string keyword)
        {
            Require(id, JsonValueKind.Array, keyword);
            List<int> children = Tree.Children(id, false);
            Tree.Work.Spend(children.Count + 1L);
            var names = new Dictionary<string, int>(children.Count, Tree.Ordinal);
            foreach (int child in children)
            {
                Require(child, JsonValueKind.String, keyword);
                string name = Tree.Document.Get(child).StringValue;
                if (names.ContainsKey(name)) Tree.Fail("INVALID_SCHEMA", "KEYWORD_FORM", child, keyword);
                names.Add(name, child);
            }
        }

        private void CheckTypes(SchemaNode node, int id)
        {
            JsonToken value = Tree.Document.Get(id);
            if (value.Kind == JsonValueKind.String) { node.TypeMask = Type(id); return; }
            Require(id, JsonValueKind.Array, "type");
            List<int> children = Tree.Children(id, false);
            if (children.Count == 0) Tree.Fail("INVALID_SCHEMA", "KEYWORD_FORM", id, "type");
            foreach (int child in children)
            {
                Require(child, JsonValueKind.String, "type");
                int type = Type(child);
                if ((node.TypeMask & type) != 0) Tree.Fail("INVALID_SCHEMA", "KEYWORD_FORM", child, "type");
                node.TypeMask |= type;
            }
        }

        private int Type(int id)
        {
            string name = Tree.Document.Get(id).StringValue;
            Tree.Work.Spend(name.Length + 1L);
            switch (name)
            {
                case "null": return 1; case "boolean": return 2; case "number": return 4;
                case "string": return 8; case "object": return 16; case "array": return 32;
                case "integer": return 64;
                default: Tree.Fail("INVALID_SCHEMA", "KEYWORD_FORM", id, "type"); return 0;
            }
        }

        private struct GraphFrame { internal int Id, Next; }
        private void CheckCycles()
        {
            Tree.Work.Spend(checked((long)Tree.Document.Count + Nodes.Count + 1));
            var colors = new byte[Tree.Document.Count];
            var stack = new GraphFrame[Nodes.Count + 1];
            foreach (int root in order)
            {
                Tree.Work.Spend(1);
                if (colors[root] != 0) continue;
                int depth = 1;
                stack[0] = new GraphFrame { Id = root };
                colors[root] = 1;
                while (depth > 0)
                {
                    Tree.Work.Spend(1);
                    GraphFrame frame = stack[depth - 1];
                    SchemaNode node = Nodes[frame.Id];
                    if (frame.Next == node.Edges.Count) { colors[frame.Id] = 2; depth--; continue; }
                    int target = node.Edges[frame.Next++];
                    stack[depth - 1] = frame;
                    if (colors[target] == 1)
                    {
                        int reference;
                        int fault = node.Keywords.TryGetValue("$ref", out reference) && target == node.Reference ? reference : target;
                        Tree.Fail("UNSUPPORTED", "REF_CYCLE", fault, "$ref");
                    }
                    if (colors[target] == 0)
                    {
                        colors[target] = 1;
                        stack[depth++] = new GraphFrame { Id = target };
                    }
                }
            }
        }
    }
}
