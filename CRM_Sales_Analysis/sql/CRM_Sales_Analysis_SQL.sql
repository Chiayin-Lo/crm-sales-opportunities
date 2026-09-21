-- 01. Data Familiarization

-- After creating tables and importing csv data, check import status and the number of records in each table. 
select
    (select count(*) from accounts) as accounts_count,
    (select count(*) from products) as products_count,
    (select count(*) from sales_pipeline) as sales_pipeline_count,
    (select count(*) from sales_teams) as sales_teams_count;

-- 02. Baseline Analysis 

-- Evaluation objective
-- Introduce the outlook of the overall sales opportuntiy to portray a baseline for the performance. 
-- Establish a win-rate benchmark to faciliate investigation into drivers of the outcomes.

-- Approach 
-- 1. Identify the unit of analyis and the size of the pipeline
select * from sales_pipeline;
-- Each row represents an opportunity id, a sales opportunity 
-- The given unit is the base of win/lost outcome evaluation
select count(*) from sales_pipeline;
-- There are 8800 opportunities

-- 2. Describe the opportunity stages
select distinct deal_stage
from sales_pipeline;
select deal_stage, count(*) as opp_nb
from sales_pipeline
group by deal_stage;
-- There are 4 stages: won, prospecting, lost and engaging
-- The won stage has the most opportunities (4238 units) and prospecing the least (500 units)
-- Won and lost stages are considered successful and unsuccessful respectively
-- Prospecting and Engaging stages are not considered in the evaluation since they aren't finalized

-- 3. Calculate the overall win rate 
-- Formula: win rate = won opp nb/ (won + lost) opp nb
select round(count(*)filter(where deal_stage = 'Won'):: numeric/ count(*)filter(where deal_stage in ('Won', 'Lost')) * 100, 2) as win_rate
from sales_pipeline;
-- The overall win-rate benchmark is 63.15% across the opportunity pipeline 
-- This indicates around 63 are won out of 100 finanlized opportunities
-- The benchmark will be used to compare in the performance analysis of the drivers

-- 03. Product Analysis

-- Hypothesis:
-- Product series have different win rates.
-- Test:
select product, round(count(*)filter(where deal_stage = 'Won'):: numeric/ count(*)filter(where deal_stage in ('Won', 'Lost')) * 100, 2) as win_rate
from sales_pipeline
group by product
order by win_rate;
-- Result: the gap between win rates is insignificant across different products 
-- The percetage-point gap is 64.84% - 60.00% = 4.84%, only around 5 percentage points across products
-- The analysis suggests product may not be a major driver to win rate.

-- 04. Sales Analysis 

-- Hypothesis:
-- Sales teams/agents affect win rates.
-- Test:
select sales_agent, round(count(*)filter(where deal_stage = 'Won'):: numeric/ count(*)filter(where deal_stage in ('Won', 'Lost')) * 100, 2) as win_rate
from sales_pipeline
group by sales_agent
order by win_rate;
select round(avg(win_rate),2) as avg_win_rate, round(stddev_samp(win_rate),2) as sd_win_rate, round(max(win_rate) - min(win_rate),2) as range_win_rate
from (select sales_agent, round(count(*)filter(where deal_stage = 'Won'):: numeric/ count(*)filter(where deal_stage in ('Won', 'Lost')) * 100, 2) as win_rate
from sales_pipeline
group by sales_agent) t;
-- Result: the range of win rates across different sales agents is 15.41 pp, the average is 63.51%, and the standard deviation is 3.67 pp
-- The indicators suggest that gap is noticeable but the the sample values are relatively clustered without significant difference
-- The analysis does not show a strong effect on win rates from sales agents.

-- 05. Sales Cycle Analysis

