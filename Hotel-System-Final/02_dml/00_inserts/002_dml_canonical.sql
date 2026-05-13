-- =============================================================================
-- HU-12: DML Datos canónicos
-- Llama los stored procedures que insertan la configuración mínima del sistema.
-- Orden de ejecución: roles → room_status → day_types → payment_methods → admin
-- =============================================================================

-- 1. Roles base del sistema
CALL security.sp_insert_roles();

-- 2. Estados de habitación
CALL distribution.sp_insert_room_status();

-- 3. Tipos de día
CALL parameterization.sp_insert_day_types();

-- 4. Métodos de pago
CALL parameterization.sp_insert_payment_methods();

-- 5. Usuario administrador inicial
--    Depende de que sp_insert_roles ya haya insertado el rol ADMIN.
CALL security.sp_insert_admin_user();

-- =============================================================================
-- Verificación: SELECT que confirma que los datos existen y son coherentes
-- =============================================================================

-- Roles
SELECT 'app_role' AS tabla, COUNT(*) AS total FROM security.app_role WHERE status = 'ACTIVE';

-- Estados de habitación
SELECT 'room_status' AS tabla, COUNT(*) AS total FROM distribution.room_status WHERE status = 'ACTIVE';

-- Tipos de día
SELECT 'day_type' AS tabla, COUNT(*) AS total FROM parameterization.day_type WHERE status = 'ACTIVE';

-- Métodos de pago
SELECT 'payment_method' AS tabla, COUNT(*) AS total FROM parameterization.payment_method WHERE status = 'ACTIVE';

-- Usuario administrador y su rol asignado (sin datos huérfanos)
SELECT
  u.username,
  p.name    AS person_name,
  p.email   AS person_email,
  r.name    AS role_name
FROM security.app_user         u
JOIN security.person           p  ON p.id  = u.person_id
JOIN security.app_user_role    ur ON ur.app_user_id = u.id
JOIN security.app_role         r  ON r.id  = ur.role_id
WHERE u.username = 'admin';
