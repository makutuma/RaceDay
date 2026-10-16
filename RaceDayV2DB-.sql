USE RaceDayV3DB;
GO

UPDATE dbo.Users
SET Role = 'Organiser'
WHERE Email = 'modiba@example.com';
GO

SELECT UserId, FullName, Email, Role
FROM dbo.Users
WHERE Email = 'modiba@example.com';
GO

USE RaceDayV3DB;
GO

UPDATE dbo.Users
SET Role = 'Organiser'
WHERE Email = 'john@example.com';

SELECT UserId, FullName, Email, Role
FROM dbo.Users
WHERE Email = 'john@example.com';