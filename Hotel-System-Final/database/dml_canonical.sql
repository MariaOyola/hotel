-- =============================================================================
-- HU-12: DML Datos canónicos — Script consolidado standalone
-- Archivo: /database/dml_canonical.sql
--
-- Crea los stored procedures e inserta la configuración mínima necesaria para
-- que el sistema hotelero pueda operar. No usa INSERT directos; todos los
-- datos se cargan a través de los procedures definidos aquí mismo.
--
-- Orden de ejecución:
--   1. sp_insert_roles            → security.app_role
--   2. sp_insert_room_status      → distribution.room_status
--   3. sp_insert_day_types        → parameterization.day_type
--   4. sp_insert_payment_methods  → parameterization.payment_method
--   5. sp_insert_admin_user       → security.person + app_user + app_user_role
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. Stored procedure: roles base
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE security.sp_insert_roles()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO security.app_role (id, name, description, status)
  VALUES
    ('00000000-0000-0000-0001-000000000001'::uuid, 'ADMIN',        'Full system administration role',           'ACTIVE'),
    ('00000000-0000-0000-0001-000000000002'::uuid, 'MANAGER',      'Hotel operations manager role',             'ACTIVE'),
    ('00000000-0000-0000-0001-000000000003'::uuid, 'RECEPTIONIST', 'Front desk and reservation role',           'ACTIVE'),
    ('00000000-0000-0000-0001-000000000004'::uuid, 'HOUSEKEEPING', 'Room cleaning and maintenance role',        'ACTIVE'),
    ('00000000-0000-0000-0001-000000000005'::uuid, 'ACCOUNTING',   'Billing and payment control role',          'ACTIVE')
  ON CONFLICT (name) DO NOTHING;

  RAISE NOTICE 'sp_insert_roles: canonical roles inserted.';
END;
$$;


