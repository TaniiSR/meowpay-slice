import { fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Home from "./page";
import { getCats, getTransferHistory, sendTreats, topUp } from "@/lib/api";
import type { Cat, Transfer } from "@/lib/types";

vi.mock("@/lib/api", () => ({
  getCats: vi.fn(),
  getTransferHistory: vi.fn(),
  sendTreats: vi.fn(),
  topUp: vi.fn(),
}));

const whiskers: Cat = { id: "w", name: "Whiskers", balanceTreats: 100 };
const mochi: Cat = { id: "m", name: "Mochi", balanceTreats: 50 };

function mockLoaded(cats: Cat[] = [whiskers, mochi], transfers: Transfer[] = []) {
  vi.mocked(getCats).mockResolvedValue(cats);
  vi.mocked(getTransferHistory).mockResolvedValue(transfers);
}

async function fillAndSubmit(fromName: string, toName: string, amount: string) {
  const fromSelect = screen.getByLabelText("From") as HTMLSelectElement;
  const toSelect = screen.getByLabelText("To") as HTMLSelectElement;
  fireEvent.change(fromSelect, {
    target: { value: within(fromSelect).getByText(new RegExp(`^${fromName}`)).closest("option")!.getAttribute("value") },
  });
  fireEvent.change(toSelect, {
    target: { value: within(toSelect).getByText(new RegExp(`^${toName}`)).closest("option")!.getAttribute("value") },
  });
  fireEvent.change(screen.getByLabelText("Amount (treats)"), { target: { value: amount } });
  fireEvent.click(screen.getByRole("button", { name: /send treats/i }));
}

beforeEach(() => {
  vi.mocked(getCats).mockReset();
  vi.mocked(getTransferHistory).mockReset();
  vi.mocked(sendTreats).mockReset();
  vi.mocked(topUp).mockReset();
});

describe("Home", () => {
  it("shows a loading state then the loaded cats", async () => {
    mockLoaded();
    render(<Home />);

    expect(screen.getByText(/loading meowpay/i)).toBeInTheDocument();

    const list = await screen.findByRole("list");
    expect(within(list).getByText("Whiskers")).toBeInTheDocument();
    expect(within(list).getByText("Mochi")).toBeInTheDocument();
  });

  it("shows a retry-able error when the initial load fails", async () => {
    vi.mocked(getCats).mockRejectedValue(new Error("backend is down"));
    vi.mocked(getTransferHistory).mockResolvedValue([]);
    render(<Home />);

    expect(await screen.findByText("backend is down")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /retry/i })).toBeInTheDocument();
  });

  it("rejects submitting without picking a sender and recipient", async () => {
    mockLoaded();
    render(<Home />);
    await screen.findByRole("list");

    fireEvent.click(screen.getByRole("button", { name: /send treats/i }));

    expect(await screen.findByText("Pick a sender and a recipient")).toBeInTheDocument();
    expect(sendTreats).not.toHaveBeenCalled();
  });

  it("rejects a cat sending treats to itself", async () => {
    mockLoaded();
    render(<Home />);
    await screen.findByRole("list");

    await fillAndSubmit("Whiskers", "Whiskers", "5");

    expect(await screen.findByText("A cat can't send treats to itself")).toBeInTheDocument();
    expect(sendTreats).not.toHaveBeenCalled();
  });

  it("rejects a non-positive amount", async () => {
    mockLoaded();
    render(<Home />);
    await screen.findByRole("list");

    await fillAndSubmit("Whiskers", "Mochi", "0");

    expect(await screen.findByText("Amount must be a positive whole number of treats")).toBeInTheDocument();
    expect(sendTreats).not.toHaveBeenCalled();
  });

  it("strips non-digit characters as they're typed into the amount field", async () => {
    mockLoaded();
    render(<Home />);
    await screen.findByRole("list");

    const amountField = screen.getByLabelText("Amount (treats)") as HTMLInputElement;
    fireEvent.change(amountField, { target: { value: "ab12cd" } });

    expect(amountField.value).toBe("12");
  });

  it("sends treats, shows a success message, clears the amount, and refreshes", async () => {
    mockLoaded();
    vi.mocked(sendTreats).mockResolvedValue({
      id: "t1",
      fromCatId: whiskers.id,
      toCatId: mochi.id,
      amountTreats: 15,
      createdAt: new Date().toISOString(),
    });
    render(<Home />);
    await screen.findByRole("list");

    await fillAndSubmit("Whiskers", "Mochi", "15");

    expect(await screen.findByText("Sent 15 treats from Whiskers to Mochi")).toBeInTheDocument();
    expect(sendTreats).toHaveBeenCalledWith(whiskers.id, mochi.id, 15);
    expect(screen.getByLabelText("Amount (treats)")).toHaveValue("");
    await waitFor(() => expect(getCats).toHaveBeenCalledTimes(2));
  });

  it("shows an error and clears a prior success message when a later submit fails", async () => {
    mockLoaded();
    vi.mocked(sendTreats)
      .mockResolvedValueOnce({
        id: "t1",
        fromCatId: whiskers.id,
        toCatId: mochi.id,
        amountTreats: 15,
        createdAt: new Date().toISOString(),
      })
      .mockRejectedValueOnce(new Error("Mochi doesn't have enough treats"));
    render(<Home />);
    await screen.findByRole("list");

    await fillAndSubmit("Whiskers", "Mochi", "15");
    expect(await screen.findByText("Sent 15 treats from Whiskers to Mochi")).toBeInTheDocument();

    await fillAndSubmit("Mochi", "Whiskers", "999");

    expect(await screen.findByText("Mochi doesn't have enough treats")).toBeInTheDocument();
    expect(screen.queryByText(/Sent 15 treats/)).not.toBeInTheDocument();
  });

  it("tops up a cat and refreshes", async () => {
    mockLoaded();
    vi.mocked(topUp).mockResolvedValue({ ...whiskers, balanceTreats: 120 });
    render(<Home />);
    await screen.findByRole("list");

    fireEvent.click(screen.getAllByRole("button", { name: /top up/i })[0]);

    await waitFor(() => expect(topUp).toHaveBeenCalledWith(whiskers.id, 20));
    await waitFor(() => expect(getCats).toHaveBeenCalledTimes(2));
  });

  it("disables a cat's top-up button while its request is in flight", async () => {
    mockLoaded();
    let resolveTopUp: (cat: Cat) => void = () => {};
    vi.mocked(topUp).mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveTopUp = resolve;
        }),
    );
    render(<Home />);
    await screen.findByRole("list");

    const [whiskersButton, mochiButton] = screen.getAllByRole("button", { name: /top up/i });
    fireEvent.click(whiskersButton);

    const pendingButton = await screen.findByRole("button", { name: /adding/i });
    expect(pendingButton).toBeDisabled();
    expect(mochiButton).not.toBeDisabled();

    resolveTopUp({ ...whiskers, balanceTreats: 120 });
    await waitFor(() => expect(screen.queryByRole("button", { name: /adding/i })).not.toBeInTheDocument());
  });
});
