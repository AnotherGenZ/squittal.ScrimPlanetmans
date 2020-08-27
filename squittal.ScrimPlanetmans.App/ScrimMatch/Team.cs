﻿using squittal.ScrimPlanetmans.ScrimMatch.Models;
using squittal.ScrimPlanetmans.Models.Planetside;
using System.Collections.Generic;
using System.Linq;
using squittal.ScrimPlanetmans.Data.Models;

using System.Collections.Concurrent;

namespace squittal.ScrimPlanetmans.ScrimMatch
{
    public class Team
    {
        public string Alias { get; set; } //first seed team, or a custom value
        public string NameInternal { get; set; } //team1 or team2
        public int TeamOrdinal { get; private set; } //1 or 2
        public int? FactionId { get; set; }

        public ScrimEventAggregate EventAggregate
        {
            get
            {
                return EventAggregateTracker.TotalStats;
            }
        }

        public ScrimEventAggregateRoundTracker EventAggregateTracker { get; set; } = new ScrimEventAggregateRoundTracker();

        public List<Player> Players { get; private set; } = new List<Player>();

        public List<Player> ParticipatingPlayers { get; set; } = new List<Player>();

        private ConcurrentDictionary<string, Player> ParticipatingPlayersMap { get; set; } = new ConcurrentDictionary<string, Player>();

        public List<Outfit> Outfits { get; private set; } = new List<Outfit>();

        public List<ConstructedTeamMatchInfo> ConstructedTeamsMatchInfo { get; set; } = new List<ConstructedTeamMatchInfo>();
        private ConcurrentDictionary<string, ConstructedTeamMatchInfo> ConstructedTeamsMap { get; set; } = new ConcurrentDictionary<string, ConstructedTeamMatchInfo>();

        private ConcurrentDictionary<string, Player> PlayersMap { get; set; } = new ConcurrentDictionary<string, Player>();

        private ConcurrentDictionary<string, Outfit> OutfitsMap { get; set; } = new ConcurrentDictionary<string, Outfit>();

        public bool HasCustomAlias { get; private set; } = false;


        public Team(string alias, string nameInternal, int teamOrdinal)
        {
            TrySetAlias(alias, false);
            NameInternal = nameInternal;
            TeamOrdinal = teamOrdinal;
        }

        public bool TrySetAlias(string alias, bool isCustomAlias = false)
        {
            // Don't overwrite a custom display alias unless the new one is also custom
            if (!HasCustomAlias || isCustomAlias)
            {
                Alias = alias;
                HasCustomAlias = isCustomAlias;
                return true;
            }
            else
            {
                return false;
            }
        }

        public void ResetAlias(string alias)
        {
            Alias = alias;
            HasCustomAlias = false;
        }

        public bool ContainsPlayer(string characterId)
        {
            return PlayersMap.ContainsKey(characterId);
        }

        public bool ContainsOutfit(string alias)
        {
            return OutfitsMap.ContainsKey(alias.ToLower());
        }

        public bool ContainsConstructedTeamFaction(int constructedTeamId, int factionId)
        {
            return ConstructedTeamsMap.ContainsKey(GetConstructedTeamFactionKey(constructedTeamId, factionId));
        }

        public IEnumerable<string> GetAllPlayerIds()
        {
            return PlayersMap.Keys.ToList();
        }

        public bool TryGetPlayerFromId(string characterId, out Player player)
        {
            return PlayersMap.TryGetValue(characterId, out player);
        }

        public bool TryAddPlayer(Player player)
        {
            if(!PlayersMap.TryAdd(player.Id, player))
            {
                return false;
            }

            Players.Add(player);

            return true;
        }

        public bool TryRemovePlayer(string characterId)
        {
            if (!PlayersMap.TryRemove(characterId, out var player))
            {
                return false;
            }

            Players.Remove(player);

            ParticipatingPlayers.Remove(player);

            ParticipatingPlayersMap.TryRemove(player.Id, out Player removedPlayer);

            RemovePlayerObjectiveTicksFromTeamAggregate(player); // TODO: remove this when Objective Ticks are saved to DB

            return true;
        }

