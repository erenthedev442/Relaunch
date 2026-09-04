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

#include "map_engine.h"

#include "common/blowfish.h"
#include "common/console_service.h"
#include "common/crash_snapshot.h"
#include "common/database.h"
#include "common/debug.h"
#include "common/ipp.h"
#include "common/logging.h"
#include "common/macros.h"
#include "common/settings.h"
#include "common/timer.h"
#include "common/utils.h"
#include "common/vana_time.h"
#include "common/version.h"
#include "common/zlib.h"

#include "ability.h"
#include "daily_system.h"
#include "map_constants.h"
#include "ipc_client.h"
#include "job_points.h"
#include "latent_effect_container.h"
#include "map_networking.h"
#include "map_statistics.h"
#include "mob_spell_list.h"
#include "monstrosity.h"
#include "roe.h"
#include "spell.h"
#include "status_effect_container.h"
#include "time_server.h"
#include "transport.h"
#include "zone.h"
#include "zone_entities.h"

#include "ai/controllers/automaton_controller.h"

#include "items/item_equipment.h"

#include "packets/s2c/0x017_chat_std.h"

#include "utils/battleutils.h"
#include "utils/charutils.h"
#include "utils/fishingutils.h"
#include "utils/gardenutils.h"
#include "utils/guildutils.h"
#include "utils/instanceutils.h"
#include "utils/itemutils.h"
#include "utils/mobutils.h"
#include "utils/moduleutils.h"
#include "utils/petutils.h"
#include "utils/serverutils.h"
#include "utils/synergyutils.h"
#include "utils/synthutils.h"
#include "utils/trustutils.h"
#include "utils/zoneutils.h"

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <fstream>
#include <thread>

#ifdef _WIN32
#include <io.h>
#endif

MapEngine::MapEngine(Application& application, MapConfig& config)
: application_(application)
, scheduler_(application_.scheduler())
, mapStatistics_(std::make_unique<MapStatistics>())
, networking_(std::make_unique<MapNetworking>(scheduler_, *mapStatistics_, config))
, config_(config)
{
}

MapEngine::~MapEngine()
{
    itemutils::FreeItemList();
    battleutils::FreeWeaponSkillsList();
    battleutils::FreeMobSkillList();
    battleutils::FreePetSkillList();
    fishingutils::CleanupFishing();
    guildutils::Cleanup();
    mobutils::Cleanup();
    traits::ClearTraitsList();

    petutils::FreePetList();
    zoneutils::FreeZoneList();

    luautils::cleanup();
}

