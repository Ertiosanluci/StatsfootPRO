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

-- Política para que los usuarios puedan ver invitaciones donde son invitados o invitadores
CREATE POLICY "Users can view relevant match invitations" ON public.match_invitations
    FOR SELECT USING (
        auth.uid() = inviter_id OR 
        auth.uid() = invited_id
    );

-- Política para que los usuarios puedan actualizar invitaciones donde son invitados
CREATE POLICY "Users can update received invitations" ON public.match_invitations
    FOR UPDATE USING (auth.uid() = invited_id);

-- Política para que el sistema pueda insertar invitaciones
CREATE POLICY "System can insert match invitations" ON public.match_invitations
    FOR INSERT WITH CHECK (true);

-- Política para que los usuarios puedan eliminar invitaciones que enviaron
CREATE POLICY "Users can delete sent invitations" ON public.match_invitations
    FOR DELETE USING (auth.uid() = inviter_id);

-- Trigger para actualizar updated_at cuando se modifica una invitación
CREATE TRIGGER update_match_invitations_updated_at 
    BEFORE UPDATE ON public.match_invitations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para documentar la tabla
COMMENT ON TABLE public.match_invitations IS 'Tabla para almacenar invitaciones a partidos';
COMMENT ON COLUMN public.match_invitations.id IS 'Identificador único de la invitación';
COMMENT ON COLUMN public.match_invitations.match_id IS 'ID del partido al que se invita';
COMMENT ON COLUMN public.match_invitations.inviter_id IS 'ID del usuario que envía la invitación';
COMMENT ON COLUMN public.match_invitations.invited_id IS 'ID del usuario invitado';
COMMENT ON COLUMN public.match_invitations.status IS 'Estado de la invitación (pending, accepted, declined)';
COMMENT ON COLUMN public.match_invitations.created_at IS 'Fecha y hora de creación';
COMMENT ON COLUMN public.match_invitations.updated_at IS 'Fecha y hora de última actualización';
