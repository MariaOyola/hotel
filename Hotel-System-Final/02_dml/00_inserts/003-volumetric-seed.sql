-- =============================================================================
-- 003-volumetric-seed.sql
-- DML Datos volumétricos — 20 filas por entidad operativa
--
-- PREREQUISITOS (deben existir antes de correr este script):
--   1. 001-seed-sample-data.sql  → clientes, rooms, stays, etc. del seed base
--   2. 002_dml_canonical.sql     → sp_insert_roles, sp_insert_room_status,
--                                   sp_insert_day_types, sp_insert_payment_methods,
--                                   sp_insert_admin_user (ya ejecutados via CALL)
--
-- CONVENCIÓN DE UUIDs VOLUMÉTRICOS:
--   Bloque 00000000-0000-0000-00AA-XXXXXXXXXXX
--   AA = 70 (reservado para volumétricos, no colisiona con seed ni canónico)
-- =============================================================================

DO $$
DECLARE

  -- -----------------------------------------------------------------------
  -- UUIDs FIJOS DEL SEED CANÓNICO (002_dml_canonical → sp_insert_*)
  -- Estos ya existen en la base; los usamos como FK destino
  -- -----------------------------------------------------------------------

  -- app_role (insertados por sp_insert_roles)
  role_admin         UUID := '00000000-0000-0000-0000-000003000001';
  role_manager       UUID := '00000000-0000-0000-0000-000003000002';
  role_receptionist  UUID := '00000000-0000-0000-0000-000003000003';
  role_housekeeping  UUID := '00000000-0000-0000-0000-000003000004';
  role_accounting    UUID := '00000000-0000-0000-0000-000003000005';

  -- room_status (insertados por sp_insert_room_status)
  rs_available  UUID := '00000000-0000-0000-0002-000000000001';
  rs_occupied   UUID := '00000000-0000-0000-0002-000000000002';
  rs_reserved   UUID := '00000000-0000-0000-0002-000000000003';
  rs_cleaning   UUID := '00000000-0000-0000-0002-000000000004';
  rs_maint      UUID := '00000000-0000-0000-0002-000000000005';

  -- day_type (insertados por sp_insert_day_types)
  dt_weekday   UUID := '00000000-0000-0000-0003-000000000001';
  dt_weekend   UUID := '00000000-0000-0000-0003-000000000002';
  dt_high      UUID := '00000000-0000-0000-0003-000000000003';
  dt_low       UUID := '00000000-0000-0000-0003-000000000004';
  dt_holiday   UUID := '00000000-0000-0000-0003-000000000005';
  dt_special   UUID := '00000000-0000-0000-0003-000000000006';

  -- payment_method (insertados por sp_insert_payment_methods)
  pm_cash    UUID := '00000000-0000-0000-0004-000000000001';
  pm_credit  UUID := '00000000-0000-0000-0004-000000000002';
  pm_debit   UUID := '00000000-0000-0000-0004-000000000003';
  pm_bank    UUID := '00000000-0000-0000-0004-000000000004';
  pm_wallet  UUID := '00000000-0000-0000-0004-000000000005';

  -- -----------------------------------------------------------------------
  -- UUIDs FIJOS DEL SEED MUESTRA (001-seed-sample-data.sql)
  -- -----------------------------------------------------------------------

  -- room_type (del seed 001)
  rt_single UUID := '00000000-0000-0000-0000-000016000001';
  rt_double UUID := '00000000-0000-0000-0000-000016000002';
  rt_suite  UUID := '00000000-0000-0000-0000-000016000003';
  rt_family UUID := '00000000-0000-0000-0000-000016000004';
  rt_deluxe UUID := '00000000-0000-0000-0000-000016000005';

  -- branch (del seed 001)
  br1 UUID := '00000000-0000-0000-0000-000014000001';
  br2 UUID := '00000000-0000-0000-0000-000014000002';
  br3 UUID := '00000000-0000-0000-0000-000014000003';
  br4 UUID := '00000000-0000-0000-0000-000014000004';
  br5 UUID := '00000000-0000-0000-0000-000014000005';

  -- supplier (del seed 001) — para product_tracking volumétrico
  sup1 UUID := '00000000-0000-0000-0000-000027000001';
  sup2 UUID := '00000000-0000-0000-0000-000027000002';
  sup3 UUID := '00000000-0000-0000-0000-000027000003';
  sup4 UUID := '00000000-0000-0000-0000-000027000004';
  sup5 UUID := '00000000-0000-0000-0000-000027000005';

  -- product (del seed 001)
  prod1 UUID := '00000000-0000-0000-0000-000028000001';
  prod2 UUID := '00000000-0000-0000-0000-000028000002';
  prod3 UUID := '00000000-0000-0000-0000-000028000003';
  prod4 UUID := '00000000-0000-0000-0000-000028000004';
  prod5 UUID := '00000000-0000-0000-0000-000028000005';

  -- service (del seed 001)
  svc1 UUID := '00000000-0000-0000-0000-000029000001';
  svc2 UUID := '00000000-0000-0000-0000-000029000002';
  svc3 UUID := '00000000-0000-0000-0000-000029000003';
  svc4 UUID := '00000000-0000-0000-0000-000029000004';
  svc5 UUID := '00000000-0000-0000-0000-000029000005';

  -- -----------------------------------------------------------------------
  -- UUIDs VOLUMÉTRICOS — bloque 70 (nunca usados antes)
  -- -----------------------------------------------------------------------

  -- customers vol (20)
  vc  UUID[] := ARRAY[
    '00000000-0000-0000-0070-000001000001'::UUID,'00000000-0000-0000-0070-000001000002'::UUID,
    '00000000-0000-0000-0070-000001000003'::UUID,'00000000-0000-0000-0070-000001000004'::UUID,
    '00000000-0000-0000-0070-000001000005'::UUID,'00000000-0000-0000-0070-000001000006'::UUID,
    '00000000-0000-0000-0070-000001000007'::UUID,'00000000-0000-0000-0070-000001000008'::UUID,
    '00000000-0000-0000-0070-000001000009'::UUID,'00000000-0000-0000-0070-000001000010'::UUID,
    '00000000-0000-0000-0070-000001000011'::UUID,'00000000-0000-0000-0070-000001000012'::UUID,
    '00000000-0000-0000-0070-000001000013'::UUID,'00000000-0000-0000-0070-000001000014'::UUID,
    '00000000-0000-0000-0070-000001000015'::UUID,'00000000-0000-0000-0070-000001000016'::UUID,
    '00000000-0000-0000-0070-000001000017'::UUID,'00000000-0000-0000-0070-000001000018'::UUID,
    '00000000-0000-0000-0070-000001000019'::UUID,'00000000-0000-0000-0070-000001000020'::UUID
  ];

  -- persons vol (20)
  vp  UUID[] := ARRAY[
    '00000000-0000-0000-0070-000002000001'::UUID,'00000000-0000-0000-0070-000002000002'::UUID,
    '00000000-0000-0000-0070-000002000003'::UUID,'00000000-0000-0000-0070-000002000004'::UUID,
    '00000000-0000-0000-0070-000002000005'::UUID,'00000000-0000-0000-0070-000002000006'::UUID,
    '00000000-0000-0000-0070-000002000007'::UUID,'00000000-0000-0000-0070-000002000008'::UUID,
    '00000000-0000-0000-0070-000002000009'::UUID,'00000000-0000-0000-0070-000002000010'::UUID,
    '00000000-0000-0000-0070-000002000011'::UUID,'00000000-0000-0000-0070-000002000012'::UUID,
    '00000000-0000-0000-0070-000002000013'::UUID,'00000000-0000-0000-0070-000002000014'::UUID,
    '00000000-0000-0000-0070-000002000015'::UUID,'00000000-0000-0000-0070-000002000016'::UUID,
    '00000000-0000-0000-0070-000002000017'::UUID,'00000000-0000-0000-0070-000002000018'::UUID,
    '00000000-0000-0000-0070-000002000019'::UUID,'00000000-0000-0000-0070-000002000020'::UUID
  ];

  -- app_users vol (20)
  vau UUID[] := ARRAY[
    '00000000-0000-0000-0070-000007000001'::UUID,'00000000-0000-0000-0070-000007000002'::UUID,
    '00000000-0000-0000-0070-000007000003'::UUID,'00000000-0000-0000-0070-000007000004'::UUID,
    '00000000-0000-0000-0070-000007000005'::UUID,'00000000-0000-0000-0070-000007000006'::UUID,
    '00000000-0000-0000-0070-000007000007'::UUID,'00000000-0000-0000-0070-000007000008'::UUID,
    '00000000-0000-0000-0070-000007000009'::UUID,'00000000-0000-0000-0070-000007000010'::UUID,
    '00000000-0000-0000-0070-000007000011'::UUID,'00000000-0000-0000-0070-000007000012'::UUID,
    '00000000-0000-0000-0070-000007000013'::UUID,'00000000-0000-0000-0070-000007000014'::UUID,
    '00000000-0000-0000-0070-000007000015'::UUID,'00000000-0000-0000-0070-000007000016'::UUID,
    '00000000-0000-0000-0070-000007000017'::UUID,'00000000-0000-0000-0070-000007000018'::UUID,
    '00000000-0000-0000-0070-000007000019'::UUID,'00000000-0000-0000-0070-000007000020'::UUID
  ];

  -- app_user_role vol (20)
  vaur UUID[] := ARRAY[
    '00000000-0000-0000-0070-000008000001'::UUID,'00000000-0000-0000-0070-000008000002'::UUID,
    '00000000-0000-0000-0070-000008000003'::UUID,'00000000-0000-0000-0070-000008000004'::UUID,
    '00000000-0000-0000-0070-000008000005'::UUID,'00000000-0000-0000-0070-000008000006'::UUID,
    '00000000-0000-0000-0070-000008000007'::UUID,'00000000-0000-0000-0070-000008000008'::UUID,
    '00000000-0000-0000-0070-000008000009'::UUID,'00000000-0000-0000-0070-000008000010'::UUID,
    '00000000-0000-0000-0070-000008000011'::UUID,'00000000-0000-0000-0070-000008000012'::UUID,
    '00000000-0000-0000-0070-000008000013'::UUID,'00000000-0000-0000-0070-000008000014'::UUID,
    '00000000-0000-0000-0070-000008000015'::UUID,'00000000-0000-0000-0070-000008000016'::UUID,
    '00000000-0000-0000-0070-000008000017'::UUID,'00000000-0000-0000-0070-000008000018'::UUID,
    '00000000-0000-0000-0070-000008000019'::UUID,'00000000-0000-0000-0070-000008000020'::UUID
  ];

  -- employees vol (20)
  ve  UUID[] := ARRAY[
    '00000000-0000-0000-0070-000013000001'::UUID,'00000000-0000-0000-0070-000013000002'::UUID,
    '00000000-0000-0000-0070-000013000003'::UUID,'00000000-0000-0000-0070-000013000004'::UUID,
    '00000000-0000-0000-0070-000013000005'::UUID,'00000000-0000-0000-0070-000013000006'::UUID,
    '00000000-0000-0000-0070-000013000007'::UUID,'00000000-0000-0000-0070-000013000008'::UUID,
    '00000000-0000-0000-0070-000013000009'::UUID,'00000000-0000-0000-0070-000013000010'::UUID,
    '00000000-0000-0000-0070-000013000011'::UUID,'00000000-0000-0000-0070-000013000012'::UUID,
    '00000000-0000-0000-0070-000013000013'::UUID,'00000000-0000-0000-0070-000013000014'::UUID,
    '00000000-0000-0000-0070-000013000015'::UUID,'00000000-0000-0000-0070-000013000016'::UUID,
    '00000000-0000-0000-0070-000013000017'::UUID,'00000000-0000-0000-0070-000013000018'::UUID,
    '00000000-0000-0000-0070-000013000019'::UUID,'00000000-0000-0000-0070-000013000020'::UUID
  ];

  -- rooms vol (20)
  vr  UUID[] := ARRAY[
    '00000000-0000-0000-0070-000018000001'::UUID,'00000000-0000-0000-0070-000018000002'::UUID,
    '00000000-0000-0000-0070-000018000003'::UUID,'00000000-0000-0000-0070-000018000004'::UUID,
    '00000000-0000-0000-0070-000018000005'::UUID,'00000000-0000-0000-0070-000018000006'::UUID,
    '00000000-0000-0000-0070-000018000007'::UUID,'00000000-0000-0000-0070-000018000008'::UUID,
    '00000000-0000-0000-0070-000018000009'::UUID,'00000000-0000-0000-0070-000018000010'::UUID,
    '00000000-0000-0000-0070-000018000011'::UUID,'00000000-0000-0000-0070-000018000012'::UUID,
    '00000000-0000-0000-0070-000018000013'::UUID,'00000000-0000-0000-0070-000018000014'::UUID,
    '00000000-0000-0000-0070-000018000015'::UUID,'00000000-0000-0000-0070-000018000016'::UUID,
    '00000000-0000-0000-0070-000018000017'::UUID,'00000000-0000-0000-0070-000018000018'::UUID,
    '00000000-0000-0000-0070-000018000019'::UUID,'00000000-0000-0000-0070-000018000020'::UUID
  ];

  -- prices vol (20)
  vpr UUID[] := ARRAY[
    '00000000-0000-0000-0070-000019000001'::UUID,'00000000-0000-0000-0070-000019000002'::UUID,
    '00000000-0000-0000-0070-000019000003'::UUID,'00000000-0000-0000-0070-000019000004'::UUID,
    '00000000-0000-0000-0070-000019000005'::UUID,'00000000-0000-0000-0070-000019000006'::UUID,
    '00000000-0000-0000-0070-000019000007'::UUID,'00000000-0000-0000-0070-000019000008'::UUID,
    '00000000-0000-0000-0070-000019000009'::UUID,'00000000-0000-0000-0070-000019000010'::UUID,
    '00000000-0000-0000-0070-000019000011'::UUID,'00000000-0000-0000-0070-000019000012'::UUID,
    '00000000-0000-0000-0070-000019000013'::UUID,'00000000-0000-0000-0070-000019000014'::UUID,
    '00000000-0000-0000-0070-000019000015'::UUID,'00000000-0000-0000-0070-000019000016'::UUID,
    '00000000-0000-0000-0070-000019000017'::UUID,'00000000-0000-0000-0070-000019000018'::UUID,
    '00000000-0000-0000-0070-000019000019'::UUID,'00000000-0000-0000-0070-000019000020'::UUID
  ];

  -- room_reservations vol (20)
  vrr UUID[] := ARRAY[
    '00000000-0000-0000-0070-000020000001'::UUID,'00000000-0000-0000-0070-000020000002'::UUID,
    '00000000-0000-0000-0070-000020000003'::UUID,'00000000-0000-0000-0070-000020000004'::UUID,
    '00000000-0000-0000-0070-000020000005'::UUID,'00000000-0000-0000-0070-000020000006'::UUID,
    '00000000-0000-0000-0070-000020000007'::UUID,'00000000-0000-0000-0070-000020000008'::UUID,
    '00000000-0000-0000-0070-000020000009'::UUID,'00000000-0000-0000-0070-000020000010'::UUID,
    '00000000-0000-0000-0070-000020000011'::UUID,'00000000-0000-0000-0070-000020000012'::UUID,
    '00000000-0000-0000-0070-000020000013'::UUID,'00000000-0000-0000-0070-000020000014'::UUID,
    '00000000-0000-0000-0070-000020000015'::UUID,'00000000-0000-0000-0070-000020000016'::UUID,
    '00000000-0000-0000-0070-000020000017'::UUID,'00000000-0000-0000-0070-000020000018'::UUID,
    '00000000-0000-0000-0070-000020000019'::UUID,'00000000-0000-0000-0070-000020000020'::UUID
  ];

  -- stays vol (20)
  vs  UUID[] := ARRAY[
    '00000000-0000-0000-0070-000024000001'::UUID,'00000000-0000-0000-0070-000024000002'::UUID,
    '00000000-0000-0000-0070-000024000003'::UUID,'00000000-0000-0000-0070-000024000004'::UUID,
    '00000000-0000-0000-0070-000024000005'::UUID,'00000000-0000-0000-0070-000024000006'::UUID,
    '00000000-0000-0000-0070-000024000007'::UUID,'00000000-0000-0000-0070-000024000008'::UUID,
    '00000000-0000-0000-0070-000024000009'::UUID,'00000000-0000-0000-0070-000024000010'::UUID,
    '00000000-0000-0000-0070-000024000011'::UUID,'00000000-0000-0000-0070-000024000012'::UUID,
    '00000000-0000-0000-0070-000024000013'::UUID,'00000000-0000-0000-0070-000024000014'::UUID,
    '00000000-0000-0000-0070-000024000015'::UUID,'00000000-0000-0000-0070-000024000016'::UUID,
    '00000000-0000-0000-0070-000024000017'::UUID,'00000000-0000-0000-0070-000024000018'::UUID,
    '00000000-0000-0000-0070-000024000019'::UUID,'00000000-0000-0000-0070-000024000020'::UUID
  ];

  -- check_ins vol (20)
  vci UUID[] := ARRAY[
    '00000000-0000-0000-0070-000025000001'::UUID,'00000000-0000-0000-0070-000025000002'::UUID,
    '00000000-0000-0000-0070-000025000003'::UUID,'00000000-0000-0000-0070-000025000004'::UUID,
    '00000000-0000-0000-0070-000025000005'::UUID,'00000000-0000-0000-0070-000025000006'::UUID,
    '00000000-0000-0000-0070-000025000007'::UUID,'00000000-0000-0000-0070-000025000008'::UUID,
    '00000000-0000-0000-0070-000025000009'::UUID,'00000000-0000-0000-0070-000025000010'::UUID,
    '00000000-0000-0000-0070-000025000011'::UUID,'00000000-0000-0000-0070-000025000012'::UUID,
    '00000000-0000-0000-0070-000025000013'::UUID,'00000000-0000-0000-0070-000025000014'::UUID,
    '00000000-0000-0000-0070-000025000015'::UUID,'00000000-0000-0000-0070-000025000016'::UUID,
    '00000000-0000-0000-0070-000025000017'::UUID,'00000000-0000-0000-0070-000025000018'::UUID,
    '00000000-0000-0000-0070-000025000019'::UUID,'00000000-0000-0000-0070-000025000020'::UUID
  ];

  -- check_outs vol (solo COMPLETED: i 1-14)
