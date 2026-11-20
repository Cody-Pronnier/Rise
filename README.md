# Rise — Godot 4.7 + GodotSteam

8 joueurs, chacun sur son terrain : son personnage combat automatiquement 3 monstres.
On joue ses cartes de classe (usage unique par manche) sur n'importe quel terrain pour s'aider ou gêner les autres.
La manche se termine quand 7 joueurs ont fini ; points selon l'ordre d'arrivée (8, 7, … 2), 0 pour le dernier.

## Lancer

1. Ouvre le dossier dans Godot 4.7.2 et installe **GodotSteam GDExtension** (AssetLib), puis redémarre l'éditeur.
2. **Entraînement (contre des bots)** depuis le menu : choisis une classe, tu joues contre 7 bots. Ça fonctionne même sans Steam lancé.
3. **Jouer en ligne** : menu → salon Steam (le lancement réseau de la manche sera l'étape suivante).

## Commandes en combat

- Onglets en haut : un par joueur (progression, rang). Clique pour voir son terrain.
- Clique une carte, puis :
  - carte « une unité » → clique le personnage, un compagnon ou le monstre du terrain affiché ;
  - carte « un joueur » / « tout un terrain » → clique n'importe où sur le terrain affiché ;
  - carte « ton terrain » → elle part tout de suite.
- Clic droit ou Échap : annule la sélection.

## Architecture

```
core/                      Logique pure (RefCounted / Resource), aucun nœud, aucune UI
  combat/                  CombatUnit, StatusContainer, Field, DamageCalculator, MonsterRoster, CombatConfig
  cards/                   CardData, CardEffect (+ effects/), CardPlayService, CardTarget, CardContext
  classes/                 Une classe = un fichier (PriestClass, MageClass…), StatusLibrary, ClassCatalog
  match/                   CombatRound, PlayerState, RoundScoring, BotPlayer, LocalMatchFactory
autoloads/
  match_service.gd         Fait tourner la manche et reçoit les cartes du joueur local
  steam_service.gd, lobby_*.gd   (inchangés)
ui/components/combat/      UnitView, ArenaView, FieldTabBar/FieldTab, HandView/CardView, RoundResultPanel
ui/screens/                class_select/, combat/ (+ écrans existants)
```

Règles suivies :

- **La simulation ne connaît pas l'UI.** `CombatRound` → `Field` → `CombatUnit` émettent des signaux ; les vues écoutent et n'écrivent jamais dans la simulation.
- **Une seule porte d'entrée pour jouer une carte** : `CombatRound.play_card(caster_id, card, target)`, qui valide (`CardPlayService`) puis résout. Les bots et le joueur passent par le même chemin. C'est ce qui rend le réseau simple à ajouter : l'hôte simule, les clients lui envoient leurs `play_card`.
- **Les cartes sont des données.** Une carte = `CardData` + une liste de `CardEffect`. Pour ajouter une carte, une ligne dans le fichier de la classe ; pour un nouveau comportement, une nouvelle sous-classe de `CardEffect`.
- **Les statuts sont des données** (`StatusData` : durée, catégorie, drapeaux, multiplicateurs). Saignement = DoT + soins reçus ×0.5, Bouclier = immunité, etc.
- **Équilibrage centralisé** : `CombatConfig`, `StatusLibrary`, stats des personnages dans chaque fichier de classe, monstres dans `MonsterRoster`.

## Choix d'interprétation à valider

- **Trappe** : la cible renvoie les dégâts d'attaque reçus vers son attaquant pendant 5 s.
- **Duel pour l'honneur** : le terrain ciblé devient inciblable par les cartes adverses pendant 10 s (comme Invisibilité, mais la progression reste visible).
- **Invisibilité** : ton terrain est inciblable et ta progression affichée « ??? » pendant 12 s.
- **Mort du personnage** : il réapparaît avec tous ses PV après 5 s ; le monstre garde ses dégâts.
- **Compagnon** : un loup qui attaque le monstre et encaisse les coups à la place du personnage.
- **Cartes de dégâts** : montants fixes, non influencés par les buffs du personnage.

## Prochaines étapes

1. Réseau : `MatchService.start_online_match()` + messages Steam P2P (hôte autoritaire).
2. Enchaînement des manches (max 3), choix de classe et achat de cartes d'autres classes contre points ou temps d'attente.
3. Échanges de cartes et alliances.
