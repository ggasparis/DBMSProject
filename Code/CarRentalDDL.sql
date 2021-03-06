USE [master]
GO
/****** Object:  Database [CarRental]    Script Date: 14/1/2018 3:28:12 πμ ******/
CREATE DATABASE [CarRental]
-- CONTAINMENT = NONE
-- ON  PRIMARY 
--( NAME = N'CarRental', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CarRental.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
-- LOG ON 
--( NAME = N'CarRental_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CarRental_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
--GO
ALTER DATABASE [CarRental] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [CarRental].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [CarRental] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [CarRental] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [CarRental] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [CarRental] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [CarRental] SET ARITHABORT OFF 
GO
ALTER DATABASE [CarRental] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [CarRental] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [CarRental] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [CarRental] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [CarRental] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [CarRental] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [CarRental] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [CarRental] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [CarRental] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [CarRental] SET  DISABLE_BROKER 
GO
ALTER DATABASE [CarRental] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [CarRental] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [CarRental] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [CarRental] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [CarRental] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [CarRental] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [CarRental] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [CarRental] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [CarRental] SET  MULTI_USER 
GO
ALTER DATABASE [CarRental] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [CarRental] SET DB_CHAINING OFF 
GO
ALTER DATABASE [CarRental] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [CarRental] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [CarRental] SET DELAYED_DURABILITY = DISABLED 
GO
USE [CarRental]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_CheckCarAvailability]    Script Date: 14/1/2018 3:28:12 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- 
-- Συνάρτηση που χρησιμοποιείται στο να επαληθεύσει 
-- τον έλεγχο του constrain στον πίνακα Rentals
-- για την διαθεσιμότητα του οχήματος
--
-- =============================================
CREATE FUNCTION [dbo].[fn_CheckCarAvailability]
(
	-- Add the parameters for the function here
	@ResID INT
)
RETURNS BIT
AS
BEGIN
	DECLARE @Available BIT
	SET @Available=0
	IF EXISTS(	SELECT 1
				FROM DBO.tbl_Reservations AS A
				INNER JOIN DBO.tbl_Cars AS B ON A.CarID=B.ID
				WHERE A.ID=@ResID AND B.Available=1)
	BEGIN
		SET @Available=1
	END
	RETURN @Available
END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_CheckForPayment]    Script Date: 14/1/2018 3:28:12 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 
-- Συνάρτηση που χρησιμοποιείται στο να επαληθεύσει 
-- τον έλεγχο του constrain στον πίνακα Rentals
-- για το αν έχει γίνει ήδη πληρωμή της ενοικίασης
--
-- =============================================
CREATE FUNCTION [dbo].[fn_CheckForPayment]
(
	-- Add the parameters for the function here
	@ID INT
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @PAYMENT INT

	-- Add the T-SQL statements to compute the return value here
	SET @PAYMENT=0
	IF EXISTS(
		SELECT 1 AS PaymentOK
		FROM DBO.tbl_Reservations
		WHERE ID=@ID AND Payment IS NOT NULL)
	BEGIN
		SET @PAYMENT=1 
	END
		-- Return the result of the function
	RETURN @PAYMENT

END


GO
/****** Object:  UserDefinedFunction [dbo].[fn_CheckInsuranceEndDate]    Script Date: 14/1/2018 3:28:12 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 
-- Συνάρτηση που χρησιμοποιείται στο να επαληθεύσει 
-- τον έλεγχο του constrain στον πίνακα Rentals
-- για το αν η ημερομηνία λήξης της ενοικίασης ξεπερνάει
-- την ημερομηνία λήξης της ασφάλειας
--
-- =============================================
CREATE FUNCTION [dbo].[fn_CheckInsuranceEndDate]
(
	-- Add the parameters for the function here
	@ResID INT
)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @InsuranceOK BIT
	SET @InsuranceOK=0

	IF EXISTS(	SELECT 1 FROM DBO.tbl_Reservations AS A
				INNER JOIN DBO.tbl_Cars AS B ON A.CarID=B.ID
				WHERE A.ID=@ResID AND B.InsuranceEndDate>=A.EndDate)
	BEGIN
		SET @InsuranceOK=1
	END
	RETURN @InsuranceOK
END


GO
/****** Object:  UserDefinedFunction [dbo].[fn_CheckKilometersForService]    Script Date: 14/1/2018 3:28:12 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- 
-- Συνάρτηση που χρησιμοποιείται στο να επαληθεύσει 
-- τον έλεγχο του constrain στον πίνακα Rentals
-- για το αν τα χιλιόμετρα του αυτοκινήτου έχουν
-- ξεπεράσει τα χιλιόμετρα του επόμενου service
--
-- =============================================
CREATE FUNCTION [dbo].[fn_CheckKilometersForService]
(
	-- Add the parameters for the function here
	@ResID INT
)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @KmsOK BIT
	SET @KmsOK=0

	IF EXISTS(	SELECT 1 FROM DBO.tbl_Reservations AS A
				INNER JOIN DBO.tbl_Cars AS B ON A.CarID=B.ID
				WHERE A.ID=@ResID AND B.Kilometers<B.NextServiceKms)
	BEGIN
		SET @KmsOK=1
	END
	RETURN @KmsOK
END

GO
/****** Object:  Table [dbo].[tbl_Branches]    Script Date: 14/1/2018 3:28:12 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Branches](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BranchName] [nvarchar](50) NOT NULL,
	[AddressStreet] [nvarchar](50) NOT NULL,
	[AddressNumber] [nvarchar](10) NOT NULL,
	[AddressTK] [nvarchar](10) NOT NULL,
	[AddressCity] [nvarchar](50) NOT NULL,
	[LandLine] [nvarchar](50) NOT NULL,
	[Mobile] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](50) NOT NULL,
	[Fax] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_tbl_Branches] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Cars]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Cars](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BranchID] [int] NOT NULL,
	[Maker] [nvarchar](50) NOT NULL,
	[Model] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](50) NOT NULL,
	[Cubism] [int] NOT NULL,
	[Horsepower] [int] NOT NULL,
	[LicensePlate] [nvarchar](50) NOT NULL,
	[YearOfPurchase] [date] NOT NULL,
	[Kilometers] [int] NOT NULL CONSTRAINT [DF_tbl_Cars_Kilometers]  DEFAULT ((0)),
	[LastServiceDate] [date] NULL,
	[LastServiceKms] [int] NULL,
	[NextServiceKms] [int] NULL,
	[InsuranceEndDate] [date] NULL,
	[InsuranceCompany] [nvarchar](50) NULL,
	[InsuranceAgreementNum] [nvarchar](50) NULL,
	[Available] [bit] NOT NULL CONSTRAINT [DF_tbl_Cars_Available]  DEFAULT ((1)),
 CONSTRAINT [PK_tbl_Cars] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Clients]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Clients](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EntryDate] [smalldatetime] NOT NULL,
	[AFM] [nvarchar](10) NOT NULL,
	[AddressStreet] [nvarchar](10) NOT NULL,
	[AddressNumber] [nvarchar](10) NOT NULL,
	[AddressTK] [nvarchar](10) NOT NULL,
	[AddressCity] [nvarchar](10) NOT NULL,
	[LandLine] [nvarchar](10) NOT NULL,
	[Mobile] [nvarchar](10) NOT NULL,
	[Email] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_tbl_Clients] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Damages]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Damages](
	[CarID] [int] NOT NULL,
	[Kilometers] [int] NOT NULL,
	[EntryDate] [date] NOT NULL,
	[Description] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_tbl_Damages] PRIMARY KEY CLUSTERED 
(
	[CarID] ASC,
	[Kilometers] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Employees]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Employees](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BranchID] [int] NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[FatherName] [nvarchar](50) NOT NULL,
	[ADT] [nvarchar](50) NOT NULL,
	[AFM] [nvarchar](50) NOT NULL,
	[Birthdate] [date] NOT NULL,
	[DriverLicenseNum] [nvarchar](50) NOT NULL,
	[AddressStreet] [nvarchar](50) NOT NULL,
	[AddressNumber] [nvarchar](50) NOT NULL,
	[AddressCity] [nvarchar](50) NOT NULL,
	[AddressTK] [nvarchar](50) NOT NULL,
	[LandLine] [nvarchar](50) NOT NULL,
	[Mobile] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](50) NOT NULL,
	[Position] [nvarchar](50) NOT NULL,
	[Duration] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_tbl_Employees] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_ForeignClient]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_ForeignClient](
	[ID] [int] NOT NULL,
	[OriginCountry] [nvarchar](50) NOT NULL,
	[PassportNum] [nvarchar](50) NOT NULL,
	[PassportEffectiveDate] [date] NOT NULL,
	[PassportEndDate] [date] NOT NULL,
 CONSTRAINT [PK_tbl_ForeignClient] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Individuals]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Individuals](
	[ID] [int] NOT NULL,
	[Occupation] [nvarchar](50) NULL,
	[BirthDate] [date] NULL,
	[LastName] [nvarchar](50) NULL,
	[FirstName] [nvarchar](50) NULL,
	[FatherName] [nvarchar](50) NULL,
	[ADT] [nvarchar](10) NULL,
 CONSTRAINT [PK_tbl_Individuals] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Organizations]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Organizations](
	[ID] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](50) NOT NULL,
	[EstablishmentDate] [date] NOT NULL,
	[RegistrationNum] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_tbl_Organizations] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Rentals]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Rentals](
	[ID] [int] NOT NULL,
	[DelivererEmpID] [int] NOT NULL,
	[ReceiverEmpID] [int] NULL,
	[CarConditionGrade] [nvarchar](1) NULL,
	[Ontime] [bit] NULL,
	[Kilometers] [int] NULL,
 CONSTRAINT [PK_tbl_Rentals] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Reservations]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Reservations](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CarID] [int] NOT NULL,
	[ClientID] [int] NOT NULL,
	[ReservationDate] [date] NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[Payment] [date] NULL,
 CONSTRAINT [PK_tbl_Reservations] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  View [dbo].[vw_UpcomingRentals]    Script Date: 14/1/2018 3:28:13 πμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_UpcomingRentals]
AS
SELECT        dbo.tbl_Reservations.ID, dbo.tbl_Reservations.CarID, dbo.tbl_Reservations.ClientID, dbo.tbl_Reservations.ReservationDate, dbo.tbl_Reservations.StartDate, 
                         dbo.tbl_Reservations.EndDate, dbo.tbl_Reservations.Payment
FROM            dbo.tbl_Reservations LEFT OUTER JOIN
                         dbo.tbl_Rentals ON dbo.tbl_Reservations.ID = dbo.tbl_Rentals.ID
WHERE        (dbo.tbl_Rentals.ID IS NULL)

GO

--
--
--Ακολουθούν διάφορα queries αποθηκευμένα στην βάση σαν views
--
--

/****** Object:  View [dbo].[vw_AllClientData]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Χρησιμοποιείται με κατάλληλο WHERE στην φόρμα των πελατών και επιστρέφει όλα τα στοιχεία
--του πελάτη και ανάλογα αποφασίζει τι πελάτης είναι και σετάρει κατάλληλα την φόρμα
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_AllClientData]
AS
SELECT        C.ID, C.EntryDate, C.AFM, C.AddressStreet, C.AddressNumber, C.AddressTK, C.AddressCity, C.LandLine, C.Mobile, C.Email, I.ID AS IND_ID, I.Occupation, I.BirthDate, 
                         I.LastName, I.FirstName, I.FatherName, I.ADT, O.ID AS ORG_ID, O.Name, O.Type, O.EstablishmentDate, O.RegistrationNum
FROM            dbo.tbl_Clients AS C LEFT OUTER JOIN
                         dbo.tbl_Individuals AS I ON C.ID = I.ID LEFT OUTER JOIN
                         dbo.tbl_Organizations AS O ON C.ID = O.ID

GO
/****** Object:  View [dbo].[vw_BranchesAndVehicles]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Ερώτημα που επιστρέφει ανά κατάστημα και ανά τύπο, μάρκα, μοντέλο το πλήθος των οχημάτων
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_BranchesAndVehicles]
AS
SELECT        B.ID, B.BranchName, C.Type, C.Maker, C.Model, COUNT(*) AS Num
FROM            dbo.tbl_Branches AS B INNER JOIN
                         dbo.tbl_Cars AS C ON B.ID = C.BranchID
GROUP BY B.ID, B.BranchName, C.Type, C.Maker, C.Model

GO
/****** Object:  View [dbo].[vw_ClientsAFMName]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Χρησιμοποιείται με κατάλληλο WHERE και LIKE στις φόρμες τις εφαρμογής για την εύρεση 
--του πελάτη (και πελατών) με κριτήριο μερικά ή και όλα τα ψηφία του ΑΦΜ
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_ClientsAFMName]
AS
SELECT A.ID,A.AFM, B.NAME
FROM [CarRental].[dbo].[tbl_Clients] AS A
INNER JOIN [CarRental].[dbo].[tbl_Organizations] AS B ON A.ID=B.ID
UNION
SELECT A.ID,A.AFM, B.LASTNAME+' '+B.FIRSTNAME AS NAME
FROM [CarRental].[dbo].[tbl_Clients] AS A
INNER JOIN [CarRental].[dbo].[tbl_Individuals] AS B ON A.ID=B.ID
AND B.ID NOT IN (SELECT ID FROM TBL_ORGANIZATIONS)

GO
/****** Object:  View [dbo].[vw_EmployeesAndBranches]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Ερώτημα που επιτρέφει λίστα με τους υπαλλήλους και σε πιο κατάστημα ανήκουν
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_EmployeesAndBranches]
AS
SELECT        TOP (100) PERCENT ID, BranchID, LastName, FirstName
FROM            dbo.tbl_Employees
ORDER BY LastName, FirstName

GO
/****** Object:  View [dbo].[vw_FindAvailableCar]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Χρησιμοποιείται με κατάλληλο WHERE στην φόρμα ττων κρατήσεων για την εύρεση 
--διαθέσιμου αυτοκινήτου στο κατάστημα επιλογής και κατά τις ζητούμενες ημερομηνίες
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_FindAvailableCar]
AS
SELECT B.ID, B.Maker, B.MODEl
FROM [CarRental].[dbo].[tbl_Branches] AS A
INNER JOIN tbl_Cars AS B ON A.ID=B.BranchID
WHERE A.ID=1 AND B.TYPE='Car'
EXCEPT
SELECT B.ID, B.Maker, B.Model
FROM [CarRental].[dbo].[tbl_Branches] AS A
INNER JOIN tbl_Cars AS B ON A.ID=B.BranchID
INNER JOIN tbl_Reservations AS C ON B.ID=C.CarID
WHERE A.ID=1 AND B.TYPE='Car'
AND NOT ('2018-01-05'<C.StartDate OR '2018-01-01'>C.EndDate)


GO
/****** Object:  View [dbo].[vw_RentalsOver1PerClient]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Ερώτημα που εμφανίζει τους πελάτες που έχουν προβεί σε ενοικίασει αυτοκινήτου πάνω από μια φορά
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_RentalsOver1PerClient]
AS
SELECT        LISTA_PELATON.ID, LISTA_PELATON.Name, COUNT(*) AS NumberOfRentals
FROM            (SELECT        A.ID, B.Name
                          FROM            dbo.tbl_Clients AS A INNER JOIN
                                                    dbo.tbl_Organizations AS B ON A.ID = B.ID
                          UNION
                          SELECT        A.ID, B.LastName + ' ' + B.FirstName AS NAME
                          FROM            dbo.tbl_Clients AS A INNER JOIN
                                                   dbo.tbl_Individuals AS B ON A.ID = B.ID AND B.ID NOT IN
                                                       (SELECT        ID
                                                         FROM            dbo.tbl_Organizations)) AS LISTA_PELATON INNER JOIN
                         dbo.tbl_Reservations AS RES ON RES.ClientID = LISTA_PELATON.ID INNER JOIN
                         dbo.tbl_Rentals AS REN ON RES.ID = REN.ID
GROUP BY LISTA_PELATON.ID, LISTA_PELATON.Name
HAVING        (COUNT(*) > 1)

GO
/****** Object:  View [dbo].[vw_ReservationsFormAllData]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Χρησιμοποιείται με κατάλληλο WHERE στην φόρμα των κρατήσεων και επιστρέφει τα στοιχεία
--της κράτησης, του πελάτη και του αυτοκινήτου για να τα εμφανίσει στην φόρμα
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_ReservationsFormAllData]
AS
SELECT        A.ID, A.CarID, A.ClientID, A.ReservationDate, A.StartDate, A.EndDate, A.Payment, B.ID AS RentalID, B.DelivererEmpID, B.ReceiverEmpID, B.CarConditionGrade, 
                         B.Ontime, B.Kilometers, C.Model, C.Maker, C.LicensePlate, C.BranchID, I.LastName, I.FirstName, O.Name, P.LandLine, P.Mobile
FROM            dbo.tbl_Reservations AS A INNER JOIN
                         dbo.tbl_Cars AS C ON A.CarID = C.ID INNER JOIN
                         dbo.tbl_Clients AS P ON A.ClientID = P.ID LEFT OUTER JOIN
                         dbo.tbl_Rentals AS B ON A.ID = B.ID LEFT OUTER JOIN
                         dbo.tbl_Individuals AS I ON A.ClientID = I.ID LEFT OUTER JOIN
                         dbo.tbl_Organizations AS O ON A.ClientID = O.ID

GO

/****** Object:  View [dbo].[vw_VehiculesPerBranch]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
--Ερώτημα που παράγει crosstable πλήθους οχημάτων ανά τύπο και ανά κατάστημα
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_VehiculesPerBranch]
AS
SELECT        B.BranchName, SUM(CASE WHEN C.Type = 'ATV' THEN 1 ELSE 0 END) AS ATVs, SUM(CASE WHEN C.Type = 'Car' THEN 1 ELSE 0 END) AS Cars, 
                         SUM(CASE WHEN C.Type = 'Mini Van' THEN 1 ELSE 0 END) AS [Mini Vans], SUM(CASE WHEN C.Type = 'Motocycle' THEN 1 ELSE 0 END) AS Motorcycles, 
                         SUM(CASE WHEN C.Type = 'Truck' THEN 1 ELSE 0 END) AS Trucks
FROM            dbo.tbl_Branches AS B LEFT OUTER JOIN
                         dbo.tbl_Cars AS C ON C.BranchID = B.ID
GROUP BY B.BranchName

GO
/****** Object:  Index [IndexOnBranchID]    Script Date: 14/1/2018 3:28:13 πμ ******/
CREATE NONCLUSTERED INDEX [IndexOnBranchID] ON [dbo].[tbl_Cars]
(
	[BranchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IndexOnClientAFM]    Script Date: 14/1/2018 3:28:13 πμ ******/
CREATE UNIQUE NONCLUSTERED INDEX [IndexOnClientAFM] ON [dbo].[tbl_Clients]
(
	[AFM] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IndexOnBranchID]    Script Date: 14/1/2018 3:28:13 πμ ******/
CREATE NONCLUSTERED INDEX [IndexOnBranchID] ON [dbo].[tbl_Employees]
(
	[BranchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IndexOnDelivererEmpID]    Script Date: 14/1/2018 3:28:13 πμ ******/
CREATE NONCLUSTERED INDEX [IndexOnDelivererEmpID] ON [dbo].[tbl_Rentals]
(
	[DelivererEmpID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IndexOnReceiverEmpID]    Script Date: 14/1/2018 3:28:13 πμ ******/
CREATE NONCLUSTERED INDEX [IndexOnReceiverEmpID] ON [dbo].[tbl_Rentals]
(
	[ReceiverEmpID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IndexOnCarID]    Script Date: 14/1/2018 3:28:13 πμ ******/
CREATE NONCLUSTERED INDEX [IndexOnCarID] ON [dbo].[tbl_Reservations]
(
	[CarID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IndexOnClientID]    Script Date: 14/1/2018 3:28:13 πμ ******/
CREATE NONCLUSTERED INDEX [IndexOnClientID] ON [dbo].[tbl_Reservations]
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tbl_Cars]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Cars_tbl_Branches] FOREIGN KEY([BranchID])
REFERENCES [dbo].[tbl_Branches] ([ID])
GO
ALTER TABLE [dbo].[tbl_Cars] CHECK CONSTRAINT [FK_tbl_Cars_tbl_Branches]
GO
ALTER TABLE [dbo].[tbl_Damages]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Damages_tbl_Cars] FOREIGN KEY([CarID])
REFERENCES [dbo].[tbl_Cars] ([ID])
GO
ALTER TABLE [dbo].[tbl_Damages] CHECK CONSTRAINT [FK_tbl_Damages_tbl_Cars]
GO
ALTER TABLE [dbo].[tbl_Employees]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Employees_tbl_Branches] FOREIGN KEY([BranchID])
REFERENCES [dbo].[tbl_Branches] ([ID])
GO
ALTER TABLE [dbo].[tbl_Employees] CHECK CONSTRAINT [FK_tbl_Employees_tbl_Branches]
GO
ALTER TABLE [dbo].[tbl_ForeignClient]  WITH CHECK ADD  CONSTRAINT [FK_tbl_ForeignClient_tbl_Individuals] FOREIGN KEY([ID])
REFERENCES [dbo].[tbl_Individuals] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[tbl_ForeignClient] CHECK CONSTRAINT [FK_tbl_ForeignClient_tbl_Individuals]
GO
ALTER TABLE [dbo].[tbl_Individuals]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Individuals_tbl_Clients] FOREIGN KEY([ID])
REFERENCES [dbo].[tbl_Clients] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[tbl_Individuals] CHECK CONSTRAINT [FK_tbl_Individuals_tbl_Clients]
GO
ALTER TABLE [dbo].[tbl_Organizations]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Organizations_tbl_Clients] FOREIGN KEY([ID])
REFERENCES [dbo].[tbl_Clients] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[tbl_Organizations] CHECK CONSTRAINT [FK_tbl_Organizations_tbl_Clients]
GO
ALTER TABLE [dbo].[tbl_Rentals]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Rentals_tbl_Employees] FOREIGN KEY([DelivererEmpID])
REFERENCES [dbo].[tbl_Employees] ([ID])
GO
ALTER TABLE [dbo].[tbl_Rentals] CHECK CONSTRAINT [FK_tbl_Rentals_tbl_Employees]
GO
ALTER TABLE [dbo].[tbl_Rentals]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Rentals_tbl_Employees1] FOREIGN KEY([ReceiverEmpID])
REFERENCES [dbo].[tbl_Employees] ([ID])
GO
ALTER TABLE [dbo].[tbl_Rentals] CHECK CONSTRAINT [FK_tbl_Rentals_tbl_Employees1]
GO
ALTER TABLE [dbo].[tbl_Rentals]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Rentals_tbl_Reservations] FOREIGN KEY([ID])
REFERENCES [dbo].[tbl_Reservations] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[tbl_Rentals] CHECK CONSTRAINT [FK_tbl_Rentals_tbl_Reservations]
GO
ALTER TABLE [dbo].[tbl_Reservations]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Reservations_tbl_Cars] FOREIGN KEY([CarID])
REFERENCES [dbo].[tbl_Cars] ([ID])
GO
ALTER TABLE [dbo].[tbl_Reservations] CHECK CONSTRAINT [FK_tbl_Reservations_tbl_Cars]
GO
ALTER TABLE [dbo].[tbl_Reservations]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Reservations_tbl_Clients] FOREIGN KEY([ClientID])
REFERENCES [dbo].[tbl_Clients] ([ID])
GO
ALTER TABLE [dbo].[tbl_Reservations] CHECK CONSTRAINT [FK_tbl_Reservations_tbl_Clients]
GO

