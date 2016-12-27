
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

�EMerger�Adelisting�̂����������ɂ���
TreSumPer�ł��܂������邱�Ƃ��ł��܂���B
�Ⴆ�΁A�ȉ��̏�����EPS�\�z���擾���邱�Ƃ͂ł��܂����B

�����F
    ALBERTSON'S LLC SecCode=2862(sedol= 2012467) <- EntPermID=55839792452, 
    LEHMAN BROTHERS SecCode=10819989 or 10975604�isedol= 2510723�j
���t�F2003/12/31

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
�E���Z�����ς�����ꍇ
���Z�����ւ�����ꍇ�A2��ނ̉�v������������悤�Ɍ��󂯂��܂��B <- Yes
�ǂ̌��Z�������������f�[�^��Ŕ��ʂ��邱�Ƃ͂ł��܂����B <- FYEMonth changed on EffectiveDate
�܂��AAnnual��12�����łȂ��ꍇ�̌����͂ǂ��Ŏ擾���邱�Ƃ��ł��܂����B <- TREPerIndex.PerLength
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
�E��Ƃ��O���[�v�⎝����Ђɕς��Ƃ�
�Ⴆ�΁AUBS��2014/11�ɃO���[�v�ɕς�������ɁA2014/10/31��UBS��EPS�\�z��T���ɍs���ƁA���R�[�h�ł��V�R�[�h�ł��擾���邱�Ƃ��ł��܂���B<- New code=OK.

���FB18YFJ4
�V�FBRJL176

�����炭TreSumPer��PermSedolData�Ŋ��Ԃ̎������ɕs�����������Ă���悤�ȋC�����܂��B
���̂悤�ȏꍇ�͂ǂ̂悤�ɂ���΂悢�ł��傤���B

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

