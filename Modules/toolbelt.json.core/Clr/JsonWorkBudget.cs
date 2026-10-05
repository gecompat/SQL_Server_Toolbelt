using System;

namespace Toolbelt.JsonCore
{
    /// <summary>
    /// Eigene abstrakte Arbeit wird vor dem Schritt belastet. Dieser Zähler
    /// misst weder CPUinstruktionen noch fremde SQL-/CLR-Transportallokationen.
    /// </summary>
    public sealed class JsonWorkBudget
    {
        private readonly long initial;
        private long remaining;

        public JsonWorkBudget(long maximum)
        {
            if (maximum <= 0) throw new ArgumentOutOfRangeException("maximum");
            initial = remaining = maximum;
        }

        public long Remaining { get { return remaining; } }
        public long Used { get { return initial - remaining; } }

        public void Spend(long cost)
        {
            if (cost < 0) throw new ArgumentOutOfRangeException("cost");
            // Keine Addition: auch long.MaxValue kann das Gate nicht umgehen.
            if (cost > remaining) throw new JsonWorkLimitException();
            remaining -= cost;
        }
    }

    /// <summary>Nur dieser fachliche Abbruch wird später zu LIMIT umgesetzt.</summary>
    public sealed class JsonWorkLimitException : Exception
    {
        public JsonWorkLimitException() : base("EVALUATION_LIMIT") { }
    }
}