vco UUID[] := ARRAY[
  '00000000-0000-0000-0070-000026000001'::UUID,'00000000-0000-0000-0070-000026000002'::UUID,
  '00000000-0000-0000-0070-000026000003'::UUID,'00000000-0000-0000-0070-000026000004'::UUID,
  '00000000-0000-0000-0070-000026000005'::UUID,'00000000-0000-0000-0070-000026000006'::UUID,
  '00000000-0000-0000-0070-000026000007'::UUID,'00000000-0000-0000-0070-000026000008'::UUID,
  '00000000-0000-0000-0070-000026000009'::UUID,'00000000-0000-0000-0070-000026000010'::UUID,
  '00000000-0000-0000-0070-000026000011'::UUID,'00000000-0000-0000-0070-000026000012'::UUID,
  '00000000-0000-0000-0070-000026000013'::UUID,'00000000-0000-0000-0070-000026000014'::UUID,
  '00000000-0000-0000-0070-000026000015'::UUID
];

  -- product_sales vol (20)
  vps UUID[] := ARRAY[
    '00000000-0000-0000-0070-000033000001'::UUID,'00000000-0000-0000-0070-000033000002'::UUID,
    '00000000-0000-0000-0070-000033000003'::UUID,'00000000-0000-0000-0070-000033000004'::UUID,
    '00000000-0000-0000-0070-000033000005'::UUID,'00000000-0000-0000-0070-000033000006'::UUID,
    '00000000-0000-0000-0070-000033000007'::UUID,'00000000-0000-0000-0070-000033000008'::UUID,
    '00000000-0000-0000-0070-000033000009'::UUID,'00000000-0000-0000-0070-000033000010'::UUID,
    '00000000-0000-0000-0070-000033000011'::UUID,'00000000-0000-0000-0070-000033000012'::UUID,
    '00000000-0000-0000-0070-000033000013'::UUID,'00000000-0000-0000-0070-000033000014'::UUID,
    '00000000-0000-0000-0070-000033000015'::UUID,'00000000-0000-0000-0070-000033000016'::UUID,
    '00000000-0000-0000-0070-000033000017'::UUID,'00000000-0000-0000-0070-000033000018'::UUID,
    '00000000-0000-0000-0070-000033000019'::UUID,'00000000-0000-0000-0070-000033000020'::UUID
  ];

  -- service_sales vol (20)
  vss UUID[] := ARRAY[
    '00000000-0000-0000-0070-000034000001'::UUID,'00000000-0000-0000-0070-000034000002'::UUID,
    '00000000-0000-0000-0070-000034000003'::UUID,'00000000-0000-0000-0070-000034000004'::UUID,
    '00000000-0000-0000-0070-000034000005'::UUID,'00000000-0000-0000-0070-000034000006'::UUID,
    '00000000-0000-0000-0070-000034000007'::UUID,'00000000-0000-0000-0070-000034000008'::UUID,
    '00000000-0000-0000-0070-000034000009'::UUID,'00000000-0000-0000-0070-000034000010'::UUID,
    '00000000-0000-0000-0070-000034000011'::UUID,'00000000-0000-0000-0070-000034000012'::UUID,
    '00000000-0000-0000-0070-000034000013'::UUID,'00000000-0000-0000-0070-000034000014'::UUID,
    '00000000-0000-0000-0070-000034000015'::UUID,'00000000-0000-0000-0070-000034000016'::UUID,
    '00000000-0000-0000-0070-000034000017'::UUID,'00000000-0000-0000-0070-000034000018'::UUID,
    '00000000-0000-0000-0070-000034000019'::UUID,'00000000-0000-0000-0070-000034000020'::UUID
  ];

  -- pre_invoices vol (20)
  vpi UUID[] := ARRAY[
    '00000000-0000-0000-0070-000035000001'::UUID,'00000000-0000-0000-0070-000035000002'::UUID,
    '00000000-0000-0000-0070-000035000003'::UUID,'00000000-0000-0000-0070-000035000004'::UUID,
    '00000000-0000-0000-0070-000035000005'::UUID,'00000000-0000-0000-0070-000035000006'::UUID,
    '00000000-0000-0000-0070-000035000007'::UUID,'00000000-0000-0000-0070-000035000008'::UUID,
    '00000000-0000-0000-0070-000035000009'::UUID,'00000000-0000-0000-0070-000035000010'::UUID,
    '00000000-0000-0000-0070-000035000011'::UUID,'00000000-0000-0000-0070-000035000012'::UUID,
    '00000000-0000-0000-0070-000035000013'::UUID,'00000000-0000-0000-0070-000035000014'::UUID,
    '00000000-0000-0000-0070-000035000015'::UUID,'00000000-0000-0000-0070-000035000016'::UUID,
    '00000000-0000-0000-0070-000035000017'::UUID,'00000000-0000-0000-0070-000035000018'::UUID,
    '00000000-0000-0000-0070-000035000019'::UUID,'00000000-0000-0000-0070-000035000020'::UUID
  ];

  -- invoices vol (20)
  vin UUID[] := ARRAY[
    '00000000-0000-0000-0070-000036000001'::UUID,'00000000-0000-0000-0070-000036000002'::UUID,
    '00000000-0000-0000-0070-000036000003'::UUID,'00000000-0000-0000-0070-000036000004'::UUID,
    '00000000-0000-0000-0070-000036000005'::UUID,'00000000-0000-0000-0070-000036000006'::UUID,
    '00000000-0000-0000-0070-000036000007'::UUID,'00000000-0000-0000-0070-000036000008'::UUID,
    '00000000-0000-0000-0070-000036000009'::UUID,'00000000-0000-0000-0070-000036000010'::UUID,
    '00000000-0000-0000-0070-000036000011'::UUID,'00000000-0000-0000-0070-000036000012'::UUID,
    '00000000-0000-0000-0070-000036000013'::UUID,'00000000-0000-0000-0070-000036000014'::UUID,
    '00000000-0000-0000-0070-000036000015'::UUID,'00000000-0000-0000-0070-000036000016'::UUID,
    '00000000-0000-0000-0070-000036000017'::UUID,'00000000-0000-0000-0070-000036000018'::UUID,
    '00000000-0000-0000-0070-000036000019'::UUID,'00000000-0000-0000-0070-000036000020'::UUID
  ];

  -- partial_payments vol (20)
  vpp UUID[] := ARRAY[
    '00000000-0000-0000-0070-000037000001'::UUID,'00000000-0000-0000-0070-000037000002'::UUID,
    '00000000-0000-0000-0070-000037000003'::UUID,'00000000-0000-0000-0070-000037000004'::UUID,
    '00000000-0000-0000-0070-000037000005'::UUID,'00000000-0000-0000-0070-000037000006'::UUID,
    '00000000-0000-0000-0070-000037000007'::UUID,'00000000-0000-0000-0070-000037000008'::UUID,
    '00000000-0000-0000-0070-000037000009'::UUID,'00000000-0000-0000-0070-000037000010'::UUID,
    '00000000-0000-0000-0070-000037000011'::UUID,'00000000-0000-0000-0070-000037000012'::UUID,
    '00000000-0000-0000-0070-000037000013'::UUID,'00000000-0000-0000-0070-000037000014'::UUID,
    '00000000-0000-0000-0070-000037000015'::UUID,'00000000-0000-0000-0070-000037000016'::UUID,
    '00000000-0000-0000-0070-000037000017'::UUID,'00000000-0000-0000-0070-000037000018'::UUID,
    '00000000-0000-0000-0070-000037000019'::UUID,'00000000-0000-0000-0070-000037000020'::UUID
  ];

  -- purchase_details vol (20)
  vpd UUID[] := ARRAY[
    '00000000-0000-0000-0070-000038000001'::UUID,'00000000-0000-0000-0070-000038000002'::UUID,
    '00000000-0000-0000-0070-000038000003'::UUID,'00000000-0000-0000-0070-000038000004'::UUID,
    '00000000-0000-0000-0070-000038000005'::UUID,'00000000-0000-0000-0070-000038000006'::UUID,
    '00000000-0000-0000-0070-000038000007'::UUID,'00000000-0000-0000-0070-000038000008'::UUID,
    '00000000-0000-0000-0070-000038000009'::UUID,'00000000-0000-0000-0070-000038000010'::UUID,
    '00000000-0000-0000-0070-000038000011'::UUID,'00000000-0000-0000-0070-000038000012'::UUID,
    '00000000-0000-0000-0070-000038000013'::UUID,'00000000-0000-0000-0070-000038000014'::UUID,
    '00000000-0000-0000-0070-000038000015'::UUID,'00000000-0000-0000-0070-000038000016'::UUID,
    '00000000-0000-0000-0070-000038000017'::UUID,'00000000-0000-0000-0070-000038000018'::UUID,
    '00000000-0000-0000-0070-000038000019'::UUID,'00000000-0000-0000-0070-000038000020'::UUID
  ];

  -- customer_loyalty vol (20)
  vcl UUID[] := ARRAY[
    '00000000-0000-0000-0070-000042000001'::UUID,'00000000-0000-0000-0070-000042000002'::UUID,
    '00000000-0000-0000-0070-000042000003'::UUID,'00000000-0000-0000-0070-000042000004'::UUID,
    '00000000-0000-0000-0070-000042000005'::UUID,'00000000-0000-0000-0070-000042000006'::UUID,
    '00000000-0000-0000-0070-000042000007'::UUID,'00000000-0000-0000-0070-000042000008'::UUID,
    '00000000-0000-0000-0070-000042000009'::UUID,'00000000-0000-0000-0070-000042000010'::UUID,
    '00000000-0000-0000-0070-000042000011'::UUID,'00000000-0000-0000-0070-000042000012'::UUID,
    '00000000-0000-0000-0070-000042000013'::UUID,'00000000-0000-0000-0070-000042000014'::UUID,
    '00000000-0000-0000-0070-000042000015'::UUID,'00000000-0000-0000-0070-000042000016'::UUID,
    '00000000-0000-0000-0070-000042000017'::UUID,'00000000-0000-0000-0070-000042000018'::UUID,
    '00000000-0000-0000-0070-000042000019'::UUID,'00000000-0000-0000-0070-000042000020'::UUID
  ];

  -- room_maintenance vol (20)
  vrm UUID[] := ARRAY[
    '00000000-0000-0000-0070-000043000001'::UUID,'00000000-0000-0000-0070-000043000002'::UUID,
    '00000000-0000-0000-0070-000043000003'::UUID,'00000000-0000-0000-0070-000043000004'::UUID,
    '00000000-0000-0000-0070-000043000005'::UUID,'00000000-0000-0000-0070-000043000006'::UUID,
    '00000000-0000-0000-0070-000043000007'::UUID,'00000000-0000-0000-0070-000043000008'::UUID,
    '00000000-0000-0000-0070-000043000009'::UUID,'00000000-0000-0000-0070-000043000010'::UUID,
    '00000000-0000-0000-0070-000043000011'::UUID,'00000000-0000-0000-0070-000043000012'::UUID,
    '00000000-0000-0000-0070-000043000013'::UUID,'00000000-0000-0000-0070-000043000014'::UUID,
    '00000000-0000-0000-0070-000043000015'::UUID,'00000000-0000-0000-0070-000043000016'::UUID,
    '00000000-0000-0000-0070-000043000017'::UUID,'00000000-0000-0000-0070-000043000018'::UUID,
    '00000000-0000-0000-0070-000043000019'::UUID,'00000000-0000-0000-0070-000043000020'::UUID
  ];

  -- -----------------------------------------------------------------------
  -- Variables de trabajo
  -- -----------------------------------------------------------------------
  i           INT;
  v_sub       NUMERIC;
  v_tax       NUMERIC;
  v_disc      NUMERIC;
  v_total     NUMERIC;
  v_end_ts    TIMESTAMP;

  -- Datos de nombres para generar texto realista
  nombres     TEXT[] := ARRAY['Valentina','Santiago','Isabella','James','Mariana',
                               'Andres','Luisa','Pierre','Natalia','Maria',
                               'Felipe','Daniela','Klaus','Alejandro','Catalina',
                               'Liam','Camilo','Paola','Yuki','Sebastian'];
  apellidos   TEXT[] := ARRAY['Herrera','Mendoza','Vargas','Brown','Ortiz',
                               'Castillo','Pardo','Dupont','Rios','Garcia',
                               'Mora','Cruz','Muller','Suarez','Guerrero',
                               'Wilson','Reyes','Nieto','Tanaka','Acosta'];
  doc_types   TEXT[] := ARRAY['CC','CC','CE','PASSPORT','CC',
                               'CC','CC','CE','CC','PASSPORT',
                               'CC','CC','CE','CC','CC',
                               'PASSPORT','CC','CC','CE','CC'];

  -- Roles rotativos para asignar a usuarios
