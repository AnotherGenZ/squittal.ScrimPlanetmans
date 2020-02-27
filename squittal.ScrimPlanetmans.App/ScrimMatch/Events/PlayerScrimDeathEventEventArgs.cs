﻿using System;

namespace squittal.ScrimPlanetmans.ScrimMatch.Events
{
    public class ScrimDeathActionEventEventArgs : EventArgs
    {
        public ScrimDeathActionEventEventArgs(ScrimDeathActionEventMessage m)
        {
            Message = m;
        }

        public ScrimDeathActionEventMessage Message { get; }
    }
}
