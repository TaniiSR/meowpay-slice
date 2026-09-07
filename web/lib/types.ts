export type Cat = {
  id: string;
  name: string;
  balanceTreats: number;
};

export type Transfer = {
  id: string;
  fromCatId: string;
  toCatId: string;
  amountTreats: number;
  createdAt: string;
};

export type ApiError = {
  error: string;
  message: string;
};
