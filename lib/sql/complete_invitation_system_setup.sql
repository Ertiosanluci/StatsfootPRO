-- COMPLETE INVITATION SYSTEM SETUP FOR STATSFOOT PRO
-- Este script configura todo el sistema de invitaciones necesario

-- ====================================
-- 1. CREAR TABLA DE NOTIFICACIONES
-- ====================================

-- Crear tabla de notificaciones
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;

-- Crear políticas RLS para notificaciones
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can delete own notifications" ON public.notifications
    FOR DELETE USING (auth.uid() = user_id);

-- ====================================
-- 2. CREAR TABLA DE INVITACIONES A PARTIDOS
-- ====================================

-- Crear tabla de invitaciones a partidos
CREATE TABLE IF NOT EXISTS public.match_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    match_id INTEGER NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invited_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evitar invitaciones duplicadas
    UNIQUE(match_id, invited_id)
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_match_invitations_match_id ON public.match_invitations(match_id);
CREATE INDEX IF NOT EXISTS idx_match_invitations_inviter_id ON public.match_invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_match_invitations_invited_id ON public.match_invitations(invited_id);
CREATE INDEX IF NOT EXISTS idx_match_invitations_status ON public.match_invitations(status);
CREATE INDEX IF NOT EXISTS idx_match_invitations_created_at ON public.match_invitations(created_at);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.match_invitations ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view relevant match invitations" ON public.match_invitations;
DROP POLICY IF EXISTS "Users can update received invitations" ON public.match_invitations;
DROP POLICY IF EXISTS "System can insert match invitations" ON public.match_invitations;
DROP POLICY IF EXISTS "Users can delete sent invitations" ON public.match_invitations;

-- Crear políticas RLS para invitaciones
CREATE POLICY "Users can view relevant match invitations" ON public.match_invitations
    FOR SELECT USING (
        auth.uid() = inviter_id OR 
        auth.uid() = invited_id
    );

CREATE POLICY "Users can update received invitations" ON public.match_invitations
    FOR UPDATE USING (auth.uid() = invited_id);

CREATE POLICY "System can insert match invitations" ON public.match_invitations
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can delete sent invitations" ON public.match_invitations
    FOR DELETE USING (auth.uid() = inviter_id);

-- ====================================
-- 3. CREAR FUNCIONES AUXILIARES
-- ====================================

-- Función para actualizar el campo updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ====================================
-- 4. CREAR TRIGGERS
-- ====================================

-- Eliminar triggers existentes si existen
DROP TRIGGER IF EXISTS update_notifications_updated_at ON public.notifications;
DROP TRIGGER IF EXISTS update_match_invitations_updated_at ON public.match_invitations;

-- Crear triggers para actualizar updated_at
CREATE TRIGGER update_notifications_updated_at 
    BEFORE UPDATE ON public.notifications 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_match_invitations_updated_at 
    BEFORE UPDATE ON public.match_invitations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================
-- 5. FUNCIÓN PRINCIPAL: CREAR INVITACIÓN A PARTIDO (CORREGIDA)
-- ====================================

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

-- ====================================
-- 6. COMENTARIOS Y DOCUMENTACIÓN
-- ====================================

-- Comentarios para la tabla de notificaciones
COMMENT ON TABLE public.notifications IS 'Tabla para almacenar notificaciones de usuarios';
COMMENT ON COLUMN public.notifications.id IS 'Identificador único de la notificación';
COMMENT ON COLUMN public.notifications.user_id IS 'ID del usuario que recibe la notificación';
COMMENT ON COLUMN public.notifications.type IS 'Tipo de notificación (match_invitation, friend_request, etc.)';
COMMENT ON COLUMN public.notifications.title IS 'Título de la notificación';
COMMENT ON COLUMN public.notifications.message IS 'Mensaje de la notificación';
COMMENT ON COLUMN public.notifications.data IS 'Datos adicionales en formato JSON';
COMMENT ON COLUMN public.notifications.read IS 'Indica si la notificación ha sido leída';

-- Comentarios para la tabla de invitaciones
COMMENT ON TABLE public.match_invitations IS 'Tabla para almacenar invitaciones a partidos';
COMMENT ON COLUMN public.match_invitations.id IS 'Identificador único de la invitación';
COMMENT ON COLUMN public.match_invitations.match_id IS 'ID del partido al que se invita';
COMMENT ON COLUMN public.match_invitations.inviter_id IS 'ID del usuario que envía la invitación';
COMMENT ON COLUMN public.match_invitations.invited_id IS 'ID del usuario invitado';
COMMENT ON COLUMN public.match_invitations.status IS 'Estado de la invitación (pending, accepted, declined)';

-- ====================================
-- VERIFICACIÓN DE INSTALACIÓN
-- ====================================

-- Verificar que las tablas se crearon correctamente
DO $$
BEGIN
  -- Verificar tabla notifications
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications') THEN
    RAISE NOTICE 'Tabla notifications creada correctamente';
  ELSE
    RAISE EXCEPTION 'Error: Tabla notifications no fue creada';
  END IF;
  
  -- Verificar tabla match_invitations
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'match_invitations') THEN
    RAISE NOTICE 'Tabla match_invitations creada correctamente';
  ELSE
    RAISE EXCEPTION 'Error: Tabla match_invitations no fue creada';
  END IF;
  
  -- Verificar función create_match_invitation
  IF EXISTS (SELECT FROM information_schema.routines WHERE routine_name = 'create_match_invitation') THEN
    RAISE NOTICE 'Función create_match_invitation creada correctamente';
  ELSE
    RAISE EXCEPTION 'Error: Función create_match_invitation no fue creada';
  END IF;
  
  RAISE NOTICE 'SISTEMA DE INVITACIONES INSTALADO CORRECTAMENTE';
END
$$;