        private void RemovePlayerObjectiveTicksFromTeamAggregate(Player player)
        {
            var teamUpdates = new ScrimEventAggregateRoundTracker();

            var playerTracker = player.EventAggregateTracker;

            var playerMaxRound = playerTracker.HighestRound;
            var teamMaxRound = EventAggregateTracker.HighestRound;

            var maxRound = playerMaxRound >= teamMaxRound ? playerMaxRound : teamMaxRound;

            for (var round = 1; round <= maxRound; round++)
            {
                if (playerTracker.TryGetTargetRoundStats(round, out var roundStats))
                {
                    var tempStats = new ScrimEventAggregate();

                    tempStats.ObjectiveCaptureTicks += roundStats.ObjectiveCaptureTicks;
                    tempStats.ObjectiveDefenseTicks += roundStats.ObjectiveDefenseTicks;

                    teamUpdates.AddToCurrent(tempStats);

                    teamUpdates.SaveRoundToHistory(round);
                }
            }

            teamUpdates.RoundStats.ObjectiveCaptureTicks += playerTracker.RoundStats.ObjectiveCaptureTicks;
            teamUpdates.RoundStats.ObjectiveDefenseTicks += playerTracker.RoundStats.ObjectiveDefenseTicks;

            EventAggregateTracker.SubtractFromHistory(teamUpdates);
        }

        public bool TryAddOutfit(Outfit outfit)
        {
            if (!OutfitsMap.TryAdd(outfit.AliasLower, outfit))
            {
                return false;
            }

            Outfits.Add(outfit);
            
            return true;
        }

        public bool TryRemoveOutfit(string aliasLower)
        {
            if (!OutfitsMap.TryRemove(aliasLower, out var outfitOut))
            {
                return false;
            }

            Outfits.RemoveAll(o => o.AliasLower == aliasLower);

            return true;
        }

        public bool TryAddConstructedTeamFaction(ConstructedTeamMatchInfo matchInfo)
        {
            var constructedTeam = matchInfo.ConstructedTeam;
            var factionId = matchInfo.ActiveFactionId;

            if (!ConstructedTeamsMap.TryAdd(GetConstructedTeamFactionKey(constructedTeam.Id, factionId), matchInfo))
            {
                return false;
            }

            ConstructedTeamsMatchInfo.Add(matchInfo);

            return true;
        }

        public bool TryRemoveConstructedTeamFaction(int constructedTeamId, int factionId)
        {
            if (!ConstructedTeamsMap.TryRemove(GetConstructedTeamFactionKey(constructedTeamId, factionId), out var teamOut))
            {
                return false;
            }

            ConstructedTeamsMatchInfo.RemoveAll(ctmi => ctmi.ConstructedTeam.Id == constructedTeamId && ctmi.ActiveFactionId == factionId);

            return true;
        }

        public void ResetMatchData()
        {
            ClearEventAggregateHistory();

            ParticipatingPlayers.Clear();
            ParticipatingPlayersMap.Clear();
        }

        public bool UpdateParticipatingPlayer(Player player)
        {
            var playerId = player.Id;

            if (player.IsParticipating)
            {
                return ParticipatingPlayersMap.TryAdd(playerId, player);
            }
            else
            {
                return ParticipatingPlayersMap.TryRemove(playerId, out Player removedPlayer);
            }
        }

        public IEnumerable<Player> GetParticipatingPlayers()
        {
            return ParticipatingPlayersMap.Values.ToList();
        }

        public IEnumerable<Player> GetOutfitPlayers(string aliasLower)
        {
            lock(Players)
            {
                return Players.Where(p => p.OutfitAliasLower == aliasLower && !p.IsOutfitless && !p.IsFromConstructedTeam).ToList();
            }
        }

        public IEnumerable<Player> GetNonOutfitPlayers()
        {
            lock (Players)
            {
                return Players.Where(p => p.IsOutfitless && !p.IsFromConstructedTeam).ToList();
            }
        }

        public IEnumerable<Player> GetConstructedTeamFactionPlayers(int constructedTeamId, int factionId)
        {
            lock (Players)
            {
                return Players
                        .Where(p => p.IsFromConstructedTeam && p.ConstructedTeamId == constructedTeamId && p.FactionId == factionId)
                        .ToList();
            }
        }

        public void AddStatsUpdate(ScrimEventAggregate update)
        {
            EventAggregateTracker.AddToCurrent(update);
        }

        public void SubtractStatsUpdate(ScrimEventAggregate update)
        {
            EventAggregateTracker.SubtractFromCurrent(update);
        }

        public void ClearEventAggregateHistory()
        {
            EventAggregateTracker = new ScrimEventAggregateRoundTracker();
        }

        private string GetConstructedTeamFactionKey(int constructedTeamId, int factionId)
        {
            return $"{constructedTeamId}^{factionId}";
        }
    }
}
