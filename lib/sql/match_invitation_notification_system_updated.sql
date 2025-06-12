-- Función actualizada para crear invitaciones a partidos con sender_id en las notificaciones
CREATE OR REPLACE FUNCTION create_match_invitation(
  p_match_id INT,
  p_inviter_id UUID,
  p_invited_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_match RECORD;
  v_inviter_profile RECORD;
  v_match_name TEXT;
  v_invitation_id UUID;
BEGIN
  -- Verificar si el partido existe
  SELECT * INTO v_match FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'El partido no existe');
  END IF;
  
  -- Verificar si el invitador es el creador del partido o un participante
  IF v_match.creator_id != p_inviter_id AND NOT EXISTS (
    SELECT 1 FROM match_participants WHERE match_id = p_match_id AND user_id = p_inviter_id
  ) THEN
    RETURN json_build_object('success', FALSE, 'message', 'No tienes permiso para invitar a este partido');
  END IF;
  
  -- Verificar si el invitado ya está en el partido
  IF EXISTS (
    SELECT 1 FROM match_participants WHERE match_id = p_match_id AND user_id = p_invited_id
  ) THEN
    RETURN json_build_object('success', FALSE, 'message', 'El usuario ya está en el partido');
  END IF;
  
  -- Verificar si ya existe una invitación pendiente
  IF EXISTS (
    SELECT 1 FROM match_invitations 
    WHERE match_id = p_match_id AND invited_id = p_invited_id AND status = 'pending'
  ) THEN
    RETURN json_build_object('success', FALSE, 'message', 'Ya existe una invitación pendiente para este usuario');
  END IF;
  
  -- Crear la invitación
  INSERT INTO match_invitations (match_id, inviter_id, invited_id)
  VALUES (p_match_id, p_inviter_id, p_invited_id)
  RETURNING id INTO v_invitation_id;
  
  -- Obtener información del invitador para la notificación
  SELECT * INTO v_inviter_profile FROM profiles WHERE id = p_inviter_id;
  
  -- Obtener el nombre del partido
  v_match_name := COALESCE(v_match.nombre, 'Partido');
  
  -- Crear notificación para el invitado
  INSERT INTO notifications (
    user_id, 
    sender_id, -- Añadido el campo sender_id
    type,
    title, 
    message, 
    data
  )
  VALUES (
    p_invited_id,
    p_inviter_id, -- Asignamos el inviter_id como sender_id
    'match_invitation',
    'Invitación a partido',
    COALESCE(v_inviter_profile.username, 'Un usuario') || ' te ha invitado al partido "' || v_match_name || '"',
    json_build_object(
      'match_id', p_match_id,
      'inviter_id', p_inviter_id,
      'match_name', v_match_name,
      'invitation_id', v_invitation_id
    )
  );
  
  RETURN json_build_object('success', TRUE, 'message', 'Invitación enviada correctamente');
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'message', 'Error al crear la invitación: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
