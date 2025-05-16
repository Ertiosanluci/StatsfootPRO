-- Tabla para almacenar los votos de MVP
CREATE TABLE IF NOT EXISTS mvp_votes (
  id BIGSERIAL PRIMARY KEY,
  match_id BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  voted_player_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  team TEXT NOT NULL CHECK (team IN ('claro', 'oscuro')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (match_id, voter_id, team)
);

-- Tabla para almacenar el estado de la votación
CREATE TABLE IF NOT EXISTS mvp_voting_status (
  match_id BIGINT PRIMARY KEY REFERENCES matches(id) ON DELETE CASCADE,
  voting_started_at TIMESTAMPTZ DEFAULT NOW(),
  voting_ends_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed')),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);
