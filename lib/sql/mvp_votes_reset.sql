-- Función para resetear los votos de MVP de un partido
CREATE OR REPLACE FUNCTION reset_mvp_votes(match_id_param BIGINT)
RETURNS VOID 
LANGUAGE plpgsql
AS $$
BEGIN
  -- Eliminar los votos relacionados con el partido
  DELETE FROM mvp_votes WHERE match_id = match_id_param;
  
  -- Eliminar los registros de top players (si la tabla existe)
  BEGIN
    DELETE FROM mvp_top_players WHERE match_id = match_id_param;
  EXCEPTION
    WHEN undefined_table THEN
      RAISE NOTICE 'Tabla mvp_top_players no existe, continuando...';
  END;
  
  -- Eliminar votaciones previas (estado)
  DELETE FROM mvp_voting_status WHERE match_id = match_id_param;
  
  -- Limpiar campos de MVP en la tabla de partidos
  UPDATE matches
  SET mvp_team_claro = NULL, mvp_team_oscuro = NULL
  WHERE id = match_id_param;
END;
$$;
