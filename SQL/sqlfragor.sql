USE Filmer;
GO

--Initial many-to-many INNER JOIN av fem tabeller. Referensintegritet genom korrekt join av existerande FKs.
--Om FKs saknas bryts referensintegritet och JOINS tappar rader. Som stored procedured.

CREATE PROCEDURE databas_oversikt
AS
BEGIN

SELECT f.filmTitel AS Titel, r.regissorNamn AS Regissör, g.genreNamn AS Genre, STRING_AGG(s.skadespelareNamn, ', ') AS Skådespelare
FROM Film f
INNER JOIN Regissor r ON f.filmRegissorId = r.regissorId
INNER JOIN Genre g ON f.filmGenreId = g.genreId
INNER JOIN FilmSkadespelare fs ON f.filmId = fs.filmSkadespelareFid
INNER JOIN Skadespelare s ON fs.filmSkadespelareSid = s.skadespelareId

--Gruppering av aggregate-värde per unik tripplett

GROUP BY f.filmTitel, r.regissorNamn, g.genreNamn
ORDER BY Titel ASC;

END;

GO

EXECUTE databas_oversikt;

--Statistikmetod för snittbudget

SELECT f.filmTitel AS Titel, AVG(f.filmBudget) AS Snittbudget
FROM Film f

GROUP BY f.filmTitel
ORDER BY Snittbudget DESC;

GO

--Skapa unikt index på nationalitet skådespelare och regissör för att sedan testa

ALTER TABLE Skadespelare
ADD CONSTRAINT UQ_skadespelareNationalitet
UNIQUE (skadespelareNamn, skadespelareNationalitet);

ALTER TABLE Regissor
ADD CONSTRAINT UQ_regissorNationalitet
UNIQUE (regissorNamn, regissorNationalitet);

--Statistikmetod för att räkna antal unika länder representerade bland skådespelare och regissörer i databasen
--Nestad SELECT för kombinerad alias skapde genom union

SELECT Nationalitet AS [Nationaliteter representerade bland skådespelare och regissörer i databasen]

FROM (

SELECT DISTINCT s.skadespelareNationalitet AS Nationalitet
FROM Skadespelare s
INNER JOIN FilmSkadespelare fs ON s.skadespelareId = fs.FilmSkadespelareSid
INNER JOIN Film f ON fs.filmSkadespelareFid = f.filmId

UNION

SELECT DISTINCT r.regissorNationalitet
FROM Regissor r
INNER JOIN Film f ON r.regissorId = f.filmRegissorId
) AS x;

--AS x alias för hela subquery krävs för en deriverad tabell. Deriverad tabell (derived table) när SELECT körs inuti in from som denna subquery.

GO

--INSERTS för ytterligare diversitet i databas med transaktion och try/catch

BEGIN TRY

BEGIN TRANSACTION transaktion_ytterligare_tabelldata;
    
INSERT INTO Regissor (regissorNamn, regissorFodd, regissorNationalitet) VALUES
('Ridley Scott', '1937-11-30', 'Storbritannien'),
('Sofia Coppola', '1971-05-14', 'USA');

SAVE TRANSACTION steg1;

INSERT INTO Skadespelare (skadespelareNamn, skadespelareFodd, skadespelareNationalitet) VALUES
('Tom Hanks', '1956-07-09', 'USA'),
('Emma Watson', '1990-04-15', 'Storbritannien'),
('Brad Pitt', '1963-12-18', 'USA');


-- SAVE TRAN förkortning istället för TRANSACTION, samma funktionalitet

SAVE TRAN steg2;

INSERT INTO Film (filmGenreId, filmRegissorId, filmTitel, filmAr, filmBudget) VALUES
(13, 6, 'Gladiator', 2000, 103000000),
(1, 7, 'Lost in Translation', 2003, 4000000),
(2, 4, 'Tenet', 2020, 205000000);

SAVE TRAN steg3;

INSERT INTO FilmSkadespelare (filmSkadespelareFid, filmSkadespelareSid) VALUES
(1, 4),
(1, 2),
(2, 3),
(2, 4),
(2, 5),
(3, 1),
(3, 2),
(4, 1),
(4, 3),
(5, 2),
(5, 4),
(6, 6),
(6, 7),
(7, 7),
(7, 8),
(8, 1),
(8, 6),
(8, 8);

COMMIT TRAN;

