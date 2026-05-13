CREATE OR REPLACE PROCEDURE parameterization.sp_insert_day_types()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO parameterization.day_type (id, name, description, date, applies_season, applies_holiday, applies_special_day, status)
  VALUES
    ('00000000-0000-0000-0003-000000000001'::uuid, 'WEEKDAY',      'Standard Monday to Friday rate',    NULL, FALSE, FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000002'::uuid, 'WEEKEND',      'Saturday and Sunday rate',          NULL, FALSE, FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000003'::uuid, 'HIGH_SEASON',  'High demand season rate',           NULL, TRUE,  FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000004'::uuid, 'LOW_SEASON',   'Low demand season rate',            NULL, TRUE,  FALSE, FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000005'::uuid, 'HOLIDAY',      'National public holiday rate',      NULL, FALSE, TRUE,  FALSE, 'ACTIVE'),
    ('00000000-0000-0000-0003-000000000006'::uuid, 'SPECIAL_EVENT','Special local or hotel event rate', NULL, FALSE, FALSE, TRUE,  'ACTIVE')
  ON CONFLICT (name, date) DO NOTHING;

  RAISE NOTICE 'sp_insert_day_types: canonical day types inserted.';
END;
$$;
