CREATE DATABASE RaceDayV2DB;
GO

USE RaceDayV2DB;
GO

SELECT DB_NAME() AS CurrentDatabase;
GO     

/*
    RaceDayDB_Part2
    Part 1 database structure + Part 2 API testing data
    Run in SQL Server Management Studio (SSMS).
*/

-- =====================================================
-- 1. CREATE A NEW DATABASE
-- =====================================================

IF DB_ID('RaceDayDB_Part2') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB_Part2;
END
GO

USE RaceDayDB_Part2;
GO

-- =====================================================
-- 2. USERS TABLE
-- Organisers and Participants
-- =====================================================

IF OBJECT_ID('dbo.Users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        UserId INT IDENTITY(1,1) PRIMARY KEY,
        FullName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(150) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(255) NOT NULL,
        Role NVARCHAR(20) NOT NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

        CONSTRAINT CK_Users_Role
            CHECK (Role IN ('Organiser', 'Participant'))
    );
END
GO

-- =====================================================
-- 3. EVENTS TABLE
-- =====================================================

IF OBJECT_ID('dbo.Events', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Events
    (
        EventId INT IDENTITY(1,1) PRIMARY KEY,
        OrganiserId INT NOT NULL,
        Name NVARCHAR(150) NOT NULL,
        Description NVARCHAR(1000) NULL,
        EventDate DATE NOT NULL,
        Location NVARCHAR(150) NOT NULL,
        EventType NVARCHAR(20) NOT NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

        CONSTRAINT CK_Events_EventType
            CHECK (EventType IN ('Running', 'Cycling', 'Walking')),

        CONSTRAINT FK_Events_Organiser
            FOREIGN KEY (OrganiserId)
            REFERENCES dbo.Users(UserId)
    );
END
GO

-- =====================================================
-- 4. CATEGORIES TABLE
-- =====================================================

IF OBJECT_ID('dbo.Categories', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categories
    (
        CategoryId INT IDENTITY(1,1) PRIMARY KEY,
        EventId INT NOT NULL,
        Name NVARCHAR(50) NOT NULL,
        DistanceKm DECIMAL(5,2) NOT NULL,
        MaxParticipants INT NOT NULL DEFAULT 100,
        EntryFee DECIMAL(8,2) NOT NULL DEFAULT 0,

        CONSTRAINT FK_Categories_Event
            FOREIGN KEY (EventId)
            REFERENCES dbo.Events(EventId)
    );
END
GO

-- =====================================================
-- 5. ROUTES TABLE
-- =====================================================

IF OBJECT_ID('dbo.Routes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Routes
    (
        RouteId INT IDENTITY(1,1) PRIMARY KEY,
        EventId INT NOT NULL,
        RouteName NVARCHAR(100) NOT NULL,
        DistanceKm DECIMAL(5,2) NOT NULL,
        ElevationGain DECIMAL(6,2) NULL,
        MapUrl NVARCHAR(255) NULL,

        CONSTRAINT FK_Routes_Event
            FOREIGN KEY (EventId)
            REFERENCES dbo.Events(EventId)
    );
END
GO

-- =====================================================
-- 6. EVENT ENROLMENTS TABLE
-- =====================================================

IF OBJECT_ID('dbo.EventEnrolments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.EventEnrolments
    (
        EnrolmentId INT IDENTITY(1,1) PRIMARY KEY,
        ParticipantId INT NOT NULL,
        CategoryId INT NOT NULL,
        EnrolmentDate DATE NOT NULL
            DEFAULT CAST(GETDATE() AS DATE),
        Status NVARCHAR(20) NOT NULL DEFAULT 'Confirmed',
        BibNumber NVARCHAR(10) NULL,

        CONSTRAINT CK_Enrolments_Status
            CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),

        CONSTRAINT FK_Enrolments_Participant
            FOREIGN KEY (ParticipantId)
            REFERENCES dbo.Users(UserId),

        CONSTRAINT FK_Enrolments_Category
            FOREIGN KEY (CategoryId)
            REFERENCES dbo.Categories(CategoryId),

        CONSTRAINT UQ_Enrolments_Participant_Category
            UNIQUE (ParticipantId, CategoryId)
    );
END
GO

-- =====================================================
-- 7. RESULTS TABLE
-- =====================================================

IF OBJECT_ID('dbo.Results', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Results
    (
        ResultId INT IDENTITY(1,1) PRIMARY KEY,
        EnrolmentId INT NOT NULL UNIQUE,
        FinishTime TIME NOT NULL,
        Position INT NULL,
        CapturedByUserId INT NOT NULL,
        CapturedAt DATETIME NOT NULL DEFAULT GETDATE(),

        CONSTRAINT FK_Results_Enrolment
            FOREIGN KEY (EnrolmentId)
            REFERENCES dbo.EventEnrolments(EnrolmentId),

        CONSTRAINT FK_Results_CapturedBy
            FOREIGN KEY (CapturedByUserId)
            REFERENCES dbo.Users(UserId)
    );
END
GO

-- =====================================================
-- 8. INSERT SAMPLE USERS
-- Passwords here are demonstration placeholders.
-- Register real users through the API.
-- =====================================================

IF NOT EXISTS
    (SELECT 1 FROM dbo.Users WHERE Email = 'sarah.naidoo@raceday.co.za')
BEGIN
    INSERT INTO dbo.Users
        (FullName, Email, PasswordHash, Role)
    VALUES
        ('Sarah Naidoo', 'sarah.naidoo@raceday.co.za',
         'HASHED_PASSWORD_1', 'Organiser'),
        ('Thabo Mokoena', 'thabo.mokoena@raceday.co.za',
         'HASHED_PASSWORD_2', 'Organiser'),
        ('Emma van der Merwe', 'emma.vdm@example.com',
         'HASHED_PASSWORD_3', 'Participant'),
        ('Sipho Dlamini', 'sipho.dlamini@example.com',
         'HASHED_PASSWORD_4', 'Participant');
END
GO

-- =====================================================
-- 9. INSERT SAMPLE EVENTS
-- =====================================================

IF NOT EXISTS
    (SELECT 1 FROM dbo.Events WHERE Name = 'Durban Beachfront 10K')
BEGIN
    INSERT INTO dbo.Events
        (OrganiserId, Name, Description, EventDate, Location, EventType)
    VALUES
        (1, 'Durban Beachfront 10K',
         'A scenic morning run along the Durban beachfront promenade.',
         '2026-11-15', 'Durban, KwaZulu-Natal', 'Running'),

        (1, 'Joburg City Cycle Challenge',
         'A closed-road cycling event through Johannesburg.',
         '2026-11-22', 'Johannesburg, Gauteng', 'Cycling'),

        (2, 'Cape Winelands Fun Walk',
         'A family-friendly walk through Stellenbosch.',
         '2026-12-06', 'Stellenbosch, Western Cape', 'Walking');
END
GO

-- =====================================================
-- 10. INSERT CATEGORIES
-- =====================================================

IF NOT EXISTS
    (SELECT 1 FROM dbo.Categories WHERE EventId = 1)
BEGIN
    INSERT INTO dbo.Categories
        (EventId, Name, DistanceKm, MaxParticipants, EntryFee)
    VALUES
        (1, '5km', 5.00, 300, 150.00),
        (1, '10km', 10.00, 500, 220.00),
        (2, '40km', 40.00, 200, 350.00),
        (2, '80km', 80.00, 150, 450.00),
        (3, '5km Fun Walk', 5.00, 400, 100.00);
END
GO

-- =====================================================
-- 11. INSERT ROUTES
-- =====================================================

IF NOT EXISTS
    (SELECT 1 FROM dbo.Routes WHERE EventId = 1)
BEGIN
    INSERT INTO dbo.Routes
        (EventId, RouteName, DistanceKm, ElevationGain, MapUrl)
    VALUES
        (1, 'Beachfront Promenade Loop', 10.00, 25.00,
         'https://raceday.co.za/routes/durban-10k'),

        (2, 'City Circuit', 80.00, 410.00,
         'https://raceday.co.za/routes/joburg-cycle'),

        (3, 'Winelands Trail', 5.00, 60.00,
         'https://raceday.co.za/routes/stellenbosch-walk');
END
GO

-- =====================================================
-- 12. INSERT SAMPLE ENROLMENTS
-- =====================================================

IF NOT EXISTS
    (SELECT 1 FROM dbo.EventEnrolments)
BEGIN
    INSERT INTO dbo.EventEnrolments
        (ParticipantId, CategoryId, Status, BibNumber)
    VALUES
        (3, 2, 'Confirmed', 'A1023'),
        (4, 3, 'Confirmed', 'B2045'),
        (3, 5, 'Confirmed', 'C3067');
END
GO

-- =====================================================
-- 13. INSERT A SAMPLE RESULT
-- =====================================================

IF NOT EXISTS
    (SELECT 1 FROM dbo.Results)
BEGIN
    INSERT INTO dbo.Results
        (EnrolmentId, FinishTime, Position, CapturedByUserId)
    VALUES
        (1, '00:52:31', 14, 1);
END
GO

-- =====================================================
-- 14. DISPLAY ALL TABLE DATA
-- =====================================================

SELECT * FROM dbo.Users;
SELECT * FROM dbo.Events;
SELECT * FROM dbo.Categories;
SELECT * FROM dbo.Routes;
SELECT * FROM dbo.EventEnrolments;
SELECT * FROM dbo.Results;
GO


USE RaceDayDB_Part2;
GO

SELECT * FROM dbo.Users;
SELECT * FROM dbo.Events;
SELECT * FROM dbo.Categories;
SELECT * FROM dbo.Routes;
SELECT * FROM dbo.EventEnrolments;
SELECT * FROM dbo.Results;
GO


UPDATE Users
SET Role = 'Organiser'
WHERE Email = 'organiser2@raceday.com';

SELECT UserId, FullName, Email, Role
FROM Users
WHERE Email = 'organiser2@raceday.com';

USE RaceDayV3DB;
GO

UPDATE Users
SET Role = 'Organiser'
WHERE UserId = 4;
GO

SELECT UserId, FullName, Email, Role
FROM Users;
GO   