END TRY

BEGIN CATCH
ROLLBACK TRAN transaktion_ytterligare_tabelldata;
THROW
END CATCH

GO

--Skapa 2 vyer. Vyerna bekräftar även referensintegritet genom korrekt FK-relationer i JOINS.

CREATE VIEW V_FilmInfo AS
SELECT 
    f.filmTitel AS Titel,
    r.regissorNamn AS Regissor,
    g.genreNamn AS Genre,
    STRING_AGG(s.skadespelareNamn, ', ') AS Skadespelare
FROM Film f
INNER JOIN Regissor r ON f.filmRegissorId = r.regissorId
INNER JOIN Genre g ON f.filmGenreId = g.genreId
INNER JOIN FilmSkadespelare fs ON f.filmId = fs.filmSkadespelareFid
INNER JOIN Skadespelare s ON fs.filmSkadespelareSid = s.skadespelareId
GROUP BY f.filmTitel, r.regissorNamn, g.genreNamn;

GO

CREATE VIEW V_FilmInfo_Modern AS
SELECT 
    f.filmTitel AS Titel,
    f.filmAr AS Ar,
    r.regissorNamn AS Regissor,
    g.genreNamn AS Genre,
    STRING_AGG(s.skadespelareNamn, ', ') AS Skadespelare
FROM Film f
INNER JOIN Regissor r ON f.filmRegissorId = r.regissorId
INNER JOIN Genre g ON f.filmGenreId = g.genreId
INNER JOIN FilmSkadespelare fs ON f.filmId = fs.filmSkadespelareFid
INNER JOIN Skadespelare s ON fs.filmSkadespelareSid = s.skadespelareId
WHERE f.filmAr >= 2000
GROUP BY f.filmTitel, r.regissorNamn, g.genreNamn;

GO

SELECT * FROM V_FilmInfo;
SELECT * FROM V_FilmInfo_Modern;

GO

--Skapa en loggtabell för att spara data från triggers

CREATE TABLE Logg_AllaTabeller (
loggId INT PRIMARY KEY IDENTITY(1,1),
tabellNamn VARCHAR(50),
postId INT,
operationTyp VARCHAR(10),
gamlaVarden VARCHAR(MAX),
nyaVarden VARCHAR(MAX),
tidpunkt DATETIME DEFAULT GETDATE()
);

--Skapa en trigger för DELETE på skådespelartabellen
--NOCOUNT för att undvika "n rows affected"-meddelande

CREATE TRIGGER trg_delete_skadespelare
ON Skadespelare
AFTER DELETE
AS
BEGIN

SET NOCOUNT ON;

INSERT INTO Logg_AllaTabeller (tabellNamn, postId, operationTyp, gamlaVarden, nyaVarden)
SELECT
'Skadespelare',
d.skadespelareId,
'DELETE',
'Namn: ' + d.skadespelareNamn + '; Fodd: ' + CAST(d.skadespelareFodd AS VARCHAR(20)) +
'; Nationalitet: ' + d.skadespelareNationalitet,
NUll
FROM deleted d;

END;

--Skapa en trigger för UPDATE på genretabellen

CREATE TRIGGER trg_uppdatera_genre
ON Genre
AFTER UPDATE
AS
BEGIN

SET NOCOUNT ON;

INSERT INTO Logg_AllaTabeller (tabellNamn, postId, operationTyp, gamlaVarden, nyaVarden)
SELECT
'Genre',
i.genreId,
'UPDATE',
'Gammalt Namn: ' + d.genreNamn,
'Nytt Namn: ' + i.genreNamn
FROM inserted i
INNER JOIN deleted d ON d.genreId = i.genreId;

END;

GO

--UPDATE och transaction

UPDATE Genre
SET genreNamn = 'Modern Drama'
WHERE genreId = 1;

UPDATE Regissor
SET regissorNationalitet = 'Storbritannien/USA'
WHERE regissorId = 4;

GO

--DELETE

DELETE FROM filmSkadespelare
WHERE filmSkadespelareSid = 8;

DELETE FROM Skadespelare
WHERE skadespelareId = 8;

DELETE FROM FilmSkadespelare
WHERE filmSkadespelareFid = 8;

DELETE FROM Film
WHERE filmId = 8;

GO

--Använd tidigare stored procedure för att överblicka databasen

EXEC databas_oversikt;