-- ---------------------------------------------------------------------------
-- 2. Stored procedure: estados de habitación
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE distribution.sp_insert_room_status()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO distribution.room_status (id, name, description, allows_reservation, allows_check_in, status)
  VALUES
    ('00000000-0000-0000-0002-000000000001'::uuid, 'AVAILABLE',      'Room is clean and ready for a new guest',        TRUE,  TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0002-000000000002'::uuid, 'OCCUPIED',       'Room is currently occupied by a guest',          FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0002-000000000003'::uuid, 'RESERVED',       'Room has a confirmed reservation',               FALSE, TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0002-000000000004'::uuid, 'CLEANING',       'Room is being cleaned after check-out',          FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0002-000000000005'::uuid, 'MAINTENANCE',    'Room is temporarily out of service for repairs', FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0002-000000000006'::uuid, 'OUT_OF_SERVICE', 'Room is permanently disabled',                   FALSE, FALSE, 'ACTIVE')
  ON CONFLICT (name) DO NOTHING;

  RAISE NOTICE 'sp_insert_room_status: canonical room statuses inserted.';
END;
$$;


-- ---------------------------------------------------------------------------
-- 3. Stored procedure: tipos de día
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE parameterization.sp_insert_day_types()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO parameterization.day_type (id, name, description, date, applies_season, applies_holiday, applies_special_day, status)
  VALUES
    ('00000000-0000-0000-0003-000000000001'::uuid, 'WEEKDAY',       'Standard Monday to Friday rate',    NULL, FALSE, FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000002'::uuid, 'WEEKEND',       'Saturday and Sunday rate',          NULL, FALSE, FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000003'::uuid, 'HIGH_SEASON',   'High demand season rate',           NULL, TRUE,  FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000004'::uuid, 'LOW_SEASON',    'Low demand season rate',            NULL, TRUE,  FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000005'::uuid, 'HOLIDAY',       'National public holiday rate',      NULL, FALSE, TRUE,  FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000006'::uuid, 'SPECIAL_EVENT', 'Special local or hotel event rate', NULL, FALSE, FALSE, TRUE,  'ACTIVE')
  ON CONFLICT (name, date) DO NOTHING;

  RAISE NOTICE 'sp_insert_day_types: canonical day types inserted.';
END;
$$;


-- ---------------------------------------------------------------------------
-- 4. Stored procedure: métodos de pago
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE parameterization.sp_insert_payment_methods()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO parameterization.payment_method (id, name, description, requires_reference, allows_partial_payment, status)
  VALUES
    ('00000000-0000-0000-0004-000000000001'::uuid, 'CASH',           'Cash payment at the front desk',                       FALSE, TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0004-000000000002'::uuid, 'CREDIT_CARD',    'Payment via credit card through POS terminal',         TRUE,  TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0004-000000000003'::uuid, 'DEBIT_CARD',     'Payment via debit card through POS terminal',          TRUE,  TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0004-000000000004'::uuid, 'BANK_TRANSFER',  'Wire transfer — reference number required',            TRUE,  FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0004-000000000005'::uuid, 'DIGITAL_WALLET', 'Payment via digital wallet (e.g. Nequi, Daviplata)',   TRUE,  TRUE,  'ACTIVE')
  ON CONFLICT (name) DO NOTHING;

  RAISE NOTICE 'sp_insert_payment_methods: canonical payment methods inserted.';
END;
$$;


-- ---------------------------------------------------------------------------
-- 5. Stored procedure: usuario administrador inicial
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE security.sp_insert_admin_user()
LANGUAGE plpgsql
AS $$
DECLARE
  v_person_id     UUID := '00000000-0000-0000-0005-000000000001'::uuid;
  v_user_id       UUID := '00000000-0000-0000-0005-000000000002'::uuid;
  v_user_role_id  UUID := '00000000-0000-0000-0005-000000000003'::uuid;
  v_admin_role_id UUID := '00000000-0000-0000-0001-000000000001'::uuid;
BEGIN
  INSERT INTO security.person (id, document_type, document_number, name, last_name, email, status)
  VALUES (v_person_id, 'CC', '0000000001', 'System', 'Administrator', 'admin@hotelsystem.com', 'ACTIVE')
  ON CONFLICT (document_type, document_number) DO NOTHING;

  -- password_hash corresponde a 'Admin1234!' con bcrypt cost 12
  INSERT INTO security.app_user (id, person_id, username, password_hash, blocked, status)
  VALUES (v_user_id, v_person_id, 'admin', '$2b$12$KIX9zr2Hn1e1vZq7hWq5aOeGtAtfQ3nZkXdN.oP8qLjM5wYFn3T8u', FALSE, 'ACTIVE')
  ON CONFLICT (username) DO NOTHING;

  INSERT INTO security.app_user_role (id, app_user_id, role_id, status)
  VALUES (v_user_role_id, v_user_id, v_admin_role_id, 'ACTIVE')
  ON CONFLICT (app_user_id, role_id) DO NOTHING;

  RAISE NOTICE 'sp_insert_admin_user: initial admin user created (username: admin).';
END;
$$;


-- =============================================================================
-- Ejecución de los procedures
-- =============================================================================

CALL security.sp_insert_roles();
CALL distribution.sp_insert_room_status();
CALL parameterization.sp_insert_day_types();
CALL parameterization.sp_insert_payment_methods();
CALL security.sp_insert_admin_user();


-- =============================================================================
-- Verificación: SELECT que confirma que los datos existen y son coherentes
-- =============================================================================

SELECT 'app_role'       AS tabla, COUNT(*) AS total FROM security.app_role            WHERE status = 'ACTIVE';
SELECT 'room_status'    AS tabla, COUNT(*) AS total FROM distribution.room_status      WHERE status = 'ACTIVE';
SELECT 'day_type'       AS tabla, COUNT(*) AS total FROM parameterization.day_type     WHERE status = 'ACTIVE';
SELECT 'payment_method' AS tabla, COUNT(*) AS total FROM parameterization.payment_method WHERE status = 'ACTIVE';

SELECT
  u.username,
  p.name        AS person_name,
  p.email       AS person_email,
  r.name        AS role_name
FROM security.app_user         u
JOIN security.person           p  ON p.id  = u.person_id
JOIN security.app_user_role    ur ON ur.app_user_id = u.id
JOIN security.app_role         r  ON r.id  = ur.role_id
WHERE u.username = 'admin';
