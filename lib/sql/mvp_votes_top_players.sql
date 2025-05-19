 -- Función para contar los votos de MVPs y obtener los jugadores más votados (hasta 3)
CREATE OR REPLACE FUNCTION get_top_mvp_votes(match_id_param BIGINT, limit_param INT DEFAULT 3)
RETURNS TABLE (
  voted_player_id TEXT,
  player_name TEXT,
  vote_count BIGINT,
  team TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.voted_player_id,
    COALESCE(up.nombre, 'Jugador') as player_name,
    COUNT(v.voted_player_id) as vote_count,
    v.team
  FROM 
    mvp_votes v
  LEFT JOIN
    users_profiles up ON v.voted_player_id = up.user_id
  WHERE 
    v.match_id = match_id_param
  GROUP BY 
    v.voted_player_id, up.nombre, v.team
  ORDER BY 
    COUNT(v.voted_player_id) DESC
  LIMIT limit_param;
END;
$$;
