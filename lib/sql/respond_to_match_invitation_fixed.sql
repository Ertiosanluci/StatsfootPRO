-- Fixed function to respond to match invitations
-- This function properly handles UUID conversion and provides better error messages

CREATE OR REPLACE FUNCTION respond_to_match_invitation(
  invitation_id TEXT,  -- Accept as TEXT to handle conversion
  response TEXT
) RETURNS JSON AS $$
DECLARE
  v_invitation RECORD;
  v_match RECORD;
  v_current_user_id UUID;
  v_invitation_uuid UUID;
BEGIN
  -- Get current user ID
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RETURN json_build_object('success', FALSE, 'message', 'Usuario no autenticado');
  END IF;
  
  -- Convert invitation_id to UUID safely
  BEGIN
    v_invitation_uuid := invitation_id::UUID;
  EXCEPTION
    WHEN invalid_text_representation THEN
      RETURN json_build_object('success', FALSE, 'message', 'ID de invitación inválido');
  END;
  
  -- Verificar que la invitación existe y es para el usuario correcto
  SELECT * INTO v_invitation 
  FROM match_invitations 
  WHERE id = v_invitation_uuid AND invited_id = v_current_user_id AND status = 'pending';
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'Invitación no encontrada o ya respondida');
  END IF;
  
  -- Validar respuesta
  IF response NOT IN ('accepted', 'declined') THEN
    RETURN json_build_object('success', FALSE, 'message', 'Respuesta inválida. Use "accepted" o "declined"');
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
  WHERE id = v_invitation_uuid;
  
  -- Si se acepta la invitación, agregar al usuario como participante del partido
  IF response = 'accepted' THEN
    -- Verificar que el partido no esté lleno
    IF (SELECT COUNT(*) FROM match_participants WHERE match_id = v_invitation.match_id) >= v_match.max_players THEN
      -- Revertir la actualización de la invitación
      UPDATE match_invitations
      SET 
        status = 'pending',
        updated_at = NOW()
      WHERE id = v_invitation_uuid;
      
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
