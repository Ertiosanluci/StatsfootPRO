-- Tabla para almacenar el top de jugadores MVP
CREATE TABLE IF NOT EXISTS mvp_top_players (
  id BIGSERIAL PRIMARY KEY,
  match_id BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  votes BIGINT NOT NULL DEFAULT 0,
  rank INT NOT NULL,
  team TEXT NOT NULL CHECK (team IN ('claro', 'oscuro')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (match_id, player_id)
);
