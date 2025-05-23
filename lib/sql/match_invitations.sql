-- Tabla para almacenar las invitaciones a partidos
CREATE TABLE IF NOT EXISTS match_invitations (
  id BIGSERIAL PRIMARY KEY,
  match_id BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invited_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, accepted, rejected
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(match_id, invited_id)
);

-- Índices para optimizar consultas comunes
CREATE INDEX IF NOT EXISTS idx_match_invitations_match_id ON match_invitations (match_id);
CREATE INDEX IF NOT EXISTS idx_match_invitations_inviter_id ON match_invitations (inviter_id);
CREATE INDEX IF NOT EXISTS idx_match_invitations_invited_id ON match_invitations (invited_id);
CREATE INDEX IF NOT EXISTS idx_match_invitations_status ON match_invitations (status);

-- Función para crear una invitación a un partido
CREATE OR REPLACE FUNCTION create_match_invitation(
  p_match_id BIGINT,
  p_inviter_id UUID,
  p_invited_id UUID
) RETURNS JSON AS $$
DECLARE
  v_match RECORD;
  v_existing_invitation RECORD;
  v_existing_participant RECORD;
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
  
  IF NOT FOUND AND v_match.creator_id != p_inviter_id THEN
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
  
  -- Crear notificación para el invitado
  INSERT INTO notifications (
    user_id, 
    title, 
    message, 
    match_id, 
    action_type, 
    link
  )
  VALUES (
    p_invited_id,
    'Invitación a partido',
    (SELECT username FROM profiles WHERE id = p_inviter_id) || ' te ha invitado a un partido',
    p_match_id,
    'match_invitation',
    '/match/' || p_match_id
  );
  
  RETURN json_build_object('success', TRUE, 'message', 'Invitación enviada correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para responder a una invitación a un partido
CREATE OR REPLACE FUNCTION respond_to_match_invitation(
  p_invitation_id BIGINT,
  p_user_id UUID,
  p_accept BOOLEAN
) RETURNS JSON AS $$
DECLARE
  v_invitation RECORD;
  v_match RECORD;
  v_result JSON;
BEGIN
  -- Verificar que la invitación existe y es para el usuario correcto
  SELECT * INTO v_invitation 
  FROM match_invitations 
  WHERE id = p_invitation_id AND invited_id = p_user_id AND status = 'pending';
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'message', 'Invitación no encontrada o ya respondida');
  END IF;
  
  -- Obtener información del partido
  SELECT * INTO v_match FROM matches WHERE id = v_invitation.match_id;
  
  -- Actualizar el estado de la invitación
  UPDATE match_invitations
  SET 
    status = CASE WHEN p_accept THEN 'accepted' ELSE 'rejected' END,
    updated_at = NOW()
  WHERE id = p_invitation_id;
  
  -- Si se acepta la invitación, añadir al usuario como participante
  IF p_accept THEN
    -- Verificar que el partido aún tiene plazas disponibles
    IF v_match.max_participants IS NOT NULL AND 
       (SELECT COUNT(*) FROM match_participants WHERE match_id = v_match.id) >= v_match.max_participants THEN
      
      -- Revertir el estado de la invitación
      UPDATE match_invitations
      SET status = 'pending', updated_at = NOW()
      WHERE id = p_invitation_id;
      
      RETURN json_build_object('success', FALSE, 'message', 'El partido está completo');
    END IF;
    
    -- Añadir al usuario como participante
    INSERT INTO match_participants (match_id, user_id)
    VALUES (v_invitation.match_id, p_user_id);
    
    -- Crear notificación para el invitador
    INSERT INTO notifications (
      user_id, 
      title, 
      message, 
      match_id, 
      action_type
    )
    VALUES (
      v_invitation.inviter_id,
      'Invitación aceptada',
      (SELECT username FROM profiles WHERE id = p_user_id) || ' ha aceptado tu invitación al partido',
      v_invitation.match_id,
      'invitation_accepted'
    );
    
    RETURN json_build_object('success', TRUE, 'message', 'Has aceptado la invitación y te has unido al partido');
  ELSE
    -- Crear notificación para el invitador
    INSERT INTO notifications (
      user_id, 
      title, 
      message, 
      match_id, 
      action_type
    )
    VALUES (
      v_invitation.inviter_id,
      'Invitación rechazada',
      (SELECT username FROM profiles WHERE id = p_user_id) || ' ha rechazado tu invitación al partido',
      v_invitation.match_id,
      'invitation_rejected'
    );
    
    RETURN json_build_object('success', TRUE, 'message', 'Has rechazado la invitación');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener las invitaciones pendientes de un usuario
CREATE OR REPLACE FUNCTION get_pending_match_invitations(p_user_id UUID)
RETURNS TABLE (
  invitation_id BIGINT,
  match_id BIGINT,
  match_name TEXT,
  match_date TIMESTAMPTZ,
  match_location TEXT,
  inviter_id UUID,
  inviter_name TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    mi.id AS invitation_id,
    m.id AS match_id,
    m.nombre AS match_name,
    m.fecha AS match_date,
    m.ubicacion AS match_location,
    mi.inviter_id,
    p.username AS inviter_name,
    mi.created_at
  FROM match_invitations mi
  JOIN matches m ON mi.match_id = m.id
  JOIN profiles p ON mi.inviter_id = p.id
  WHERE mi.invited_id = p_user_id AND mi.status = 'pending'
  ORDER BY mi.created_at DESC;
END;
$$ LANGUAGE plpgsql;
