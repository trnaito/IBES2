-- CTE tables

with vw_SecurityMasterX as
	(
	select m.seccode,m.id,m.typ,m.sedol,m.prevSedol,m.sedol2,m.prevSedol2,m.cusip,m.prevcusip,m.isin,m.name,m.country
		from (
			 select seccode,id,1 as typ,sedol,prevSedol,sedol2,prevSedol2,cusip,prevcusip,isin,name,country from secmstrx where type_ = 1 
			 union all 
			 select seccode,id,6 as typ,sedol,prevSedol,sedol2,prevSedol2,cusip,prevcusip,isin,name,country from gsecmstrx where type_ = 10
			 )	as m
	)
	, vw_IBES2Mapping	as
	(
	select		SecCode, RegCode, Typ, IBESTicker, EstPermID, QuotePermID, InstrPermID, CtryPermID, Source_
		from	(
				select		SecCode
							, RegCode
							, IBESTicker
							, EstPermID
							, QuotePermID
							, CtryPermID
							, InstrPermID

							, case RegCode 
								when 0 then 6 
								else 1 
							  end									as Typ

							, case Priority_ 
								when 1 then 'instrPrimaryQuote' 
								when 2 then 'quote' 
								when 3 then 'instrument' 
							  end									as Source_

							, row_number() over (partition by RegCode,SecCode order by Priority_,ExpireDate desc,EffectiveDate desc,Rank) as Rank_

					from	(
							select			2						as Priority_ 
											, p.RegCode
											, p.SecCode
											, p.[Rank] 
											, t.IBESTicker
											, t.EstPermID
											, t.QuotePermID
											, t.CtryPermID
											, t.InstrPermID
											, coalesce(dateadd(mi,-(t.ExpireOffset),t.ExpireDate),'2079-12-31')			as ExpireDate
											, coalesce(dateadd(mi,-(t.EffectiveOffset),t.EffectiveDate),'2079-12-31')	as EffectiveDate
								
								from		PermSecMapx			as p

								left join	TREInfo				as t
									on		t.QuotePermID		= p.EntPermID 
								
								where		p.EntType			= 55
									and		t.IBESTicker		is not null
							
							union all
 
							select			1					as Priority_ 
											, p.RegCode
											, p.SecCode
											, p.[Rank]
											, t.IBESTicker
											, t.EstPermID
											, t.QuotePermID
											, t.CtryPermID
											, q.InstrPermID
											, coalesce(dateadd(mi,-(t.ExpireOffset),t.ExpireDate),'2079-12-31')			as ExpireDate
											, coalesce(dateadd(mi,-(t.EffectiveOffset),t.EffectiveDate),'2079-12-31')	as EffectiveDate
								
								from		PermSecMapx			as p
								
								left join	PermQuoteRef		as q
									on		q.InstrPermID		= p.EntPermID 
									and		q.IsPrimary			= 1
								
								left join	TREInfo			as t
									on		t.QuotePermID		= q.QuotePermID 
									and		t.CtryPermID		in (100052,100319)

								where		p.EntType			= 49
									and		p.RegCode			= 1	 
									and		t.IBESTicker		is not null										
													
							union all
					
							select			3					as Priority_ 
											, p.RegCode
											, p.SecCode
											, p.[Rank] 
											, t.IBESTicker
											, t.EstPermID
											, t.QuotePermID
											, t.CtryPermID
											, t.InstrPermID
											, coalesce(dateadd(mi,-(t.ExpireOffset),t.ExpireDate),'2079-12-31')			as ExpireDate
											, coalesce(dateadd(mi,-(t.EffectiveOffset),t.EffectiveDate),'2079-12-31')	as EffectiveDate
								
								from		PermSecMapx			as p
								
								left join	TREINfo				as t
									on		t.InstrPermID		= p.EntPermID 
									and		t.CtryPermID		in (100052,100319)
								
								where		p.EntType			= 49
									and		p.RegCode			= 1		
									and		t.IBESTicker		is not null
							)	in_
				)	out_
		
		where	Rank_		= 1
	)

-- Main query

select			mstr.Id
				, map.Source_

				, c5.Description
				
				, sum_.IsParent
				, sum_.PerType
				, sum_.PerEndDate
				, sum_.EffectiveDate
				, sum_.ExpireDate
				, sum_.FYEMonth
				, sum_.DefMeanEst
				, sum_.DefCurrPermID
				, c6.Description
				, sum_.DefScale
				
				

	from		vw_SecurityMasterX			as mstr		
	
	join		vw_IBES2Mapping				as map
		on		map.SecCode					= mstr.SecCode
		and		map.typ						= mstr.typ

	join		TREInfo						as info
		on		info.EstPermID				= map.EstPermID		

	join		TRESumPer					as sum_
		on		sum_.EstPermID				= info.EstPermID	
	
	join		TRECode						as c5
		on		c5.CodeType					= 5
		and		c5.Code						= sum_.Measure

	join		TRECode						as c6
		on		c6.CodeType					= 6
		and		c6.Code						= sum_.DefCurrPermID

	where		1 = 1
		and		mstr.sedol					in ('690064') --'B03MLX','B03MM4','B09CBL')	-- list of sedol 

	order by	mstr.Id, sum_.Measure, sum_.PerEndDate
	