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

-- Política para que los usuarios solo puedan ver sus propias notificaciones
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Política para que los usuarios puedan actualizar sus propias notificaciones (marcar como leídas)
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para que el sistema pueda insertar notificaciones para cualquier usuario
-- (esto permitirá que las funciones RPC creen notificaciones)
CREATE POLICY "System can insert notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- Política para que los usuarios puedan eliminar sus propias notificaciones
CREATE POLICY "Users can delete own notifications" ON public.notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Función para actualizar el campo updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at cuando se modifica una notificación
CREATE TRIGGER update_notifications_updated_at 
    BEFORE UPDATE ON public.notifications 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para documentar la tabla
COMMENT ON TABLE public.notifications IS 'Tabla para almacenar notificaciones de usuarios';
COMMENT ON COLUMN public.notifications.id IS 'Identificador único de la notificación';
COMMENT ON COLUMN public.notifications.user_id IS 'ID del usuario que recibe la notificación';
COMMENT ON COLUMN public.notifications.type IS 'Tipo de notificación (match_invitation, friend_request, etc.)';
COMMENT ON COLUMN public.notifications.title IS 'Título de la notificación';
COMMENT ON COLUMN public.notifications.message IS 'Mensaje de la notificación';
COMMENT ON COLUMN public.notifications.data IS 'Datos adicionales en formato JSON';
COMMENT ON COLUMN public.notifications.read IS 'Indica si la notificación ha sido leída';
COMMENT ON COLUMN public.notifications.created_at IS 'Fecha y hora de creación';
COMMENT ON COLUMN public.notifications.updated_at IS 'Fecha y hora de última actualización';
