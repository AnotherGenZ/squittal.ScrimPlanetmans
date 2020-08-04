USE [PlanetmansDbContext];

GO

CREATE OR ALTER VIEW View_ScrimMatchReportInfantryTeamStats AS

  SELECT match_players.ScrimMatchId,
         match_players.TeamOrdinal,
         COALESCE(killStats.Points, 0) Points,
         COALESCE(killStats.NetScore, 0) NetScore,
         COALESCE(killStats.Kills, 0) Kills,
         COALESCE(killStats.HeadshotKills, 0) HeadshotKills,
         COALESCE(killStats.Deaths, 0) Deaths,
         COALESCE(killStats.HeadshotEnemyDeaths, 0) HeadshotEnemyDeaths,
         COALESCE(killStats.TeamKills, 0) TeamKills,
         COALESCE(killStats.Suicides, 0) Suicides,
         COALESCE(killStats.ScoredDeaths, 0) ScoredDeaths,
         COALESCE(killStats.ZeroPointDeaths, 0) ZeroPointDeaths,
         COALESCE(killStats.TeamKillDeaths, 0) TeamKillDeaths,
         COALESCE(damageStats.DamageAssists, 0) DamageAssists,
         COALESCE(damageStats.DamageTeamAssists, 0) DamageTeamAssists,
         COALESCE(killStats.DamageAssistedKills, 0) DamageAssistedKills,
         COALESCE(killStats.DamageAssistedDeaths, 0) DamageAssistedDeaths,
         COALESCE(killStats.DamageAssistedEnemyDeaths, 0) DamageAssistedEnemyDeaths,
         COALESCE(killStats.UnassistedEnemyDeaths, 0) UnassistedEnemyDeaths,
         COALESCE(killStats.KillsAsHeavyAssault, 0) KillsAsHeavyAssault,
         COALESCE(killStats.KillsAsInfiltrator, 0) KillsAsInfiltrator,
         COALESCE(killStats.KillsAsLightAssault, 0) KillsAsLightAssault,
         COALESCE(killStats.KillsAsMedic, 0) KillsAsMedic,
         COALESCE(killStats.KillsAsEngineer, 0) KillsAsEngineer,
         COALESCE(killStats.KillsAsMax, 0) KillsAsMax,
         COALESCE(killStats.DeathsAsHeavyAssault, 0) DeathsAsHeavyAssault,
         COALESCE(killStats.DeathsAsInfiltrator, 0) DeathsAsInfiltrator,
         COALESCE(killStats.DeathsAsLightAssault, 0) DeathsAsLightAssault,
         COALESCE(killStats.DeathsAsMedic, 0) DeathsAsMedic,
         COALESCE(killStats.DeathsAsEngineer, 0) DeathsAsEngineer,
         COALESCE(killStats.DeathsAsMax, 0) DeathsAsMax,
         COALESCE(damageStats.DamageAssistsAsHeavyAssault, 0) DamageAssistsAsHeavyAssault,
         COALESCE(damageStats.DamageAssistsAsInfiltrator, 0) DamageAssistsAsInfiltrator,
         COALESCE(damageStats.DamageAssistsAsLightAssault, 0) DamageAssistsAsLightAssault,
         COALESCE(damageStats.DamageAssistsAsMedic, 0) DamageAssistsAsMedic,
         COALESCE(damageStats.DamageAssistsAsEngineer, 0) DamageAssistsAsEngineer,
         COALESCE(damageStats.DamageAssistsAsMax, 0) DamageAssistsAsMax
        FROM ( SELECT match_players.ScrimMatchId,
					            match_players.TeamOrdinal
			           FROM ScrimMatchParticipatingPlayer match_players
                 GROUP BY match_players.ScrimMatchId, match_players.TeamOrdinal ) match_players
          INNER JOIN ( SELECT match_players.ScrimMatchId,
						      match_players.TeamOrdinal,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal THEN kills.Points ELSE 0 END ) Points,
                              SUM( CASE WHEN DeathType = 0 -- Kill
                                          THEN CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal THEN kills.Points ELSE (kills.Points * -1) END
                                        WHEN DeathType = 1 -- Teamkill
                                          THEN CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal THEN kills.Points ELSE 0 END
                                        WHEN DeathType = 2 -- Suicide
                                          THEN CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal THEN kills.Points ELSE 0 END
                                        ELSE 0 END ) NetScore,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 THEN 1 ELSE 0 END ) Kills,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal THEN 1 ELSE 0 END ) Deaths,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 1 THEN 1 ELSE 0 END ) TeamKills,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND DeathType = 2 THEN 1 ELSE 0 END ) Suicides,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND kills.IsHeadshot = 1 THEN 1 ELSE 0 END ) HeadshotKills,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND DeathType = 0 AND kills.IsHeadshot = 1 THEN 1 ELSE 0 END ) HeadshotEnemyDeaths,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND DeathType = 0 AND kills.Points > 0 THEN 1 ELSE 0 END ) ScoredDeaths,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND DeathType = 0 AND kills.Points = 0 THEN 1 ELSE 0 END ) ZeroPointDeaths,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND DeathType = 1 THEN 1 ELSE 0 END ) TeamKillDeaths,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND kills.AttackerLoadoutId IN ( 7, 15, 22) THEN 1 ELSE 0 END ) KillsAsHeavyAssault,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND kills.AttackerLoadoutId IN ( 2, 10, 17) THEN 1 ELSE 0 END ) KillsAsInfiltrator,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND kills.AttackerLoadoutId IN ( 4, 12, 19) THEN 1 ELSE 0 END ) KillsAsLightAssault,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND kills.AttackerLoadoutId IN ( 5, 13, 20) THEN 1 ELSE 0 END ) KillsAsMedic,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND kills.AttackerLoadoutId IN ( 6, 14, 21) THEN 1 ELSE 0 END ) KillsAsEngineer,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND kills.AttackerLoadoutId IN ( 8, 16, 23) THEN 1 ELSE 0 END ) KillsAsMax,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND kills.AttackerLoadoutId IN ( 7, 15, 22) THEN 1 ELSE 0 END ) DeathsAsHeavyAssault,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND kills.AttackerLoadoutId IN ( 2, 10, 17) THEN 1 ELSE 0 END ) DeathsAsInfiltrator,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND kills.AttackerLoadoutId IN ( 4, 12, 19) THEN 1 ELSE 0 END ) DeathsAsLightAssault,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND kills.AttackerLoadoutId IN ( 5, 13, 20) THEN 1 ELSE 0 END ) DeathsAsMedic,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND kills.AttackerLoadoutId IN ( 6, 14, 21) THEN 1 ELSE 0 END ) DeathsAsEngineer,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND kills.AttackerLoadoutId IN ( 8, 16, 23) THEN 1 ELSE 0 END ) DeathsAsMax,
                              SUM( CASE WHEN TeamOrdinal = kills.AttackerTeamOrdinal AND DeathType = 0 AND damages.ActionType = 304 THEN 1 ELSE 0 END ) DamageAssistedKills,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND TeamOrdinal = damages.VictimTeamOrdinal THEN 1 ELSE 0 END ) DamageAssistedDeaths,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND DeathType = 0 AND TeamOrdinal = damages.VictimTeamOrdinal THEN 1 ELSE 0 END ) DamageAssistedEnemyDeaths,
                              SUM( CASE WHEN TeamOrdinal = kills.VictimTeamOrdinal AND DeathType = 0 AND damages.ActionType IS NULL THEN 1 ELSE 0 END ) UnassistedEnemyDeaths
                          FROM ScrimMatchParticipatingPlayer match_players
                            INNER JOIN ScrimDeath kills
                              ON match_players.ScrimMatchId = kills.ScrimMatchId
                                AND ( kills.AttackerCharacterId = match_players.CharacterId
                                      OR kills.VictimCharacterId = match_players.CharacterId )
                            LEFT OUTER JOIN ScrimDamageAssist damages
                              ON kills.ScrimMatchId = damages.ScrimMatchId
                                AND kills.Timestamp = damages.Timestamp
                          GROUP BY match_players.ScrimMatchId, match_players.TeamOrdinal
                      ) killStats
            ON killStats.ScrimMatchId = match_players.ScrimMatchId
                AND killStats.TeamOrdinal = match_players.TeamOrdinal
          LEFT OUTER JOIN ( SELECT match_players.ScrimMatchId,
                                   match_players.TeamOrdinal,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.ActionType = 304 THEN 1 ELSE 0 END ) DamageAssists,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.ActionType = 310 THEN 1 ELSE 0 END ) DamageTeamAssists,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.AttackerLoadoutId IN ( 7, 15, 22) THEN 1 ELSE 0 END ) DamageAssistsAsHeavyAssault,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.AttackerLoadoutId IN ( 2, 10, 17) THEN 1 ELSE 0 END ) DamageAssistsAsInfiltrator,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.AttackerLoadoutId IN ( 4, 12, 19) THEN 1 ELSE 0 END ) DamageAssistsAsLightAssault,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.AttackerLoadoutId IN ( 5, 13, 20) THEN 1 ELSE 0 END ) DamageAssistsAsMedic,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.AttackerLoadoutId IN ( 6, 14, 21) THEN 1 ELSE 0 END ) DamageAssistsAsEngineer,
                                   SUM( CASE WHEN CharacterId = damages.AttackerCharacterId AND damages.AttackerLoadoutId IN ( 8, 16, 23) THEN 1 ELSE 0 END ) DamageAssistsAsMax
                              FROM ScrimMatchParticipatingPlayer match_players
                                INNER JOIN ScrimDamageAssist damages
                                  ON match_players.ScrimMatchId = damages.ScrimMatchId
                                     AND  match_players.CharacterId = damages.AttackerCharacterId
                              GROUP BY match_players.ScrimMatchId, match_players.TeamOrdinal
                          ) damageStats
              ON damageStats.ScrimMatchId = match_players.ScrimMatchId
                AND damageStats.TeamOrdinal = match_players.TeamOrdinal