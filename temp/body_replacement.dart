// Archivo temporal para reemplazar el body del MatchDetailsScreen
body: _isLoading 
  ? Center(child: CircularProgressIndicator(color: Colors.blue))
  : Stack(
      children: [
        // Contenido principal
        Column(
          children: [
            // Marcador
            ScoreboardWidget(
              golesEquipoClaro: golesEquipoClaro,
              golesEquipoOscuro: golesEquipoOscuro,
              isPartidoFinalizado: isPartidoFinalizado,
            ),
            
            // Mostrar resultados de MVP si el partido está finalizado y hay MVPs
            if (isPartidoFinalizado && (_mvpTeamClaro != null || _mvpTeamOscuro != null))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: MVPResultsWidget(
                  playerDataClaro: _getMVPPlayerData(_mvpTeamClaro, _teamClaro),
                  playerDataOscuro: _getMVPPlayerData(_mvpTeamOscuro, _teamOscuro),
                ),
              ),
            
            // Campo y jugadores
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade300],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: TabBarView(
                  controller: _tabController,
                  physics: BouncingScrollPhysics(),
                  children: [
                    // Equipo Claro
                    TeamFormation(
                      players: _teamClaro,
                      positions: _teamClaroPositions,
                      isTeamClaro: true,
                      matchData: _matchData,
                      onPlayerPositionChanged: isReadOnly ? null : (playerId, position) => 
                          _updatePlayerPosition(playerId, position, true),
                      onSavePositions: isReadOnly ? null : () => _saveAllPositionsToDatabase(true),
                      mvpId: _mvpTeamClaro,
                      isReadOnly: isReadOnly,
                      onPlayerTap: isReadOnly || isPartidoFinalizado ? null : _showPlayerStatsDialog,
                    ),
                    
                    // Equipo Oscuro
                    TeamFormation(
                      players: _teamOscuro,
                      positions: _teamOscuroPositions,
                      isTeamClaro: false,
                      matchData: _matchData,
                      onPlayerPositionChanged: isReadOnly ? null : (playerId, position) => 
                          _updatePlayerPosition(playerId, position, false),
                      onSavePositions: isReadOnly ? null : () => _saveAllPositionsToDatabase(false),
                      mvpId: _mvpTeamOscuro,
                      isReadOnly: isReadOnly,
                      onPlayerTap: isReadOnly || isPartidoFinalizado ? null : _showPlayerStatsDialog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Widget flotante de votación (solo si hay votación activa)
        if (_activeVoting != null)
          FloatingVotingTimerWidget(
            votingData: _activeVoting!,
            onVoteButtonPressed: _showMVPVotingDialog,
          ),
      ],
    ),