auto MapEngine::init() -> Task<void>
{
    TracyZoneScoped;

#ifdef TRACY_ENABLE
    ShowInfo("*** TRACY IS ENABLED ***");
#endif // TRACY_ENABLE

    ShowInfo(fmt::format("Last Branch: {}", version::GetGitBranch()));
    ShowInfo(fmt::format("SHA: {} ({})", version::GetGitSha(), version::GetGitDate()));

    ShowInfo("do_init: begin server initialization");

    const auto mapIPP = networking_->ipp();

    ShowInfoFmt("map_ip: {}", mapIPP.getIPString());
    ShowInfoFmt("map_port: {}", mapIPP.getPort());

    ShowInfoFmt("Zones assigned to this process: {}", zoneutils::GetZonesAssignedToThisProcess(mapIPP).size());

    ShowInfo(fmt::format("Random samples (integer): {}", utils::getRandomSampleString(0, 255)));
    ShowInfo(fmt::format("Random samples (float): {}", utils::getRandomSampleString(0.0f, 1.0f)));

    ShowInfo("do_init: connecting to database");
    ShowInfo(fmt::format("database name: {}", db::getDatabaseSchema()).c_str());
    ShowInfo(fmt::format("database server version: {}", db::getDatabaseVersion()).c_str());
    ShowInfo(fmt::format("database client version: {}", db::getDriverVersion()).c_str());

    if (!config_.inCI)
    {
        db::checkCharset();
    }

    db::checkTriggers();

    luautils::init(mapIPP, config_.inCI); // Also calls moduleutils::LoadLuaModules();

    // Delete sessions that are associated with this map process, but leave others alone
    db::preparedStmt("DELETE FROM accounts_sessions WHERE IF(? = 0 AND ? = 0, true, server_addr = ? AND server_port = ?)",
                     mapIPP.getIP(),
                     mapIPP.getPort(),
                     mapIPP.getIP(),
                     mapIPP.getPort());

    ShowInfo("do_init: zlib is reading");
    zlib_init();

    ShowInfo("do_init: starting ZMQ thread");
    message::init(networking());

    ShowInfo("do_init: loading items");
    itemutils::Initialize();

    ShowInfo("do_init: loading plants");
    gardenutils::Initialize();

    ShowInfo("do_init: loading spells");
    spell::LoadSpellList();
    mobSpellList::LoadMobSpellList();
    automaton::LoadAutomatonSpellList();
    automaton::LoadAutomatonAbilities();

    guildutils::Initialize();
    charutils::LoadExpTable();
    traits::LoadTraitsList();
    effects::LoadEffectsParameters();
    battleutils::LoadSkillTable();
    meritNameSpace::LoadMeritsList();
    ability::LoadAbilitiesList();
    battleutils::LoadWeaponSkillsList();
    battleutils::LoadMobSkillsList();
    battleutils::LoadPetSkillsList();
    battleutils::LoadSkillChainDamageModifiers();
    petutils::LoadPetList();
    trustutils::LoadTrustList();
    mobutils::LoadSqlModifiers();
    jobpointutils::LoadGifts();
    daily::LoadDailyItems();
    roeutils::UpdateUnityRankings();
    synthutils::LoadSynthRecipes();
    synergyutils::LoadSynergyRecipes();
    CItemEquipment::LoadAugmentData(); // TODO: Move to itemutils

    if (!std::filesystem::exists("./ximeshes/") || std::filesystem::is_empty("./ximeshes/"))
    {
        ShowError("./ximeshes/ directory isn't present or is empty");
    }

    if (!std::filesystem::exists("./navmeshes/") || std::filesystem::is_empty("./navmeshes/"))
    {
        ShowWarning("./navmeshes/ directory isn't present or is empty");
    }

    co_await zoneutils::Initialize(scheduler_, config_);
    instanceutils::Initialize(config_);

    if (!config_.lazyZones)
    {
        CTransportHandler::getInstance()->InitializeTransport(mapIPP);
    }

    fishingutils::InitializeFishingSystem();

    monstrosity::LoadStaticData();

    if (!config_.controlledWeather)
    {
        zoneutils::InitializeWeather(); // Need VanaTime initialized
    }

    //
    // Queue up regular tasks for the Scheduler
    //

    if (!config_.isTestServer)
    {
        mapCleanupToken_        = scheduler_.intervalOnMainThread(kSessionCleanupInterval, std::bind(&MapEngine::sessionCleanup, this));
        mapGarbageCollectToken_ = scheduler_.intervalOnMainThread(kGarbageCollectionInterval, std::bind(&MapEngine::garbageCollect, this));

        timeServerToken_ = scheduler_.intervalOnMainThread(
            kTimeServerTickInterval,
            [this]() -> Task<void>
            {
                co_await time_server(scheduler_, config_);
            });

        persistVolatileServerVarsToken_ = scheduler_.intervalOnMainThread(kPersistVolatileServerVarsInterval, serverutils::PersistVolatileServerVars);
        pumpIPCToken_                   = scheduler_.intervalOnMainThread(kIPCPumpInterval, message::handle_incoming);
        flushStatisticsToken_           = scheduler_.intervalOnMainThread(kTimeServerTickInterval, std::bind(&MapNetworking::flushStatistics, networking_.get()));
    }

    zoneutils::TOTDChange(vanadiel_time::get_totd()); // This tells the zones to spawn stuff based on time of day conditions (such as undead at night)

    ShowInfo("do_init: Removing expired database variables");
    uint32 currentTimestamp = earth_time::timestamp();
    db::preparedStmt("DELETE FROM char_vars WHERE expiry > 0 AND expiry <= ?", currentTimestamp);
    db::preparedStmt("DELETE FROM server_variables WHERE expiry > 0 AND expiry <= ?", currentTimestamp);

    moduleutils::OnInit();

    luautils::OnServerStart();

    if (!config_.isTestServer)
    {
        moduleutils::ReportLuaModuleUsage();
    }

    db::enableTimers();

    //
    // Set up the watchdog tasks
    //

    if (!config_.isTestServer)
    {
        scheduler_.postToMainThread(watchdogUpdater());
        scheduler_.postToWorkerThread(watchdogWatcher());
    }

#ifdef TRACY_ENABLE
    ShowInfo("*** TRACY IS ENABLED ***");
#endif // TRACY_ENABLE

    //
    // At this point, the scheduler is loaded up with all the tasks it will need
    // to run everything.
    //

    application_.markLoaded();
}

