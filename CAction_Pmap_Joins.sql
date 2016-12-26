
/*
 Corporate actions (stock split check)
 
 4528 Ono Pharma 1:5, EstPermID=30064809841
 発表日			 : 2016/3/4
 権利付最終売買日: 2016/3/28
 権利落ち日      : 2016/3/29
 新株式売却可能日: 2016/3/29

 3092 Start Today 1:3 EstPermID=30064775467
 発表日			 : 2016/7/29
 権利付最終売買日: 2016/9/27
 権利落ち日      : 2016/9/28
 新株式売却可能日: 2016/9/28

 3673 Broadleaf 1:2 EstPermID=30064869328
 発表日
 権利付最終売買日: 2016/12/13
 権利落ち日　　　: 2016/12/14
 新株式売却可能日: 2016/12/14

 6161 Estic 1:2 EstPermID=30064810039
 発表日
 権利付最終売買日: 2016/12/15
 権利落ち日　　　: 2016/12/16
 新株式売却可能日: 2016/12/16

 */

------------------ All JP stocks for EstPermID
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

select * from #alljp_ibes2 order by Name
-------------------

------------------- Historical EPS in IBES2

-- 4528.T Ono Pharma EstPermID=30064809841
-- 3092.T Start Today EstPermID=30064775467
select
	cd.Description
,	su.*
,	ix.*
from
	TRESumPer su
	join TREPerIndex ix on su.EstPermID=ix.EstPermID and su.PerType=ix.PerType and su.PerEndDate=ix.PerEndDate
	join TRECode cd on su.Measure=cd.Code and cd.CodeType=5
where
	su.EstPermID=30064809841
	and su.Measure=9 -- EPS
	and su.IsParent = 0 -- consolidated
	and su.PerType = 4 -- 1=long-term, 2=month, 3=quater, 4=annual, 5=half-year
order by
	su.PerEndDate, su.EffectiveDate



/*
 Check query execution time for TRESumPer
 */
declare @startTime datetime
set @startTime = GETDATE()
select
	cd.Description
,	su.*
,	ix.*
from
	TRESumPer su
	join TREPerIndex ix on su.EstPermID=ix.EstPermID and su.PerType=ix.PerType and su.PerEndDate=ix.PerEndDate
	join TRECode cd on su.Measure=cd.Code and cd.CodeType=5 where
	su.EstPermID=30064810039 -- 6161 Estic 12/16分割実施
	and su.Measure=9 -- EPS
	and su.IsParent = 0 -- consolidated
	and su.PerType = 4 -- 1=long-term, 2=month, 3=quater, 4=annual, 5=half-year 
order by
	su.PerEndDate, su.EffectiveDate
select convert(varchar, GETDATE()-@startTime, 114) as sqlTime



