# projet-oz plus jamais je vais sur superprof je vois ta gueule partout

- [projet-oz plus jamais je vais sur superprof je vois ta gueule partout](#projet-oz-plus-jamais-je-vais-sur-superprof-je-vois-ta-gueule-partout)
  - [Objectif](#objectif)
  - [Impératif](#impératif)
  - [Info fichier et fonction](#info-fichier-et-fonction)
  - [Truc en plus pour le fun](#truc-en-plus-pour-le-fun)
  - [Ref](#ref)
  - [Fonctionnement N-Gramme](#fonctionnement-n-gramme)
  - [Définition](#définition)
  - [Implémentation](#implémentation)


## Objectif
* 2-gramme fonctionnel donc prend en compte 2 mots
* Multi-Thread
* Faire des tests "unitaires"
* Rapport de 2 pages qui décrit les extensions utilisées, et les infos utiles

## Impératif
*Deadline le 1 mai* et s'inscrire au groupe **Inginious**

Structure déclarative donc *sans cellule*

## Info fichier et fonction
Attention, on ne feed pas le *buffer*, on compile

## Truc en plus pour le fun
* N-gramme
* Optimiser
* faire du scrapping pour mettre à jour la base de donnée
* Créer un bot twitter qui tweet comme elon musk

## Ref
[pour les interfaces graphiques](http://mozart2.org/mozart-v1/doc-1.4.0/mozart-stdlib/wp/qtk/html/)

## Fonctionnement N-Gramme

[Un N-gramme](https://fr.wikipedia.org/wiki/N-gramme)
Donc ce sont des statistiques tel que $P(x|ab) = \frac{P(x)}{P(ab)} = \frac{P(x)}{\Sigma_{X\in\{a,b,...,c\}} P(abX)}$

On a aussi l'équation: $P(w_{1,k})=P(w_{1})\times P(w_{2}|w_{1})\times P(w_{3}|w_{1},w_{2})\times ...\times P(w_{k}|w_{1},w_{2}...w_{k-1})$ et comme on est en $k=3$ car on veut prédire un troisième mot à partir de 2 donc $P(w_{1,k})=P(w_{1})\times P(w_{2}|w_{1})\times P(w_{3}|w_{1},w_{2})$

[Pour approximer et Justifier](https://www.iro.umontreal.ca/~nie/IFT6255/modele_langue.pdf) On peut en tirer une formule (là même mais c'est plus clair) $P(s) = \Pi P(m_i|m_{i-1}) = \Pi\frac{P(m_{i-1}m_{i})}{P(m_{i-1})}$ Donc pour une phrase $s$ on mulitplie la probabilité du mot actuel $m_i$ par la probabilité du mot précédent $m_{i-1}$

Comme nous disposons d'un large dataset, on peut estimer la probabilité d'un mot selon le précédent comme une constante s'il on veut.

[Référence d'un bouqin](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwjP4sCynJH-AhWZgP0HHTynAu0QFnoECCsQAQ&url=https%3A%2F%2Fwww.foo.be%2Fcours%2Fdess-20122013%2Fb%2FNatural%2520Language%2520Processing%2520with%2520Python%2520-%2520O%27Reilly2009.pdf&usg=AOvVaw3USAS04By7RstJc66n5WiL) Important de train les données à l'avance, une idée: structurer en PICKLE (j'ai vu ça dans le bouquin et c'est pris en charge en [Oz](http://mozart2.org/mozart-v1/doc-1.4.0/system/node57.html#chapter.pickle))

On va utiliser des *Bytes-string* qui est plus efficace d'un facteur 8

## Définition

* **Corpus**: le dataset sur lequel on se base
* **Bigram**: un N-gram de 2 qui est donc consister de tel sorte `Thomas se branle sur son code` est lu `"Thomas se", "se branle", "branle sur", "sur son","son code"`

## Implémentation
1. Lire le Data set et split mot par mot
2. Faire des sortes de tuples
3. Faire des tuples avec un label comme étant le premier mot qui contient des petits tuples avec le mot suivant et son nombre d'apparition
4. Sauvegarder ces tuples en Pickle
5. Lire le Pickle
6. Simplement appliquer la formule