CREATE OR REPLACE PROCEDURE distribution.sp_insert_room_status()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO distribution.room_status (id, name, description, allows_reservation, allows_check_in, status)
  VALUES
    ('00000000-0000-0000-0002-000000000001'::uuid, 'AVAILABLE',     'Room is clean and ready for a new guest',        TRUE,  TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0002-000000000002'::uuid, 'OCCUPIED',      'Room is currently occupied by a guest',          FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0002-000000000003'::uuid, 'RESERVED',      'Room has a confirmed reservation',               FALSE, TRUE,  'ACTIVE'),
    ('00000000-0000-0000-0002-000000000004'::uuid, 'CLEANING',      'Room is being cleaned after check-out',          FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0002-000000000005'::uuid, 'MAINTENANCE',   'Room is temporarily out of service for repairs', FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0002-000000000006'::uuid, 'OUT_OF_SERVICE','Room is permanently disabled',                   FALSE, FALSE, 'ACTIVE')
  ON CONFLICT (name) DO NOTHING;

  RAISE NOTICE 'sp_insert_room_status: canonical room statuses inserted.';
END;
$$;
