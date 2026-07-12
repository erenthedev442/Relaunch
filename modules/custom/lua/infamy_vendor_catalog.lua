-----------------------------------
-- infamy_vendor_catalog.lua
-- Config for the Infamy Vendor NPC. InfamyVendor.lua reads it.
--
-- ACCESSORIES-ONLY, fully hand-curated (2026-07-06). Weapons + armor were
-- moved to the Voidwatch NM loot tables; the auto-generated sections
-- (vendorItemsAuto / plus4Sets / itemTypeMap) and their build_infamy_*.py
-- generators were retired. Each item carries its own `sub` slot for the
-- vendor category browser. Add/remove items by editing catalog.vendorItems.
-----------------------------------
local catalog = {}

catalog.currencyCv = 'Infamy'

catalog.npcPos =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        =  554.971,
    y        =  -3.360,
    z        = 520.586,
    rotation = 128,
}

catalog.vendorItems =
{
    { id = 25461, sub = "Neck", name = "Abyssal Bead Necklace +2", cost = 250, stats = { 'WS score 90', 'Accessory top-5 (neck)', 'Jobs: DRK' } },
    { id = 11607, sub = "Neck", name = "Artemiss Medal", cost = 250, stats = { 'CASTER score 95', 'Accessory top-5 (neck)', 'Jobs: All' } },
    { id = 26003, sub = "Neck", name = "Baetyl Pendant", cost = 300, stats = { 'Neck. Caster (Magic Attack).', 'EX/RARE.' } },
    { id = 26015, sub = "Neck", name = "Combatants Torque", cost = 300, stats = { 'Neck. DD (Accuracy / Attack).', 'EX/RARE.' } },
    { id = 25497, sub = "Neck", name = "Dragoons Collar +2", cost = 250, stats = { 'WS score 83', 'Accessory top-5 (neck)', 'Jobs: DRG' } },
    { id = 27510, sub = "Neck", name = "Fotia Gorget", cost = 250, stats = { 'Neck. Universal WS gorget (WS damage).', 'EX/RARE.' } },
    { id = 26004, sub = "Neck", name = "Lissome Necklace", cost = 250, stats = { 'DPS score 140', 'Accessory top-5 (neck)', 'Jobs: All' } },
    { id = 26023, sub = "Neck", name = "Sanctity Necklace", cost = 350, stats = { 'CASTER score 252', 'Accessory top-5 (neck)', 'Jobs: All' } },
    { id = 26022, sub = "Neck", name = "Vim Torque +1", cost = 300, stats = { 'Neck. DEF+15.', 'Regain+20 while weapon drawn (latent).' } },
    { id = 25482, sub = "Ear", name = "Amini Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for RNG', 'Jobs: RNG' } },
    { id = 25535, sub = "Ear", name = "Arbatel Earring +1", cost = 250, stats = { 'CASTER score 56', 'Accessory top-5 (ear)', 'Jobs: SCH' } },
    { id = 25536, sub = "Ear", name = "Arbatel Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for SCH', 'Jobs: SCH' } },
    { id = 25542, sub = "Ear", name = "Azimuth Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for GEO', 'Jobs: GEO' } },
    { id = 25506, sub = "Ear", name = "Beckoners Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for SMN', 'Jobs: SMN' } },
    { id = 25428, sub = "Ear", name = "Bhikku Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for MNK', 'Jobs: MNK' } },
    { id = 25422, sub = "Ear", name = "Boii Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for WAR', 'Jobs: WAR' } },
    { id = 25518, sub = "Ear", name = "Chasseurs Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for COR', 'Jobs: COR' } },
    { id = 25458, sub = "Ear", name = "Chevaliers Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for PLD', 'Jobs: PLD' } },
    { id = 21431, sub = "Ear", name = "Coiste Bodhar", cost = 300, stats = { 'Earring. Double Attack + WS damage.', 'Top DD earring (Omen).' } },
    { id = 25434, sub = "Ear", name = "Ebers Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for WHM', 'Jobs: WHM' } },
    { id = 25548, sub = "Ear", name = "Erilaz Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for RUN', 'Jobs: RUN' } },
    { id = 25476, sub = "Ear", name = "Fili Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BRD', 'Jobs: BRD' } },
    { id = 25512, sub = "Ear", name = "Hashishin Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BLU', 'Jobs: BLU' } },
    { id = 25494, sub = "Ear", name = "Hattori Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for NIN', 'Jobs: NIN' } },
    { id = 25464, sub = "Ear", name = "Heathens Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for DRK', 'Jobs: DRK' } },
    { id = 25524, sub = "Ear", name = "Karagoz Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for PUP', 'Jobs: PUP' } },
    { id = 25488, sub = "Ear", name = "Kasuga Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for SAM', 'Jobs: SAM' } },
    { id = 25446, sub = "Ear", name = "Lethargy Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for RDM', 'Jobs: RDM' } },
    { id = 25530, sub = "Ear", name = "Maculele Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for DNC', 'Jobs: DNC' } },
    { id = 25470, sub = "Ear", name = "Nukumi Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BST', 'Jobs: BST' } },
    { id = 26108, sub = "Ear", name = "Odr Earring", cost = 250, stats = { 'DPS score 55', 'Accessory top-5 (ear)', 'Jobs: MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' } },
    { id = 25500, sub = "Ear", name = "Peltasts Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for DRG', 'Jobs: DRG' } },
    { id = 26084, sub = "Ear", name = "Sherida Earring", cost = 300, stats = { 'Earring. DEX, Double Attack, crit.', 'DD earring.' } },
    { id = 25452, sub = "Ear", name = "Skulkers Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for THF', 'Jobs: THF' } },
    { id = 26118, sub = "Ear", name = "Sroda Earring", cost = 300, stats = { 'Earring. STR + WS damage.', 'DD earring.' } },
    { id = 25439, sub = "Ear", name = "Wicce Earring +1", cost = 250, stats = { 'CASTER score 56', 'Accessory top-5 (ear)', 'Jobs: BLM' } },
    { id = 25440, sub = "Ear", name = "Wicce Earring +2", cost = 300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BLM', 'Jobs: BLM' } },
    { id = 26192, sub = "Ring", name = "Adoulin Ring +1", cost = 10000, stats = { 'Ring. All-rounder: HP/MP+55, Atk/Rng.Atk+20, Acc/Rng.Acc/MAtk/MAcc+8.', 'EX/RARE.' } },
    { id = 26227, sub = "Ring", name = "Cornelia\'s Ring", cost = 500, stats = { 'Ring. Best WS-damage ring (WS damage +10%, WS Acc+20).', 'EX/RARE.' } },
    { id = 13566, sub = "Ring", name = "Defending Ring", cost = 1500, stats = { 'Damage Taken -10%.', 'Locks itself once equipped.', 'The grand prize.' } },
    { id = 26231, sub = "Ring", name = "Ephramad's Ring", cost = 300, stats = { 'Ring. MND+15, Cure Potency+10%, Healing Skill+15.', 'EX/RARE.' } },
    { id = 26230, sub = "Ring", name = "Fickblix's Ring", cost = 300, stats = { 'Ring. INT+15, Magic Atk+15, Magic Acc+20.', 'EX/RARE.' } },
    { id = 28471, sub = "Ring", name = "Gere Ring", cost = 250, stats = { 'DPS score 76', 'Accessory top-5 (ring)', 'Jobs: MNK/THF/BST/NIN/PUP/DNC' } },
    { id = 26197, sub = "Ring", name = "Gorney Ring +1", cost = 10000, stats = { 'Ring. THF utility: Steal+3, Treasure Hunter+1, Mug+2, Gilfinder+2.', 'EX/RARE.' } },
    { id = 26226, sub = "Ring", name = "Gurebu's Ring", cost = 300, stats = { 'Ring. STR+10, VIT+10, Double Attack+5%.', 'EX/RARE.' } },
    { id = 26198, sub = "Ring", name = "Haverton Ring +1", cost = 10000, stats = { 'Ring. Ranged/NIN: Rng.Acc+23, Ninjutsu+11, Dual Wield+6%, Snapshot+7%.', 'EX/RARE.' } },
    { id = 26186, sub = "Ring", name = "Ilabrat Ring", cost = 250, stats = { 'WS score 72', 'Accessory top-5 (ring)', 'Jobs: MNK/WHM/RDM/THF/BST/BRD/RNG/SAM/NIN/BLU/COR/DNC/RUN' } },
    { id = 26195, sub = "Ring", name = "Janniston Ring +1", cost = 10000, stats = { 'Ring. Healer: MP+44, Enmity-8, Cure Potency II+6%.', 'EX/RARE.' } },
    { id = 26199, sub = "Ring", name = "Karieyh Ring +1", cost = 10000, stats = { 'Ring. Weaponskill: WS Acc+10, Regain+5, WS damage+4%.', 'EX/RARE.' } },
    { id = 26229, sub = "Ring", name = "Lehko's Ring", cost = 300, stats = { 'Ring. DEX+10, AGI+10, Store TP+5, Haste+2%.', 'EX/RARE.' } },
    { id = 26225, sub = "Ring", name = "Medada's Ring", cost = 300, stats = { 'Ring. STR+10, Acc+15, Crit Rate+3%.', 'EX/RARE.' } },
    { id = 26190, sub = "Ring", name = "Moonlight Ring", cost = 300, stats = { 'Ring. Hybrid (DT-, Accuracy).', 'Universal ring.' } },
    { id = 26185, sub = "Ring", name = "Niqmaddu Ring", cost = 300, stats = { 'Ring. STR/VIT, Double Attack.', 'DD ring.' } },
    { id = 26203, sub = "Ring", name = "Orvail Ring +1", cost = 10000, stats = { 'Ring. Crafting: Synth success+2%, skill-up+6, material loss-2%, HQ+2.', 'EX/RARE.' } },
    { id = 26228, sub = "Ring", name = "Ragelise's Ring", cost = 300, stats = { 'Ring. HP+30, DEF+20, MND+10.', 'EX/RARE.' } },
    { id = 26191, sub = "Ring", name = "Regal Ring", cost = 250, stats = { 'WS score 85', 'Accessory top-5 (ring)', 'Jobs: WAR/MNK/THF/PLD/DRK/BST/RNG/SAM/NIN/DRG/COR/PUP/DNC/RUN' } },
    { id = 26196, sub = "Ring", name = "Renaye Ring +1", cost = 10000, stats = { 'Ring. Magic skill (Singing/Blue/Geomancy)+11, Refresh+2.', 'EX/RARE.' } },
    { id = 26202, sub = "Ring", name = "Shneddick Ring +1", cost = 10000, stats = { 'Ring. Movement+18%, Resist Petrify/Bind/Gravity+17.', 'EX/RARE.' } },
    { id = 26201, sub = "Ring", name = "Thurandaut Ring +1", cost = 10000, stats = { 'Ring. Pet: Atk/Rng.Atk+23, Acc/Rng.Acc+22, Dmg taken-4%, Haste+4%.', 'EX/RARE. (BST/SMN/PUP/DRG)' } },
    { id = 26200, sub = "Ring", name = "Vocane Ring +1", cost = 10000, stats = { 'Ring. Tank: Damage taken-8%, Cure Potency Rcvd+6%, Knockback res+2.', 'EX/RARE.' } },
    { id = 26194, sub = "Ring", name = "Weatherspoon Ring +1", cost = 10000, stats = { 'Ring. Caster: Magic Acc+13, Fast Cast+6%, Light magic+11%, Quick Magic+4%.', 'EX/RARE.' } },
    { id = 26193, sub = "Ring", name = "Woltaris Ring +1", cost = 10000, stats = { 'Ring. Sustain: Refresh+2, Regen+2, Sublimation+2.', 'EX/RARE.' } },
    { id = 28420, sub = "Waist", name = "Fotia Belt", cost = 250, stats = { 'Waist. Universal WS belt (WS damage).', 'EX/RARE.' } },
    { id = 26361, sub = "Waist", name = "Gerdr Belt +1", cost = 250, stats = { 'DPS score 136', 'Accessory top-5 (waist)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id = 26334, sub = "Waist", name = "Ioskeha Belt +1", cost = 300, stats = { 'Waist. DEX + Double Attack.', 'DD belt.' } },
    { id = 26341, sub = "Waist", name = "Moonbow Belt +1", cost = 250, stats = { 'DPS score 162', 'Accessory top-5 (waist)', 'Jobs: MNK/PUP' } },
    { id = 26359, sub = "Waist", name = "Orpheuss Sash", cost = 250, stats = { 'DPS score 92', 'Accessory top-5 (waist)', 'Jobs: All' } },
    { id = 26357, sub = "Waist", name = "Skrymir Cord +1", cost = 350, stats = { 'CASTER score 175', 'Accessory top-5 (waist)', 'Jobs: All' } },
    { id = 26248, sub = "Back", name = "Alaunus's Cape", cost = 4000, stats = { 'Back. WHM JSE cape. DEF+15.', 'Afflatus Solace+10, Cursna+25.' } },
    { id = 26258, sub = "Back", name = "Andartia's Mantle", cost = 4000, stats = { 'Back. NIN JSE cape. DEF+16.', 'Utsusemi: extra shadow+1.' } },
    { id = 26253, sub = "Back", name = "Ankou's Mantle", cost = 4000, stats = { 'Back. DRK JSE cape. DEF+18.', 'Absorb duration+10.' } },
    { id = 28607, sub = "Back", name = "Aput Mantle +1", cost = 250, stats = { 'CASTER score 80', 'Accessory top-5 (back)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id = 27595, sub = "Back", name = "Argochampsa Mantle", cost = 300, stats = { 'Back. Caster cape (Magic Acc / Atk).', 'EX/RARE.' } },
    { id = 26254, sub = "Back", name = "Artio's Mantle", cost = 4000, stats = { 'Back. BST JSE cape. DEF+18.', 'Reward HP+30, Spur+10.' } },
    { id = 27620, sub = "Back", name = "Aurists Cape +1", cost = 350, stats = { 'CASTER score 177', 'Accessory top-5 (back)', 'Jobs: WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' } },
    { id = 26256, sub = "Back", name = "Belenus's Cape", cost = 4000, stats = { 'Back. RNG JSE cape. DEF+16.', 'Velocity Shot+2, Ranged Atk+20.' } },
    { id = 26259, sub = "Back", name = "Brigantia's Mantle", cost = 4000, stats = { 'Back. DRG JSE cape. DEF+18.', 'All Jumps: DA+20%. Wyvern: Breath+15.' } },
    { id = 26260, sub = "Back", name = "Campestres's Cape", cost = 4000, stats = { 'Back. SMN JSE cape. DEF+15.', 'Avatar Lv+1, Blood Pact dmg+5.' } },
    { id = 26262, sub = "Back", name = "Camulus's Mantle", cost = 4000, stats = { 'Back. COR JSE cape. DEF+16.', 'Phantom Roll dur+30, Triple Shot+5%.' } },
    { id = 26246, sub = "Back", name = "Cichol's Mantle", cost = 4000, stats = { 'Back. WAR JSE cape. DEF+18.', 'Double Atk dmg+20, Berserk dur+15.' } },
    { id = 26255, sub = "Back", name = "Intarabus's Cape", cost = 4000, stats = { 'Back. BRD JSE cape. DEF+15.', 'Madrigal+1, Prelude+1.' } },
    { id = 11007, sub = "Back", name = "Letalis Mantle", cost = 300, stats = { 'Back. DD cape (STR, Double Attack).', 'EX/RARE.' } },
    { id = 26265, sub = "Back", name = "Lugh's Cape", cost = 4000, stats = { 'Back. SCH JSE cape. DEF+15.', 'Skillchain Bonus+10, Regen dur+15.' } },
    { id = 26269, sub = "Back", name = "Moonlight Cape", cost = 250, stats = { 'TANK score 171', 'Accessory top-5 (back)', 'Jobs: All' } },
    { id = 26266, sub = "Back", name = "Nantosuelta's Cape", cost = 4000, stats = { 'Back. GEO JSE cape. DEF+15.', 'Indi duration+20, Life Cycle+10.' } },
    { id = 26267, sub = "Back", name = "Ogma's Cape", cost = 4000, stats = { 'Back. RUN JSE cape. DEF+18.', 'Inquartata+3, Vallation/Valiance dur+15.' } },
    { id = 27615, sub = "Back", name = "Reiki Cloak", cost = 250, stats = { 'TANK score 153', 'Accessory top-5 (back)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id = 26261, sub = "Back", name = "Rosmerta's Cape", cost = 4000, stats = { 'Back. BLU JSE cape. DEF+16.', 'Monster correlation+10.' } },
    { id = 26252, sub = "Back", name = "Rudianos's Mantle", cost = 4000, stats = { 'Back. PLD JSE cape. DEF+20.', 'Phys dmg->MP 5%, Shield block+3.' } },
    { id = 13655, sub = "Back", name = "Sand Mantle", cost = 250, stats = { 'TANK score 108', 'Accessory top-5 (back)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id = 26247, sub = "Back", name = "Segomo's Mantle", cost = 4000, stats = { 'Back. MNK JSE cape. DEF+16.', 'Kick Attacks+10, Attack+25.' } },
    { id = 26264, sub = "Back", name = "Senuna's Mantle", cost = 4000, stats = { 'Back. DNC JSE cape. DEF+16.', 'Samba dur+15, Crit dmg+5%.' } },
    { id = 26257, sub = "Back", name = "Smertrios's Mantle", cost = 4000, stats = { 'Back. SAM JSE cape. DEF+18.', 'Meditate dur+8, Skillchain Bonus+3.' } },
    { id = 26250, sub = "Back", name = "Sucellos's Cape", cost = 4000, stats = { 'Back. RDM JSE cape. DEF+15.', 'Enhancing dur+20, Enfeebling eff+10.' } },
    { id = 26249, sub = "Back", name = "Taranus's Cape", cost = 4000, stats = { 'Back. BLM JSE cape. DEF+15.', 'Magic Burst dmg+5.' } },
    { id = 26251, sub = "Back", name = "Toutatis's Cape", cost = 4000, stats = { 'Back. THF JSE cape. DEF+16.', 'Sneak Atk+10, Triple Atk dmg+20.' } },
    { id = 26263, sub = "Back", name = "Visucius's Mantle", cost = 4000, stats = { 'Back. PUP JSE cape. DEF+16.', 'Automaton Lv+1, Overload-10.' } },
    -- Catalyst (not an accessory) -- added 2026-07-09 (report: Burtgang/Spyro/Duff --
    -- Philosopher Stone too scarce; ~80 catalyst per gear set). Native shop charges
    -- Infamy; shows under the browser's "Other" sub-bucket. Peiste skins untouched.
    { id = 942, sub = "Other", name = "Philosopher's Stone", cost = 50, stats = { 'Augment catalyst: Capacity Point +33%.', 'Alchemy material / stacks to 12.' } },
}

return catalog
