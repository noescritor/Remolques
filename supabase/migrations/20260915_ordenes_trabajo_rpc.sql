CREATE OR REPLACE FUNCTION obtener_siguiente_produccion()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  proximo int;
BEGIN
  SELECT nextval('seq_produccion_global') INTO proximo;
  RETURN proximo;
END;
$$;