auto MapEngine::watchdogUpdater() -> Task<void>
{
    // Run "forever"
    while (!scheduler_.closeRequested())
    {
        // If something manages to block the main thread, this task won't be run, and the watcher
        // will kill the server from a worker thread.
        // We do this because if the main thread is blocked severely enough to trigger the watchdog,
        // your server is degraded - likely beyond repair.
        watchdogLastUpdate_ = timer::now();
        co_await scheduler_.yieldFor(kMainThreadBacklogThreshold);
    }
}

namespace
{
    void writeWatchdogHangReport(const std::string& backtrace, std::chrono::milliseconds stalledMs)
    {
        const auto now = std::chrono::system_clock::now();
        const auto t   = std::chrono::system_clock::to_time_t(now);
        std::tm    tm{};
#ifdef _WIN32
        localtime_s(&tm, &t);
#else
        localtime_r(&t, &tm);
#endif
        char when[32]{};
        std::strftime(when, sizeof(when), "%Y/%m/%d %H:%M:%S", &tm);
        char name[128]{};
        std::snprintf(name, sizeof(name), "dmp/xi_map.exe_hang_%u-%u_%u-%u-%u.log",
                      static_cast<unsigned>(tm.tm_mon + 1),
                      static_cast<unsigned>(tm.tm_mday),
                      static_cast<unsigned>(tm.tm_hour),
                      static_cast<unsigned>(tm.tm_min),
                      static_cast<unsigned>(tm.tm_sec));

        std::ofstream out(name, std::ios::out | std::ios::trunc);
        if (out)
        {
            out << "=====================================================\n"
                << "!!! HANG !!!\n"
                << "Exception code: HANG (main tick stalled)\n"
                << "Time of crash: " << when << "\n"
                << "Git SHA: " << version::GetGitSha() << "\n"
                << "Git Commit Subject: " << version::GetGitCommitSubject() << "\n"
                << "Git Branch: " << version::GetGitBranch() << "\n"
                << "Process Name: xi_map\n"
                << "Process Uptime: stalled " << stalledMs.count() << "ms\n"
                << "Full crash report: " << name << "\n\n"
                << backtrace
                << "=====================================================\n"
                << "=== Flight recorder ===\n"
                << crash_snapshot::Copy()
                << "=====================================================\n";
        }

        crash_snapshot::WriteSidecar(name);
    }
} // namespace

