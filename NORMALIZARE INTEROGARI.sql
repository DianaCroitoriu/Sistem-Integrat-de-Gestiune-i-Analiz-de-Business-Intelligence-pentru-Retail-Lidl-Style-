
-- 1. Cu grupare și filtrare
-- Cerință: Aflați numărul total de bonuri fiscale emise
-- și valoarea medie a unui bon pentru fiecare magazin în parte.

SELECT 
    m.idmagazin,
    m.oras,
    COUNT(DISTINCT bf.idbonfiscal) AS numar_total_bonuri,
    ROUND(COALESCE(SUM(dbf.cantitate * dbf.pret_final) / NULLIF(COUNT(DISTINCT bf.idbonfiscal), 0), 0), 2) AS valoare_medie_bon
FROM magazine m
LEFT JOIN bonuri_fiscale bf ON m.idmagazin = bf.idmagazin
LEFT JOIN detalii_bon_fiscal dbf ON bf.idbonfiscal = dbf.idbonfiscal
GROUP BY m.idmagazin, m.oras
ORDER BY numar_total_bonuri DESC;


-- 2. Cu subconsultări în clauza HAVING și FROM
-- Cerință: Afișați magazinul și numărul de casieri, 
-- dar doar pentru magazinele unde numărul de casieri depășește media pe rețea.

SELECT 
    sub_m.oras,
    sub_m.adresa,
    COUNT(a.idangajat) AS numar_casieri
FROM (
    SELECT idmagazin, oras, adresa 
    FROM magazine
) sub_m
JOIN angajati a ON sub_m.idmagazin = a.idmagazin
WHERE a.functie = 'Casier'
GROUP BY sub_m.idmagazin, sub_m.oras, sub_m.adresa
HAVING COUNT(a.idangajat) > (

    SELECT AVG(nr_casieri)
    FROM (
        SELECT idmagazin, COUNT(idangajat) AS nr_casieri
        FROM angajati
        WHERE functie = 'Casier'
        GROUP BY idmagazin
    ) tabel_medie
)
ORDER BY numar_casieri DESC;


-- 3. Cu expresii-tabelă (CTE) și "tabele-pivot"
-- Cerință: Generați un raport pivot care afișează stocul produselor pe două coloane,
-- în funcție de tipul magazinului ('Standard' și 'Supermagazin/XL').

WITH DatePivot_Stocuri AS (
    SELECT 
        p.nume_produs,
        m.tip AS tip_magazin,
        s.cantitate_disp
    FROM produse p
    JOIN stocuri s ON p.idprodus = s.idprodus
    JOIN magazine m ON s.idmagazin = m.idmagazin
)
SELECT 
    nume_produs,
    COALESCE(SUM(CASE WHEN tip_magazin = 'Standard' THEN cantitate_disp END), 0) AS stoc_standard,
    COALESCE(SUM(CASE WHEN tip_magazin = 'Supermagazin/XL' THEN cantitate_disp END), 0) AS stoc_supermagazin
FROM DatePivot_Stocuri
GROUP BY nume_produs
ORDER BY nume_produs;


-- 4. Interogări (pseudo) recursive
-- Cerință: Generați recursiv pragurile de analiză a stocurilor 
-- (de la 10 la 50 de bucăți, din 10 în 10) și 
-- numărați câte produse din baza de date se află la sau sub fiecare prag de alertă.

WITH RECURSIVE PraguriAlerta (prag) AS (
    SELECT 10
    UNION ALL
    SELECT prag + 10 
    FROM PraguriAlerta 
    WHERE prag < 50
)
SELECT 
    p.prag AS prag_cantitate,
    COUNT(DISTINCT s.idprodus) AS numar_produse_sub_prag
FROM PraguriAlerta p
LEFT JOIN stocuri s ON s.cantitate_disp <= p.prag
GROUP BY p.prag
ORDER BY p.prag;


-- 1. cu grupare și filtrare

-- Afișați furnizorii care au realizat cel puțin două livrări 
-- și a căror valoare medie a aprovizionărilor depășește 
-- media generală a tuturor aprovizionărilor din sistem.

