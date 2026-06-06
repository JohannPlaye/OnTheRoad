# OnTheRoad 🚗

Application iOS native de suivi kilométrique pour remboursements professionnels.

---

## Contexte

Application personnelle destinée à une professionnelle itinérante se déplaçant quotidiennement en voiture. Elle utilise son iPhone en voiture avec CarPlay et Waze en parallèle. L'app enregistre les trajets réels (tracé GPS exact) en arrière-plan, même lorsqu'une autre application est au premier plan.

**OnTheRoad fonctionne entièrement hors-ligne** et ne synchronise aucune donnée dans le cloud.

---

## Fonctionnalités prévues

### 🏠 Nouveau trajet (HomeView)
- Interface intuitive avec état GPS en temps réel
- Bouton Démarrer avec vérification automatique des permissions
- Carte temps réel pendant le tracking avec tracé GPS progressif
- Contrôles : Pause ⏸️ / Resume ▶️ / Stop ⏹️
- Affichage live : distance, durée, vitesse, nombre de points GPS
- Modal de fin avec saisie optionnelle du motif
- Statistiques du jour : nombre de trajets et distance totale

### 📋 Historique (HistoryView)
- Filtrage : Tous, Aujourd'hui, Cette semaine, Ce mois, Personnalisé
- Navigation vers les détails complets de chaque trajet
- Résumés automatiques par période sélectionnée
- Interface groupée par jour

### 📊 Détails des trajets (TripDetailView)
- Carte avec tracé GPS et annotations début/fin
- Statistiques : durée, vitesse moyenne, précision GPS
- Actions : export individuel, suppression

### 📈 Statistiques (StatisticsView)
- Vue d'ensemble : trajets totaux, distance, durée, moyennes
- Détails jour par jour

### 📤 Export (ExportView)
- Export CSV résumé (1 ligne par trajet)
- Export CSV détaillé (tous les points GPS)
- Compatibilité Excel : UTF-8 + BOM, délimiteur français (`;`)
- Partage natif iOS : Mail, AirDrop, iCloud Drive, Fichiers

---

## Données enregistrées par trajet

| Champ | Type | Obligatoire |
|---|---|---|
| Date | Date | ✅ |
| Heure de départ | Heure | ✅ |
| Heure d'arrivée | Heure | ✅ |
| Durée | Calculée | ✅ |
| Distance réelle | Calculée (km) | ✅ |
| Tracé GPS | Tableau de coordonnées | ✅ |
| Motif | Texte libre | ❌ Facultatif |