-- Hypothesis:
-- Longer sales cycles result in lower win rates.
-- Test:
with sales_cycle_category as (
select (case when close_date - engage_date <= 30 and close_date - engage_date >= 0 then 'very short' 
when close_date - engage_date > 30 and close_date - engage_date <= 60 then 'short' 
when close_date - engage_date > 60 and close_date - engage_date <= 90 then 'medium'
when close_date - engage_date > 90 and close_date - engage_date <= 180 then 'long'
when close_date - engage_date > 180 then 'very long' end) as sales_cycle, deal_stage, close_value, close_date
from sales_pipeline)
-- Categorize various sales cycles into 5 groups: 'very short', 'short', 'medium', 'long', 'very long'
select sales_cycle, round(count(*)filter(where deal_stage = 'Won'):: numeric/count(*)filter(where deal_stage in ('Won', 'Lost')) * 100, 2) as win_rate
from sales_cycle_category
where sales_cycle is not null 
group by sales_cycle
order by win_rate;
-- Result: Longer sales cycles are correlated with higher win rates.
-- The percetage-point gap is 71.13% - 57.45% = 13.68%.

-- Check the deal volumn per category 
select sales_cycle, count(*) as total_deal_nb, count(case when deal_stage = 'Won' then 1 end) as won_nb, count(case when deal_stage = 'Lost' then 1 end) as lost_nb
from sales_cycle_category
where sales_cycle is not null
group by sales_cycle
order by total_deal_nb desc;
-- Result: The shortest sales cycle also has the largest deal volumn (3163) while the longest sales cycle also has a solid deal volumn(1358).
-- Having 3,163 deals in the shortest category and 1,358 in the longest category does make the result more useful and refutes the hypothesis. 
-- ** if volumn, sales allocated time, poor quality, marketing-sales inefficiency

-- H1a: High opportunity volume at sales_agent/product/account may be associated with lower win rates.
select sales_agent, count(*) as deal_nb, round(count(*)filter(where deal_stage = 'Won'):: numeric/count(*)filter(where deal_stage in ('Won', 'Lost')) * 100, 2) as win_rate
from sales_pipeline
group by sales_agent
order by deal_nb desc;
-- Win rates do not vary significantly to volumn at the sales agent level -- higher volumn does not have lower win rates.
select product, count(*) as deal_nb, round(count(*)filter(where deal_stage = 'Won'):: numeric/count(*)filter(where deal_stage in ('Won', 'Lost')) * 100, 2) as win_rate
from sales_pipeline
group by product
order by deal_nb desc;
-- Win rates do not vary significantly to volumn at the product level -- higher volumn does not have lower win rates.
select account, count(*) as deal_nb, coalesce(round(count(*)filter(where deal_stage = 'Won'):: numeric/nullif(count(*)filter(where deal_stage in ('Won', 'Lost')),0) * 100, 2),0) as win_rate
from sales_pipeline
group by account
order by deal_nb desc;
-- Companies with higher opportunity volumes do not consistently achieve higher or lower win rates.
select extract(year from close_date) as year, extract(quarter from close_date) as quarter, count(*) as deal_nb, sum(close_value) as revenue, coalesce(round(count(*)filter(where deal_stage = 'Won'):: numeric/nullif(count(*)filter(where deal_stage in ('Won', 'Lost')),0) * 100, 2),0) as win_rate
from sales_pipeline
group by year, quarter
order by quarter;
-- First quarter with the lowest deal number has the highest win rate.
-- However, quarters with lower deal numbers do not consistently show higher win rates.
-- Result: The volume analysis does not provide a clear alternative explanation for the observed relationship between sales cycle and win rate.

-- H1b: Does the sales-cycle relationship remain consistent across time quarters?
-- Check the timing per category 
select extract(year from close_date) as year, extract(quarter from close_date) as quarter, sales_cycle, count(*) as deal_nb, coalesce(round(count(*)filter(where deal_stage = 'Won'):: numeric/nullif(count(*)filter(where deal_stage in ('Won', 'Lost')),0) * 100, 2),0) as win_rate
from sales_cycle_category
group by year, quarter, sales_cycle
order by quarter, sales_cycle;
-- Result: Sales cycle length is not consistently associated with win rate across time quarters.
-- Timing may serve as alternative explanation for the cycle vs win-rate relatonship as shorter cycle deals exist more in quarters with lower win rates.

