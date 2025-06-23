-- Léane Salais pour JungleBike, juin 2025

/* 1. Dépenses mensuelles par client
* Pour chaque client, calculez le **total dépensé par mois** au cours des **12 derniers mois** 
* (relativement à la date la plus récente dans la table `transactions`).
*/

EXPLAIN
with max_date as(
	-- Récupération de la transaction la plus récente dans le but de calculer une période d'un an
	select max(transactions.date) actuel 
	from transactions
),
periodes as(
	-- Extraction du mois et de l'année à partir de la date, pour groupement et affichage
	select extract(month from date) mois, 
			extract(year from date) annee 
	from transactions, max_date
	-- on évite de récupérer des dates antérieures à la période qui nous intéresse : 
	-- placer ce where ici plutôt que dans la requête principale permet d'économiser du scan
	where transactions.date > (max_date.actuel - interval'12 month')
)
-- Affichage du client, de l'année et du mois (en français et non en chiffres) avec le total mensuel requis.
-- Le to_char() pour l'affichage du mois ne peut être fait en CTE, cela fausserait les tris et groupements.
select 'Client n°' || transactions.client_id client, 
	periodes.annee, to_char(to_date(periodes.mois::text, 'MM'), 'tmMonth') mois, 
	sum(transactions.montant) total_mensuel
-- Jointure interne : on ignore automatiquement les clients inactifs, le client apparaît dès lors qu'une transaction a lieu.
-- Joindre avec periodes permet de ne s'intéresser qu'aux dates cible.
from transactions 
	cross join max_date 
	join periodes 
		on extract(month from date)=periodes.mois
-- Interprétation du terme "dépenses" comme "achat"
where transactions.type_transaction = 'achat'
group by transactions.client_id, periodes.annee, periodes.mois
order by transactions.client_id, periodes.annee desc, periodes.mois DESC

-- On pouvait aussi envisager une approche par fonctions à fenêtre, 
-- mais le rapport aurait autant de lignes que de transactions.



/* 2. Top clients Assurance Vie
 * Trouvez les **10 clients** ayant la plus grande **dépense moyenne par transaction** 
 * pour des produits de la **catégorie "Assurance Vie"**.
 * N’incluez que les clients ayant **au moins 3 transactions** dans cette catégorie
 */

select clients.client_id, clients.nom, round(avg(transactions.montant),2) depense_moyenne 
-- Nécessité d'une double jointure car l'information requise (type du produit, nom des clients, montant)
-- est disséminée sur trois tables
from transactions join clients 
	on clients.client_id = transactions.client_id
join produits
	on produits.produit_id = transactions.produit_id
-- Restriction aux assurances-vie
where produits.categorie = 'Assurance Vie' 
	and type_transaction = 'achat'
group by clients.client_id
-- Au moins trois transactions effectuées par ce client dans ce contexte
having count(*) >= 3
-- Top 10 : on veut "les 10 clients" et tant pis s'il y a des égalités selon l'énoncé
order by depense_moyenne desc 
fetch first 10 rows only;

-- "dépense" était ambigu, vérification des types de transaction pour l'assurance-vie
select distinct(type_transaction)
from transactions join produits
	on produits.produit_id = transactions.produit_id
where produits.categorie = 'Assurance Vie' ; 

-- Résultat, il n'y a que deux clients concernés. 
-- Il faudrait voir si la table est plus peuplée en production. 


/* 3. Détection de transactions suspectes
 * Identifiez les clients ayant effectué **plus de 3 transactions supérieures à 10 000 €** sur une **même journée**
*/
select client_id, date, count(*) nombre_transactions
from transactions 
where montant > 10000
group by client_id, date
-- 3 est une limite peut-être trop laxiste ? Cela dépend du genre de portefeuilles gérés.
having count(*) > 3
order by nombre_transactions desc;

-- On ne constate rien de suspect. 
-- Mais si on compte deux et non trois transactions, attention, le client n°11 éveille les soupçons.


/*4. Optimisation (bonus)
 * Pour **au moins une** des requêtes précédentes :
	- Ajoutez les **indexes SQL** utiles (création via `CREATE INDEX`)
	- Justifiez leur pertinence
	- Montrez un plan d'exécution via `EXPLAIN` (sous forme de commentaire ou capture)
*/

-- Les indices sont intéressants pour optimiser l'exécution sur des requêtes 
-- impliquant des colonnes d'intérêt récurrentes dans GROUP BY et dans WHERE.
-- Les indices sur les clés primaires sont créés par défaut : clients_id, produits_id, transactions_id.

-- Premier exemple, pour le GROUP BY de la q3. 
-- Regardons avant : 
EXPLAIN 
select client_id, date, count(*) nombre_transactions
from transactions 
where montant > 10000
group by client_id, date
having count(*) > 3
order by nombre_transactions desc;
-- Utilise un seq scan.

CREATE INDEX ix_datecli_transactions
ON transactions(client_id,date);

EXPLAIN 
select client_id, date, count(*) nombre_transactions
from transactions 
where montant > 10000
group by client_id, date
having count(*) > 3
order by nombre_transactions desc;
-- Utilise toujours un seq scan, la petite taille de la table le justifie.


-- Deuxième exemple, s'il y a de nombreuses années dans la table, pour le WHERE sur la date dans la q1.
-- Avant : explain_q1_before.png --> utiise un seq scan.
CREATE INDEX ix_date_transactions
ON transactions(date);
-- Après : explain_q1_after.png --> utilise l'index au moins pour la CTE avec max_date.
-- On pourra, en production, considérer un index partiel ou un index fonctionnel avec extraction du mois par exemple, 
-- mais ce n'est pas pertinent avec la syntaxe que j'ai utilisée. Cela pourrait l'être pour les autres requêtes effectuées dans l'équipe.


-- Troisième exemple, pour les WHERE sur le type_transaction de q1 et q2, 
-- l'index suivant aurait été valable SEULEMENT si les catégories de transactions n'étaient pas uniformes:
CREATE INDEX ix_cat_transactions
ON transactions(type_transaction);
-- Mais ce n'est pas le cas.