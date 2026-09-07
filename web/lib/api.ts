import type { ApiError, Cat, Transfer } from "./types";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...init?.headers },
  });

  if (!res.ok) {
    const body = (await res.json().catch(() => null)) as ApiError | null;
    throw new Error(body?.message ?? `Request failed with status ${res.status}`);
  }

  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export function getCats(): Promise<Cat[]> {
  return request<Cat[]>("/api/cats");
}

export function topUp(catId: string, amountTreats: number): Promise<Cat> {
  return request<Cat>(`/api/cats/${catId}/topup`, {
    method: "POST",
    body: JSON.stringify({ amountTreats }),
  });
}

export function sendTreats(
  fromCatId: string,
  toCatId: string,
  amountTreats: number,
): Promise<Transfer> {
  return request<Transfer>("/api/transfers", {
    method: "POST",
    body: JSON.stringify({ fromCatId, toCatId, amountTreats }),
  });
}

export function getTransferHistory(catId?: string): Promise<Transfer[]> {
  const query = catId ? `?catId=${encodeURIComponent(catId)}` : "";
  return request<Transfer[]>(`/api/transfers${query}`);
}