auto MapEngine::watchdogWatcher() -> Task<void>
{
    auto period = settings::get<uint32>("main.INACTIVITY_WATCHDOG_PERIOD");

    if (config_.inCI)
    {
        // Double the timer period, to account for the slower CI environment
        period *= 2;
    }

    const auto periodMs = (period > 0) ? std::chrono::milliseconds(period) : 2000ms;

    watchdogLastUpdate_ = timer::now();
    bool        loggedStall    = false;
    std::string stallBacktrace;

    // Run "forever"
    while (!scheduler_.closeRequested())
    {
        const auto lastUpdate = watchdogLastUpdate_.load();
        const auto stalledFor = timer::now() - lastUpdate;
        if (stalledFor >= periodMs)
        {
            if (debug::isRunningUnderDebugger())
            {
                if (!loggedStall)
                {
                    ShowCritical("!!! INACTIVITY WATCHDOG HAS TRIGGERED !!!");
                    ShowCriticalFmt("Process main tick has taken {}ms or more.", period);
                    ShowCritical("Debugger attached — watchdog will not kill. Fix the stall or continue.");
                    loggedStall = true;
                }
            }
            else if (!settings::get<bool>("main.DISABLE_INACTIVITY_WATCHDOG"))
            {
                if (!loggedStall)
                {
                    std::string outputStr = "!!! INACTIVITY WATCHDOG HAS TRIGGERED !!!\n\n";
                    outputStr += fmt::format("Process main tick has taken {}ms or more.\n", period);
                    outputStr += fmt::format("Will exit if still stalled after {}ms.\n",
                                            std::chrono::duration_cast<std::chrono::milliseconds>(kWatchdogKillAfter).count());
                    outputStr += fmt::format("Backtrace Messages:\n\n");

                    const auto backtrace = logging::GetBacktrace();
                    for (const auto& line : backtrace)
                    {
                        outputStr += fmt::format("    {}\n", line);
                    }

                    stallBacktrace = outputStr;
                    ShowCritical(outputStr);
                    loggedStall = true;
                }

                if (stalledFor >= kWatchdogKillAfter)
                {
                    const auto stalledMs = std::chrono::duration_cast<std::chrono::milliseconds>(stalledFor);
                    writeWatchdogHangReport(stallBacktrace, stalledMs);
                    std::this_thread::sleep_for(200ms);
                    std::_Exit(1);
                }
            }
        }
        else
        {
            loggedStall    = false;
            stallBacktrace.clear();
        }

        co_await scheduler_.yieldFor(periodMs);
    }
}

void MapEngine::sessionCleanup() const
{
    TracyZoneScoped;

    networking().sessions().cleanupSessions(networking().ipp());

    zoneutils::ForEachZone(
        [](CZone* PZone)
        {
            PZone->GetZoneEntities()->EraseStaleDynamicTargIDs();
        });
}

void MapEngine::garbageCollect() const
{
    TracyZoneScoped;

    luautils::garbageCollectFull();
}

void MapEngine::onStats(std::vector<std::string>& inputs) const
{
    mapStatistics_->print();
}

void MapEngine::onBacktrace(std::vector<std::string>& inputs) const
{
    const auto backtrace = logging::GetBacktrace();
    for (const auto& line : backtrace)
    {
        fmt::print("{}\n", line);
    }
}

void MapEngine::onReloadRecipes(std::vector<std::string>& inputs) const
{
    fmt::print("> Reloading crafting recipes\n");
    synthutils::LoadSynthRecipes();
}

void MapEngine::onGM(const std::vector<std::string>& inputs) const
{
    if (inputs.size() != 3)
    {
        fmt::print("Usage: gm <char_name> <level>. example: gm Testo 1\n");
        return;
    }

    const auto& name  = inputs[1];
    auto*       PChar = zoneutils::GetCharByName(name);
    if (!PChar)
    {
        fmt::print("Couldnt find character: {}\n", name);
        return;
    }

    const auto level = std::clamp<uint8>(static_cast<uint8>(stoi(inputs[2])), 0, 5);

    PChar->m_GMlevel = level;

    charutils::SaveCharGMLevel(PChar);

    fmt::print("> Promoting {} to GM level {}\n", PChar->name, level);
    PChar->pushPacket<GP_SERV_COMMAND_CHAT_STD>(PChar, MESSAGE_SYSTEM_3, fmt::format("You have been set to GM level {}.", level));
}

auto MapEngine::networking() const -> MapNetworking&
{
    return *networking_;
}

auto MapEngine::statistics() const -> MapStatistics&
{
    return *mapStatistics_;
}

auto MapEngine::zones() const -> std::map<uint16, CZone*>&
{
    return g_PZoneList;
}

auto MapEngine::scheduler() -> Scheduler&
{
    return scheduler_;
}

auto MapEngine::config() const -> MapConfig&
{
    return config_;
}