roles_rot   UUID[] := ARRAY[
  '00000000-0000-0000-0000-000003000001'::UUID, -- ADMIN
  '00000000-0000-0000-0000-000003000002'::UUID, -- MANAGER
  '00000000-0000-0000-0000-000003000003'::UUID, -- RECEPTIONIST
  '00000000-0000-0000-0000-000003000004'::UUID, -- HOUSEKEEPING
  '00000000-0000-0000-0000-000003000005'::UUID  -- ACCOUNTING
];

  -- Tipos de habitación rotativos
  rtypes      UUID[] := ARRAY[rt_single, rt_double, rt_suite, rt_family, rt_deluxe];

  -- Branches rotativos
  branches    UUID[] := ARRAY[br1, br2, br3, br4, br5];

  -- Room status rotativos (solo AVAILABLE y RESERVED para rooms nuevas)
  rstatuses   UUID[] := ARRAY[rs_available, rs_reserved, rs_available, rs_reserved, rs_available,
                               rs_available, rs_reserved, rs_available, rs_reserved, rs_available,
                               rs_available, rs_reserved, rs_available, rs_reserved, rs_available,
                               rs_available, rs_reserved, rs_available, rs_reserved, rs_available];

  -- day_types rotativos para precios (6 tipos, 20 combinaciones → start_date varía para no violar UK)
  dtypes      UUID[] := ARRAY[dt_weekday,dt_weekend,dt_high,dt_low,dt_holiday,dt_special,
                               dt_weekday,dt_weekend,dt_high,dt_low,dt_holiday,dt_special,
                               dt_weekday,dt_weekend,dt_high,dt_low,dt_holiday,dt_special,
                               dt_weekday,dt_weekend];

  -- Capacidades según tipo de habitación
  caps        SMALLINT[] := ARRAY[1,2,3,5,4, 1,2,3,5,4, 1,2,3,5,4, 1,2,3,5,4];

  -- Títulos de trabajo para empleados
  job_titles  TEXT[] := ARRAY['Receptionist','Night Auditor','Concierge','Housekeeping Staff',
                               'Accountant','Maintenance Tech','IT Support','Security Guard',
                               'Reservations Agent','Sales Rep','F&B Supervisor','HR Coordinator',
                               'Front Desk Supervisor','Revenue Manager','Purchasing Agent',
                               'Chef','Porter','Spa Therapist','Laundry Supervisor','Valet'];

  -- Estados de reserva distribuidos
  res_statuses TEXT[] := ARRAY['CONFIRMED','CONFIRMED','CONFIRMED','CONFIRMED','CONFIRMED',
                                'CONFIRMED','CONFIRMED','CONFIRMED','CONFIRMED','CONFIRMED',
                                'PENDING','PENDING','PENDING','PENDING','PENDING',
                                'CANCELED','CANCELED','CANCELED','CONFIRMED','CONFIRMED'];

  -- Montos estimados de reserva
  est_amounts NUMERIC[] := ARRAY[360000,520000,840000,1040000,1300000,
                                  380000,540000,860000,1060000,1320000,
                                  400000,560000,880000,1080000,1340000,
                                  420000,580000,900000,1100000,1360000];

  -- Estados de estadía (15 COMPLETED, 5 ACTIVE — coincide con reservas no canceladas)
  stay_statuses TEXT[] := ARRAY['COMPLETED','COMPLETED','COMPLETED','COMPLETED','COMPLETED',
                                 'COMPLETED','COMPLETED','COMPLETED','COMPLETED','COMPLETED',
                                 'COMPLETED','COMPLETED','COMPLETED','COMPLETED','COMPLETED',
                                 'CANCELED','CANCELED','CANCELED','ACTIVE','ACTIVE'];

  -- Notas de check_in
  ci_notes    TEXT[] := ARRAY['On-time arrival','Early check-in requested','VIP guest',
                               'Quiet floor requested','Group booking','Late arrival',
                               'Adjoining rooms needed','Baby cot requested','Allergies noted',
                               'First time guest','Corporate booking','Repeat guest GOLD',
                               'Weekend getaway','Honeymoon setup','Early departure notice',
                               'No smoking confirmed','Pets allowed cleared','Long stay pack',
                               'High floor requested','Welcome amenity delivered'];

  -- Métodos de pago rotativos
  pms         UUID[] := ARRAY[pm_cash, pm_credit, pm_debit, pm_bank, pm_wallet,
                               pm_cash, pm_credit, pm_debit, pm_bank, pm_wallet,
                               pm_cash, pm_credit, pm_debit, pm_bank, pm_wallet,
                               pm_cash, pm_credit, pm_debit, pm_bank, pm_wallet];

  pm_refs     TEXT[] := ARRAY[NULL,'CARD-VOL','DEBIT-VOL','TRF-VOL','WALLET-VOL',
                               NULL,'CARD-VOL','DEBIT-VOL','TRF-VOL','WALLET-VOL',
                               NULL,'CARD-VOL','DEBIT-VOL','TRF-VOL','WALLET-VOL',
                               NULL,'CARD-VOL','DEBIT-VOL','TRF-VOL','WALLET-VOL'];

  -- Productos y servicios rotativos
  prods       UUID[] := ARRAY[prod1,prod2,prod3,prod4,prod5,
                               prod1,prod2,prod3,prod4,prod5,
                               prod1,prod2,prod3,prod4,prod5,
                               prod1,prod2,prod3,prod4,prod5];
  prod_prices NUMERIC[] := ARRAY[5000,8000,15000,3000,35000,
                                  5000,8000,15000,3000,35000,
                                  5000,8000,15000,3000,35000,
                                  5000,8000,15000,3000,35000];
  prod_qtys   INT[]    := ARRAY[3,2,1,4,1,2,3,2,1,2,3,2,1,4,1,2,3,2,1,2];

  svcs        UUID[] := ARRAY[svc1,svc2,svc3,svc4,svc5,
                               svc1,svc2,svc3,svc4,svc5,
                               svc1,svc2,svc3,svc4,svc5,
                               svc1,svc2,svc3,svc4,svc5];
  svc_prices  NUMERIC[] := ARRAY[45000,90000,30000,160000,70000,
                                  45000,90000,30000,160000,70000,
                                  45000,90000,30000,160000,70000,
                                  45000,90000,30000,160000,70000];
  svc_qtys    INT[]     := ARRAY[2,1,1,2,1,3,1,1,2,1,2,1,1,2,1,3,1,1,2,1];

  -- Niveles de fidelización
  loyalty_lvls TEXT[] := ARRAY['BASIC','BASIC','SILVER','SILVER','GOLD',
                                'GOLD','PLATINUM','PLATINUM','BASIC','SILVER',
                                'GOLD','PLATINUM','BASIC','SILVER','GOLD',
                                'BASIC','SILVER','GOLD','PLATINUM','BASIC'];
  loyalty_pts  INT[]  := ARRAY[50,90,310,450,800,950,1800,2200,60,400,
                                750,2000,80,350,900,100,500,1100,2800,30];

  -- Tipos de mantenimiento
  maint_types   TEXT[] := ARRAY['PREVENTIVE','CORRECTIVE','INSPECTION','REMODELING','CLEANING_SUPPORT',
                                  'PREVENTIVE','CORRECTIVE','INSPECTION','PREVENTIVE','CORRECTIVE',
                                  'INSPECTION','CLEANING_SUPPORT','PREVENTIVE','CORRECTIVE','REMODELING',
                                  'PREVENTIVE','INSPECTION','CORRECTIVE','CLEANING_SUPPORT','PREVENTIVE'];
  maint_statuses TEXT[] := ARRAY['COMPLETED','COMPLETED','IN_PROGRESS','PENDING','COMPLETED',
                                   'COMPLETED','COMPLETED','IN_PROGRESS','PENDING','COMPLETED',
                                   'COMPLETED','COMPLETED','IN_PROGRESS','PENDING','COMPLETED',
                                   'COMPLETED','COMPLETED','IN_PROGRESS','PENDING','COMPLETED'];
  maint_notes   TEXT[] := ARRAY['AC filter check','Plumbing repair','Quarterly inspection',
                                 'Carpet renovation','Deep clean support','Smoke detector test',
                                 'Window seal fix','Safety audit','Lighting check','Shower fix',
                                 'Fire exit review','Pre-season clean','HVAC service','Lock re-key',
                                 'Tile replacement','Panel check','Pool inspection',
                                 'Lobby touch-up','Corridor clean','Boiler annual check'];

