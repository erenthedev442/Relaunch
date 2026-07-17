-- Remove character state for retired universal weapon-skill effects.
--
-- Rupture Sage / !aoews and Mastery Splash are already absent from runtime.
-- Mastery Lifesteal was retired because healing from every weapon skill
-- bypassed encounter HP-management mechanics.  No currency refunds are needed
-- for the pre-relaunch test population.
DELETE FROM `char_vars`
WHERE `varname` IN (
    'AoEWSID',
    'AoEWSPct',
    'Mastery_WSFx_splash',
    'Mastery_WSFx_drain'
);
