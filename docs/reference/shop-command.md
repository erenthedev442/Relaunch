# !shop Command

Type `!shop` in any zone to open an instant player shop — no NPC visit required.

```
!shop                            — browse General items
!shop <category>                 — jump to a specific category
!shop armor rings|pearls         — Rare/Ex rings and elemental pearls
!shop armor accessories|combat   — Rare/Ex back/waist/neck or ammo/grips
!shop pets jugs / !shop pets food — Beastmaster pet sub-pages
!shop reforge af|relic|empy|all  — free reforged armor claim for your main job
```

**Available categories:** general · weapons · armor · consumables · food · dice · ammo · ninja · pets · reforge

The four Rare/Ex armor sub-pages cost **10,000 gil per item**. These pieces
cannot be traded, delivered, or listed on the Auction House and resell to
standard NPC vendors for **5,000 gil**.

<!-- DOCGEN:BEGIN id="shop-catalog" -->
<div class="st-wrap">
<div class="st-bar"><input id="st-q" type="text" placeholder="Search all items…" oninput="stFilter()"></div>
<div class="st-tabs">  <button class="st-tab active" data-cat="general">General</button>
  <button class="st-tab" data-cat="consumables">Consumables</button>
  <button class="st-tab" data-cat="weapons">Weapons</button>
  <button class="st-tab" data-cat="armor">Armor</button>
  <button class="st-tab" data-cat="food">Food</button>
  <button class="st-tab" data-cat="dice">COR Dice</button>
  <button class="st-tab" data-cat="ammo">Ammo</button>
  <button class="st-tab" data-cat="ninja">Ninja Tools</button>
  <button class="st-tab" data-cat="cards">COR Cards</button>
  <button class="st-tab" data-cat="scrolls">Scrolls</button>
  <button class="st-tab" data-cat="crystals">Crystals</button>
  <button class="st-tab" data-cat="keys">Keys</button>
  <button class="st-tab" data-cat="pets_jugs">BST Pets</button>
  <button class="st-tab" data-cat="pets_food">BST Pet Food</button>
  <button class="st-tab" data-cat="reforge">Reforge Claim</button>