SELECT f.idfurnizor, f.nume_furnizor,
    COUNT(a.idintrare) AS nr_livrari,
    ROUND(AVG(a.total_plata)) AS medie_aprovizionari
FROM furnizori f
INNER JOIN aprovizionare a
    ON f.idfurnizor = a.idfurnizor
GROUP BY f.idfurnizor, f.nume_furnizor
HAVING COUNT(a.idintrare) >= 2
   AND AVG(a.total_plata) >
       (
           SELECT AVG(total_plata)
           FROM aprovizionare
       );


-- 2. cu subconsultări în clauza HAVING și/sau FROM

-- Afișați produsele și cantitatea totală vândută prin plata cu cardul,
-- doar pentru produsele a căror cantitate totală vândută depășește 
-- media globală a cantităților vândute per produs.

SELECT p.idprodus, p.nume_produs,
    SUM(card.cantitate_vanduta) AS total_vandut_card
FROM produse p
INNER JOIN (
    SELECT dbf.idprodus, dbf.cantitate AS cantitate_vanduta
    FROM detalii_bon_fiscal dbf
    INNER JOIN bonuri_fiscale bf
        ON dbf.idbonfiscal = bf.idbonfiscal
    WHERE bf.mod_plata = 'Card'
) card
    ON p.idprodus = card.idprodus
GROUP BY p.idprodus, p.nume_produs
HAVING SUM(card.cantitate_vanduta) >
(
    SELECT AVG(total_produs)
    FROM (
        SELECT
            SUM(dbf2.cantitate) AS total_produs
        FROM detalii_bon_fiscal dbf2
        INNER JOIN bonuri_fiscale bf2
            ON dbf2.idbonfiscal = bf2.idbonfiscal
        WHERE bf2.mod_plata = 'Card'
        GROUP BY dbf2.idprodus
    )
)
ORDER BY total_vandut_card DESC;

-- 3. cu expresii-tabelă și "tabele-pivot" (cu sau fără joncțiuni externe)

-- Generați un raport pivot care afișează valoarea totală a vânzărilor
-- pentru fiecare categorie de produse, separată în 
-- funcție de metoda de plată utilizată.

SELECT denumire,
    SUM(CASE WHEN mod_plata = 'Cash' THEN valoare_vanzari ELSE 0 END) AS cash,
    SUM(CASE WHEN mod_plata = 'Card' THEN valoare_vanzari ELSE 0 END) AS card,
    SUM(CASE WHEN mod_plata = 'Lidl Pay' THEN valoare_vanzari ELSE 0 END) AS lidl_pay
FROM
( WITH vanzari_categorii AS
    (SELECT c.denumire, bf.mod_plata,
		SUM(dbf.cantitate * dbf.pret_final) AS valoare_vanzari
		FROM categorii c
        INNER JOIN produse p
            ON c.idcategorie = p.idcategorie
        INNER JOIN detalii_bon_fiscal dbf
            ON p.idprodus = dbf.idprodus
        INNER JOIN bonuri_fiscale bf
            ON dbf.idbonfiscal = bf.idbonfiscal
        GROUP BY c.denumire, bf.mod_plata
    )
    SELECT *
    FROM vanzari_categorii
) vc
GROUP BY denumire
ORDER BY denumire;


-- 4. interogări (pseudo) recursive

-- Generați recursiv pragurile de fidelitate pentru aplicația Lidl Plus
-- (de la 100 la 500 de puncte, din 100 în 100) și determinați 
-- numărul de clienți care au acumulat suficiente puncte pentru a atinge fiecare prag.

SELECT p.prag, c.nume, c.prenume, clp.puncte_acumulate
FROM
	(WITH RECURSIVE praguri AS
    	(SELECT 100 AS prag
		
        UNION ALL
		
        SELECT prag + 100
        FROM praguri
        WHERE prag < 500
    )
    SELECT *
    FROM praguri
) p
INNER JOIN cont_lidl_plus clp
    ON clp.puncte_acumulate >= p.prag
INNER JOIN clienti c
    ON clp.idclient = c.idclient
ORDER BY p.prag, clp.puncte_acumulate;












