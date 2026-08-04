-- Legacy helper; prefer trust_combat_round5_zeid.sql for live apply.
DELETE FROM mob_skill_lists WHERE skill_list_id = 1021;
INSERT INTO mob_skill_lists
    (skill_list_name, skill_list_id, mob_skill_id)
VALUES
    ('TRUST_Zeid',1021,980), -- Freezebite
    ('TRUST_Zeid',1021,981), -- Ground Strike
    ('TRUST_Zeid',1021,982), -- Abyssal Drain
    ('TRUST_Zeid',1021,983); -- Abyssal Strike
