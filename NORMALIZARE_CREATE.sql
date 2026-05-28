DROP TABLE IF EXISTS detalii_bon_fiscal;
DROP TABLE IF EXISTS detalii_aprovizionare;
DROP TABLE IF EXISTS produse_furnizori;
DROP TABLE IF EXISTS stocuri;
DROP TABLE IF EXISTS cupoane_client;
DROP TABLE IF EXISTS bonuri_fiscale;
DROP TABLE IF EXISTS promotii;
DROP TABLE IF EXISTS aprovizionare;
DROP TABLE IF EXISTS angajati;
DROP TABLE IF EXISTS cont_lidl_plus;
DROP TABLE IF EXISTS produse;
DROP TABLE IF EXISTS categorii;
DROP TABLE IF EXISTS furnizori;
DROP TABLE IF EXISTS magazine;
DROP TABLE IF EXISTS clienti;


CREATE TABLE clienti (
	idClient NUMERIC(5)
		CONSTRAINT pk_idClient PRIMARY KEY,
	nume VARCHAR(30)
		CONSTRAINT nn_nume NOT NULL
		CONSTRAINT ck_nume CHECK (SUBSTR(nume,1,1) = UPPER(SUBSTR(nume,1,1))),
	prenume VARCHAR(30)
		CONSTRAINT nn_prenume NOT NULL
		CONSTRAINT ck_prenume CHECK (SUBSTR(prenume,1,1) = UPPER(SUBSTR(prenume,1,1))),
	email VARCHAR(50)
		CONSTRAINT un_email UNIQUE
		CONSTRAINT ck_email CHECK (email LIKE '%@%.%'),
	telefon VARCHAR(15)
		CONSTRAINT ck_telefon CHECK (LENGTH(telefon) >= 10)
);


CREATE TABLE magazine (
	idMagazin NUMERIC(5)
		CONSTRAINT pk_idMagazin PRIMARY KEY,
	oras VARCHAR(30)
		CONSTRAINT nn_oras NOT NULL,
	adresa VARCHAR(100)
		CONSTRAINT nn_adresa NOT NULL,
	tip VARCHAR(30)
		CONSTRAINT nn_tip NOT NULL
		CONSTRAINT ck_tip CHECK (tip IN ('Standard', 'Supermagazin/XL', 'Centru Logistic/Depozit'))
);

CREATE TABLE furnizori (
	idFurnizor NUMERIC(5)
		CONSTRAINT pk_idFurnizor PRIMARY KEY,
	nume_furnizor VARCHAR(50)
		CONSTRAINT nn_nume_furnizor NOT NULL
		CONSTRAINT un_nume_furnizor UNIQUE,
	contact VARCHAR(50)
		CONSTRAINT nn_contact NOT NULL,
	tara_origine VARCHAR(30)
		CONSTRAINT nn_tara_origine NOT NULL
);

CREATE TABLE categorii (
	idCategorie NUMERIC(5)
		CONSTRAINT pk_idCategorie PRIMARY KEY,
	denumire VARCHAR(50)
		CONSTRAINT nn_denumire NOT NULL
);


