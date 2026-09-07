CREATE TABLE cats (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE wallets (
    id UUID PRIMARY KEY,
    cat_id UUID NOT NULL UNIQUE,
    balance_treats BIGINT NOT NULL CHECK (balance_treats >= 0),
    version INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE transfers (
    id UUID PRIMARY KEY,
    from_cat_id UUID NOT NULL,
    to_cat_id UUID NOT NULL,
    amount_treats BIGINT NOT NULL CHECK (amount_treats > 0),
    created_at TIMESTAMPTZ NOT NULL,
    CHECK (from_cat_id <> to_cat_id)
);
