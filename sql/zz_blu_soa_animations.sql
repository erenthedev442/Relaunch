-- Remap Seekers BLU spells onto existing TOAU/Abyssea BLU animations.
-- This client has no unique DATs at 915-937 (Trust spawn/dismiss, Haste II,
-- Geo-ish 930, Warp 933). Map reload required after import.

UPDATE `spell_list` SET `animation` = 695 WHERE `spellid` = 715; -- molting_plumage -> Mysterious Light
UPDATE `spell_list` SET `animation` = 690 WHERE `spellid` = 716; -- nectarous_deluge -> Maelstrom
UPDATE `spell_list` SET `animation` = 698 WHERE `spellid` = 717; -- sweeping_gouge -> Sickle Slash
UPDATE `spell_list` SET `animation` = 673 WHERE `spellid` = 719; -- searing_tempest -> Self-Destruct
UPDATE `spell_list` SET `animation` = 721 WHERE `spellid` = 720; -- spectral_floe -> Ice Break
UPDATE `spell_list` SET `animation` = 697 WHERE `spellid` = 721; -- anvil_lightning -> Blitzstrahl
UPDATE `spell_list` SET `animation` = 631 WHERE `spellid` = 722; -- entomb -> Sandspin
UPDATE `spell_list` SET `animation` = 692 WHERE `spellid` = 723; -- saurian_slide -> Uppercut
UPDATE `spell_list` SET `animation` = 704 WHERE `spellid` = 724; -- palling_salvo -> Eyes On Me
UPDATE `spell_list` SET `animation` = 741 WHERE `spellid` = 725; -- blinding_fulgor -> Actinic Burst
UPDATE `spell_list` SET `animation` = 690 WHERE `spellid` = 726; -- scouring_spate -> Maelstrom
UPDATE `spell_list` SET `animation` = 695 WHERE `spellid` = 727; -- silent_storm -> Mysterious Light
UPDATE `spell_list` SET `animation` = 661 WHERE `spellid` = 728; -- tenebral_crush -> Blood Saber
UPDATE `spell_list` SET `animation` = 695 WHERE `spellid` = 744; -- droning_whirlwind -> Mysterious Light
UPDATE `spell_list` SET `animation` = 737 WHERE `spellid` = 745; -- carcharian_verve -> Saline Coat
UPDATE `spell_list` SET `animation` = 703 WHERE `spellid` = 746; -- blistering_roar -> Geist Wall
UPDATE `spell_list` SET `animation` = 724 WHERE `spellid` = 747; -- uproot -> 1000 Needles
UPDATE `spell_list` SET `animation` = 697 WHERE `spellid` = 748; -- crashing_thunder -> Blitzstrahl
UPDATE `spell_list` SET `animation` = 688 WHERE `spellid` = 749; -- polar_roar -> Frost Breath
UPDATE `spell_list` SET `animation` = 654 WHERE `spellid` = 750; -- mighty_guard -> Cocoon
UPDATE `spell_list` SET `animation` = 682 WHERE `spellid` = 751; -- cruel_joke -> Soporific
UPDATE `spell_list` SET `animation` = 685 WHERE `spellid` = 752; -- cesspool -> Cursed Sphere
UPDATE `spell_list` SET `animation` = 732 WHERE `spellid` = 753; -- tearing_gust -> Hecatomb Wave
