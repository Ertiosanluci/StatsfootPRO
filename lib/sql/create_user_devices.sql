-- Crear la tabla user_devices si no existe
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    onesignal_player_id TEXT NOT NULL,
    device_type TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_onesignal_player_id ON public.user_devices(onesignal_player_id);

-- Crear políticas de seguridad RLS para la tabla user_devices
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Política para permitir a los usuarios ver solo sus propios dispositivos
CREATE POLICY user_devices_select_policy ON public.user_devices
    FOR SELECT USING (auth.uid() = user_id);

-- Política para permitir a los usuarios insertar solo sus propios dispositivos
CREATE POLICY user_devices_insert_policy ON public.user_devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para permitir a los usuarios actualizar solo sus propios dispositivos
CREATE POLICY user_devices_update_policy ON public.user_devices
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para permitir a los usuarios eliminar solo sus propios dispositivos
CREATE POLICY user_devices_delete_policy ON public.user_devices
    FOR DELETE USING (auth.uid() = user_id);

-- Consulta para migrar datos de la tabla antigua a la nueva
-- Esta consulta se puede ejecutar una sola vez para migrar todos los datos existentes
INSERT INTO public.user_devices (user_id, onesignal_player_id, device_type, created_at, last_used_at)
SELECT 
    user_id, 
    player_id AS onesignal_player_id, 
    'mobile' AS device_type, 
    created_at, 
    updated_at AS last_used_at
FROM 
    public.user_push_tokens
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM public.user_devices 
        WHERE user_devices.user_id = user_push_tokens.user_id 
        AND user_devices.onesignal_player_id = user_push_tokens.player_id
    );

-- Comentario: Esta consulta inserta registros de la tabla user_push_tokens en user_devices
-- solo si no existe ya un registro con el mismo user_id y player_id en la tabla user_devices.
