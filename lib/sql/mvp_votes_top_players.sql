 -- Función para contar los votos de MVPs y obtener los jugadores más votados (hasta 3)
CREATE OR REPLACE FUNCTION get_top_mvp_votes(match_id_param BIGINT, limit_param INT DEFAULT 3)
RETURNS TABLE (
  voted_player_id TEXT,
  player_name TEXT,
  vote_count BIGINT,
  team TEXT,
  foto_url TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH vote_counts AS (
    SELECT 
      v.voted_player_id,
      COUNT(v.voted_player_id) as vote_count,
      v.team
    FROM 
      mvp_votes v
    WHERE 
      v.match_id = match_id_param
    GROUP BY 
      v.voted_player_id, v.team
  )
  SELECT 
    vc.voted_player_id,
    COALESCE(up.nombre, 'Jugador') as player_name,
    vc.vote_count,
    vc.team,
    up.foto_perfil as foto_url
  FROM 
    vote_counts vc
  LEFT JOIN
    users_profiles up ON vc.voted_player_id = up.user_id
  ORDER BY 
    vc.vote_count DESC
  LIMIT limit_param;
END;
$$;
