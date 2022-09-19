CREATE DATABASE Performance;

USE Performance;

DROP TABLE IF EXISTS Random;

CREATE TABLE Random (
	Id INTEGER PRIMARY KEY,
	RandomNumber INTEGER);

BULK INSERT Random FROM 'C:\data\ManyLines.txt'
WITH
(FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n')
GO

SELECT * FROM Random;

--Søg efter et bestemt tilfældigt tal, f.eks. 4711
SELECT *
FROM Random
WHERE RandomNumber = 4711;
--Duration (No index)	      : 35ms	Reads (No index)	: 2210	CPU (No index)	: 31
--Duration (Index)            :  1ms	Reads (Index)		:   25	CPU (Index)		:  0

--Lav en oversigt over alle de tilfældige tal og hvor mange gange de hver især forekommer, sorteret 
--efter de tilfældige tal (dette kan også benyttes som et VIEW til løsning af de næste forespørgsler)
CREATE VIEW NumberOccurrences 
AS
SELECT COUNT(*) AS 'Occurrences', RandomNumber
FROM Random
GROUP BY RandomNumber
GO

SELECT *
FROM NumberOccurrences
ORDER BY 'Occurrences' DESC;
--Duration (No index)	      :  76ms	Reads (No index)	: 2136	CPU (No index)	: 108
--Duration (Index)            : 143ms	Reads (Index)		: 1787	CPU (Index)		:  94
--Unexpected duration?

--Find hvor mange gange det eller de sjældneste tilfældige tal forekommer
DECLARE @MinOccurrences INTEGER;
SELECT @MinOccurrences = MIN([Occurrences]) FROM NumberOccurrences;

SELECT COUNT(*) AS 'Occurrences', RandomNumber
FROM Random
GROUP BY RandomNumber
HAVING 'Occurrences' = MIN('Occurrences');
--Duration (No index)	      :  18ms	Reads (No index)	: 2156	CPU (No index)	:  31
--Duration (Index)            : 129ms	Reads (Index)		: 3574	CPU (Index)		: 110
--Result: 340 (61 occurrences)

--Find sjældneste tal (alternativ)
SELECT TOP 1 RandomNumber, COUNT(*)
FROM Random
GROUP BY RandomNumber
ORDER BY COUNT(*) ASC;
--Duration (Index)            :  64ms	Reads (Index)		: 1771	CPU (Index)		:  63

--Find hvor mange gange det eller de hyppigste tilfældige tal forekommer
DECLARE @MaxOccurrences INTEGER;
SELECT @MaxOccurrences = MAX([Occurrences]) FROM NumberOccurrences;

SELECT RandomNumber, [Occurrences]
FROM NumberOccurrences
WHERE [Occurrences] = @MaxOccurrences;
--Duration (Index)            :  30ms	Reads (Index)		: 4727	CPU (Index)		:  32
--Duration (Index)            : 135ms	Reads (Index)		: 3686	CPU (Index)		: 125
--Result: 1892 (137 occurrences)

--Find hyppigste tal (alternativ)
SELECT TOP 1 RandomNumber, COUNT(*)
FROM Random
GROUP BY RandomNumber
ORDER BY COUNT(*) DESC;
--Duration (Index)            :  71ms	Reads (Index)		: 1848	CPU (Index)		:  62

--Tilføj nu et INDEX til tabellen Random. Det er feltet RandomNumber, der laves index på.
CREATE INDEX index_random_numbers
ON Random(RandomNumber);

--Afprøv nu de samme forespørgsler som tidligere og dokumenter forskellene.

--Forskelle: Færre reads, mere CPU, længere tid (undtagen)
