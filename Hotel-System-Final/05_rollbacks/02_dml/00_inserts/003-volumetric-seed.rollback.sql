-- =============================================================================
-- 003-volumetric-seed.rollback.sql
-- Elimina todos los datos volumétricos en orden inverso de inserción
-- para respetar las foreign keys.
-- Identificador del bloque: UUID con 0070 en posición 3
-- =============================================================================

DO $$
BEGIN

  -- 19. room_maintenance
  DELETE FROM maintenance.room_maintenance
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000043%';

  -- 18. customer_loyalty
  DELETE FROM notification.customer_loyalty
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000042%';

  -- 17. purchase_detail
  DELETE FROM billing.purchase_detail
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000038%';

  -- 16. partial_payment
  DELETE FROM billing.partial_payment
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000037%';

  -- 15. invoice
  DELETE FROM billing.invoice
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000036%';

  -- 14. pre_invoice
  DELETE FROM billing.pre_invoice
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000035%';

  -- 13. service_sale
  DELETE FROM service_delivery.service_sale
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000034%';

  -- 12. product_sale
  DELETE FROM service_delivery.product_sale
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000033%';

  -- 11. check_out
  DELETE FROM service_delivery.check_out
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000026%';

  -- 10. check_in
  DELETE FROM service_delivery.check_in
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000025%';

  -- 9. stay
  DELETE FROM service_delivery.stay
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000024%';

  -- 8. room_reservation
  DELETE FROM service_delivery.room_reservation
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000020%';

  -- 7. price
  DELETE FROM parameterization.price
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000019%';

  -- 6. room
  DELETE FROM distribution.room
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000018%';

  -- 5. employee
  DELETE FROM parameterization.employee
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000013%';

  -- 4. app_user_role
  DELETE FROM security.app_user_role
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000008%';

  -- 3. app_user
  DELETE FROM security.app_user
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000007%';

  -- 2. person
  DELETE FROM security.person
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000002%';

  -- 1. customer
  DELETE FROM parameterization.customer
  WHERE id::TEXT LIKE '00000000-0000-0000-0070-000001%';

  RAISE NOTICE 'Volumetric seed rollback completed successfully.';

END $$;