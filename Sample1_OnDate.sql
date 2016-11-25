
/*============================================================================================================

 Version 1.0 2016/11/25 Ryoichi Naito: ryoichi.naito@thomsonreuters.com

 Retrieve all available consensus data for a universe.

 Temp tables:

 Note: If you encountered an error 'Cannot drop the table...', please ignore and continue the rest of SQLs.
  
 ============================================================================================================*/

----------------------------------------------------
-- 1. All PermID for current listed stocks for IBES2
----------------------------------------------------
/*
 Mapping rule with QA Direct master tables and IBES2 tables
 Domestic securities: SecMstrX.SecCode -> PermSecMapX.SecCode where EntType=55 and RegCode= 1 -> PermSecMapX.EntPermID -> TREInfo.QuotePermID
 Global securities: GSecMstrX.SecCode -> PermSecMapX.SecCode where EntType=55 and RegCode= 0 -> PermSecMapX.EntPermID -> TREInfo.QuotePermID

 <Take all Japanese stocks from GSecMstrX with EntPermID>
 ---------------------------------------------------------*/

drop table #alljp_ibes2
select
	gmst.SecCode
,	gmst.Isin
,	gmst.Name
,	gmap.VenCode
,	pmap.EntPermID
,	pmap.EndDate
,	iifo.QuotePermID
,	iifo.EstPermID
into #alljp_ibes2
from
	GSecMstrX gmst
	join GSecMapX gmap on gmst.SecCode = gmap.SecCode 
		and gmap.VenType=2
	join PermSecMapX pmap on gmst.SecCode=pmap.SecCode 
		and pmap.RegCode=0           -- 0=Global, 1=US only
		and pmap.EntType=55          -- QuotePermID (mapping with IBES2)
		and pmap.EndDate > getdate() -- Exclude delisted stocks
	join TREInfo iifo on pmap.EntPermID = iifo.QuotePermID
where
	gmst.Country='JPN'
order by Name asc


select * from #alljp_ibes2 order by Name -- (sample) 7203.T Toyota Motors.. EstPermID=30064817552, EntPermID=55837434056, QuotePermID=55837434056


-----------------------
-- 2. Available items
-----------------------
drop table #measlist_jp
select
	distinct(Measure)
into #measlist_jp
from
	TRESumPer esum
where
	EstPermID in (select distinct EstPermID from #alljp_ibes2)
	and IsParent=0 -- Consolidated
	and PerType=4 -- Year
	and PerEndDate > GetDate()
	and format(PerEndDate, 'yyyyMM') > format(dateadd(year, -3, getdate()), 'yyyyMM') -- Strict recent 3 years to speed-up the query
	and ExpireDate is null

/*---------------------------------
 * The list of available data items
 *---------------------------------*/
select
	ml.*
,	de.Description
from 
	#measlist_jp ml
	join TRECode de on ml.Measure = de.Code and de.CodeType=5 -- CodeType=4 (measure code), CodeType=5 (measure name)
order by
	ml.Measure

select * from TRECode


--------------------------------------------------------------------------------------------------
-- 3. Show all consensus data items for a stock (7203.T Toyota Motors) on a specific date of FY1.
--    The data is annual and consolidated.
--    @myMonth is 'yyyyMM'
--------------------------------------------------------------------------------------------------

declare @myMonth char(6);
select @myMonth = '201610'; -- <<== Please specify the month in 'yyyyMM' format

-----------------------------

declare @fMyMonth char(8);
select @fMyMonth = @myMonth + '01';

select top 10000
	cd.Description
,	su.*
from
	TRESumPer su
	join TREPerIndex ix on su.EstPermID=ix.EstPermID and su.PerType=ix.PerType and su.PerEndDate=ix.PerEndDate
	join TRECode cd on su.Measure=cd.Code and cd.CodeType=5
where
	su.EstPermID=30064817552
	and su.EffectiveDate between convert(datetime, @fMyMonth, 112) and dateadd(month, 1, dateadd(day, -1, convert(datetime, @fMyMonth, 112))) 
	and su.IsParent = 0 -- consolidated
	and su.PerType = 4 -- 1=long-term, 2=month, 3=quater, 4=annual, 5=half-year
	and ix.PerIndex = 1



-------------------------------------------------------------------------------
-- 4. Show all consensus data items for a universe on a specific month of FY1.
--    The data is annual and consolidated.
--    @myMonth is 'yyyyMM'
-------------------------------------------------------------------------------

declare @myMonth char(6);
select @myMonth = '201610'; -- <<== Please specify the month in 'yyyyMM' format

-----------------------------

declare @fMyMonth char(8);
select @fMyMonth = @myMonth + '01';

select
	cd.Description
,	su.*
from
	TRESumPer su
	join TREPerIndex ix on su.EstPermID=ix.EstPermID and su.PerType=ix.PerType and su.PerEndDate=ix.PerEndDate
	join TRECode cd on su.Measure=cd.Code and cd.CodeType=5
where
	su.EstPermID in (select EstPermID from #alljp_ibes2)
	and su.EffectiveDate between convert(datetime, @fMyMonth, 112) and dateadd(month, 1, dateadd(day, -1, convert(datetime, @fMyMonth, 112))) 
	and su.IsParent = 0 -- consolidated
	and su.PerType = 4 -- 1=long-term, 2=month, 3=quater, 4=annual, 5=half-year
	and ix.PerIndex = 1
order by 
	EstPermID asc
,	Measure asc
,	EffectiveDate desc


--------------------------------- Retrieve all DS2 current JP stocks
drop table #ds2jp
select
	dmap.*
,	difo.*
into #ds2jp
from
	vw_Ds2Mapping dmap
	join vw_Ds2SecInfo difo on dmap.VenCode=difo.InfoCode
where
	difo.IsPrimQt = 1
	and difo.StatusCode='A'
	and difo.CountryTradingInName='JAPAN'

drop table #ibsdsjp
select 
	ibs2.SecCode
,	ibs2.Name
,	ibs2.EntPermID
,	ibs2.EstPermID
,	ds2j.InfoCode
,	ds2j.DsQtName
,	ds2j.PrimaryExchange
,	convert(int, right(dsqt.DsLocalCode,4)) as 'Ticker'
into #ibsdsjp
from
	#alljp_ibes2 ibs2
	join #ds2jp ds2j on ibs2.SecCode=ds2j.SecCode
	join Ds2CtryQtInfo dsqt on ds2j.InfoCode=dsqt.InfoCode