--
--User Defined Constraints
--

--ALTER TABLE [dbo].[tbl_Cars]  WITH CHECK ADD  CONSTRAINT [CK_CarType] CHECK  (([Type]='Mini Van' OR [Type]='Truck' OR [Type]='ATV' OR [Type]='Motorcycle' OR [Type]='Car'))
--GO
--ALTER TABLE [dbo].[tbl_Cars] CHECK CONSTRAINT [CK_CarType]
--GO
--ALTER TABLE [dbo].[tbl_Rentals]  WITH NOCHECK ADD  CONSTRAINT [CK_tbl_CarForAvailability] CHECK  (([DBO].[fn_CheckCarAvailability]([ID])=(1)))
--GO
--ALTER TABLE [dbo].[tbl_Rentals] CHECK CONSTRAINT [CK_tbl_CarForAvailability]
--GO
--ALTER TABLE [dbo].[tbl_Rentals]  WITH NOCHECK ADD  CONSTRAINT [CK_tbl_CarsCheckKilometers] CHECK  (([dbo].[fn_CheckKilometersForService]([ID])=(1)))
--GO
--ALTER TABLE [dbo].[tbl_Rentals] CHECK CONSTRAINT [CK_tbl_CarsCheckKilometers]
--GO
--ALTER TABLE [dbo].[tbl_Rentals]  WITH NOCHECK ADD  CONSTRAINT [CK_tbl_CarsInsuranceDate] CHECK  (([dbo].[fn_CheckInsuranceEndDate]([ID])=(1)))
--GO
--ALTER TABLE [dbo].[tbl_Rentals] CHECK CONSTRAINT [CK_tbl_CarsInsuranceDate]
--GO
--ALTER TABLE [dbo].[tbl_Rentals]  WITH NOCHECK ADD  CONSTRAINT [CK_tbl_ReservationForPayment] CHECK  (([dbo].[fn_CheckForPayment]([ID])=(1)))
--GO
--ALTER TABLE [dbo].[tbl_Rentals] CHECK CONSTRAINT [CK_tbl_ReservationForPayment]
--GO
--ALTER TABLE [dbo].[tbl_Reservations]  WITH NOCHECK ADD  CONSTRAINT [CK_StartAndEndDates] CHECK  (([EndDate]>[StartDate]))
--GO
--ALTER TABLE [dbo].[tbl_Reservations] CHECK CONSTRAINT [CK_StartAndEndDates]
--GO
/****** Object:  Trigger [dbo].[trgCarAvailable]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
-- Το trigger αυτό αναμένει ενημέρωση στον πίνακα των ενοικιάσεων που σημαίνει παραλαβή οχήματος
-- και θέτει το flag της διαθεσιμότητας του αυτοκινήτου σε TRUE και παράλληλα γράφει και τα χιλιόμετρα
-- της καταχώρησης της επιστροφής στην καρτέλλα του οχήματος 
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trgCarAvailable] on [dbo].[tbl_Rentals] FOR UPDATE
AS
DECLARE @ResID INT
DECLARE @Kilometers INT
SELECT @ResID=I.ID FROM INSERTED I;
SELECT @Kilometers=I.Kilometers FROM INSERTED I;	

UPDATE DBO.tbl_Cars
	SET Available=1,
	KILOMETERS = @KILOMETERS
	WHERE ID=(SELECT CARID FROM tbl_Reservations WHERE ID=@ResID)

GO
/****** Object:  Trigger [dbo].[trgCarNotAvailable]    Script Date: 14/1/2018 3:28:13 πμ ******/
--
-- Το trigger αυτό αναμένει εγγραφή στον πίνακα των ενοικιάσεων που σημαίνει παράδοση οχήματος
-- και θέτει το flag της διαθεσιμότητας του σε FALSE 
--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trgCarNotAvailable] on [dbo].[tbl_Rentals] FOR INSERT
AS
DECLARE @ResID INT
SELECT @ResID=I.ID FROM INSERTED I;	

