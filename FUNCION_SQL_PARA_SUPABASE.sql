-- FUNCIÓN SQL CORREGIDA PARA SUPABASE
-- Esta función arregla el error "ID de invitación no encontrado"
-- Usar esta función en el SQL Editor de Supabase

-- 1. Función para crear invitación de partido (CORREGIDA)
CREATE OR REPLACE FUNCTION create_match_invitation(
  p_match_id BIGINT,
  p_inviter_id UUID,
  p_invitee_id UUID  -- Usar invitee_id (campo correcto en la BD)
) RETURNS JSON AS $$
DECLARE
  v_match RECORD;
  v_existing_invitation RECORD;
  v_existing_participant RECORD;
  v_inviter_profile RECORD;
  v_match_name TEXT;
  v_invitation_id UUID;
BEGIN
  -- Verificar que el partido existe
  SELECT * INTO v_match FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'El partido no existe');
  END IF;
  
  -- Verificar que el invitado no es el mismo que el invitador
  IF p_inviter_id = p_invitee_id THEN
    RETURN json_build_object('success', FALSE, 'message', 'No puedes invitarte a ti mismo');
  END IF;
  
  -- Verificar que el invitador es organizador o participante del partido
  SELECT * INTO v_existing_participant 
  FROM match_participants 
  WHERE match_id = p_match_id AND user_id = p_inviter_id;
  
  -- Usar el campo correcto del creador del partido
  IF NOT FOUND AND v_match.creador_id != p_inviter_id THEN
    RETURN json_build_object('success', FALSE, 'message', 'No eres participante de este partido');
  END IF;
  
  -- Verificar que el invitado no está ya participando en el partido
  SELECT * INTO v_existing_participant 
  FROM match_participants 
  WHERE match_id = p_match_id AND user_id = p_invitee_id;
  
  IF FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'El usuario ya es participante de este partido');
  END IF;
  
  -- Verificar que no existe una invitación pendiente (USAR INVITEE_ID CORRECTO)
  SELECT * INTO v_existing_invitation 
  FROM match_invitations 
  WHERE match_id = p_match_id AND invitee_id = p_invitee_id AND status = 'pending';
  
  IF FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'Ya existe una invitación pendiente para este usuario');
  END IF;
  
  -- Crear la invitación (USAR INVITEE_ID CORRECTO)
  INSERT INTO match_invitations (match_id, inviter_id, invitee_id, status)
  VALUES (p_match_id, p_inviter_id, p_invitee_id, 'pending')
  RETURNING id INTO v_invitation_id;
  
  -- Obtener información del invitador para la notificación
  SELECT username INTO v_inviter_profile FROM profiles WHERE id = p_inviter_id;
  
  -- Obtener el nombre del partido
  v_match_name := COALESCE(v_match.nombre, v_match.title, 'Partido');
  
  -- ⭐ CREAR NOTIFICACIÓN CON INVITATION_ID (FIX PRINCIPAL)
  INSERT INTO notifications (
    user_id, 
    type,
    title, 
    message, 
    data
  )
  VALUES (
    p_invitee_id,
    'match_invitation',
    'Invitación a partido',
    COALESCE(v_inviter_profile.username, 'Un usuario') || ' te ha invitado al partido "' || v_match_name || '"',
    json_build_object(
      'match_id', p_match_id,
      'inviter_id', p_inviter_id,
      'match_name', v_match_name,
      'invitation_id', v_invitation_id  -- ⭐ ESTE ES EL FIX PRINCIPAL
    )
  );
  
  RETURN json_build_object(
    'success', TRUE, 
    'message', 'Invitación enviada correctamente',
    'invitation_id', v_invitation_id
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE, 
      'message', 'Error interno: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Función para responder a invitaciones (CORREGIDA)
CREATE OR REPLACE FUNCTION respond_to_match_invitation(
  invitation_id UUID,
  response TEXT
) RETURNS JSON AS $$
DECLARE
  v_invitation RECORD;
  v_match RECORD;
  v_current_user_id UUID;
  v_participant_count INTEGER;
BEGIN
  -- Get current user ID
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RETURN json_build_object('success', FALSE, 'message', 'Usuario no autenticado');
  END IF;
  
  -- Verificar que la invitación existe y es para el usuario correcto (USAR INVITEE_ID)
  SELECT * INTO v_invitation 
  FROM match_invitations 
  WHERE id = invitation_id::UUID AND invitee_id = v_current_user_id AND status = 'pending';
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'Invitación no encontrada o ya respondida');
  END IF;
  
  -- Validar respuesta
  IF response NOT IN ('accepted', 'declined', 'rejected') THEN
    RETURN json_build_object('success', FALSE, 'message', 'Respuesta inválida');
  END IF;
  
  -- Obtener información del partido
  SELECT * INTO v_match FROM matches WHERE id = v_invitation.match_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'Partido no encontrado');
  END IF;
  
  -- Actualizar el estado de la invitación
  UPDATE match_invitations
  SET 
    status = response,
    updated_at = NOW()
  WHERE id = invitation_id::UUID;
  
  -- Si se acepta la invitación, agregar al usuario como participante del partido
  IF response = 'accepted' THEN
    -- Verificar que el partido no esté lleno
    SELECT COUNT(*) INTO v_participant_count 
    FROM match_participants 
    WHERE match_id = v_invitation.match_id;
    
    IF v_participant_count >= COALESCE(v_match.max_players, v_match.max_participants, 999) THEN
      -- Revertir la actualización de la invitación
      UPDATE match_invitations
      SET 
        status = 'pending',
        updated_at = NOW()
      WHERE id = invitation_id::UUID;
      
      RETURN json_build_object('success', FALSE, 'message', 'El partido está lleno');
    END IF;
    
    -- Agregar usuario como participante
    INSERT INTO match_participants (match_id, user_id)
    VALUES (v_invitation.match_id, v_current_user_id)
    ON CONFLICT (match_id, user_id) DO NOTHING;
    
    RETURN json_build_object(
      'success', TRUE, 
      'message', 'Invitación aceptada correctamente',
      'match_id', v_invitation.match_id
    );
  ELSE
    RETURN json_build_object(
      'success', TRUE, 
      'message', 'Invitación rechazada'
    );
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE, 
      'message', 'Error interno: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Dar permisos
GRANT EXECUTE ON FUNCTION create_match_invitation(BIGINT, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION respond_to_match_invitation(UUID, TEXT) TO authenticated;
