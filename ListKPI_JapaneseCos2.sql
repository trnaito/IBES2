
/*====================================================================================================================

 Version 1.0 2016/11/08 Ryoichi Naito ryoichi.naito@thomsonreuters.com

 To search all available KPIs of Japanese stocks, the final result from this query will be used to be the stock list
 which is mapped to all available IBES2 items.

 Temp tables:
 #measlist_jp .. All IBES2 items for Japanese stocks
 #ibsdsjp .. All Japanese stocks with EstPermID which is the key ID for IBES2 data.

 Note: If you encountered an error 'Cannot drop the table...', please ignore and continue the rest of SQLs.
  
 ====================================================================================================================*/

------------------------------------------------------------------------------
-- 1. List all PermID for current listed stocks where IBES2 data is available
------------------------------------------------------------------------------
/*
 Domestic securities: SecMstrX.SecCode -> PermSecMapX.SecCode where EntType=55 and RegCode= 1 -> PermSecMapX.EntPermID -> TREInfo.QuotePermID
 Global securities: GSecMstrX.SecCode -> PermSecMapX.SecCode where EntType=55 and RegCode= 0 -> PermSecMapX.EntPermID -> TREInfo.QuotePermID
*/
---------------------------------- Take all JPM stocks from GSecMstrX with EntPermID
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
	join GSecMapX gmap on gmst.SecCode = gmap.SecCode and gmap.VenType=2
	join PermSecMapX pmap on gmst.SecCode=pmap.SecCode and pmap.RegCode=0 and pmap.EntType=55 and pmap.EndDate > getdate()
	join TREInfo iifo on pmap.EntPermID = iifo.QuotePermID
where
	gmst.Country='JPN'
order by Name asc

select * from #alljp_ibes2

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


--------------------------------------------------------
-- 2. Pick only available items for FY 2016/10 - 2017/9
--------------------------------------------------------
drop table #measlist_jp
select
	distinct(Measure)
into #measlist_jp
from
	TRESumPer esum
where
	EstPermID in (select distinct EstPermID from #ibsdsjp)
	and IsParent=0 -- Consolidated
	and PerType=4 -- Year
	and PerEndDate > GetDate()
	and format(PerEndDate, 'yyyyMM') between '201610' and '201709'
	and ExpireDate is null


------------------------------------------------------------------------
-- 3. Summarize and format the table and delete unnecessary temp tables
------------------------------------------------------------------------
select
	mname.*
from
	#measlist_jp mlst
	join TRECode mname on mlst.Measure=mname.Code
where
	mname.CodeType=5

drop table #alljp_ibes2
drop table #ds2jp

-------------------------------------
-- 4. Sample KPI data for each stock 
-------------------------------------
select * from #ibsdsjp

select distinct top 1000
	tsum.EstPermID
,	tsum.Measure
,	mcod.Description
,	Min(tsum.PerEndDate)
,	tsum.DefMeanEst
from
	TRESumPer tsum
	join TRECode mcod on tsum.Measure = mcod.Code and mcod.CodeType=5
where
	tsum.EstPermID=30064825471
	and tsum.ExpireDate is null
	and tsum.PerEndDate > GetDate()
group by
	tsum.EstPermID, tsum.Measure, mcod.Description, tsum.DefMeanEst

	-- and IsParent=0 -- Consolidated
	-- and PerType=4 -- Year
	-- and (DateDiff(year, PerEndDate, EffectiveDate) = 0 -- temporary specify Konki
	-- or (EffectiveDate>='2016-07-25' and DateDiff(year, PerEndDate, EffectiveDate) <0))

