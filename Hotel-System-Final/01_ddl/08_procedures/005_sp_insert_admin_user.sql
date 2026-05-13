CREATE OR REPLACE PROCEDURE security.sp_insert_admin_user()
LANGUAGE plpgsql
AS $$
DECLARE
  v_person_id     UUID := '00000000-0000-0000-0005-000000000001'::uuid;
  v_user_id       UUID := '00000000-0000-0000-0005-000000000002'::uuid;
  v_user_role_id  UUID := '00000000-0000-0000-0005-000000000003'::uuid;
  v_admin_role_id UUID;
BEGIN
  -- Obtener el ID real del rol ADMIN
  SELECT id INTO v_admin_role_id
  FROM security.app_role
  WHERE name = 'ADMIN';

 
  IF v_admin_role_id IS NULL THEN
    RAISE EXCEPTION 'ERROR: ADMIN role not found. sp_insert_roles must run first.';
  END IF;

  -- Insert person
  INSERT INTO security.person (id, document_type, document_number, name, last_name, email, status)
  VALUES (
    v_person_id,
    'CC',
    '0000000001',
    'System',
    'Administrator',
    'admin@hotelsystem.com',
    'ACTIVE'
  )
  ON CONFLICT (document_type, document_number) DO NOTHING;

  -- Insert user
  INSERT INTO security.app_user (id, person_id, username, password_hash, blocked, status)
  VALUES (
    v_user_id,
    v_person_id,
    'admin',
    '$2b$12$KIX9zr2Hn1e1vZq7hWq5aOeGtAtfQ3nZkXdN.oP8qLjM5wYFn3T8u',
    FALSE,
    'ACTIVE'
  )
  ON CONFLICT (username) DO NOTHING;

  -- Assign role
  INSERT INTO security.app_user_role (id, app_user_id, role_id, status)
  VALUES (
    v_user_role_id,
    v_user_id,
    v_admin_role_id,
    'ACTIVE'
  )
  ON CONFLICT (app_user_id, role_id) DO NOTHING;

  RAISE NOTICE 'sp_insert_admin_user: initial admin user created (username: admin).';
END;
$$;