-- Función para obtener los jugadores más votados como MVP
CREATE OR REPLACE FUNCTION get_top_mvp_votes(match_id_param BIGINT, limit_param INT DEFAULT 3)
RETURNS TABLE (
    match_id BIGINT,
    voted_player_id TEXT,
    vote_count BIGINT,
    player_name TEXT,
    foto_url TEXT,
    team TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH vote_counts AS (
        SELECT 
            v.match_id,
            v.voted_player_id::TEXT,
            COUNT(*) AS vote_count,
            v.team
        FROM 
            mvp_votes v
        WHERE
            v.match_id = match_id_param
        GROUP BY 
            v.match_id, 
            v.voted_player_id,
            v.team
        ORDER BY 
            COUNT(*) DESC
        LIMIT limit_param
    )    SELECT
        vc.match_id,
        vc.voted_player_id,
        vc.vote_count,
        p.full_name as player_name,
        p.avatar_url as foto_url,
        vc.team
    FROM 
        vote_counts vc
    LEFT JOIN
        users_profiles p ON p.user_id = vc.voted_player_id
    ORDER BY 
        vc.vote_count DESC,
        COALESCE(p.full_name, 'Desconocido') ASC;
END;
$$ LANGUAGE plpgsql;