UPDATE DBO.tbl_Cars
	SET Available=0
	WHERE ID=(SELECT CARID FROM tbl_Reservations WHERE ID=@ResID)

GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[24] 4[7] 2[38] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "C"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 213
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "I"
            Begin Extent = 
               Top = 6
               Left = 251
               Bottom = 135
               Right = 421
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "O"
            Begin Extent = 
               Top = 6
               Left = 459
               Bottom = 135
               Right = 646
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_AllClientData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_AllClientData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[21] 2[14] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "B"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 229
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "C"
            Begin Extent = 
               Top = 6
               Left = 267
               Bottom = 135
               Right = 509
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_BranchesAndVehicles'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_BranchesAndVehicles'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[21] 4[6] 2[44] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 3330
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_ClientsAFMName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_ClientsAFMName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[36] 4[17] 2[19] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "tbl_Employees"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_EmployeesAndBranches'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_EmployeesAndBranches'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[11] 4[9] 2[64] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FindAvailableCar'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FindAvailableCar'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[19] 4[18] 2[45] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "LISTA_PELATON"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 101
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "RES"
            Begin Extent = 
               Top = 6
               Left = 262
               Bottom = 135
               Right = 452
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "REN"
            Begin Extent = 
               Top = 6
               Left = 490
               Bottom = 135
               Right = 697
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_RentalsOver1PerClient'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_RentalsOver1PerClient'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[6] 4[6] 2[45] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "A"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 212
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "C"
            Begin Extent = 
               Top = 6
               Left = 250
               Bottom = 135
               Right = 476
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "P"
            Begin Extent = 
               Top = 6
               Left = 514
               Bottom = 135
               Right = 689
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "I"
            Begin Extent = 
               Top = 138
               Left = 267
               Bottom = 267
               Right = 437
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "O"
            Begin Extent = 
               Top = 138
               Left = 475
               Bottom = 267
               Right = 662
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "B"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 267
               Right = 229
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_ReservationsFormAllData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_ReservationsFormAllData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_ReservationsFormAllData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[44] 4[14] 2[21] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "tbl_Reservations"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 152
               Right = 212
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "tbl_Rentals"
            Begin Extent = 
               Top = 6
               Left = 332
               Bottom = 135
               Right = 523
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_UpcomingRentals'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_UpcomingRentals'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "B"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 229
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "C"
            Begin Extent = 
               Top = 6
               Left = 267
               Bottom = 135
               Right = 509
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_VehiculesPerBranch'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_VehiculesPerBranch'
GO
USE [master]
GO
ALTER DATABASE [CarRental] SET  READ_WRITE 
GO
