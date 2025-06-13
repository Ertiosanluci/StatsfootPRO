-- Función mejorada para crear un partido
CREATE OR REPLACE FUNCTION create_match(
  p_creador_id UUID,
  p_nombre TEXT,
  p_formato TEXT,
  p_fecha TIMESTAMPTZ,
  p_ubicacion VARCHAR,
  p_descripcion TEXT,
  p_publico BOOLEAN DEFAULT FALSE
) RETURNS JSON AS $$
DECLARE
  v_match_id BIGINT;
  v_creator_profile RECORD;
  v_match_link TEXT;
  v_result JSON;
BEGIN
  -- Verificar que el usuario existe
  SELECT * INTO v_creator_profile FROM profiles WHERE id = p_creador_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'El usuario no existe');
  END IF;

  -- Insertar el partido en la base de datos con el formato de fecha correcto
  INSERT INTO matches (
    creador_id,
    nombre,
    formato,
    fecha,
    ubicacion,
    descripcion,
    estado,
    created_at,
    publico,
    resultado_claro,
    resultado_oscuro
  ) VALUES (
    p_creador_id,
    p_nombre,
    p_formato,
    p_fecha,
    p_ubicacion,
    p_descripcion,
    'pendiente',
    NOW(),
    p_publico,
    0,
    0
  ) RETURNING id INTO v_match_id;

  -- Generar enlace único para el partido
  v_match_link := 'https://statsfootpro.netlify.app/match/' || v_match_id;
  
  -- Actualizar el partido con el enlace
  UPDATE matches SET enlace = v_match_link WHERE id = v_match_id;
  
  -- Registrar al creador como organizador en match_participants
  INSERT INTO match_participants (
    match_id,
    user_id,
    equipo,
    es_organizador,
    joined_at
  ) VALUES (
    v_match_id,
    p_creador_id,
    NULL,
    TRUE,
    NOW()
  );
  
  -- Devolver información del partido creado
  RETURN json_build_object(
    'success', TRUE,
    'message', 'Partido creado correctamente',
    'match_id', v_match_id,
    'match_link', v_match_link,
    'creator_name', v_creator_profile.username
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'message', 'Error interno: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener detalles de un partido incluyendo el nombre del organizador
CREATE OR REPLACE FUNCTION get_match_details(p_match_id BIGINT)
RETURNS JSON AS $$
DECLARE
  v_match RECORD;
  v_creator_profile RECORD;
  v_participants_count INTEGER;
BEGIN
  -- Obtener información del partido
  SELECT * INTO v_match FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'El partido no existe');
  END IF;
  
  -- Obtener información del creador
  SELECT username, avatar_url INTO v_creator_profile FROM profiles WHERE id = v_match.creador_id;
  
  -- Contar participantes
  SELECT COUNT(*) INTO v_participants_count FROM match_participants WHERE match_id = p_match_id;
  
  -- Devolver información completa
  RETURN json_build_object(
    'success', TRUE,
    'match', json_build_object(
      'id', v_match.id,
      'nombre', v_match.nombre,
      'formato', v_match.formato,
      'fecha', v_match.fecha,
      'ubicacion', v_match.ubicacion,
      'descripcion', v_match.descripcion,
      'estado', v_match.estado,
      'publico', v_match.publico,
      'enlace', v_match.enlace,
      'resultado_claro', v_match.resultado_claro,
      'resultado_oscuro', v_match.resultado_oscuro,
      'created_at', v_match.created_at,
      'updated_at', v_match.updated_at,
      'creador', json_build_object(
        'id', v_match.creador_id,
        'username', v_creator_profile.username,
        'avatar_url', v_creator_profile.avatar_url
      ),
      'participantes_count', v_participants_count
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
