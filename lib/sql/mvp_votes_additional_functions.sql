-- Función para contar votantes únicos en un partido
CREATE OR REPLACE FUNCTION get_unique_voters_count(match_id_param BIGINT)
RETURNS TABLE (
  count BIGINT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT voter_id) as count
  FROM 
    mvp_votes
  WHERE 
    match_id = match_id_param;
END;
$$;
