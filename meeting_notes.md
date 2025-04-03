## Réunion 03/03/2025

**Présents**: Bienvenu Amani, Beatriz Bellon, Clovis Grinand, Larissa Houphouet, Evans Ehouman, Camille Piponiot

-   Présentation par Amani de l'état du travail sur la cartographie du C du sol (terrain, constitution d'une base de données, modèle randomForest et choix des variables)

-   Clovis: ne pas faire de sélection de variable dans RandomForest (sauf si un nombre trop important de variables par rapport aux points de calibration, ce qui n'est pas le cas) car modèle plutôt robuste à l'overfitting et aux variables colinéaires.

-   Choix des variables: possible redondance des données SoilGrids car inclue C du sol; occupation du sol: ne pas utiliser carte du BNEDT (seulement 2 dates) mais plutôt des produits de télédétection avec meilleure résolution temporelle ou dérivés (par exemple métriques temporelles à partir de TMF) ;

-   Importance du choix de l'échelle car conditionne le choix des variables auxiliaires. Dépend entre autres de la résolution des données de terrain, par exemple la taille et la distance entre les parcelles au sein d'un site.

-   Organisation du travail: tout le monde est OK pour collaborer sur github (ou gitlab) pour les codes; la base de données sol sera versée sur un dataverse; les données auxiliaires seront soit téléchargées avec les codes soit partagées en transfert interne et sauvegardées localement.

-   Maintenir un rythme d'une à deux réunions par mois pour garder la dynamique de travail.

-   Prochaines étapes:

    -   Coordination: Amani et Camille (organisation des réunions, etc)

    -   Prochaine réunion début avril (date à définir avec un doodle)

    -   d'ici là Camille et Amani préparent les codes d'Amani pour les partager sur github, et Clovis et Bea préparent une liste de variables auxiliaires; Evans finit d'ajouter les données de Mébifon à la base de données sol.

## Réunion 02/04/2025

**Présents**: Bienvenu Amani, Beatriz Bellon, Clovis Grinand, Evans Ehouman, Blandine Ahou Koffi, Camille Piponiot, Larissa Houphouet

-   Présentation du dépot github t4s_soc_map (organisation, codes); ajout de contributeurs au dépot, et besoin de refaire une réunion pour prendre en main l'outil une fois que tout le monde aura connecté Rstudio à son github.

-   Proposition d'Evans: Faire la liste des taches et calendrier prévisionnel, avec une deadline (fin 2025)

-   Presentation du travail réalisé par Beatriz

-   priorité #1 = mettre au propre les données:

    -   il manque des coordonnées (et extraction des variables spatiales en dépend)

    -   taille des parcelles très hétérogène -\> à vérifier (importance d'avoir un protocole homogène: quel a été le protocole?)

    -   importance d'avoir de la précision sur la taille et coordonnées des parcelles pour définir l'échelle des variables spatialisées

    -   vérifier données stocks de C par profondeur (doivent diminuer)

-   Beatriz n'a pas eu le temps de tout présenter: elle enverra sa présentation à tous avec un lien google drive, et finira la présentation à la prochaine réunion

-   réunions régulières un mercredi sur deux de 11h à 12h (prochaine: 18/04/2025)
