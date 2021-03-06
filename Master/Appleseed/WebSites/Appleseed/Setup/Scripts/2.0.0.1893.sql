SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE rb_GetMonitoringEntries
(
    @PortalID			int,
    @StartDate			datetime,
    @EndDate			datetime,
    @ReportType			nvarchar(50),
    @CurrentTabID		bigint,
    @IPAddress			nvarchar(16),
    @IncludeMonitorPage		bit,   
    @IncludePageRequests	bit,
    @IncludeLogon		bit,
    @IncludeLogoff		bit,
    @IncludeIPAddress		bit
)
AS

	SET NOCOUNT ON

	DECLARE @SQLSTRING nvarchar(2000)

	IF (UPPER(@ReportType) = 'DETAILED SITE LOG')
	BEGIN

		SET @SQLSTRING = 'SELECT rbm.ActivityTime, rbm.ActivityType, rbt.PageName, rbu.[UserName], rbm.BrowserName, rbm.BrowserVersion, rbm.BrowserPlatform, rbm.UserHostAddress, rbm.UserField ' +
					'FROM rb_Monitoring rbm ' + 
					'LEFT OUTER JOIN aspnet_Users rbu ON rbm.UserID = rbu.UserID ' +
					'INNER JOIN rb_Portals rbp ON rbm.PortalID = rbp.PortalID ' +
					'LEFT OUTER JOIN rb_Pages rbt ON rbm.PageID = rbt.PageID ' +
					'WHERE ActivityTime >= ''' + CAST(@StartDate AS nvarchar) + ''' AND ActivityTime <= ''' + CAST(@EndDate AS nvarchar) + '''  ' +
					'AND rbm.PortalID = ' + CAST(@PortalID AS nvarchar)

		IF (@IncludeMonitorPage = 0) 
			SET @SQLSTRING = @SQLSTRING + 'AND rbm.PageID != ' + CAST(@CurrentTabID AS nvarchar) + ' '
		
		IF (@IncludePageRequests = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''PageRequest'' '
		IF (@IncludeLogon = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logon'' '
		IF (@IncludeLogoff = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logoff'' '
		IF (@IncludeIPAddress = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND UserHostAddress != ''' + @IPAddress + ''' '

		SET @SQLSTRING = @SQLSTRING + ' ORDER BY ActivityTime DESC'

	END
	ELSE
	IF (UPPER(@ReportType) = 'PAGE POPULARITY')
	BEGIN

		SET @SQLSTRING = 'SELECT rbt.PageName, ''Requests'' = COUNT(*), ''LastRequest'' = max(ActivityTime) ' +
					'FROM rb_Monitoring rbm ' +
					'INNER JOIN rb_Pages rbt ON rbm.PageID = rbt.PageID ' +
					'WHERE ActivityTime >= ''' + CAST(@StartDate AS nvarchar) + ''' AND ActivityTime <= ''' + CAST(@EndDate AS nvarchar) + '''  ' +
					'AND rbm.PortalID = ' + CAST(@PortalID AS nvarchar) + ' AND rbm.ActivityType=''PageRequest'''

		IF (@IncludeMonitorPage = 0) 
			SET @SQLSTRING = @SQLSTRING + 'AND rbm.PageID != ' + CAST(@CurrentTabID AS nvarchar) + ' '
		
		IF (@IncludePageRequests = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''PageRequest'' '
		IF (@IncludeLogon = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logon'' '
		IF (@IncludeLogoff = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logoff'' '
		IF (@IncludeIPAddress = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND UserHostAddress != ''' + @IPAddress + ''' '

		SET @SQLSTRING = @SQLSTRING + ' GROUP BY rbt.PageName ORDER BY Requests DESC'

	END
	ELSE
	IF (UPPER(@ReportType) = 'MOST ACTIVE USERS')
	BEGIN

		DECLARE @portalName nvarchar(2000)
	    
	    SELECT @portalName = LOWER(por.PortalAlias)
	    FROM rb_Portals por
	    WHERE por.PortalID = @PortalID

		SET @SQLSTRING = 'SELECT mem.Email, ''Actions'' = COUNT(*), ''LastAction'' = max(ActivityTime) ' +
					'FROM rb_Monitoring rbm ' +
					'INNER JOIN aspnet_Membership mem ON mem.UserID = rbm.UserID ' +
					'INNER JOIN aspnet_Applications app ON mem.ApplicationID = app.ApplicationID ' +
					'WHERE ActivityTime >= ''' + CAST(@StartDate AS nvarchar) + ''' AND ActivityTime <= ''' + CAST(@EndDate AS nvarchar) + '''  ' +
					'AND app.LoweredApplicationName = ''' + @portalName + ''' '

		IF (@IncludeMonitorPage = 0) 
			SET @SQLSTRING = @SQLSTRING + 'AND rbm.PageID != ' + CAST(@CurrentTabID AS nvarchar) + ' '
		
		IF (@IncludePageRequests = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''PageRequest'' '
		IF (@IncludeLogon = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logon'' '
		IF (@IncludeLogoff = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logoff'' '
		IF (@IncludeIPAddress = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND UserHostAddress != ''' + @IPAddress + ''' '

		SET @SQLSTRING = @SQLSTRING + ' GROUP BY mem.Email ORDER BY Actions DESC'

	END
	ELSE
	IF (UPPER(@ReportType) = 'PAGE VIEWS BY DAY')
	BEGIN
		SET @SQLSTRING = 'SELECT ''Date'' = convert(varchar,ActivityTime,102), ''Views'' = COUNT(*), ''Visitors'' = COUNT(DISTINCT UserHostAddress), ''Users'' = COUNT(DISTINCT UserID) ' +
					'FROM rb_Monitoring rbm ' +
					'WHERE ActivityTime >= ''' + CAST(@StartDate AS nvarchar) + ''' AND ActivityTime <= ''' + CAST(@EndDate AS nvarchar) + '''  ' +
					'AND rbm.PortalID = ' + CAST(@PortalID AS nvarchar) + ' AND rbm.ActivityType=''PageRequest'''

		IF (@IncludeMonitorPage = 0) 
			SET @SQLSTRING = @SQLSTRING + 'AND rbm.PageID != ' + CAST(@CurrentTabID AS nvarchar) + ' '
		
		IF (@IncludePageRequests = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''PageRequest'' '
		IF (@IncludeLogon = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logon'' '
		IF (@IncludeLogoff = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logoff'' '
		IF (@IncludeIPAddress = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND UserHostAddress != ''' + @IPAddress + ''' '

		SET @SQLSTRING = @SQLSTRING + 'GROUP BY convert(varchar,ActivityTime,102) ORDER BY [Date] ASC'

	END
	ELSE
	IF (UPPER(@ReportType) = 'PAGE VIEWS BY BROWSER TYPE')
	BEGIN

		SET @SQLSTRING = 'SELECT BrowserType, ''Views'' = COUNT(*) ' +
					'FROM rb_Monitoring rbm ' +
					'WHERE ActivityTime >= ''' + CAST(@StartDate AS nvarchar) + ''' AND ActivityTime <= ''' + CAST(@EndDate AS nvarchar) + '''  ' + 
					'AND rbm.PortalID = ' + CAST(@PortalID AS nvarchar) + ' AND rbm.ActivityType=''PageRequest'''

		IF (@IncludeMonitorPage = 0) 
			SET @SQLSTRING = @SQLSTRING + 'AND rbm.PageID != ' + CAST(@CurrentTabID AS nvarchar) + ' '
		
		IF (@IncludePageRequests = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''PageRequest'' '
		IF (@IncludeLogon = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logon'' '
		IF (@IncludeLogoff = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND ActivityType != ''Logoff'' '
		IF (@IncludeIPAddress = 0)
			SET @SQLSTRING = @SQLSTRING + 'AND UserHostAddress != ''' + @IPAddress + ''' '

		SET @SQLSTRING = @SQLSTRING + 'GROUP BY BrowserType ORDER BY [Views] DESC'

	END

	exec (@SQLSTRING)