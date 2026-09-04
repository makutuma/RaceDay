/*
RaceDay Database Script
Part 1 - Section C
*/

 -- ****************************************
-- DROP DATABASE IF IT ALREADY EXISTS
-- ****************************************

IF DB_ID('RaceDay') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO


-- ****************************************
-- CREATE DATABASE
-- ****************************************

CREATE DATABASE RaceDay;
GO

USE RaceDay;
GO

-- ****************************************
-- TABLE: Users
-- Holds both Organisers and Participants, distinguished by Role.
-- ****************************************

CREATE TABLE Users (
    UserId          INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(255)   NOT NULL,
    Role            NVARCHAR(20)    NOT NULL,
    CONSTRAINT CK_Users_Role
        CHECK (Role IN ('Organiser', 'Participant')),
    CreatedAt       DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

-- ****************************************
-- TABLE: Events
-- Each event is created and owned by an Organiser.
-- ****************************************

CREATE TABLE Events (
    EventId         INT             IDENTITY(1,1) PRIMARY KEY,
    OrganiserId     INT             NOT NULL,
    Name            NVARCHAR(150)   NOT NULL,
    Description     NVARCHAR(1000)  NULL,
    EventDate       DATE            NOT NULL,
    Location        NVARCHAR(150)   NOT NULL,
    EventType       NVARCHAR(20)    NOT NULL,
    CONSTRAINT CK_Events_EventType
        CHECK (EventType IN ('Running', 'Cycling', 'Walking')),
    CreatedAt       DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Events_Organiser
        FOREIGN KEY (OrganiserId) REFERENCES Users(UserId)
);
GO

-- ****************************************
-- TABLE: Categories
-- Distance/entry categories that belong to a single event.
-- ****************************************

CREATE TABLE Categories (
    CategoryId      INT             IDENTITY(1,1) PRIMARY KEY,
    EventId         INT             NOT NULL,
    Name            NVARCHAR(50)    NOT NULL,
    DistanceKm      DECIMAL(5,2)    NOT NULL,
    MaxParticipants INT             NOT NULL DEFAULT 100,
    EntryFee        DECIMAL(8,2)    NOT NULL DEFAULT 0,
    CONSTRAINT FK_Categories_Event  
        FOREIGN KEY (EventId) REFERENCES Events(EventId)
);
GO

-- ****************************************
-- TABLE: Routes
-- Route/map information for an event.
-- ****************************************

CREATE TABLE Routes (
    RouteId         INT             IDENTITY(1,1) PRIMARY KEY,
    EventId         INT             NOT NULL,
    RouteName       NVARCHAR(100)   NOT NULL,
    DistanceKm      DECIMAL(5,2)    NOT NULL,
    ElevationGain   DECIMAL(6,2)    NULL,
    MapUrl          NVARCHAR(255)   NULL,
    CONSTRAINT FK_Routes_Event
        FOREIGN KEY (EventId) REFERENCES Events(EventId)
);
GO

-- ****************************************
-- TABLE: EventEnrolments
-- Links a Participant to a Category they have entered.
-- ****************************************

CREATE TABLE EventEnrolments (
    EnrolmentId     INT             IDENTITY(1,1) PRIMARY KEY,
    ParticipantId   INT             NOT NULL,
    CategoryId      INT             NOT NULL,
    EnrolmentDate   DATE            NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Confirmed',
    CONSTRAINT CK_Enrolments_Status
        CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),
    BibNumber       NVARCHAR(10)    NULL,
    CONSTRAINT FK_Enrolments_Participant
        FOREIGN KEY (ParticipantId) REFERENCES Users(UserId),
    CONSTRAINT FK_Enrolments_Category
        FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT UQ_Enrolments_Participant_Category
        UNIQUE (ParticipantId, CategoryId)
);
GO

-- ****************************************
-- TABLE: Results
-- One result per enrolment (1:1), captured by an Organiser.
-- ****************************************

