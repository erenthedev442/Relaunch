/*
===========================================================================

  Copyright (c) 2010-2015 Darkstar Dev Teams

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

===========================================================================
*/

#include <algorithm>
#include <map/ai/helpers/event_handler.h>

void CAIEventHandler::addListener(const std::string& eventName, const sol::function& luaFunc, const std::string& identifier)
{
    TracyZoneScoped;
    TracyZoneString(eventName);
    TracyZoneString(identifier);

    // Adding during triggerListener reallocates the vector being walked.
    if (triggerDepth_ > 0)
    {
        eventsToAdd_.push_back({ eventName, luaFunc, identifier });
        return;
    }

    // Remove entries with same identifier (if they exist)
    removeFromAllListeners(identifier);

    // Add the new listener
    eventListeners_[eventName].emplace_back(identifier, luaFunc);
}

void CAIEventHandler::removeListener(const std::string& identifier)
{
    TracyZoneScoped;
    TracyZoneString(identifier);

    // If we're currently triggering listeners, it isn't safe to remove
    // the listener from the list, so we'll mark it for lazy removal later
    if (triggerDepth_ > 0)
    {
        eventsToRemove_.push_back(identifier);
        return;
    }

    // Otherwise, we can remove the listener immediately
    removeFromAllListeners(identifier);
}

bool CAIEventHandler::hasListener(const std::string& eventName) const
{
    const auto& listeners = eventListeners_.find(eventName);
    return listeners != eventListeners_.end() && !listeners->second.empty();
}

void CAIEventHandler::removeFromAllListeners(const std::string& identifier)
{
    TracyZoneScoped;
    TracyZoneString(identifier);

    if (eventListeners_.empty())
    {
        return;
    }

    const auto isSameIdentifier = [&identifier](const AIEvent& event)
    {
        return identifier == event.identifier_;
    };

    // Copy keys first. Destroying a sol::function during erase can re-enter
    // addListener (Lua GC / __gc) and rehash eventListeners_ under a live
    // range-for, which is the same class of crash as mutating the vector
    // during triggerListener.
    std::vector<std::string> names;
    names.reserve(eventListeners_.size());
    for (const auto& [name, _] : eventListeners_)
    {
        names.push_back(name);
    }

    for (const auto& name : names)
    {
        auto itMap = eventListeners_.find(name);
        if (itMap == eventListeners_.end())
        {
            continue;
        }

        auto& listeners = itMap->second;
        auto  it        = std::remove_if(listeners.begin(), listeners.end(), isSameIdentifier);
        listeners.erase(it, listeners.end());
    }
}