BEGIN

  -- =========================================================================
  -- 1. CUSTOMERS (20) — documentos 7000000001-20, emails únicos vol
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO parameterization.customer
      (id, document_type, document_number, name, last_name, phone, email, address)
    VALUES (
      vc[i],
      doc_types[i],
      '700000' || LPAD(i::TEXT, 4, '0'),
      nombres[i],
      apellidos[i],
      '320' || LPAD(i::TEXT, 7, '0'),
      lower(nombres[i]) || '.' || lower(apellidos[i]) || '.vol@example.com',
      'Calle Vol ' || i || ' #' || i || '-' || (i * 2)
    );
  END LOOP;

  -- =========================================================================
  -- 2. PERSONS (20) — documentos 8000000001-20, emails únicos vol
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO security.person
      (id, document_type, document_number, name, last_name, phone, email)
    VALUES (
      vp[i],
      'CC',
      '800000' || LPAD(i::TEXT, 4, '0'),
      nombres[i],
      apellidos[i] || 'E',
      '311' || LPAD(i::TEXT, 7, '0'),
      lower(nombres[i]) || '.' || lower(apellidos[i]) || '.emp.vol@hotel.local'
    );
  END LOOP;

  -- =========================================================================
  -- 3. APP_USERS (20) — un usuario por person, usernames únicos vol_usr_XX
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO security.app_user
      (id, person_id, username, password_hash, last_access_at, blocked)
    VALUES (
      vau[i],
      vp[i],
      'vol_usr_' || LPAD(i::TEXT, 2, '0'),
      'vol_hash_' || LPAD(i::TEXT, 3, '0'),
      TIMESTAMP '2026-04-01 08:00:00' + (i * INTERVAL '1 hour'),
      CASE WHEN i IN (8, 16) THEN TRUE ELSE FALSE END
    );
  END LOOP;

  -- =========================================================================
  -- 4. APP_USER_ROLE (20) — rota los 5 roles canónicos del sp_insert_roles
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO security.app_user_role (id, app_user_id, role_id)
    VALUES (vaur[i], vau[i], roles_rot[((i - 1) % 5) + 1]);
  END LOOP;

  -- =========================================================================
  -- 5. EMPLOYEES (20) — cada uno ligado a una person vol
  --    work_email único: usa el mismo patrón que person pero dominio distinto
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO parameterization.employee
      (id, person_id, job_title, hire_date, work_phone, work_email)
    VALUES (
      ve[i],
      vp[i],
      job_titles[i],
      DATE '2023-01-01' + ((i - 1) * 15),
      '601556' || LPAD(i::TEXT, 4, '0'),
      lower(nombres[i]) || '.' || lower(apellidos[i]) || '.vol@centralplaza.example'
    );
  END LOOP;

  -- =========================================================================
  -- 6. ROOMS (20) — números V101-V120 (prefijo V evita colisión con seed 101-505)
  --    UNIQUE (branch_id, number): branch rota, número siempre distinto por branch
  --    → usamos 'V' + branch_idx + seq para garantizar unicidad
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO distribution.room
      (id, branch_id, room_type_id, room_status_id, number, floor, capacity, description)
    VALUES (
      vr[i],
      branches[((i - 1) % 5) + 1],
      rtypes[((i - 1) % 5) + 1],
      rstatuses[i],
      'V' || ((i - 1) % 5 + 1)::TEXT || LPAD(i::TEXT, 3, '0'),
      ((i - 1) / 4) + 1,
      caps[i],
      'Vol room ' || i || ' — ' || job_titles[((i-1)%5)+1]
    );
  END LOOP;

  -- =========================================================================
  -- 7. PRICES (20)
  --    UNIQUE (room_type_id, day_type_id, start_date)
  --    → usamos start_date = '2027-01-01' + i días para NO colisionar con el
  --      seed que usa '2026-01-01'
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO parameterization.price
      (id, room_type_id, day_type_id, amount, start_date, end_date, condition)
    VALUES (
      vpr[i],
      rtypes[((i - 1) % 5) + 1],
      dtypes[i],
      190000.00 + (i * 15000),
      DATE '2027-01-01' + (i - 1),
      NULL,
      'Vol price row ' || i
    );
  END LOOP;

  -- =========================================================================
  -- 8. ROOM_RESERVATIONS (20) — clientes vol, rooms vol
  --    Fechas en 2027 para no solapar con el seed (que usa mayo 2026)
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO service_delivery.room_reservation
      (id, customer_id, room_id, start_date, end_date,
       guest_count, reservation_status, estimated_amount)
    VALUES (
      vrr[i],
      vc[i],
      vr[i],
      TIMESTAMP '2027-01-01 15:00:00' + ((i - 1) * INTERVAL '4 days'),
      TIMESTAMP '2027-01-01 15:00:00' + ((i - 1) * INTERVAL '4 days') + INTERVAL '2 days',
      CASE ((i-1)%5)+1 WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 2 WHEN 4 THEN 4 ELSE 2 END,
      res_statuses[i],
      est_amounts[i]
    );
  END LOOP;

  -- =========================================================================
  -- 9. STAYS (20)
  --    UNIQUE (room_reservation_id) → 1 stay por reserva, OK
  --    Solo creamos stay para reservas que no son CANCELED (i 1-15, 19-20)
  --    Para i 16,17,18 (CANCELED) omitimos stay — no tiene sentido de negocio
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      v_end_ts := CASE WHEN stay_statuses[i] = 'COMPLETED'
                    THEN TIMESTAMP '2027-01-01 15:20:00' + ((i-1)*INTERVAL '4 days') + INTERVAL '2 days'
                    ELSE NULL
                  END;
      INSERT INTO service_delivery.stay
        (id, room_reservation_id, customer_id, room_id, start_date, end_date, stay_status)
      VALUES (
        vs[i],
        vrr[i],
        vc[i],
        vr[i],
        TIMESTAMP '2027-01-01 15:20:00' + ((i - 1) * INTERVAL '4 days'),
        v_end_ts,
        CASE WHEN res_statuses[i] = 'CANCELED' THEN 'CANCELED' ELSE stay_statuses[i] END
      );
    END IF;
  END LOOP;

  -- =========================================================================
  -- 10. CHECK_IN (20)
  --     UNIQUE (room_reservation_id) → 1 check_in por reserva
  --     check_in.employee_id → FK a employee; usamos employees vol ve[1..3]
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      INSERT INTO service_delivery.check_in
        (id, room_reservation_id, employee_id, checked_in_at, note)
      VALUES (
        vci[i],
        vrr[i],
        ve[((i - 1) % 3) + 1],   -- rota entre 3 recepcionistas vol
        TIMESTAMP '2027-01-01 15:20:00' + ((i - 1) * INTERVAL '4 days'),
        ci_notes[i]
      );
    END IF;
  END LOOP;

  -- =========================================================================
  -- 11. CHECK_OUT (solo stays COMPLETED: i 1-15)
  --     UNIQUE (stay_id) → 1 check_out por estadía
  --     employee_id → ve[5] (accountant vol)
  -- =========================================================================
  FOR i IN 1..15 LOOP
    IF stay_statuses[i] = 'COMPLETED' THEN
      INSERT INTO service_delivery.check_out
        (id, stay_id, employee_id, checked_out_at, note, total_amount)
      VALUES (
        vco[i],
        vs[i],
        ve[5],
        TIMESTAMP '2027-01-01 15:20:00' + ((i-1)*INTERVAL '4 days') + INTERVAL '2 days 45 minutes',
        'Vol checkout note ' || i,
        est_amounts[i] * 1.05   -- total = estimado + 5% extras
      );
    END IF;
  END LOOP;

  -- =========================================================================
  -- 12. PRODUCT_SALE (20) — ligados a stays no cancelados
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      INSERT INTO service_delivery.product_sale
        (id, stay_id, product_id, quantity, unit_amount, total_amount)
      VALUES (
        vps[i],
        vs[i],
        prods[i],
        prod_qtys[i],
        prod_prices[i],
        prod_prices[i] * prod_qtys[i]
      );
    END IF;
  END LOOP;

  -- =========================================================================
  -- 13. SERVICE_SALE (20) — ligados a stays no cancelados
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      INSERT INTO service_delivery.service_sale
        (id, stay_id, service_id, quantity, unit_amount, total_amount)
      VALUES (
        vss[i],
        vs[i],
        svcs[i],
        svc_qtys[i],
        svc_prices[i],
        svc_prices[i] * svc_qtys[i]
      );
    END IF;
  END LOOP;

  -- =========================================================================
  -- 14. PRE_INVOICE (20)
  --     UNIQUE (stay_id) → 1 pre_invoice por estadía
  --     Solo para stays que existen (no cancelados)
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      v_sub  := est_amounts[i];
      v_tax  := ROUND(v_sub * 0.19, 0);
      v_disc := ROUND(v_sub * 0.05, 0);
      v_total := v_sub + v_tax - v_disc;
      INSERT INTO billing.pre_invoice
        (id, stay_id, room_reservation_id, customer_id,
         subtotal, tax_amount, discount_amount, total)
      VALUES (vpi[i], vs[i], vrr[i], vc[i], v_sub, v_tax, v_disc, v_total);
    END IF;
  END LOOP;

  -- =========================================================================
  -- 15. INVOICE (20)
  --     UNIQUE (invoice_number) → INV-VOL-2027-XXXX
  --     UNIQUE (stay_id)        → 1 invoice por estadía
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      v_sub  := est_amounts[i];
      v_tax  := ROUND(v_sub * 0.19, 0);
      v_disc := ROUND(v_sub * 0.05, 0);
      v_total := v_sub + v_tax - v_disc;
      INSERT INTO billing.invoice
        (id, customer_id, stay_id, invoice_number, issued_at,
         subtotal, tax_amount, discount_amount, total, invoice_status)
      VALUES (
        vin[i], vc[i], vs[i],
        'INV-VOL-2027-' || LPAD(i::TEXT, 4, '0'),
        TIMESTAMP '2027-01-01 11:00:00' + ((i-1)*INTERVAL '4 days') + INTERVAL '2 days',
        v_sub, v_tax, v_disc, v_total,
        CASE WHEN i <= 15 THEN 'ISSUED' ELSE 'DRAFT' END
      );
    END IF;
  END LOOP;

  -- =========================================================================
  -- 16. PARTIAL_PAYMENT (20)
  --     CHECK: room_reservation_id IS NOT NULL OR invoice_id IS NOT NULL → ambos OK
  --     CHECK: amount > 0 → OK
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      v_sub  := est_amounts[i];
      v_tax  := ROUND(v_sub * 0.19, 0);
      v_disc := ROUND(v_sub * 0.05, 0);
      v_total := v_sub + v_tax - v_disc;
      INSERT INTO billing.partial_payment
        (id, room_reservation_id, invoice_id, payment_method_id,
         amount, paid_at, payment_reference)
      VALUES (
        vpp[i],
        vrr[i],
        vin[i],
        pms[i],
        v_total,
        TIMESTAMP '2027-01-01 11:10:00' + ((i-1)*INTERVAL '4 days') + INTERVAL '2 days',
        CASE WHEN pm_refs[i] IS NULL THEN NULL
             ELSE pm_refs[i] || '-' || LPAD(i::TEXT, 4, '0')
        END
      );
    END IF;
  END LOOP;

  -- =========================================================================
  -- 17. PURCHASE_DETAIL (20) — alterna producto / servicio
  --     CHECK: product_id IS NOT NULL OR service_id IS NOT NULL → OK
  --     CHECK: quantity > 0 AND unit_amount >= 0 AND total_amount >= 0 → OK
  -- =========================================================================
  FOR i IN 1..20 LOOP
    IF res_statuses[i] != 'CANCELED' THEN
      IF i % 2 = 1 THEN
        -- Detalle de producto
        INSERT INTO billing.purchase_detail
          (id, invoice_id, product_id, service_id,
           description, quantity, unit_amount, total_amount)
        VALUES (
          vpd[i], vin[i], prods[i], NULL,
          'Vol product charge row ' || i,
          prod_qtys[i], prod_prices[i], prod_prices[i] * prod_qtys[i]
        );
      ELSE
        -- Detalle de servicio
        INSERT INTO billing.purchase_detail
          (id, invoice_id, product_id, service_id,
           description, quantity, unit_amount, total_amount)
        VALUES (
          vpd[i], vin[i], NULL, svcs[i],
          'Vol service charge row ' || i,
          svc_qtys[i], svc_prices[i], svc_prices[i] * svc_qtys[i]
        );
      END IF;
    END IF;
  END LOOP;

  -- =========================================================================
  -- 18. CUSTOMER_LOYALTY (20)
  --     UNIQUE (customer_id) → cada customer vol tiene una sola fila → OK
  -- =========================================================================
  FOR i IN 1..20 LOOP
    INSERT INTO notification.customer_loyalty
      (id, customer_id, level, points, last_interaction_at, note)
    VALUES (
      vcl[i],
      vc[i],
      loyalty_lvls[i],
      loyalty_pts[i],
      TIMESTAMP '2027-01-01 09:00:00' + (i * INTERVAL '1 day'),
      'Vol loyalty row ' || i
    );
  END LOOP;

  -- =========================================================================
  -- 19. ROOM_MAINTENANCE (20) — rooms vol, employees vol
  -- =========================================================================
  FOR i IN 1..20 LOOP
    v_end_ts := CASE WHEN maint_statuses[i] = 'COMPLETED'
                  THEN TIMESTAMP '2027-01-01 08:00:00' + ((i-1)*INTERVAL '2 days') + INTERVAL '3 hours'
                  ELSE NULL
                END;
    INSERT INTO maintenance.room_maintenance
      (id, room_id, employee_id, maintenance_type,
       start_date, end_date, maintenance_status, note)
    VALUES (
      vrm[i],
      vr[((i - 1) % 20) + 1],
      ve[((i - 1) % 5) + 1],
      maint_types[i],
      TIMESTAMP '2027-01-01 08:00:00' + ((i-1)*INTERVAL '2 days'),
      v_end_ts,
      maint_statuses[i],
      maint_notes[i]
    );
  END LOOP;

  -- =========================================================================
  -- VERIFICACIÓN FINAL — muestra conteos para confirmar en el log de Liquibase
  -- =========================================================================
  RAISE NOTICE '=== VOLUMETRIC SEED VERIFICATION ===';
  RAISE NOTICE 'customer          vol: %', (SELECT COUNT(*) FROM parameterization.customer       WHERE id = ANY(vc));
  RAISE NOTICE 'person            vol: %', (SELECT COUNT(*) FROM security.person                 WHERE id = ANY(vp));
  RAISE NOTICE 'app_user          vol: %', (SELECT COUNT(*) FROM security.app_user               WHERE id = ANY(vau));
  RAISE NOTICE 'app_user_role     vol: %', (SELECT COUNT(*) FROM security.app_user_role          WHERE id = ANY(vaur));
  RAISE NOTICE 'employee          vol: %', (SELECT COUNT(*) FROM parameterization.employee       WHERE id = ANY(ve));
  RAISE NOTICE 'room              vol: %', (SELECT COUNT(*) FROM distribution.room               WHERE id = ANY(vr));
  RAISE NOTICE 'price             vol: %', (SELECT COUNT(*) FROM parameterization.price          WHERE id = ANY(vpr));
  RAISE NOTICE 'room_reservation  vol: %', (SELECT COUNT(*) FROM service_delivery.room_reservation WHERE id = ANY(vrr));
  RAISE NOTICE 'stay              vol: %', (SELECT COUNT(*) FROM service_delivery.stay            WHERE id = ANY(vs));
  RAISE NOTICE 'check_in          vol: %', (SELECT COUNT(*) FROM service_delivery.check_in       WHERE id = ANY(vci));
  RAISE NOTICE 'check_out         vol: %', (SELECT COUNT(*) FROM service_delivery.check_out      WHERE id = ANY(vco));
  RAISE NOTICE 'product_sale      vol: %', (SELECT COUNT(*) FROM service_delivery.product_sale   WHERE id = ANY(vps));
  RAISE NOTICE 'service_sale      vol: %', (SELECT COUNT(*) FROM service_delivery.service_sale   WHERE id = ANY(vss));
  RAISE NOTICE 'pre_invoice       vol: %', (SELECT COUNT(*) FROM billing.pre_invoice             WHERE id = ANY(vpi));
  RAISE NOTICE 'invoice           vol: %', (SELECT COUNT(*) FROM billing.invoice                 WHERE invoice_number LIKE 'INV-VOL-2027-%');
  RAISE NOTICE 'partial_payment   vol: %', (SELECT COUNT(*) FROM billing.partial_payment         WHERE id = ANY(vpp));
  RAISE NOTICE 'purchase_detail   vol: %', (SELECT COUNT(*) FROM billing.purchase_detail         WHERE id = ANY(vpd));
  RAISE NOTICE 'customer_loyalty  vol: %', (SELECT COUNT(*) FROM notification.customer_loyalty   WHERE id = ANY(vcl));
  RAISE NOTICE 'room_maintenance  vol: %', (SELECT COUNT(*) FROM maintenance.room_maintenance    WHERE id = ANY(vrm));
  RAISE NOTICE '=====================================';

END $$;