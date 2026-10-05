using System;
using Toolbelt.JsonCore;

internal static class WorkBudgetHarness
{
    private static int assertions;
    private static void Assert(bool condition)
    {
        assertions++;
        if (!condition) throw new InvalidOperationException("CORE_BUDGET_ASSERT");
    }

    public static int Main()
    {
        try
        {
            var budget = new JsonWorkBudget(9);
            Assert(budget.Remaining == 9 && budget.Used == 0);
            budget.Spend(9);
            Assert(budget.Remaining == 0 && budget.Used == 9);
            budget.Spend(0);
            Assert(budget.Remaining == 0);
            bool limited = false;
            try { budget.Spend(1); }
            catch (JsonWorkLimitException exception)
            {
                limited = true;
                Assert(exception.Message == "EVALUATION_LIMIT");
            }
            Assert(limited && budget.Remaining == 0 && budget.Used == 9);

            bool rejected = false;
            try { budget.Spend(-1); }
            catch (ArgumentOutOfRangeException) { rejected = true; }
            Assert(rejected && budget.Remaining == 0);

            var large = new JsonWorkBudget(long.MaxValue);
            large.Spend(long.MaxValue);
            Assert(large.Remaining == 0 && large.Used == long.MaxValue);
            var small = new JsonWorkBudget(1);
            limited = false;
            try { small.Spend(long.MaxValue); }
            catch (JsonWorkLimitException) { limited = true; }
            Assert(limited && small.Remaining == 1 && small.Used == 0);
            rejected = false;
            try { new JsonWorkBudget(0); }
            catch (ArgumentOutOfRangeException) { rejected = true; }
            Assert(rejected);
            rejected = false;
            try { new JsonWorkBudget(-1); }
            catch (ArgumentOutOfRangeException) { rejected = true; }
            Assert(rejected);
            Console.WriteLine("PASS CORE_BUDGET ASSERTIONS " + assertions);
            return 0;
        }
        catch (Exception)
        {
            Console.WriteLine("FAIL CORE_BUDGET");
            return 1;
        }
    }
}
