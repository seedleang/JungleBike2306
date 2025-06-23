Dans cet exercice, j'ai souhaité me limiter en termes de temps comme c'était requis dans l'énoncé. Je n'ai donc essayé qu'un seul type de modèle et ai préféré inclure le bonus : essayer de classifier aussi sur summary ou description. 

Il n'est pas nécessaire d'utiliser du Deep Learning pour une si petite tâche. La vectorisation aide déjà. L'hyperparamétrage n'était donc pas un problème.

Dans un premier temps, j'avais essayé de classifier directement sur products_name_decli et ai obtenu une accuracy tout à fait acceptable.
Sauf que l'accuracy n'est pas une métrique exceptionnelle quand les classes sont déséquilibrées, j'en ai conscience et c'est pourquoi j'avais commencé à étudier la matrice de confusion.

Dans le rendu, j'aurais souhaité : 
- explorer le feature "feature" et trouver ce qu'il représente
- essayer d'autres modèles et notamment démontrer mes compétences avec spaCy et TextClassifier 
- étoffer le rapport de classification avec des scores f1, etc.
- améliorer l'interface : exploration et entraînement auraient dû être séparés dans le main.

Etant en plein déménagement, je n'ai pas d'environnement Python fonctionnel sur ma machine et je suis passée par Google Colab. Je n'ai donc qu'un seul fichier contenant main et fonctions...