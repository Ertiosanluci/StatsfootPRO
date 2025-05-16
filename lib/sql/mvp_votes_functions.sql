-- Función para contar votos de MVP
CREATE OR REPLACE FUNCTION count_mvp_votes(match_id_param BIGINT, team_param TEXT)
RETURNS TABLE (
  voted_player_id UUID,
  vote_count BIGINT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.voted_player_id,
    COUNT(*) as vote_count
  FROM 
    mvp_votes v
  WHERE 
    v.match_id = match_id_param AND
    v.team = team_param
  GROUP BY 
    v.voted_player_id
  ORDER BY 
    vote_count DESC
  LIMIT 1;
END;
$$;
