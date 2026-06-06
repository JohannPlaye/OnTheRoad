# Contexte projet — OnTheRoad

## Projet
Application iOS native **OnTheRoad** de suivi kilométrique pour remboursements professionnels.
- Nom du bundle : `Surferjo-Project.OnTheRoad`
- Swift 5.0, iOS deployment target : 26.4
- Version : 1.0
- Démarré le 06/06/2026

## Utilisateur
- Johann (johannplaye@gmail.com)
- Langue : **français** — toujours répondre en français
- Style : concis, direct, sans verbosité inutile

## Architecture cible
App iOS SwiftUI, **100 % hors-ligne**, pas de cloud, pas de backend.

### Vues prévues
- `HomeView` — bouton central prominent (action principale visuelle) pour démarrer un trajet → navigue vers `TripView`. Boutons secondaires en bas vers HistoryView, StatisticsView, ExportView
- `TripView` — carte temps réel avec point de position courante animé + tracé polyline du chemin parcouru depuis le départ, contrôles Pause/Resume/Stop. Après Stop : modal de saisie du motif (optionnel), enregistrement automatique avec horodatage YYYY/MM/DD-HH:mm:ss départ/arrivée. Animation feu d'artifice native iOS après validation
- `HistoryView` — historique filtrable par période (Aujourd'hui / Cette semaine / Ce mois / Personnalisé), groupé par jour
- `TripDetailView` — détail d'un trajet : carte avec tracé GPS complet stocké, stats (durée, distance, vitesse moyenne), export/suppression
- `StatisticsView` — métriques globales (distance totale, nombre de trajets, durée cumulée, moyenne par jour) + détail jour par jour
- `ExportView` — CSV compatible Excel FR (UTF-8 BOM, délimiteur `;`) avec : horodatage départ/arrivée, motif, km parcourus, coordonnées GPS départ et arrivée

### Modèle de données (par trajet)
| Champ | Type | Req |
|---|---|---|
| Date | Date | ✅ |
| Heure départ / arrivée | Heure | ✅ |
| Durée | Calculée | ✅ |
| Distance réelle (km) | Calculée | ✅ |
| Tracé GPS complet | [CLLocationCoordinate2D] | ✅ (stocké, pas exporté) |
| Coordonnée GPS départ | CLLocationCoordinate2D | ✅ |
| Coordonnée GPS arrivée | CLLocationCoordinate2D | ✅ |
| Motif | String? | ❌ |

### Contraintes techniques
- Enregistrement GPS en **background** (même si Waze / CarPlay en premier plan)
- Permissions GPS demandées via le dialogue système iOS natif (pas d'écran d'onboarding custom)
- CarPlay : **hors scope v1**, mais l'architecture doit permettre son ajout sans refonte (ViewModels découplés des vues)
- Pas de dépendances externes si possible (privilégier frameworks Apple natifs)
- Persistance locale : **CoreData** (migration vers SwiftData possible plus tard)

## État actuel
- Premier build réussi (projet Xcode initialisé)
- `ContentView.swift` : placeholder "Hello, world!" — tout reste à construire
- `OnTheRoadApp.swift` : entry point standard SwiftUI

## Conventions de code
- SwiftUI pour toutes les vues
- Architecture MVVM
- Commentaires et noms de variables en **anglais** dans le code, UI en **français**

## Design
Style **glassmorphism dark** (référence : https://dribbble.com/shots/27240139)

- Background : bleu très foncé (type `#050D1A` / `#0A1628`)
- Cards : effet verre dépoli (`ultraThinMaterial`), coins très arrondis (`cornerRadius: 20+`), bords légèrement lumineux
- Textes et icônes : couleurs lumineuses et contrastées — blancs, mauves (`#C084FC`, `#A855F7`), verts acidulés (`#4ADE80`, `#22D3EE`)
- Accents : dégradés subtils violet→cyan
- Pas de couleurs plates ternes — tout doit ressortir sur le fond sombre