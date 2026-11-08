# Documentation Algorithmique : Escalier Axe Oblique

Ce document détaille la logique mathématique et algorithmique utilisée pour la génération automatique des escaliers dans le plugin. 

## 1. Concepts Fondamentaux

Le plugin génère un composant SketchUp qui contient un composant pour le poteau et autant de composants qu'il y a de marches. Les marches sont définies par un polygone reliant des points clés ($C1$ à $C5$), garantissant la continuité structurelle entre les marches et les poteaux.

### Paramètres d'entrée

- $W, L, H$ : Largeur, Longueur et Hauteur de l'ouverture.
- $N$ : Nombre de marches.
- $\theta_{total}$ : Angle de rotation total.
- $z_{i}$ : Hauteur cumulative de la marche actuelle, soit $\frac{H}{N} \times i$ (variable `z_marche` dans le code).

---

## 2. Logique de Génération : Diagonales Larges (Large Diagonals)

L'algorithme des « Large Diagonals » utilise une approche trigonométrique basée sur un cercle imaginaire centré au milieu de l'ouverture.

### A. Calcul du point cible ($C2$)

Contrairement aux escaliers classiques, le point $C2$ (le bord extérieur de la marche) est calculé sur un cercle dont le rayon $R$ correspond à la demi-ouverture.

Dans les formules ci-dessous, $\theta_{debut}$ correspond à `start_angle` et $(x_c, y_c)$ correspond à `center_x` et `center_y`.

$$\theta_i = \theta_{debut} + \left(i \times \frac{\theta_{total}}{N}\right)$$

$$X_{C2} = x_c + R \cdot \cos(\theta_i)$$

$$Y_{C2} = y_c + R \cdot \sin(\theta_i)$$

$$Z_{C2} = z_{i}$$

### B. Intersection avec le rectangle ($C3$)

Le point $C3$ est le point de contact réel de la marche avec le bord de l'ouverture. Il est calculé comme l'intersection du segment $[C1, C2]$ avec les limites du rectangle $[0, W] \times [0, L]$.

L'algorithme `intersect-with-box` utilise l'équation paramétrique du segment :

$$P(t) = C1 + t \cdot (C2 - C1), \quad t \in [0, 1]$$

On recherche la plus petite valeur de $t > 0$ pour laquelle $P(t)$ touche une arête du rectangle.

---

## 3. Topologie de la Marche (Polygone)

Chaque marche est un volume dont la face supérieure est définie par un polygone fermé.

### Les 5 points de contrôle

- **$C1$** : Point d'ancrage sur le poteau actuel.
- **$C2$** : Point guide trigonométrique (utilisé pour le calcul, pas forcément dans le polygone).
- **$C3$** : Intersection de la marche actuelle avec le bord de l'ouverture.
- **$C4$** : Intersection de la marche suivante avec le bord de l'ouverture.
- **$C5$** : Point d'ancrage sur le poteau suivant.

### Gestion des coins (Corner Logic)

Si $C3$ et $C4$ ne se trouvent pas sur la même arête du rectangle, l'algorithme insère un **point de coin** (le sommet du rectangle) entre $C3$ et $C4$. Cela évite que la marche ne « coupe » le vide et assure qu'elle suit parfaitement le contour de l'ouverture.

**L'ordre des points du polygone :**

$$C1 \rightarrow C3 \rightarrow (\text{Coin optionnel}) \rightarrow C4 \rightarrow C5 \rightarrow C1$$

---

## 4. Génération du Volume (Manuel PushPull)

Pour garantir la compatibilité et la stabilité dans SketchUp 2020, le volume n'est pas créé via `pushpull`, mais par la construction manuelle de faces :

1. **Face Supérieure :** Créée à partir du polygone $[C1, C3, \dots, C5]$.
2. **Face Inférieure :** Copie de la face supérieure décalée de $-e$ sur l'axe Z, où $e$ correspond à `thickness`.
3. **Faces Latérales :** Création de faces verticales reliant chaque segment de la face supérieure à son correspondant sur la face inférieure.

---

## 5. Règles de Rotation et Indexation

### Sens de rotation

- **Clockwise (CW) :** Départ à $-\pi/2$, direction $-1$.
- **Anti-clockwise (ACW) :** Départ à $0.0$, direction $+1$.

### Indexation circulaire

Pour assurer la fermeture de l'escalier (la dernière marche se connectant à la première), le plugin utilise l'opérateur modulo :

$$i_{suivant} = (i + 1) \bmod N$$

(variable `index_suivant` dans le code)

### Position des poteaux

Le poteau est désynchronisé de l'index de rotation pour optimiser le support structurel :

$$i_{poteau} = (i - 2) \bmod N$$

(variable `post_idx` dans le code)