CREATE TABLE produse (
	idProdus NUMERIC(5)
		CONSTRAINT pk_idProdus PRIMARY KEY,
	nume_produs VARCHAR(50)
		CONSTRAINT nn_nume_produs NOT NULL,
	unitate_masura VARCHAR(10)
		CONSTRAINT nn_unitate_masura NOT NULL,
	cod_bare VARCHAR(30)
		CONSTRAINT nn_cod_bare NOT NULL
		CONSTRAINT un_cod_bare UNIQUE,
	pret_unitar NUMERIC(6, 2)
		CONSTRAINT nn_pret_unitar NOT NULL
		CONSTRAINT ck_pret_unitar CHECK (pret_unitar > 0),
	tva NUMERIC(2)
		CONSTRAINT nn_tva NOT NULL
		CONSTRAINT ck_tva CHECK (tva IN (9, 21)),
	idCategorie NUMERIC(5)
		CONSTRAINT fk_produse_idCategorie REFERENCES categorii(idCategorie)
			ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE cont_lidl_plus (
	idcontlidlplus NUMERIC(5)
		CONSTRAINT pk_idcontlidlplus PRIMARY KEY,
	data_inregistrarii DATE
		CONSTRAINT nn_data_inregistrarii NOT NULL,
	id_card_qr VARCHAR(50)
		CONSTRAINT nn_id_card_qr NOT NULL
		CONSTRAINT un_id_card_qr UNIQUE,
	puncte_acumulate NUMERIC(5)
		CONSTRAINT ck_puncte_acumulate CHECK (puncte_acumulate >= 0),
	idclient NUMERIC(5)
		CONSTRAINT fk_cont_lidl_plus_idclient REFERENCES clienti(idclient) 
			ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE angajati (
	idangajat NUMERIC(5)
		CONSTRAINT pk_idangajat PRIMARY KEY,
	nume VARCHAR(30)
		CONSTRAINT nn_nume NOT NULL
		CONSTRAINT ck_nume CHECK (SUBSTR(nume,1,1) = UPPER(SUBSTR(nume,1,1))),
	prenume VARCHAR(30)
		CONSTRAINT nn_prenume NOT NULL
		CONSTRAINT ck_prenume CHECK (SUBSTR(prenume,1,1) = UPPER(SUBSTR(prenume,1,1))),
	cnp VARCHAR(20)
		CONSTRAINT nn_cnp NOT NULL,
	functie VARCHAR(50)
		CONSTRAINT nn_functie NOT NULL,
	data_angajarii DATE
		CONSTRAINT nn_data_angajarii NOT NULL,
	idmagazin NUMERIC(5)
		CONSTRAINT fk_angajati_idmagazin REFERENCES magazine(idmagazin)
			ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE aprovizionare (
	idintrare NUMERIC(5)
		CONSTRAINT pk_idintrare PRIMARY KEY,
	data_receptie DATE
		CONSTRAINT nn_data_receptie NOT NULL,
	total_plata NUMERIC(8, 2)
		CONSTRAINT nn_total_plata NOT NULL
		CONSTRAINT ck_total_plata CHECK (total_plata >= 0),
	idmagazin NUMERIC(5)
		CONSTRAINT fk_aprovizionare_idmagazin REFERENCES magazine(idmagazin)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idfurnizor NUMERIC(5)
		CONSTRAINT fk_aprovizionare_idfurnizor REFERENCES furnizori(idfurnizor)
			ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE promotii (
	idpromotie NUMERIC(5)
		CONSTRAINT pk_idpromotie PRIMARY KEY,
	discount NUMERIC(4, 2)
		CONSTRAINT nn_discount NOT NULL
		CONSTRAINT ck_discount CHECK (discount >= 0),
	data_emitere DATE
		CONSTRAINT nn_data_emitere NOT NULL,
	data_expirare DATE
		CONSTRAINT nn_data_expirare NOT NULL,
	idprodus NUMERIC(5)
		CONSTRAINT fk_promotii_idprodus REFERENCES produse(idprodus)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT ck_perioada_valabilitate CHECK (data_expirare >= data_emitere)
);

CREATE TABLE bonuri_fiscale (
	idbonfiscal NUMERIC(8)
		CONSTRAINT pk_idbonfiscal PRIMARY KEY,
	data_bon DATE
		CONSTRAINT nn_data_bon NOT NULL,
	ora VARCHAR(5)
		CONSTRAINT nn_ora_b NOT NULL,
	mod_plata VARCHAR(20)
		CONSTRAINT nn_mod_plata NOT NULL,
	idangajat NUMERIC(5)
		CONSTRAINT fk_bonuri_fiscale_idangajat REFERENCES angajati(idangajat)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idmagazin NUMERIC(5)
		CONSTRAINT fk_bonuri_fiscale_idmagazin REFERENCES magazine(idmagazin)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idcontlidlplus NUMERIC(5)
		CONSTRAINT fk_bonuri_fiscale_idcontlidlplus REFERENCES cont_lidl_plus(idcontlidlplus)
			ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cupoane_client (
	idcontlidlplus NUMERIC(5)
		CONSTRAINT fk_cupoane_client_idcontlidlplus REFERENCES cont_lidl_plus(idcontlidlplus) 
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idpromotie NUMERIC(5)
		CONSTRAINT fk_cupoane_client_idpromotie REFERENCES promotii(idpromotie)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	stare_cupon VARCHAR(20)
		CONSTRAINT nn_stare_cupon NOT NULL
		CONSTRAINT ck_stare_cupon CHECK (stare_cupon IN ('Neactivat', 'Activat', 'Utilizat', 'Expirat')),
        
	CONSTRAINT pk_cupoane_client PRIMARY KEY (idcontlidlplus, idpromotie)
);

CREATE TABLE stocuri (
	idprodus NUMERIC(5)
		CONSTRAINT fk_stocuri_idprodus REFERENCES produse(idprodus)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idmagazin NUMERIC(5)
		CONSTRAINT fk_stocuri_idmagazin REFERENCES magazine(idmagazin) 
			ON DELETE RESTRICT ON UPDATE CASCADE,
	cantitate_disp NUMERIC(6)
		CONSTRAINT nn_cantitate_disp NOT NULL
		CONSTRAINT ck_cantitate_disp CHECK (cantitate_disp >= 0),
	localizare_raft VARCHAR(30)
		CONSTRAINT nn_localizare_raft NOT NULL,
	data_inventar DATE,
        
	CONSTRAINT pk_stocuri PRIMARY KEY (idprodus, idmagazin)
);

CREATE TABLE produse_furnizori (
	idprodus NUMERIC(5)
		CONSTRAINT fk_produse_furnizori_idprodus REFERENCES produse(idprodus)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idfurnizor NUMERIC(5)
		CONSTRAINT fk_produse_furnizori_idfurnizor REFERENCES furnizori(idfurnizor) 
			ON DELETE RESTRICT ON UPDATE CASCADE,
	timp_livrare_zile NUMERIC(3)
		CONSTRAINT ck_timp_livrare CHECK (timp_livrare_zile >= 0),
	status_furnizor VARCHAR(20)
		CONSTRAINT nn_status_furnizor NOT NULL,
        
	CONSTRAINT pk_produse_furnizori PRIMARY KEY (idprodus, idfurnizor)
);

CREATE TABLE detalii_aprovizionare (
	idprodus NUMERIC(5)
		CONSTRAINT fk_detalii_aprovizionare_idprodus REFERENCES produse(idprodus) 
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idintrare NUMERIC(5)
		CONSTRAINT fk_detalii_aprovizionare_idintrare REFERENCES aprovizionare(idintrare) 
			ON DELETE RESTRICT ON UPDATE CASCADE,
	cant_primita NUMERIC(6)
		CONSTRAINT nn_cant_primita NOT NULL
		CONSTRAINT ck_cant_primita CHECK (cant_primita > 0),
	pret_achizitie NUMERIC(6, 2)
		CONSTRAINT nn_pret_achizitie NOT NULL
		CONSTRAINT ck_pret_achizitie CHECK (pret_achizitie > 0),
        
	CONSTRAINT pk_detalii_aprovizionare PRIMARY KEY (idprodus, idintrare)
);

CREATE TABLE detalii_bon_fiscal (
	idprodus NUMERIC(5)
		CONSTRAINT fk_detalii_bon_fiscal_idprodus REFERENCES produse(idprodus)
			ON DELETE RESTRICT ON UPDATE CASCADE,
	idbonfiscal NUMERIC(8)
		CONSTRAINT fk_detalii_bon_fiscal_idbonfiscal REFERENCES bonuri_fiscale(idbonfiscal) 
			ON DELETE RESTRICT ON UPDATE CASCADE,
	cantitate NUMERIC(4)
		CONSTRAINT nn_cantitate_dbf NOT NULL
		CONSTRAINT ck_cantitate_dbf CHECK (cantitate > 0),
	pret_final NUMERIC(6, 2)
		CONSTRAINT nn_pret_final_dbf NOT NULL
		CONSTRAINT ck_pret_final_dbf CHECK (pret_final >= 0),
        
	CONSTRAINT pk_detalii_bon_fiscal PRIMARY KEY (idprodus, idbonfiscal)
);

