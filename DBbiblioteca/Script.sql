##################### CREAZIONE BASE DI DATI #############################

DROP DATABASE IF EXISTS ProgettoBibliotecaUniversitaria;
CREATE DATABASE IF NOT EXISTS ProgettoBibliotecaUniversitaria;
USE ProgettoBibliotecaUniversitaria;

SET GLOBAL local_infile = ON;

##################### CREAZIONE TABELLE #############################


DROP TABLE IF EXISTS Dipartimento;
CREATE TABLE IF NOT EXISTS Dipartimento (
    CodDipartimentale VARCHAR(50) NOT NULL,
    Nome VARCHAR(50) NOT NULL,
    Città VARCHAR(50) NOT NULL,
    OrarioChiusura TIME NOT NULL,
    PRIMARY KEY (CodDipartimentale)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Tipologia;
CREATE TABLE IF NOT EXISTS Tipologia (
    Id INT(50) NOT NULL AUTO_INCREMENT,
    Dipartimento VARCHAR(50) NOT NULL,
    Nome VARCHAR(50) NOT NULL,
    PRIMARY KEY (Id),
    FOREIGN KEY (Dipartimento) REFERENCES Dipartimento(CodDipartimentale) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Utente;
CREATE TABLE IF NOT EXISTS Utente (
    Email VARCHAR(50) NOT NULL,
    Nome VARCHAR(50) NOT NULL,
    Cognome VARCHAR(50) NOT NULL,
    Tipologia INT(50) NOT NULL,
    PRIMARY KEY (Email),
    FOREIGN KEY (Tipologia) REFERENCES Tipologia(Id) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Biblioteca;
CREATE TABLE IF NOT EXISTS Biblioteca (
    LibraryId VARCHAR(50) NOT NULL,
    Dipartimento VARCHAR(50) NOT NULL,
    Nome VARCHAR(50) NOT NULL,
    Email VARCHAR(50) NOT NULL,
    Telefono VARCHAR(50) NOT NULL,
    PRIMARY KEY (LibraryId),
    FOREIGN KEY (Dipartimento) REFERENCES Dipartimento(CodDipartimentale) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Articolo;
CREATE TABLE IF NOT EXISTS Articolo (
    Id INT(50) NOT NULL AUTO_INCREMENT,
    Biblioteca VARCHAR(50) NOT NULL,
    Nome VARCHAR(50) NOT NULL,
    Tipo ENUM('Libro', 'Rivista', 'Giornale', 'DVD', 'Audiolibro'),
    PRIMARY KEY (Id),
    FOREIGN KEY (Biblioteca) REFERENCES Biblioteca(LibraryId) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Prenotazione;
CREATE TABLE IF NOT EXISTS Prenotazione (
    Id INT(50) NOT NULL AUTO_INCREMENT,
    Utente VARCHAR(50) NOT NULL,
    Articolo INT(50) NOT NULL,
    Quantità INT(50) NOT NULL,
    Data datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (Id),
    FOREIGN KEY (Utente) REFERENCES Utente(Email) ON UPDATE CASCADE,
    FOREIGN KEY (Articolo) REFERENCES Articolo(Id) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Conferma;
CREATE TABLE IF NOT EXISTS Conferma (
    Id INT(50) NOT NULL AUTO_INCREMENT,
    Biblioteca VARCHAR(50) NOT NULL,
    Utente VARCHAR(50) NOT NULL,
    Data datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (Id),
    FOREIGN KEY (Utente) REFERENCES Utente(Email) ON UPDATE CASCADE,
    FOREIGN KEY (Biblioteca) REFERENCES Biblioteca(LibraryId) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS StoricoNoleggi;
CREATE TABLE IF NOT EXISTS StoricoNoleggi (
    Conferma INT(50) NOT NULL,
    Articolo INT(50) NOT NULL,
    Quantità INT(50) NOT NULL,
    PRIMARY KEY (Conferma),
    FOREIGN KEY (Conferma) REFERENCES Conferma(Id) ON UPDATE CASCADE,
    FOREIGN KEY (Articolo) REFERENCES Articolo(Id) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Reso;
CREATE TABLE IF NOT EXISTS Reso (
    Conferma INT(50) NOT NULL,
    ArticoloRichiesto VARCHAR(50) NOT NULL,
    PRIMARY KEY (Conferma),
    FOREIGN KEY (Conferma) REFERENCES Conferma(Id) ON UPDATE CASCADE
) ENGINE=InnoDB;


###################### VISTE #####################


-- Vista delle Informazioni degli Utenti e delle Loro Tipologie
DROP VIEW IF EXISTS UtentiConTipologie;
CREATE VIEW UtentiConTipologie AS
SELECT u.Email, u.Nome, u.Cognome, t.Nome AS Tipologia
FROM Utente u
INNER JOIN Tipologia t ON u.Tipologia = t.Id;

-- Vista dei Dettagli Completi delle Prenotazioni
DROP VIEW IF EXISTS DettagliPrenotazioni;
CREATE VIEW DettagliPrenotazioni AS
SELECT p.Id, u.Email AS Utente, a.Nome AS Articolo, p.Quantità, p.Data
FROM Prenotazione p
JOIN Utente u ON p.Utente = u.Email
JOIN Articolo a ON p.Articolo = a.Id;

-- Vista delle Biblioteche con Informazioni Complete sui Dipartimenti
DROP VIEW IF EXISTS InfoDipartimentoConBiblioteca;
CREATE VIEW InfoDipartimentoConBiblioteca AS
SELECT b.LibraryId, b.Nome AS NomeBiblioteca, b.Email, b.Telefono, d.Nome AS Dipartimento, d.Città, d.OrarioChiusura
FROM Biblioteca b
JOIN Dipartimento d ON b.Dipartimento = d.CodDipartimentale;

-- Vista dei Resi di Articoli con Dettagli Completi
DROP VIEW IF EXISTS DettagliResi;
CREATE VIEW DettagliResi AS
SELECT r.Conferma, a.Nome AS Articolo, c.Utente, c.Biblioteca, c.Data AS DataConferma
FROM Reso r
JOIN Conferma c ON r.Conferma = c.Id
JOIN Articolo a ON c.Biblioteca = a.Biblioteca AND r.ArticoloRichiesto = a.Id;

-- Vista dei Dettagli delle Conferme con Informazioni sugli Utenti
DROP VIEW IF EXISTS DettagliConfermeUtenti;
CREATE VIEW DettagliConfermeUtenti AS
SELECT c.Id, c.Utente, u.Nome, u.Cognome, b.Nome AS Biblioteca, c.Data
FROM Conferma c
JOIN Utente u ON c.Utente = u.Email
JOIN Biblioteca b ON c.Biblioteca = b.LibraryId;

-- Vista delle Prenotazioni ad una specifica Biblioteca con LibraryId = LIB01
DROP VIEW IF EXISTS PrenotazioniBiblioteca;
CREATE VIEW PrenotazioniBiblioteca AS
SELECT p.Id AS PrenotazioneId, u.Email AS UtenteEmail, u.Nome AS UtenteNome, u.Cognome AS UtenteCognome,
       a.Nome AS Articolo, p.Quantità, p.Data
FROM Prenotazione p
JOIN Utente u ON p.Utente = u.Email
JOIN Articolo a ON p.Articolo = a.Id
JOIN Biblioteca b ON a.Biblioteca = b.LibraryId
WHERE b.LibraryId = 'LIB01';


###################### FUNZIONI E PROCEDURE #####################

DROP FUNCTION IF EXISTS BibliotecaAccessibileDaUtente;
DELIMITER //
CREATE FUNCTION BibliotecaAccessibileDaUtente(Email VARCHAR(50), Biblioteca VARCHAR(50)) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	IF(Biblioteca IN (SELECT Biblioteca.LibraryId
				FROM Biblioteca
                JOIN Tipologia ON Biblioteca.Dipartimento=Tipologia.Dipartimento
                JOIN Utente ON Tipologia.Id=Utente.Tipologia
                WHERE Utente.Email = Email)) 
		THEN 
			RETURN TRUE;
    ELSE 
			RETURN FALSE;
    END IF;
END //
DELIMITER;


DROP PROCEDURE IF EXISTS EseguiPrenotazione;
DELIMITER //
CREATE PROCEDURE EseguiPrenotazione (
    IN p_Utente VARCHAR(50), 
    IN p_Biblioteca VARCHAR(50), 
    IN p_Articolo VARCHAR(50), 
    IN p_Quantità VARCHAR(50), 
    IN p_Data DATE
)
BEGIN
    DECLARE p_ConfermaId INT(50);

    -- Inserisco nella tabella Conferma
    INSERT INTO Conferma (Utente, Biblioteca, Data)
    VALUES (p_Utente, p_Biblioteca, p_Data);

    -- Recupero l'ultimo Id inserito nella tabella Conferma
    SET p_ConfermaId = LAST_INSERT_ID();

    -- Inserisco l'Id nella tabella StoricoNoleggi
    INSERT INTO StoricoNoleggi (Conferma, Articolo, Quantità)
    VALUES (p_ConfermaId, p_Articolo, p_Quantità);
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS ConfermaPrenotazione;
DELIMITER //
CREATE PROCEDURE ConfermaPrenotazione (
    IN p_PrenotazioneId VARCHAR(50)
)
BEGIN
    DECLARE p_Utente VARCHAR(50);
    DECLARE p_Biblioteca VARCHAR(50);
    DECLARE p_Articolo VARCHAR(50);
    DECLARE p_Quantità VARCHAR(50);
    DECLARE p_Data DATE;

    -- Recupero i dettagli della prenotazione
    SELECT Prenotazione.Utente, Articolo.Biblioteca, Prenotazione.Articolo, Prenotazione.Quantità, Prenotazione.Data
    INTO p_Utente, p_Biblioteca, p_Articolo, p_Quantità, p_Data
    FROM Prenotazione
    INNER JOIN Articolo ON Prenotazione.Articolo = Articolo.Id
    WHERE Prenotazione.Id = p_PrenotazioneId;

    -- Controlla che l'utente non sia NULL
    IF p_Utente IS NOT NULL THEN
        -- Chiama la procedura EseguiPrenotazione
        CALL EseguiPrenotazione(p_Utente, p_Biblioteca, p_Articolo, p_Quantità, p_Data);

        -- Elimina la prenotazione dalla tabella Prenotazione
        DELETE FROM Prenotazione
        WHERE Id = p_PrenotazioneId;
    ELSE
        -- Ritorna un errore se l'utente è NULL
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Utente non valido';
    END IF;
END //
DELIMITER ;


############### POPOLAMENTO TABELLE #########################


INSERT INTO Dipartimento VALUES
    ('DIP001', 'Informatica', 'Firenze', '18:00'),
    ('DIP002', 'Lettere', 'Firenze', '17:30'),
    ('DIP003', 'Statistica', 'Firenze', '19:00'),
    ('DIP004', 'Economia', 'Firenze', '18:30');

###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "/Users/matteopascuzzo/Desktop/DBbiblioteca/Tipologia.csv" INTO TABLE Tipologia
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;

###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "/Users/matteopascuzzo/Desktop/DBbiblioteca/Utenti.txt" INTO TABLE Utente
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;

INSERT INTO Biblioteca VALUES
    ('LIB01', 'DIP001', 'Biblioteca di Informatica', 'biblio.informatica@email.it', '+39 055 1234567'),
    ('LIB02', 'DIP002', 'Biblioteca di Lettere', 'biblio.lettere@email.it', '+39 055 2345678'),
    ('LIB03', 'DIP003', 'Biblioteca di Statistica', 'biblio.statistica@email.it', '+39 055 3456789'),
    ('LIB04', 'DIP004', 'Biblioteca di Economia', 'biblio.economia@email.it', '+39 055 4567890');


INSERT INTO Articolo (Biblioteca, Nome, Tipo) VALUES 
    ('LIB01', 'Introduzione alla Programmazione', 'Libro'),
    ('LIB01', 'Fondamenti di Algoritmi', 'Libro'),
    ('LIB01', 'Videolezione Informatica', 'DVD'),
    ('LIB01', 'Introduction to Machine Learning', 'Rivista'),
    ('LIB01', 'Data Science in Practice', 'Libro'),

    ('LIB02', 'La Divina Commedia', 'Audiolibro'),
    ('LIB02', 'Antologia della Letteratura Italiana', 'Libro'),
    ('LIB02', 'Decameron', 'DVD'),

    ('LIB03', 'Manuale di Statistica', 'Libro'),
    ('LIB03', 'Statistical Methods in Biology', 'Rivista'),
    ('LIB03', 'Statistica Baesiana', 'Libro'),
    ('LIB03', 'Statistic for Dummies', 'Libro'),

    ('LIB04', 'Elementi di Economia', 'Libro'),
    ('LIB04', 'Economia Politica', 'Giornale'),
    ('LIB04', 'The Wolf of Wall Street', 'DVD');


INSERT INTO Prenotazione (Utente, Articolo, Quantità) VALUES
    ("chiara.russo138@email.it", 5, 1);


###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "/Users/matteopascuzzo/Desktop/DBbiblioteca/Conferma.csv" INTO TABLE Conferma
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS
    (Biblioteca, Utente);


###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "/Users/matteopascuzzo/Desktop/DBbiblioteca/StoricoNoleggi.csv" INTO TABLE StoricoNoleggi
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;


###################### TRIGGER #####################


DROP TRIGGER IF EXISTS CheckBibliotecaInPrenotazione;
DELIMITER //
CREATE TRIGGER CheckBibliotecaInPrenotazione
BEFORE INSERT ON Prenotazione
FOR EACH ROW
BEGIN
	DECLARE Biblioteca VARCHAR(50);
    
    SELECT P.Biblioteca
    INTO Biblioteca
    FROM Articolo P
    WHERE P.Id=NEW.Articolo;

	IF NOT BibliotecaAccessibileDaUtente (NEW.Utente, Biblioteca)
		THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Biblioteca non accessibile da Utente';
	END IF;
END //
DELIMITER ;


###################### INTERROGAZIONI #####################


## Trovare tutti gli Utenti che appartengono alla Biblioteca con LibraryId "LIB01":

SELECT Utente.Email, Utente.Nome, Utente.Cognome
FROM Utente
JOIN Tipologia ON Utente.Tipologia = Tipologia.Id
JOIN Biblioteca ON Tipologia.Dipartimento = Biblioteca.Dipartimento
WHERE Biblioteca.LibraryId = 'LIB01';

## Visualizzare tutte le Prenotazioni di un Utente specifico:

SELECT *
FROM Prenotazione
WHERE Utente = "francesca.rossi100@email.it";

## Elencare tutti gli articoli di una Biblioteca specifica: 
SELECT *
FROM Articolo
WHERE Biblioteca IN (SELECT LibraryId FROM Biblioteca WHERE Nome = 'Biblioteca di Informatica');