-- Conclusion: 
-- Sales-cycle length is associated with win rate but the relationship between sales-cycle length and win rate is not consistent across quarters. 
-- While longer-cycle opportunities have higher win rates from Q2 onward, this pattern does not hold in Q1. 
-- This suggests that timing may influence the observed relationship between sales-cycle length and win rate.
-- Therefore, sales-cycle length alone should not be interpreted as the primary driver of win rate.

-- 06. Time Quarter Analysis

-- Hypothesis: 
-- Sales seasons/timing affect win rates.
-- Test:
select extract(year from close_date) as year, extract(quarter from close_date) as quarter, coalesce(round(count(*)filter(where deal_stage = 'Won'):: numeric/nullif(count(*)filter(where deal_stage in ('Won', 'Lost')),0) * 100, 2),0) as win_rate
from sales_pipeline
group by year, quarter
order by quarter;
-- Result: Q1 exhibits an unexpectedly high win rate, whereas win rates across the remaining quarters remain stable.
-- The analysis does not establish a consistent quarterly or seasonal effect, with win rate concentrated in Q1.

-- 07. Region Analysis
-- Hypothesis a: 
-- Sales regions have different win rates.
-- Test:
select st.regional_office, count(*) as deal_nb, coalesce(round(count(*)filter(where sp.deal_stage = 'Won'):: numeric/nullif(count(*)filter(where sp.deal_stage in ('Won', 'Lost')),0) * 100, 2),0) as win_rate
from sales_pipeline sp
join sales_teams st
on sp.sales_agent = st.sales_agent 
group by st.regional_office
order by win_rate desc;
-- Result: The win rates across different regional sales offices remain stable.
-- The analysis shows sales regions do not hold significant effect on win rate outcomes.

-- Hypothesis a: 
-- Customer regions have different win rates.
-- Test:
select a.office_location, count(*) as deal_nb, coalesce(round(count(*)filter(where sp.deal_stage = 'Won'):: numeric/nullif(count(*)filter(where sp.deal_stage in ('Won', 'Lost')),0)* 100, 2),0) as win_rate
from sales_pipeline sp
join accounts a
on sp.account = a.account
group by a.office_location
order by win_rate desc;
-- Result: The percentage-point gap across different customer office locations is 18.9%.
-- There are noticeable win-rate differences among office locations/countries. 

-- 08. Customer Analysis
-- Hypothesis a: 
-- Customer industry sectors display different win rates.
-- Test:
select a.sector, count(*) as deal_nb, coalesce(round(count(*)filter(where sp.deal_stage = 'Won'):: numeric/nullif(count(*)filter(where sp.deal_stage in ('Won', 'Lost')),0)* 100, 2),0) as win_rate
from sales_pipeline sp
join accounts a
on sp.account = a.account
group by a.sector 
order by win_rate desc;
-- Result: The percetage-point gap across different account sectors is only 3.68%.
-- Win rates do not vary significantly by customer industry. 

-- Hypothesis b: 
-- Customer revenue display different win rates.
-- Test:
select a.revenue, count(*) as deal_nb, coalesce(round(count(*)filter(where sp.deal_stage = 'Won'):: numeric/nullif(count(*)filter(where sp.deal_stage in ('Won', 'Lost')),0)* 100, 2),0) as win_rate
from sales_pipeline sp
join accounts a
on sp.account = a.account
group by a.revenue 
order by win_rate desc, a.revenue desc;
-- Result: The percetage-point gap across different customer revenues is noticeable, with the value of 21.87%.
-- The second hypothesis is accepted but does not confirm customers with higher revenue have higher win rates.

-- Hb1: Are the office locations with higher win rates also higher in revenue?
-- Check customer locations and revenues
select a.office_location, sum(a.revenue) as revenue, count(*) as deal_nb, coalesce(round(count(*)filter(where sp.deal_stage = 'Won'):: numeric/nullif(count(*)filter(where sp.deal_stage in ('Won', 'Lost')),0)* 100, 2),0) as win_rate
from sales_pipeline sp
join accounts a
on sp.account = a.account
group by a.office_location 
order by win_rate desc;
-- Result: The revenue does not show a consistent pattern in relationship with location and win rate.
-- The office locations with higher win rates do not hold higher revenue.




