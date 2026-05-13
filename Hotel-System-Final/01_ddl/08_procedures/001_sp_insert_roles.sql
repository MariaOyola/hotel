CREATE OR REPLACE PROCEDURE security.sp_insert_roles()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO security.app_role (id, name, description, status)
  VALUES
    ('00000000-0000-0000-0001-000000000001'::uuid, 'ADMIN',         'Full system administration role',           'ACTIVE'),
    ('00000000-0000-0000-0001-000000000002'::uuid, 'MANAGER',       'Hotel operations manager role',             'ACTIVE'),
    ('00000000-0000-0000-0001-000000000003'::uuid, 'RECEPTIONIST',  'Front desk and reservation role',           'ACTIVE'),
    ('00000000-0000-0000-0001-000000000004'::uuid, 'HOUSEKEEPING',  'Room cleaning and maintenance role',        'ACTIVE'),
    ('00000000-0000-0000-0001-000000000005'::uuid, 'ACCOUNTING',    'Billing and payment control role',          'ACTIVE')
  ON CONFLICT (name) DO NOTHING;

  RAISE NOTICE 'sp_insert_roles: canonical roles inserted.';
END;
$$;
