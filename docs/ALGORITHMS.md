# Documentation Algorithmique : Escalier Axe Oblique

Ce document détaille la logique mathématique et algorithmique utilisée pour la génération automatique des escaliers dans le plugin. L'objectif est de transformer des paramètres d'ouverture (largeur, longueur, hauteur) en une géométrie 3D précise.

## 1. Concepts Fondamentaux

Le plugin génère un composant SketchUp qui contient un composant pour le poteau et autant de composants qu'il y a de marches. Les marches sont définies par un polygone reliant des points clés ($C1$ à $C5$), garantissant la continuité structurelle entre les marches et les poteaux.

### Paramètres d'entrée
- $W, L, H$ : Largeur, Longueur et Hauteur de l'ouverture.
- $N$ : Nombre de marches.
- $\theta_{total}$ : Angle de rotation total.
- $z_{marche}$ : Hauteur cumulative de la marche actuelle ($\frac{H}{N} \times i$).

---

## 2. Logique de Génération : Diagonales Larges (Large Diagonals)

L'algorithme des "Large Diagonals" utilise une approche trigonométrique basée sur un cercle imaginaire centré au milieu de l'ouverture.

### A. Calcul du point cible ($C2$)
Contrairement aux escaliers classiques, le point $C2$ (le bord extérieur de la marche) est calculé sur un cercle dont le rayon $R$ correspond à la demi-ouverture.

$$\theta_i = \text{start\_angle} + (i \times \frac{\theta_{total}}{N})$$
$$X_{C2} = \text{center\_x} + R \cdot \cos(\theta_i)$$
$$Y_{C2} = \text{center\_y} + R \cdot \sin(\theta_i)$$
$$Z_{C2} = z_{marche}$$

### B. Intersection avec le rectangle ($C3$)
Le point $C3$ est le point de contact réel de la marche avec le bord de l'ouverture. Il est calculé comme l'intersection du segment $[C1, C2]$ avec les limites du rectangle $[0, W] \times [0, L]$.

L'algorithme `intersect-with-box` utilise l'équation paramétrique du segment :
$$P(t) = C1 + t \cdot (C2 - C1), \quad t \in [0, 1]$$
On recherche la plus petite valeur de $t > 0$ pour laquelle $P(t)$ touche une arête du rectangle.

---

## 3. Topologie de la Marche (Le Polygone)

Chaque marche est un volume dont la face supérieure est définie par un polygone fermé.

### Les 5 points de contrôle :
- **$C1$** : Point d'ancrage sur le poteau actuel.
- **$C2$** : Point guide trigonométrique (utilisé pour le calcul, pas forcément dans le polygone).
- **$C3$** : Intersection de la marche actuelle avec le bord de l'ouverture.
- **$C4$** : Intersection de la marche suivante avec le bord de l'ouverture.
- **$C5$** : Point d'ancrage sur le poteau suivant.

### Gestion des coins (Corner Logic)
Si $C3$ et $C4$ ne se trouvent pas sur la même arête du rectangle, l'algorithme insère un **point de coin** (le sommet du rectangle) entre $C3$ et $C4$. Cela évite que la marche ne "coupe" le vide et assure qu'elle suit parfaitement le contour de l'ouverture.

**L'ordre des points du polygone :**
$$C1 \rightarrow C3 \rightarrow (\text{Coin optionnel}) \rightarrow C4 \rightarrow C5 \rightarrow C1$$

---

## 4. Génération du Volume (Manuel PushPull)

Pour garantir la compatibilité et la stabilité dans SketchUp 2020, le volume n'est pas créé via `pushpull`, mais par la construction manuelle de faces :

1. **Face Supérieure :** Créée à partir du polygone $[C1, C3, \dots, C5]$.
2. **Face Inférieure :** Copie de la face supérieure décalée de $-\text{thickness}$ sur l'axe Z.
3. **Faces Latérales :** Création de faces verticales reliant chaque segment de la face supérieure à son correspondant sur la face inférieure.

---

## 5. Règles de Rotation et Indexation

### Sens de rotation
- **Clockwise (CW) :** Départ à $-\pi/2$, direction $-1$.
- **Anti-clockwise (ACW) :** Départ à $0.0$, direction $+1$.

### Indexation circulaire
Pour assurer la fermeture de l'escalier (la dernière marche se connectant à la première), le plugin utilise l'opérateur modulo :
$$\text{index\_suivant} = (i + 1) \pmod N$$

### Position des poteaux
Le poteau est désynchronisé de l'index de rotation pour optimiser le support structurel :
$$\text{post\_idx} = (i - 2) \pmod N$$
