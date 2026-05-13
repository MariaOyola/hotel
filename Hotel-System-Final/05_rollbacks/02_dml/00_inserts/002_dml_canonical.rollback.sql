-- =============================================================================
-- Rollback HU-12: Elimina los datos canónicos insertados por los stored procedures
-- Orden inverso al de inserción para respetar las FKs
-- =============================================================================

-- 5. Eliminar asignación de rol del admin
DELETE FROM security.app_user_role
WHERE id = '00000000-0000-0000-0005-000000000003'::uuid;

-- 5. Eliminar usuario administrador
DELETE FROM security.app_user
WHERE id = '00000000-0000-0000-0005-000000000002'::uuid;

-- 5. Eliminar persona del administrador
DELETE FROM security.person
WHERE id = '00000000-0000-0000-0005-000000000001'::uuid;

-- 4. Eliminar métodos de pago canónicos
DELETE FROM parameterization.payment_method
WHERE id IN (
  '00000000-0000-0000-0004-000000000001'::uuid,
  '00000000-0000-0000-0004-000000000002'::uuid,
  '00000000-0000-0000-0004-000000000003'::uuid,
  '00000000-0000-0000-0004-000000000004'::uuid,
  '00000000-0000-0000-0004-000000000005'::uuid
);

-- 3. Eliminar tipos de día canónicos
DELETE FROM parameterization.day_type
WHERE id IN (
  '00000000-0000-0000-0003-000000000001'::uuid,
  '00000000-0000-0000-0003-000000000002'::uuid,
  '00000000-0000-0000-0003-000000000003'::uuid,
  '00000000-0000-0000-0003-000000000004'::uuid,
  '00000000-0000-0000-0003-000000000005'::uuid,
  '00000000-0000-0000-0003-000000000006'::uuid
);

-- 2. Eliminar estados de habitación canónicos
DELETE FROM distribution.room_status
WHERE id IN (
  '00000000-0000-0000-0002-000000000001'::uuid,
  '00000000-0000-0000-0002-000000000002'::uuid,
  '00000000-0000-0000-0002-000000000003'::uuid,
  '00000000-0000-0000-0002-000000000004'::uuid,
  '00000000-0000-0000-0002-000000000005'::uuid,
  '00000000-0000-0000-0002-000000000006'::uuid
);

-- 1. Eliminar roles canónicos
DELETE FROM security.app_role
WHERE id IN (
  '00000000-0000-0000-0001-000000000001'::uuid,
  '00000000-0000-0000-0001-000000000002'::uuid,
  '00000000-0000-0000-0001-000000000003'::uuid,
  '00000000-0000-0000-0001-000000000004'::uuid,
  '00000000-0000-0000-0001-000000000005'::uuid
);
