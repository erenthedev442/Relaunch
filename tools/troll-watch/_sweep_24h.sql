SELECT c.charid, c.charname, IF(c.accid=0,c.original_accid,c.accid) AS accid,
       a.login, a.status, a.timecreate AS acc_created, c.timecreated,
       c.playtime, SEC_TO_TIME(c.playtime) AS play_hms,
       IF(s.charid IS NULL,'OFFLINE','ONLINE') AS state,
       (SELECT ip.client_ip FROM account_ip_record ip
         WHERE ip.accid = IF(c.accid=0,c.original_accid,c.accid)
         ORDER BY ip.login_time DESC LIMIT 1) AS last_ip
FROM chars c
LEFT JOIN accounts a ON a.id = IF(c.accid=0,c.original_accid,c.accid)
LEFT JOIN accounts_sessions s ON s.charid=c.charid
WHERE c.timecreated >= NOW() - INTERVAL 24 HOUR
ORDER BY c.timecreated DESC;

SELECT a.id, a.login, a.status, a.timecreate
FROM accounts a
LEFT JOIN chars c ON c.accid=a.id OR c.original_accid=a.id
WHERE a.timecreate >= NOW() - INTERVAL 24 HOUR AND c.charid IS NULL
ORDER BY a.timecreate DESC;

SELECT ip.client_ip, a.id AS accid, a.login, a.status, c.charname, c.playtime,
       MAX(ip.login_time) AS last_seen
FROM account_ip_record ip
JOIN accounts a ON a.id=ip.accid
LEFT JOIN chars c ON c.accid=a.id OR c.original_accid=a.id
WHERE ip.login_time >= NOW() - INTERVAL 24 HOUR
  AND (
    ip.client_ip LIKE '186.247.%'
    OR ip.client_ip LIKE '187.13.%'
    OR ip.client_ip LIKE '187.40.%'
    OR ip.client_ip LIKE '187.15.%'
    OR ip.client_ip LIKE '66.179.156.%'
    OR ip.client_ip LIKE '92.119.18.%'
    OR ip.client_ip LIKE '69.1.199.%'
    OR ip.client_ip LIKE '84.247.%'
    OR ip.client_ip LIKE '209.46.1.%'
  )
GROUP BY ip.client_ip, a.id, c.charid
ORDER BY last_seen DESC;

SELECT newc.charname AS new_char, newa.login AS new_login, newa.status AS new_status,
       ip.client_ip, oldc.charname AS shared_with, olda.login AS shared_login, olda.status AS shared_status
FROM chars newc
JOIN account_ip_record ip ON ip.accid = IF(newc.accid=0,newc.original_accid,newc.accid)
JOIN account_ip_record ip2 ON ip2.client_ip=ip.client_ip AND ip2.accid<>ip.accid
JOIN accounts olda ON olda.id=ip2.accid
LEFT JOIN chars oldc ON oldc.accid=olda.id OR oldc.original_accid=olda.id
LEFT JOIN accounts newa ON newa.id=IF(newc.accid=0,newc.original_accid,newc.accid)
WHERE newc.timecreated >= NOW() - INTERVAL 24 HOUR
  AND (olda.status<>1
       OR LOWER(olda.login) REGEXP 'erenis|bankai|penis|niqqer|gaspard|blazeit|isuck|jamestajew|1234|retard'
       OR LOWER(IFNULL(oldc.charname,'')) REGEXP 'bankai|chatgpt|iminyourwalls|boobookitty|bigbangow|mildford|nicholas|gaspar|cummies|dequan')
GROUP BY newc.charid, ip.client_ip, olda.id, oldc.charid
ORDER BY ip.client_ip;

SELECT c.charid, c.charname, a.id AS accid, a.login, a.status, a.timecreate,
       (SELECT ip.client_ip FROM account_ip_record ip WHERE ip.accid=a.id ORDER BY ip.login_time DESC LIMIT 1) AS last_ip
FROM accounts a
LEFT JOIN chars c ON c.accid=a.id OR c.original_accid=a.id
WHERE a.timecreate >= NOW() - INTERVAL 24 HOUR
  AND (
    LOWER(a.login) REGEXP 'erenis|bankai|penis|niqqer|nigger|retard|jew|blazeit|donkey|gaspard|isuck|chatgpt|iminyour|booboo|bangow|420'
    OR LOWER(IFNULL(c.charname,'')) REGEXP 'erenis|bankai|penis|niqqer|nigger|retard|chatgpt|iminyour|booboo|bangow|mildford|nicholas|gaspar|cummies'
    OR a.login REGEXP '^[0-9]{1,6}$'
    OR a.login REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$'
  )
ORDER BY a.timecreate DESC;
