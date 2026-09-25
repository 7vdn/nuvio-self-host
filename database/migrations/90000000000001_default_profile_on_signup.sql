BEGIN;

CREATE OR REPLACE FUNCTION public.handle_new_user_default_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (
    user_id,
    profile_index,
    name
  )
  VALUES (
    NEW.id,
    1,
    'Profile 1'
  )
  ON CONFLICT (user_id, profile_index) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;

CREATE TRIGGER on_auth_user_created_profile
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user_default_profile();

-- Backfill existing accounts that do not yet have Profile 1.
INSERT INTO public.profiles (
  user_id,
  profile_index,
  name
)
SELECT
  u.id,
  1,
  'Profile 1'
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1
  FROM public.profiles p
  WHERE p.user_id = u.id
    AND p.profile_index = 1
)
ON CONFLICT (user_id, profile_index) DO NOTHING;

INSERT INTO nuvio_migrations.schema_migrations (version)
VALUES ('90000000000001')
ON CONFLICT (version) DO NOTHING;

COMMIT;
