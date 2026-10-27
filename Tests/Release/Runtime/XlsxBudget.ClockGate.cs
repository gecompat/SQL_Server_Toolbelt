using System;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;

internal static class ClockGateFakeClockTests
{
    private static int assertions;

    private static void Require(bool condition, string name)
    {
        assertions++;
        if (!condition) throw new InvalidOperationException("CLOCK_GATE_TEST_" + name);
    }

    private static string Sha256(string path)
    {
        using (var sha = SHA256.Create())
        using (var stream = File.OpenRead(path))
        {
            byte[] hash = sha.ComputeHash(stream);
            return BitConverter.ToString(hash).Replace("-", "");
        }
    }

    private static object Invoke(MethodInfo method, params object[] args)
    {
        return method.Invoke(null, args);
    }

    private static bool Gate(MethodInfo method, int budget, uint elapsed)
    {
        return (bool)Invoke(method, budget, elapsed);
    }

    private static bool Expired(MethodInfo method, long elapsed, int budget)
    {
        return (bool)Invoke(method, elapsed, budget);
    }

    private static uint CoarseElapsed(MethodInfo method, int start, int now)
    {
        return (uint)Invoke(method, start, now);
    }

    public static int Main(string[] args)
    {
        if (args == null || args.Length != 4) return 2;
        string zipPath = Path.GetFullPath(args[0]);
        string xlsxPath = Path.GetFullPath(args[1]);
        if (!String.Equals(Sha256(zipPath), args[2], StringComparison.Ordinal) ||
            !String.Equals(Sha256(xlsxPath), args[3], StringComparison.Ordinal)) return 3;

        Assembly.LoadFrom(zipPath);
        Assembly xlsx = Assembly.LoadFrom(xlsxPath);
        Type workbook = xlsx.GetType("Toolbelt.Xlsx.Qualification.Workbook", true, false);
        const BindingFlags flags = BindingFlags.Static | BindingFlags.NonPublic;
        MethodInfo gate = workbook.GetMethod("ShouldCheckPrecise", flags);
        MethodInfo coarse = workbook.GetMethod("CoarseElapsedMilliseconds", flags);
        MethodInfo expired = workbook.GetMethod("IsBudgetExpired", flags);
        if (gate == null || coarse == null || expired == null) return 4;

        int[] budgets = { 1, 32, 33, 4999, 5000 };
        foreach (int budget in budgets)
        {
            uint threshold = budget <= 32 ? 0U : (uint)(budget - 32);
            if (budget <= 32)
            {
                Require(Gate(gate, budget, 0), "SMALL_ZERO_" + budget);
                Require(Gate(gate, budget, (uint)budget), "SMALL_AT_" + budget);
            }
            else
            {
                Require(!Gate(gate, budget, threshold - 1), "BEFORE_GATE_" + budget);
                Require(Gate(gate, budget, threshold), "AT_GATE_" + budget);
                Require(Gate(gate, budget, (uint)(budget - 1)), "NEAR_DEADLINE_" + budget);
            }
            Require(!Expired(expired, budget - 1L, budget), "PRECISE_BEFORE_" + budget);
            Require(Expired(expired, budget, budget), "PRECISE_AT_" + budget);
            Require(Expired(expired, budget + 1L, budget), "PRECISE_AFTER_" + budget);
        }

        Require(CoarseElapsed(coarse, Int32.MaxValue - 2, Int32.MinValue + 1) == 4U, "WRAP");
        Require(!Gate(gate, 5000, 0U), "STALL_SKIPS_INNER_PRECISE");
        Require(!Expired(expired, 4999L, 5000), "STALL_PRECISE_STILL_ACCEPTS_BEFORE");
        Require(Expired(expired, 5000L, 5000), "STALL_FINAL_PRECISE_REJECTS_AT");
        Require(Gate(gate, 5000, UInt32.MaxValue), "JUMP_REQUESTS_PRECISE");
        Require(!Expired(expired, 4999L, 5000), "JUMP_PRECISE_NO_EARLY_FAILURE");
        Require(Expired(expired, 5000L, 5000), "JUMP_PRECISE_EXPIRES_AT");

        Console.WriteLine("CLOCK_GATE_FAKE_TEST_PASS|assertions=" + assertions);
        return 0;
    }
}