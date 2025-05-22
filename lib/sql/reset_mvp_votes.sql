-- Función para resetear las votaciones de MVP de un partido
-- Esta función elimina todos los votos y estado de votación, devolviendo el partido al estado sin votaciones
CREATE OR REPLACE FUNCTION reset_mvp_votes(match_id_param BIGINT)
RETURNS VOID AS $$
BEGIN
    -- Eliminar todos los votos relacionados con este partido
    DELETE FROM mvp_votes
    WHERE match_id = match_id_param;    -- Eliminar cualquier registro de votación existente para este partido
    -- En lugar de intentar cambiar el estado, eliminamos el registro por completo
    -- para permitir crear uno nuevo desde cero
    DELETE FROM mvp_voting_status
    WHERE match_id = match_id_param;
    
    -- Eliminar los MVPs del partido (poner a NULL)
    UPDATE matches
    SET mvp_team_claro = NULL,
        mvp_team_oscuro = NULL
    WHERE id = match_id_param;
    
    -- Registrar en logs (opcional)
    -- INSERT INTO voting_activity_log (match_id, action, performed_at)
    -- VALUES (match_id_param, 'reset_voting', NOW());
END;
$$ LANGUAGE plpgsql;