</div>
<div id="st-body"></div>
</div>
<script>
(function(){
const D={"general":[{"id":27556,"name":"Echad Ring","price":100000},{"id":27557,"name":"Trizek Ring","price":100000},{"id":2974,"name":"Trump Card","price":50},{"id":5870,"name":"Trump Card Case","price":50},{"id":27604,"name":"Aptitude Mantle +1","price":300000},{"id":4148,"name":"Antidote","price":50},{"id":4151,"name":"Echo Drops","price":100},{"id":4128,"name":"Ether","price":300},{"id":4150,"name":"Eye Drops","price":50},{"id":4132,"name":"Hi Ether","price":1000},{"id":4116,"name":"Hi Potion","price":400},{"id":4154,"name":"Holy Water","price":100},{"id":4376,"name":"Meat Jerky","price":50},{"id":4161,"name":"Sleeping Potion","price":200},{"id":4120,"name":"X Potion","price":1000}],"consumables":[{"id":4153,"name":"Antacid","price":200},{"id":4148,"name":"Antidote","price":50},{"id":4151,"name":"Echo Drops","price":100},{"id":4145,"name":"Elixir","price":2000},{"id":4128,"name":"Ether","price":300},{"id":4150,"name":"Eye Drops","price":50},{"id":4132,"name":"Hi Ether","price":1000},{"id":4116,"name":"Hi Potion","price":400},{"id":4154,"name":"Holy Water","price":100},{"id":4112,"name":"Potion","price":100},{"id":4155,"name":"Remedy","price":500},{"id":4161,"name":"Sleeping Potion","price":200},{"id":4174,"name":"Vile Elixir","price":3000},{"id":4175,"name":"Vile Elixir +1","price":5000},{"id":4120,"name":"X Potion","price":1000}],"weapons":[{"id":17859,"name":"Animator","price":10000},{"id":17857,"name":"Animator +1","price":50000},{"id":21392,"name":"Animator Z   (PUP, iLvl 119)","price":500000},{"id":21460,"name":"Matre Bell","price":10000},{"id":21463,"name":"Nepote Bell","price":250000}],"armor":[{"id":13402,"name":"Cassie Earring","price":250000},{"id":10293,"name":"Chocobo Shirt","price":50000},{"id":11811,"name":"Destrier Beret","price":50000},{"id":14724,"name":"Moldavite Earring","price":500000},{"id":13122,"name":"Miner's Pendant","price":50000},{"id":11009,"name":"Shaper's Shawl","price":100000},{"id":28509,"name":"She-Slime Earring","price":250000},{"id":28511,"name":"Slime Earring","price":250000}],"food":[{"id":6465,"name":"Behemoth Steak +1","price":2000},{"id":5177,"name":"Bream Sushi +1","price":2000},{"id":5925,"name":"Charred Salisbury Steak","price":2000},{"id":5167,"name":"Coeurl Sub +1","price":2000},{"id":5722,"name":"Crab Sushi +1","price":2000},{"id":5179,"name":"Dorado Sushi +1","price":2000},{"id":5666,"name":"Fin Sushi +1","price":2000},{"id":6344,"name":"Grape Daifuku +1","price":2000},{"id":6072,"name":"Magma Steak +1","price":2000},{"id":5744,"name":"Marinara Pizza +1","price":2000},{"id":5694,"name":"Octopus Sushi +1","price":2000},{"id":4301,"name":"Pear au Lait","price":2000},{"id":4303,"name":"Persikos au Lait","price":2000},{"id":5765,"name":"Red Curry Bun +1","price":2000},{"id":5664,"name":"Salmon Sushi +1","price":2000},{"id":5692,"name":"Shrimp Sushi +1","price":2000},{"id":5924,"name":"Smoldering Salisbury Steak","price":2000},{"id":5163,"name":"Sole Sushi +1","price":2000},{"id":6459,"name":"Soy Ramen +1","price":2000},{"id":5199,"name":"Spaghetti Carbonara +1","price":2000},{"id":5162,"name":"Squid Sushi +1","price":2000},{"id":6469,"name":"Sublime Sushi +1","price":2000},{"id":5216,"name":"Tentacle Sushi +1","price":2000},{"id":5160,"name":"Urchin Sushi +1","price":2000},{"id":4330,"name":"Witch Risotto","price":2000},{"id":5763,"name":"Yellow Curry Bun +1","price":2000}],"dice":[{"id":5502,"name":"Allies' Die       -> Allies' Roll","price":1},{"id":5505,"name":"Avenger's Die     -> Avenger's Roll","price":1},{"id":5486,"name":"Bard Die          -> Choral Roll","price":1},{"id":5485,"name":"Beastmaster Die   -> Beast Roll","price":1},{"id":5480,"name":"Black Mage Die    -> Wizard's Roll","price":1},{"id":5500,"name":"Blitzer's Die     -> Blitzer's Roll","price":1},{"id":5492,"name":"Blue Mage Die     -> Magus's Roll","price":1},{"id":5497,"name":"Bolter's Die      -> Bolter's Roll","price":1},{"id":5498,"name":"Caster's Die      -> Caster's Roll","price":1},{"id":5504,"name":"Companion's Die   -> Companion's Roll","price":1},{"id":5493,"name":"Corsair Die       -> Corsair's Roll","price":1},{"id":5499,"name":"Courser's Die     -> Courser's Roll","price":1},{"id":5495,"name":"Dancer Die        -> Dancer's Roll","price":1},{"id":5484,"name":"Dark Knight Die   -> Chaos Roll","price":1},{"id":5490,"name":"Dragoon Die       -> Drachen Roll","price":1},{"id":6368,"name":"Geomancer Die     -> Naturalist's Roll","price":1},{"id":5503,"name":"Miser's Die       -> Miser's Roll","price":1},{"id":5478,"name":"Monk Die          -> Monk's Roll","price":1},{"id":5489,"name":"Ninja Die         -> Ninja Roll","price":1},{"id":5483,"name":"Paladin Die       -> Gallant's Roll","price":1},{"id":5494,"name":"Puppetmaster Die  -> Puppet Roll","price":1},{"id":5487,"name":"Ranger Die        -> Hunter's Roll","price":1},{"id":5481,"name":"Red Mage Die      -> Warlock's Roll","price":1},{"id":6369,"name":"Rune Fencer Die   -> Runeist's Roll","price":1},{"id":5488,"name":"Samurai Die       -> Samurai Roll","price":1},{"id":5496,"name":"Scholar Die       -> Scholar's Roll","price":1},{"id":5491,"name":"Summoner Die      -> Evoker's Roll","price":1},{"id":5501,"name":"Tactician's Die   -> Tactician's Roll","price":1},{"id":5482,"name":"Thief Die         -> Rogue's Roll","price":1},{"id":5477,"name":"Warrior Die       -> Fighter's Roll","price":1},{"id":5479,"name":"White Mage Die    -> Healer's Roll","price":1}],"ammo":[{"id":21307,"name":"Achiyalabopa Arrow","price":100},{"id":21321,"name":"Achiyalabopa Bolt","price":100},{"id":21337,"name":"Achiyalabopa Bullet","price":100},{"id":18259,"name":"Angon","price":50},{"id":22308,"name":"Bayeux Bullet","price":50},{"id":21295,"name":"Beryllium Arrow","price":50},{"id":17319,"name":"Bone Arrow","price":2},{"id":17343,"name":"Bronze Bullet","price":2},{"id":17340,"name":"Bullet","price":3},{"id":21297,"name":"Chrono Arrow","price":50},{"id":21296,"name":"Chrono Bullet","price":50},{"id":26350,"name":"Chrono Bullet Pouch","price":50000},{"id":17336,"name":"Crossbow Bolt","price":2},{"id":18159,"name":"Demon Arrow","price":10},{"id":26349,"name":"Devastating Bullet Pouch","price":50000},{"id":21302,"name":"Eminent Arrow","price":50},{"id":21316,"name":"Eminent Bolt","price":50},{"id":21331,"name":"Eminent Bullet","price":50},{"id":26347,"name":"Eradicating Bullet Pouch","price":50000},{"id":17304,"name":"Fuma Shuriken","price":20},{"id":19197,"name":"Fusion Bolt","price":20},{"id":21353,"name":"Happo Shuriken","price":50},{"id":17320,"name":"Iron Arrow","price":3},{"id":17302,"name":"Juji Shuriken","price":5},{"id":17325,"name":"Kabura Arrow","price":20},{"id":26348,"name":"Living Bullet Pouch","price":50000},{"id":17303,"name":"Manji Shuriken","price":8},{"id":17337,"name":"Mythril Bolt","price":5},{"id":21311,"name":"Quelling Bolt","price":50},{"id":21310,"name":"Raetic Arrow","price":50},{"id":18155,"name":"Scorpion Arrow","price":5},{"id":17301,"name":"Shuriken","price":3},{"id":17341,"name":"Silver Bullet","price":8},{"id":18160,"name":"Spartan Bullet","price":5},{"id":18723,"name":"Steel Bullet","price":20},{"id":18258,"name":"Throwing Tomahawk","price":50}],"ninja":[{"id":5869,"name":"Toolbag (Cho)   -> 99x Chonofuda","price":1},{"id":6266,"name":"Toolbag (Furu)  -> 99x Furusumi","price":1},{"id":5312,"name":"Toolbag (Hira)  -> 99x Hiraishin","price":1},{"id":5867,"name":"Toolbag (Ino)   -> 99x Inoshishinofuda","price":1},{"id":5864,"name":"Toolbag (Jinko) -> 99x Jinko","price":1},{"id":5315,"name":"Toolbag (Jusa)  -> 99x Jusatsu","price":1},{"id":5863,"name":"Toolbag (Kaben) -> 99x Kabenro","price":1},{"id":5316,"name":"Toolbag (Kagi)  -> 99x Kaginawa","price":1},{"id":5310,"name":"Toolbag (Kawa)  -> 99x Kawahori","price":1},{"id":5318,"name":"Toolbag (Kodo)  -> 99x Kodoku","price":1},{"id":5311,"name":"Toolbag (Maki)  -> 99x Makibishi","price":1},{"id":5313,"name":"Toolbag (Mizu)  -> 99x Mizu","price":1},{"id":5866,"name":"Toolbag (Moku)  -> 99x Mokujin","price":1},{"id":6265,"name":"Toolbag (Ranka) -> 99x Ranka","price":1},{"id":5865,"name":"Toolbag (Ryuno) -> 99x Ryuno","price":1},{"id":5317,"name":"Toolbag (Sai)   -> 99x Sairui","price":1},{"id":5417,"name":"Toolbag (Sanja) -> 99x Sanjaku","price":1},{"id":5314,"name":"Toolbag (Shihe) -> 99x Shihei","price":1},{"id":5868,"name":"Toolbag (Shika) -> 99x Shikanofuda","price":1},{"id":5319,"name":"Toolbag (Shino) -> 99x Shinobi","price":1},{"id":5734,"name":"Toolbag (Soshi) -> 99x Soshi","price":1},{"id":5309,"name":"Toolbag (Tsura) -> 99x Tsurara","price":1},{"id":5308,"name":"Toolbag (Uchi)  -> 99x Uchitake","price":1}],"cards":[{"id":2176,"name":"Fire Card","price":50},{"id":2177,"name":"Ice Card","price":50},{"id":2178,"name":"Wind Card","price":50},{"id":2179,"name":"Earth Card","price":50},{"id":2180,"name":"Thunder Card","price":50},{"id":2181,"name":"Water Card","price":50},{"id":2182,"name":"Light Card","price":50},{"id":2183,"name":"Dark Card","price":50},{"id":2974,"name":"Trump Card","price":50}],"scrolls":[{"id":4181,"name":"Instant Warp","price":500},{"id":4182,"name":"Instant Reraise","price":500},{"id":5428,"name":"Instant Retrace","price":500},{"id":5988,"name":"Instant Protect","price":300},{"id":5989,"name":"Instant Shell","price":300},{"id":5990,"name":"Instant Stoneskin","price":300}],"crystals":[{"id":4096,"name":"Fire Crystal","price":100},{"id":4097,"name":"Ice Crystal","price":100},{"id":4098,"name":"Wind Crystal","price":100},{"id":4099,"name":"Earth Crystal","price":100},{"id":4100,"name":"Lightning Crystal","price":100},{"id":4101,"name":"Water Crystal","price":100},{"id":4102,"name":"Light Crystal","price":200},{"id":4103,"name":"Dark Crystal","price":200},{"id":4104,"name":"Fire Cluster","price":500},{"id":4105,"name":"Ice Cluster","price":500},{"id":4106,"name":"Wind Cluster","price":500},{"id":4107,"name":"Earth Cluster","price":500},{"id":4108,"name":"Lightning Cluster","price":500},{"id":4109,"name":"Water Cluster","price":500},{"id":4110,"name":"Light Cluster","price":1000},{"id":4111,"name":"Dark Cluster","price":1000}],"keys":[{"id":1042,"name":"Davoi Coffer Key","price":5000},{"id":1043,"name":"Beadeaux Coffer Key","price":5000},{"id":1044,"name":"Oztroja Coffer Key","price":5000},{"id":1045,"name":"Nest Coffer Key","price":5000},{"id":1046,"name":"Eldieme Coffer Key","price":5000},{"id":1047,"name":"Garlaige Coffer Key","price":5000},{"id":1048,"name":"Zvahl Coffer Key","price":5000},{"id":1049,"name":"Uggalepih Coffer Key","price":5000},{"id":1050,"name":"Den Coffer Key","price":5000},{"id":1051,"name":"Kuftal Coffer Key","price":5000},{"id":1052,"name":"Boyahda Coffer Key","price":5000},{"id":1053,"name":"Cauldron Coffer Key","price":5000},{"id":1054,"name":"Quicksand Coffer Key","price":5000},{"id":1057,"name":"Toraimarai Coffer Key","price":5000},{"id":1058,"name":"Ru'Aun Coffer Key","price":5000},{"id":1060,"name":"Ve'Lugannon Coffer Key","price":5000}],"pets_jugs":[{"id":21446,"name":"Airy Broth","price":1000},{"id":17922,"name":"Blackwater Broth","price":1000},{"id":17917,"name":"Bubbly Broth","price":1000},{"id":21498,"name":"Crackling Broth","price":1000},{"id":21493,"name":"Deepwater Broth","price":1000},{"id":21449,"name":"Dire Broth","price":1000},{"id":21450,"name":"Electrified Broth","price":1000},{"id":21496,"name":"Furious Broth","price":1000},{"id":21441,"name":"Glazed Broth","price":1000},{"id":21495,"name":"Heavenly Broth","price":1000},{"id":21444,"name":"Livid Broth","price":1000},{"id":17902,"name":"Lucky Broth        -> CourierCarrie (crab): Metallic Body, heavy PDT","price":1000},{"id":21445,"name":"Lyrical Broth","price":1000},{"id":21497,"name":"Rapid Broth","price":1000},{"id":21440,"name":"Sugary Broth","price":1000},{"id":21494,"name":"Wetlands Broth","price":1000}],"pets_food":[{"id":17016,"name":"Pet Food Alpha Biscuit","price":500},{"id":17017,"name":"Pet Food Beta Biscuit","price":500},{"id":17019,"name":"Pet Food Delta Biscuit","price":500},{"id":17020,"name":"Pet Food Epsilon Biscuit","price":500},{"id":17022,"name":"Pet Food Eta Biscuit","price":500},{"id":17018,"name":"Pet Food Gamma Biscuit","price":500},{"id":17023,"name":"Pet Food Theta Biscuit","price":500},{"id":17021,"name":"Pet Food Zeta Biscuit","price":500},{"id":19251,"name":"Pet Roborant","price":500},{"id":19252,"name":"Pet Poultice","price":500}],"reforge":[]};
const L={"general":"General","consumables":"Consumables","weapons":"Weapons","armor":"Armor","food":"Food","dice":"COR Dice","ammo":"Ammo","ninja":"Ninja Tools","cards":"COR Cards","scrolls":"Scrolls","crystals":"Crystals","keys":"Keys","pets_jugs":"BST Pets","pets_food":"BST Pet Food","reforge":"Reforge Claim"};
const N={"general":"Rings, potions, and everyday convenience items.","consumables":"Full consumable stack — potions, ethers, Elixirs, and utility items.","weapons":"Leveling and endgame weapons across all weapon types, including GEO handbells and PUP Animators.","armor":"Earrings, belts, capes, and utility armor pieces.","food":"Best-in-slot endgame food for every role. All items are 2,000 gil.","dice":"All 32 Phantom Roll dice at 1 gil each. Using a die on a Corsair of the right level teaches that roll permanently.","ammo":"Arrows, bolts, bullets, waist bullet pouches (infinite-ammo / RECYCLE 100), throwing weapons, and shuriken. Leveling ladder plus Lv99 endgame options.","ninja":"All ninja toolbags at 1 gil each. One purchase gives 99 charges of that tool. Toolbags stack to 12 (≈1,188 charges per slot). The three card toolbags (Ino/Shika/Cho) can substitute for ANY elemental ninjutsu on a main-job NIN.","cards":"Corsair Quick Draw cards — one of each element, plus Trump Card. Consumed on Quick Draw, so keep a stack. 50 gil each.","scrolls":"Instant scrolls — self Warp, Reraise, and Retrace, plus instant Protect / Shell / Stoneskin.","crystals":"Elemental crafting crystals (100–200 gil) and clusters (500–1,000 gil), one of each element.","keys":"Dungeon coffer keys for the ??? coffers — niche treasure-hunting convenience. 5,000 gil each.","pets_jugs":"Jug broths for Beastmaster. Buy a broth, then use Call Beast or Bestial Loyalty to summon the pet. Pet food is on a separate sub-page (!shop pets food).","pets_food":"Pet food biscuits (Alpha through Theta) to heal and feed your jug pet.","reforge":"Free one-time claim of your current main job's ilvl-109 Artifact, Relic, and Empyrean armor sets. One claim per job per set — switch jobs and re-run for another job's gear."};
const O=["general","consumables","weapons","armor","food","dice","ammo","ninja","cards","scrolls","crystals","keys","pets_jugs","pets_food","reforge"];
let cur=O[0];

function gil(p){
  if(p===0)return'Free';
  if(p===1)return'1 gil';
  return p.toLocaleString()+'&thinsp;gil';
}
function link(id,name){
  if(!id)return name;
  return`<a class="item-link" href="https://www.ffxiah.com/item/${id}" data-img="https://static.ffxiah.com/images/icon/${id}.png" target="_blank" rel="noopener">${name}</a>`;
}
function table(rows){
  if(!rows.length)return'<p class="st-empty">No items.</p>';
  return'<table class="st-tbl"><thead><tr><th>Item</th><th>Price</th></tr></thead><tbody>'
    +rows.map(r=>`<tr><td>${link(r.id,r.name)}</td><td class="st-price">${gil(r.price)}</td></tr>`).join('')
    +'</tbody></table>';
}
function noteBox(cat){
  return N[cat]?`<div class="st-note">${N[cat]}</div>`:'';
}
function reforgePanel(){
  return`<div class="st-reforge">
    <p>Claim your current main-job ilvl-109 armor sets for free — one set per job, per category:</p>
    <table class="st-tbl" style="width:auto;max-width:500px"><thead><tr><th>Command</th><th>What you get</th></tr></thead><tbody>
    <tr><td><code>!shop reforge af</code></td><td>Artifact set (5 pieces)</td></tr>
    <tr><td><code>!shop reforge relic</code></td><td>Relic set (5 pieces)</td></tr>
    <tr><td><code>!shop reforge empy</code></td><td>Empyrean set (5 pieces)</td></tr>
    <tr><td><code>!shop reforge all</code></td><td>All three sets (15 pieces)</td></tr>
    </tbody></table>
    <p style="margin-top:10px;font-size:13px;color:#7878a0">Switch to a different main job and re-run to claim that job's set.</p>
  </div>`;
}
function render(cat,q){
  const items=(D[cat]||[]).filter(r=>!q||r.name.toLowerCase().includes(q));
  let html=noteBox(cat);
  html+=cat==='reforge'?reforgePanel():table(items);
  document.getElementById('st-body').innerHTML=html;
}
function stFilter(){
  const q=document.getElementById('st-q').value.trim().toLowerCase();
  if(!q){render(cur,'');return;}
  let html='';
  for(const cat of O){
    const rows=(D[cat]||[]).filter(r=>r.name.toLowerCase().includes(q));
    if(!rows.length)continue;
    html+=`<div class="st-section"><div class="st-section-hdr">${L[cat]}</div>${table(rows)}</div>`;
  }
  document.getElementById('st-body').innerHTML=html||'<p class="st-empty">No items match.</p>';
}
document.querySelectorAll('.st-tab').forEach(b=>b.addEventListener('click',()=>{
  cur=b.dataset.cat;
  document.querySelectorAll('.st-tab').forEach(t=>t.classList.toggle('active',t===b));
  document.getElementById('st-q').value='';
  render(cur,'');
}));
render(cur,'');
})();
</script>
<style>
.st-wrap{font-family:inherit;}
.st-bar{margin-bottom:10px;}
.st-bar input{width:100%;max-width:320px;padding:7px 12px;background:#0b0d1a;border:1px solid #252840;border-radius:20px;color:#d2d2dc;font-size:13px;outline:none;}
.st-bar input:focus{border-color:#6e37d2;}
.st-tabs{display:flex;flex-wrap:wrap;gap:5px;margin-bottom:14px;}
.st-tab{padding:5px 13px;border-radius:20px;border:1px solid #252840;background:#14162a;color:#7878a0;font-size:12px;cursor:pointer;transition:all .15s;}
.st-tab.active,.st-tab:hover{background:#6e37d2;border-color:#6e37d2;color:#fff;}
.st-note{background:#14162a;border-left:3px solid #6e37d2;padding:8px 14px;border-radius:0 4px 4px 0;margin-bottom:12px;font-size:13px;color:#9090b8;line-height:1.5;}
.st-tbl{width:100%;border-collapse:collapse;font-size:13px;}
.st-tbl thead th{text-align:left;padding:5px 10px;border-bottom:1px solid #252840;color:#6e37d2;font-size:11px;text-transform:uppercase;letter-spacing:.07em;}
.st-tbl tbody tr{border-bottom:1px solid #161830;}
.st-tbl tbody tr:hover{background:#14162a;}
.st-tbl td{padding:6px 10px;}
.st-tbl td a{color:#c8aaff;text-decoration:none;}
.st-tbl td a:hover{text-decoration:underline;}
.st-price{text-align:right;color:#f0c84a;font-variant-numeric:tabular-nums;white-space:nowrap;}
.st-section{margin-bottom:20px;}
.st-section-hdr{font-size:11px;color:#6e37d2;text-transform:uppercase;letter-spacing:.07em;font-weight:600;margin-bottom:6px;padding-bottom:4px;border-bottom:1px solid #252840;}
.st-empty{color:#50507a;font-style:italic;padding:16px 0;}
.st-reforge{background:#14162a;border-radius:6px;padding:16px 20px;color:#9090b8;line-height:1.6;}
.st-reforge code{background:#0b0d1a;padding:2px 7px;border-radius:3px;font-size:12px;color:#d2d2dc;}
</style>
<!-- DOCGEN:END id="shop-catalog" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: ee2f0181c1ed -->
_Last updated: 2026-07-15 11:36 PDT_
<!-- DOCGEN:END id="last-updated" -->
