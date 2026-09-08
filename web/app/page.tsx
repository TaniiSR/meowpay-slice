"use client";

import { useEffect, useMemo, useState } from "react";
import { getCats, getTransferHistory, sendTreats, topUp } from "@/lib/api";
import type { Cat, Transfer } from "@/lib/types";

export default function Home() {
  const [cats, setCats] = useState<Cat[]>([]);
  const [transfers, setTransfers] = useState<Transfer[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [fromCatId, setFromCatId] = useState("");
  const [toCatId, setToCatId] = useState("");
  const [amount, setAmount] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [formSuccess, setFormSuccess] = useState<string | null>(null);

  const catsById = useMemo(() => new Map(cats.map((cat) => [cat.id, cat])), [cats]);

  async function loadInitial() {
    setLoading(true);
    setLoadError(null);
    try {
      const [catList, transferList] = await Promise.all([getCats(), getTransferHistory()]);
      setCats(catList);
      setTransfers(transferList);
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : "Failed to load MeowPay data");
    } finally {
      setLoading(false);
    }
  }

  async function refreshQuietly() {
    const [catList, transferList] = await Promise.all([getCats(), getTransferHistory()]);
    setCats(catList);
    setTransfers(transferList);
  }

  useEffect(() => {
    // loadInitial() only touches state after its internal await resolves, so this
    // is the standard "fetch on mount" effect, not a synchronous setState-in-effect.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    loadInitial();
  }, []);

  async function handleTopUp(catId: string) {
    setFormError(null);
    setFormSuccess(null);
    try {
      await topUp(catId, 20);
      await refreshQuietly();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : "Top-up failed");
    }
  }

  async function handleTransfer(e: React.FormEvent) {
    e.preventDefault();
    setFormError(null);
    setFormSuccess(null);

    if (!fromCatId || !toCatId) {
      setFormError("Pick a sender and a recipient");
      return;
    }
    if (fromCatId === toCatId) {
      setFormError("A cat can't send treats to itself");
      return;
    }
    const amountTreats = Number(amount);
    if (!Number.isInteger(amountTreats) || amountTreats <= 0) {
      setFormError("Amount must be a positive whole number of treats");
      return;
    }

    setSubmitting(true);
    try {
      await sendTreats(fromCatId, toCatId, amountTreats);
      setFormSuccess(
        `Sent ${amountTreats} treat${amountTreats === 1 ? "" : "s"} from ${catsById.get(fromCatId)?.name ?? "cat"} to ${catsById.get(toCatId)?.name ?? "cat"}`,
      );
      setAmount("");
      await refreshQuietly();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : "Transfer failed");
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) {
    return (
      <main className="flex flex-1 items-center justify-center">
        <p className="text-zinc-500">Loading MeowPay…</p>
      </main>
    );
  }

  if (loadError) {
    return (
      <main className="flex flex-1 flex-col items-center justify-center gap-3 px-6 text-center">
        <p className="text-red-600">Couldn&apos;t reach the MeowPay backend.</p>
        <p className="max-w-md text-sm text-zinc-500">{loadError}</p>
        <button
          onClick={loadInitial}
          className="rounded-full bg-black px-4 py-2 text-sm font-medium text-white dark:bg-white dark:text-black"
        >
          Retry
        </button>
      </main>
    );
  }

  const sortedTransfers = [...transfers].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  );

  return (
    <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-10 px-6 py-12">
      <header>
        <h1 className="text-2xl font-semibold tracking-tight">🐾 MeowPay</h1>
        <p className="text-sm text-zinc-500">Send treats between cats.</p>
      </header>

      <section aria-labelledby="cats-heading" className="flex flex-col gap-3">
        <h2 id="cats-heading" className="text-sm font-medium uppercase tracking-wide text-zinc-500">
          Cats
        </h2>
        <ul className="flex flex-col gap-2">
          {cats.map((cat) => (
            <li
              key={cat.id}
              className="flex items-center justify-between rounded-lg border border-black/10 px-4 py-3 dark:border-white/10"
            >
              <p className="font-medium">{cat.name}</p>
              <div className="flex items-center gap-3">
                <span className="font-mono text-sm">{cat.balanceTreats} 🍪</span>
                <button
                  onClick={() => handleTopUp(cat.id)}
                  className="rounded-full border border-black/10 px-3 py-1 text-xs font-medium hover:bg-black/5 dark:border-white/20 dark:hover:bg-white/10"
                  title="Top up this cat's wallet by 20 treats"
                >
                  Top up +20
                </button>
              </div>
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="transfer-heading" className="flex flex-col gap-3">
        <h2 id="transfer-heading" className="text-sm font-medium uppercase tracking-wide text-zinc-500">
          Send treats
        </h2>
        <form onSubmit={handleTransfer} className="flex flex-col gap-3 rounded-lg border border-black/10 p-4 dark:border-white/10">
          <div className="flex flex-col gap-1">
            <label htmlFor="from" className="text-xs text-zinc-500">
              From
            </label>
            <select
              id="from"
              value={fromCatId}
              onChange={(e) => setFromCatId(e.target.value)}
              className="rounded-md border border-black/10 bg-transparent px-3 py-2 dark:border-white/20"
            >
              <option value="">Select a cat…</option>
              {cats.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name} ({cat.balanceTreats} treats)
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label htmlFor="to" className="text-xs text-zinc-500">
              To
            </label>
            <select
              id="to"
              value={toCatId}
              onChange={(e) => setToCatId(e.target.value)}
              className="rounded-md border border-black/10 bg-transparent px-3 py-2 dark:border-white/20"
            >
              <option value="">Select a cat…</option>
              {cats.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label htmlFor="amount" className="text-xs text-zinc-500">
              Amount (treats)
            </label>
            <input
              id="amount"
              type="text"
              inputMode="numeric"
              pattern="[0-9]*"
              value={amount}
              onChange={(e) => setAmount(e.target.value.replace(/\D/g, ""))}
              className="rounded-md border border-black/10 bg-transparent px-3 py-2 dark:border-white/20"
              placeholder="e.g. 10"
            />
          </div>

          {formError && <p className="text-sm text-red-600">{formError}</p>}
          {formSuccess && <p className="text-sm text-green-600">{formSuccess}</p>}

          <button
            type="submit"
            disabled={submitting}
            className="rounded-full bg-black px-4 py-2 text-sm font-medium text-white disabled:opacity-50 dark:bg-white dark:text-black"
          >
            {submitting ? "Sending…" : "Send treats"}
          </button>
        </form>
      </section>

      <section aria-labelledby="history-heading" className="flex flex-col gap-3">
        <h2 id="history-heading" className="text-sm font-medium uppercase tracking-wide text-zinc-500">
          Recent transfers
        </h2>
        {sortedTransfers.length === 0 ? (
          <p className="text-sm text-zinc-500">No transfers yet.</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {sortedTransfers.map((transfer) => (
              <li
                key={transfer.id}
                className="flex items-center justify-between rounded-lg border border-black/10 px-4 py-3 text-sm dark:border-white/10"
              >
                <span>
                  {catsById.get(transfer.fromCatId)?.name ?? "Unknown"} →{" "}
                  {catsById.get(transfer.toCatId)?.name ?? "Unknown"}
                </span>
                <span className="font-mono">{transfer.amountTreats} 🍪</span>
                <span className="text-xs text-zinc-500">
                  {new Date(transfer.createdAt).toLocaleString()}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
