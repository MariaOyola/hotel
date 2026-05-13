CREATE OR REPLACE PROCEDURE parameterization.sp_insert_payment_methods()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO parameterization.payment_method (id, name, description, requires_reference, allows_partial_payment, status)
  VALUES
    ('00000000-0000-0000-0004-000000000001'::uuid, 'CASH',           'Cash payment at the front desk',                          FALSE, TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0004-000000000002'::uuid, 'CREDIT_CARD',    'Payment via credit card through POS terminal',            TRUE,  TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0004-000000000003'::uuid, 'DEBIT_CARD',     'Payment via debit card through POS terminal',             TRUE,  TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0004-000000000004'::uuid, 'BANK_TRANSFER',  'Wire transfer — reference number required',               TRUE,  FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0004-000000000005'::uuid, 'DIGITAL_WALLET', 'Payment via digital wallet (e.g. Nequi, Daviplata)',       TRUE,  TRUE,  'ACTIVE')
  ON CONFLICT (name) DO NOTHING;

  RAISE NOTICE 'sp_insert_payment_methods: canonical payment methods inserted.';
END;
$$;