CREATE TABLE Results (
    ResultId            INT             IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId         INT             NOT NULL UNIQUE,
    FinishTime          TIME            NOT NULL,
    Position            INT             NULL,
    CapturedByUserId    INT             NOT NULL,
    CapturedAt          DATETIME        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Results_Enrolment
        FOREIGN KEY (EnrolmentId) REFERENCES EventEnrolments(EnrolmentId),

    CONSTRAINT FK_Results_CapturedBy
        FOREIGN KEY (CapturedByUserId) REFERENCES Users(UserId)
);
GO


INSERT INTO Users
    (FullName, Email, PasswordHash, Role)
VALUES
    ('Sarah Naidoo', 'sarah.naidoo@raceday.co.za',
     'HASHED_PASSWORD_1', 'Organiser'),

    ('Thabo Mokoena', 'thabo.mokoena@raceday.co.za',
     'HASHED_PASSWORD_2', 'Organiser');

-- ****************************************
-- Participants
-- ****************************************

INSERT INTO Users
    (FullName, Email, PasswordHash, Role)
VALUES
    ('Emma van der Merwe', 'emma.vdm@example.com',
     'HASHED_PASSWORD_3', 'Participant'),

    ('Sipho Dlamini', 'sipho.dlamini@example.com',
     'HASHED_PASSWORD_4', 'Participant');

-- ****************************************
-- Events
-- ****************************************
INSERT INTO Events
    (OrganiserId, Name, Description, EventDate, Location, EventType)
VALUES
    (1,
     'Durban Beachfront 10K',
     'A scenic morning run along the Durban beachfront promenade.',
     '2026-03-15',
     'Durban, KwaZulu-Natal',
     'Running'),

    (1,
     'Joburg City Cycle Challenge',
     'A closed-road cycling event through the heart of Johannesburg.',
     '2026-04-12',
     'Johannesburg, Gauteng',
     'Cycling'),

    (2,
     'Cape Winelands Fun Walk',
     'A family-friendly walk through the vineyards of Stellenbosch.',
     '2026-05-03',
     'Stellenbosch, Western Cape',
     'Walking');

-- ****************************************
-- Categories
-- ****************************************

INSERT INTO Categories
    (EventId, Name, DistanceKm, MaxParticipants, EntryFee)
VALUES
    (1, '5km', 5.00, 300, 150.00),
    (1, '10km', 10.00, 500, 220.00),
    (2, '40km', 40.00, 200, 350.00),
    (2, '80km', 80.00, 150, 450.00),
    (3, '5km Fun Walk', 5.00, 400, 100.00);

-- ****************************************
-- Routes
-- ****************************************

INSERT INTO Routes
    (EventId, RouteName, DistanceKm, ElevationGain, MapUrl)
VALUES
    (1,
     'Beachfront Promenade Loop',
     10.00,
     25.00,
     'https://raceday.co.za/routes/durban-10k'),

    (2,
     'City Circuit',
     80.00,
     410.00,
     'https://raceday.co.za/routes/joburg-cycle'),

    (3,
     'Winelands Trail',
     5.00,
     60.00,
     'https://raceday.co.za/routes/stellenbosch-walk');

-- ****************************************
-- Enrolments
-- ****************************************
INSERT INTO EventEnrolments
    (ParticipantId, CategoryId, Status, BibNumber)
VALUES
    (3, 2, 'Confirmed', 'A1023'),   -- Emma enters the Durban 10km
    (4, 3, 'Confirmed', 'B2045'),   -- Sipho enters the Joburg 40km
    (3, 5, 'Confirmed', 'C3067');   -- Emma enters the Stellenbosch fun walk

-- ****************************************
-- Sample Result
-- ****************************************

INSERT INTO Results
    (EnrolmentId, FinishTime, Position, CapturedByUserId)
VALUES
    (1, '00:52:31', 14, 1);

GO

-- ****************************************
-- DISPLAY ALL TABLES
-- ****************************************
USE RaceDay;
GO

SELECT * FROM Users;
SELECT * FROM Events;
SELECT * FROM Categories;
SELECT * FROM Routes;
SELECT * FROM EventEnrolments;
SELECT * FROM Results;
GO