INSERT INTO cats (id, name) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Whiskers'),
    ('22222222-2222-2222-2222-222222222222', 'Mochi'),
    ('33333333-3333-3333-3333-333333333333', 'Biscuit');

INSERT INTO wallets (id, cat_id, balance_treats) VALUES
    (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 100),
    (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 50),
    (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 0);
