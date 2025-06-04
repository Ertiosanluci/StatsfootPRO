-- Función corregida para crear una invitación a un partido
CREATE OR REPLACE FUNCTION create_match_invitation(
  p_match_id BIGINT,
  p_inviter_id UUID,
  p_invited_id UUID
) RETURNS JSON AS $$
DECLARE
  v_match RECORD;
  v_existing_invitation RECORD;
  v_existing_participant RECORD;
  v_inviter_profile RECORD;
  v_match_name TEXT;
  v_result JSON;
BEGIN
  -- Verificar que el partido existe
  SELECT * INTO v_match FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'El partido no existe');
  END IF;
  
  -- Verificar que el invitado no es el mismo que el invitador
  IF p_inviter_id = p_invited_id THEN
    RETURN json_build_object('success', FALSE, 'message', 'No puedes invitarte a ti mismo');
  END IF;
  
  -- Verificar que el invitador es organizador o participante del partido
  SELECT * INTO v_existing_participant 
  FROM match_participants 
  WHERE match_id = p_match_id AND user_id = p_inviter_id;
  
  -- CORRECCIÓN: Usar creador_id en lugar de creator_id
  IF NOT FOUND AND v_match.creador_id != p_inviter_id THEN
    RETURN json_build_object('success', FALSE, 'message', 'No eres participante de este partido');
  END IF;
  
  -- Verificar que el invitado no está ya participando en el partido
  SELECT * INTO v_existing_participant 
  FROM match_participants 
  WHERE match_id = p_match_id AND user_id = p_invited_id;
  
  IF FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'El usuario ya es participante de este partido');
  END IF;
  
  -- Verificar que no existe una invitación pendiente
  SELECT * INTO v_existing_invitation 
  FROM match_invitations 
  WHERE match_id = p_match_id AND invited_id = p_invited_id AND status = 'pending';
  
  IF FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'Ya existe una invitación pendiente para este usuario');
  END IF;
  
  -- Crear la invitación
  INSERT INTO match_invitations (match_id, inviter_id, invited_id)
  VALUES (p_match_id, p_inviter_id, p_invited_id);
  
  -- Obtener información del invitador para la notificación
  SELECT username INTO v_inviter_profile FROM profiles WHERE id = p_inviter_id;
  
  -- Obtener el nombre del partido
  v_match_name := COALESCE(v_match.nombre, 'Partido');
  
  -- Crear notificación para el invitado
  INSERT INTO notifications (
    user_id, 
    type,
    title, 
    message, 
    data
  )
  VALUES (
    p_invited_id,
    'match_invitation',
    'Invitación a partido',
    COALESCE(v_inviter_profile.username, 'Un usuario') || ' te ha invitado al partido "' || v_match_name || '"',
    json_build_object(
      'match_id', p_match_id,
      'inviter_id', p_inviter_id,
      'match_name', v_match_name
    )
  );
  
  RETURN json_build_object('success', TRUE, 'message', 'Invitación enviada correctamente');
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE, 
      'message', 'Error interno: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
