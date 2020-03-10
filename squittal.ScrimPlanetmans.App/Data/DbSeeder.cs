﻿using squittal.ScrimPlanetmans.ScrimMatch;
using squittal.ScrimPlanetmans.Services.Planetside;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace squittal.ScrimPlanetmans.Data
{
    public class DbSeeder : IDbSeeder
    {
        private readonly IWorldService _worldService;
        private readonly IFactionService _factionService;
        private readonly IItemService _itemService;
        private readonly IZoneService _zoneService;
        private readonly IProfileService _profileService;
        private readonly IScrimRulesetManager _rulesetManager;
        private readonly IFacilityService _facilityService;

        public DbSeeder(
            IWorldService worldService,
            IFactionService factionService,
            IItemService itemService,
            IZoneService zoneService,
            IProfileService profileService,
            IScrimRulesetManager rulesetManager,
            IFacilityService facilityService
        )
        {
            _worldService = worldService;
            _factionService = factionService;
            _itemService = itemService;
            _zoneService = zoneService;
            _profileService = profileService;
            _rulesetManager = rulesetManager;
            _facilityService = facilityService;
        }

        public async Task OnApplicationStartup(CancellationToken cancellationToken)
        {
            List<Task> TaskList = new List<Task>();

            Task worldsTask = _worldService.RefreshStore();
            TaskList.Add(worldsTask);

            Task factionsTask = _factionService.RefreshStore();
            TaskList.Add(factionsTask);

            // Won't refresh if already populated
            Task itemsTask = _itemService.RefreshStore();
            TaskList.Add(itemsTask);

            Task zoneTask = _zoneService.RefreshStore();
            TaskList.Add(zoneTask);

            Task profileTask = _profileService.RefreshStore();
            TaskList.Add(profileTask);

            Task scrimActionTask = _rulesetManager.SeedScrimActionModels();
            TaskList.Add(scrimActionTask);

            Task defaultRulesetTask = _rulesetManager.SeedDefaultRuleset();
            TaskList.Add(defaultRulesetTask);

            // Won't refresh if already populated
            Task facilitiesTask = _facilityService.RefreshStore();
            TaskList.Add(facilitiesTask);

            await Task.WhenAll(TaskList);
        }

        public async Task OnApplicationShutdown(CancellationToken cancellationToken)
        {
            await Task.CompletedTask;
        }
    }
}
