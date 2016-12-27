
/*
 QuotePermID=55838855991: BANK ST PETERSBURG RUB1(RUB) <- a Russian Bank
 It's unique in master tables and there's nothing in "PrevSedol", "Sedol2", and "PrevSedol2"
 InstrPermID=8589991128
 OrgPermID=4298010041
 EstPermID=30064773379
 EntPermID=55838855991 <- same as QuotePermID
 SecCode=556018
 Sedol=B596R6
*/
select
        gmst.*
,       gmap.*
,       pmap.*
,       iifo.*
from
        GSecMstrX gmst
        join GSecMapX gmap on gmst.SecCode = gmap.SecCode
                and gmap.VenType=2
        join PermSecMapX pmap on gmst.SecCode=pmap.SecCode
                and pmap.RegCode=0           -- 0=Global, 1=US only
                and pmap.EntType=55          -- QuotePermID (mapping with IBES2)
        join TREInfo iifo on pmap.EntPermID = iifo.QuotePermID where
        QuotePermID=55838855991

/*
 There 2 Sedols for the bank in PermSedolData table
*/
declare @myDay as date
select @myDay = '2014-12-26'

select
    *
from
    PermSedolData
where
    QuotePermID=55838855991
	and StartDate < @myDay
	and EndDate > @myDay

/*
 There's no Sedol change
 */
select * from SecSdlChg where SecCode=556018
select * from SecSdl2Chg where SecCode=556018

-------------------------------
select * from PermSedolData where QuotePermID=55838855991
select * from PermRicData where QuotePermID=55838855991
select * from PermCusipData where InstrPermID=8589991128
select * from PermISINData where InstrPermID=8589991128

select * from PermQuoteInfo where QuotePermID=55838855991
select * from PermQuoteRef where QuotePermID=55838855991

select
    psd.*
,   prd.*
from
    PermSedolData psd
	left join PermRicData prd on psd.QuotePermID=prd.QuotePermID
where
    psd.QuotePermID=55838855991

/*********************************************************************

・Merger、delistingのあった銘柄について
TreSumPerでうまく見つけることができません。
例えば、以下の条件でEPS予想を取得することはできますか。

銘柄：
    ALBERTSON'S LLC SecCode=2862(sedol= 2012467) <- EntPermID=55839792452, 
    LEHMAN BROTHERS SecCode=10819989 or 10975604（sedol= 2510723）
日付：2003/12/31

**********************************************************************/

select
	smx.*
,   psm.*
,   ifo.*
from
    vw_securityMasterX smx
	join PermSecMapX psm on smx.SecCode=psm.SecCode and psm.EntType=55 and psm.RegCode=0
	join TREInfo ifo on psm.EntPermID=ifo.QuotePermID
where
	--smx.SecCode=10975604
	smx.Name like 'UBS%'
	and country='CHE'


select
	cd.Description as "item_name"
,   cd2.Description as "item_currency"
,	su.*
from
	TRESumPer su
	join TREPerIndex ix on su.EstPermID=ix.EstPermID and su.PerType=ix.PerType and su.PerEndDate=ix.PerEndDate
	join TRECode cd on su.Measure=cd.Code and cd.CodeType=5
	join TRECode cd2 on su.DefCurrPermID=cd2.Code and cd2.CodeType=6
where
	su.EstPermID=30064779506 -- UBS
	and su.IsParent = 0 -- consolidated
	and su.PerType = 4 -- 1=long-term, 2=month, 3=quater, 4=annual, 5=half-year
order by
	su.EffectiveDate


/**********************************************************************
・決算期が変わった場合
決算月が替わった場合、2種類の会計期が併存するように見受けられます。 <- Yes
どの決算月が正しいかデータ上で判別することはできますか。 <- FYEMonth changed on EffectiveDate
また、Annualが12か月でない場合の月数はどこで取得することができますか。 <- TREPerIndex.PerLength
***********************************************************************/

select
	cd.Description as "item_name"
,   cd2.Description as "item_currency"
,	su.*
,   ix.*
from
	TRESumPer su
	join TREPerIndex ix on su.EstPermID=ix.EstPermID and su.PerType=ix.PerType and su.PerEndDate=ix.PerEndDate
	join TRECode cd on su.Measure=cd.Code and cd.CodeType=5
	join TRECode cd2 on su.DefCurrPermID=cd2.Code and cd2.CodeType=6
where
	su.EstPermID=30064803750 -- Kagome
	and su.IsParent = 0 -- consolidated
	and su.PerType = 4 -- 1=long-term, 2=month, 3=quater, 4=annual, 5=half-year
	--and ix.PerIndex = 1
	and su.Measure=4 -- DPS
order by
	su.EffectiveDate


/**********************************************************************
・企業がグループや持株会社に変わるとき
例えば、UBSが2014/11にグループに変わった時に、2014/10/31でUBSのEPS予想を探しに行くと、旧コードでも新コードでも取得することができません。<- New code=OK.

旧：B18YFJ4
新：BRJL176

おそらくTreSumPerとPermSedolDataで期間の持ち方に不整合がおきているような気がします。
このような場合はどのようにすればよいでしょうか。

***********************************************************************/

select
	smx.*
,   psm.*
,   ifo.*
from
    vw_securityMasterX smx
	join PermSecMapX psm on smx.SecCode=psm.SecCode and psm.EntType=55 and psm.RegCode=0
	join TREInfo ifo on psm.EntPermID=ifo.QuotePermID
where
	--smx.SecCode=10975604
	smx.Name like 'UBS%'
	and country='CHE'


select
	cd.Description as "item_name"
,   cd2.Description as "item_currency"
,	su.*
from
	TRESumPer su
	join TREPerIndex ix on su.EstPermID=ix.EstPermID and su.PerType=ix.PerType and su.PerEndDate=ix.PerEndDate
	join TRECode cd on su.Measure=cd.Code and cd.CodeType=5
	join TRECode cd2 on su.DefCurrPermID=cd2.Code and cd2.CodeType=6
where
	su.EstPermID=30064815126 -- UBS
	and su.IsParent = 0 -- consolidated
	and su.PerType = 4 -- 1=long-term, 2=month, 3=quater, 4=annual, 5=half-year
	and su.Measure=4 -- DPS
order by
	su.EffectiveDate, su.PerEndDate

