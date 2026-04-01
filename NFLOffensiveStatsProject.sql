/* NFL Stats Project */

/* This Data set only records offensive players with recorded stats, so some stats may be missing for players who were drafted but did not play or did not have recorded stats. */

/* Let's start with Draft Picks. I want to see what conference had the most draft picks between 2023 and 2024. */

Select *
from NFLSportsProject.dbo.weekly_player_stats_offense;

Select 
	draft_year, 
	college_conference, 
	count(*) as num_draft_picks
from NFLSportsProject.dbo.weekly_player_stats_offense
where draft_year between '2023.0' and '2024.0'
group by draft_year, college_conference
order by draft_year, num_draft_picks desc;

-- Based on the Data, the SEC had the most draft picks in 2023 but second most in 2024. The Big Ten had the most Draft picks in 2024 but 4th most in 2023. 
-- The ACC and the Pac-12 are not far behind the SEC and Big Ten in terms of draft picks, but they are not consistently in the top spot. 
-- The American Athletic Conference and Conference USA usually have fewer dfraft picks each year.

-- I can conclude that based on the data, the SEC and Big Ten are the most successful conferences in terms of producing NFL draft picks, but there is some variability from year to year. The ACC and Pac-12 are also strong contenders, while the American Athletic Conference and Conference USA tend to have fewer draft picks.



/* Now let's look at how many positions were drafted (WR, QB, RB, TE, etc.) between rounds 1 and 3 and between 2023 and 2025 */

Select *
from NFLSportsProject.dbo.weekly_player_stats_offense;

SELECT
    draft_year,
    draft_round,
    position,
    COUNT(DISTINCT player_id) AS drafted_players
FROM NFLSportsProject.dbo.weekly_player_stats_offense
WHERE
    draft_year >= '2023.0' and draft_round Between '1.0' and '3.0'
GROUP BY
    draft_year,
    draft_round,
    position
ORDER BY
    draft_year,
    draft_round,
    drafted_players DESC;

-- Based on the Data, players with a recorded offensive stat (including defense for touchdowns), the most drafted position between rounds 1 and 3 in 2023 and 2024 was Wide Receiver (WR), followed by Running Back (RB) then Quarterback (QB).
-- This is suprising because I would have expected Quarterback to be the most drafted position in the first 3 rounds, espcially in the first round, but it is not.
-- We see some defensive roles like Corner Back (CB) and some offesnive lineman (C) & (G) that have some recorded stats, but they are not drafted as much as the skill positions (WR, RB, QB, TE).

-- I can conlcude to my suprise, that the most drafted position between rounds 1 and 3 in 2023 and 2024 was Wide Receiver (WR), followed by Running Back (RB) then Quarterback (QB) with a recorded offensive stat.



/* Let's dive into a the latest season. I'll look at QB effeciency by team for the 2024 Regular (REG) season. The teams I'll look at are the DET Lions, ARI Cardinals, BAL Ravens, & HOU Texans */

-- I did CAST() to have two decimal points and ROUND() was allowing extra zeros so we used CAST(). 

Select *
From NFLSportsProject.dbo.yearly_team_stats_offense;

WITH QB_Efficiency AS (
Select 
    team, 
    season, 
    CAST(
    ROUND(
        TRY_CONVERT(decimal(10,2), complete_pass) * 100.0
        / NULLIF(TRY_CONVERT(decimal(10,2), pass_attempts), 0),
        2
    ) AS decimal (5,2) 
    ) AS completion_percentage,
    CAST(
    ROUND(
        TRY_CONVERT(decimal(10,2), incomplete_pass) * 100.0
        / NULLIF(TRY_CONVERT(decimal(10,2), pass_attempts), 0),
        2
    ) AS decimal (5,2)
    ) AS incompletion_percentage, 
    qb_scramble,
    season_type

From NFLSportsProject.dbo.yearly_team_stats_offense
)

Select team, season, completion_percentage, incompletion_percentage, qb_scramble
From QB_Efficiency
where team in ('DET', 'ARI', 'BAL', 'HOU')
      AND season = '2024' 
      AND season_type = 'REG';

-- I used a CTE to simplify the format of looking at QB Efficiency by team for the 2024 Regular (REG) season.
-- There is a correlation to where the more the QB scrambles, the lower the completion percentage and typically a higher incompletion percentage.
-- Results can vary because some QBs are more mobile and scramble more often, but they may not be as accurate as a pocket passer, but could still complete passes at a high percentage.

-- Based on the results:
  -- DET had the highest completion percentage at roughly 74% and the lowest incompletion percentage at roughly 26% with the lowest QB scrambles at 15. They had one of the best Offensive lines and one of the best offenses in the league in 2024, so this makes sense.
  -- HOU had the lowest completion percentage at roughly 64% and the highest incompletion percentage at roughly 36% with the third highest QB scrambles at 41. They had one of the worst Offensive lines and one of the worst offenses in the league in 2024, so this also makes sense.
  -- BAL and ARI also had midicore offensive lines but they had mobile QBs who were able to have high completion percentages and low incompletion percentages with a high number of QB scrambles. This shows that mobile QBs can still be accurate passers and have high completion percentages even if they scramble a lot


/* Lastly, Let's look at the highest productive WR, RB and TE for the 2023 and 2024 seasons for their respected teams, including REG and POST Seasons and the most productive week they had */
/* The teams we'll look at are BUF, CIN, DAL, MIA */
/* We'll be joining the yearly team stats and weekly player stats */

Select *
from NFLSportsProject.dbo.yearly_player_stats_offense

Select *
from NFLSportsProject.dbo.weekly_player_stats_offense

/* WR Production */

WITH WR_Productivity AS (
    SELECT
        yr.player_id,
        yr.player_name,
        yr.team,
        yr.season,
        yr.position,
        yr.season_type,

        -- Year-level productivity
        yr.receiving_yards      AS season_receiving_yards,
        yr.receiving_touchdown     AS season_touchdowns,

        -- Most productive WEEK
        MAX(wk.receiving_yards)        AS max_week_receiving_yards,
        MAX(wk.receiving_touchdown)   AS max_week_receiving_td

    FROM NFLSportsProject.dbo.yearly_player_stats_offense  yr
    JOIN NFLSportsProject.dbo.weekly_player_stats_offense wk
        ON yr.player_id = wk.player_id
       AND yr.season    = wk.season
       AND yr.team      = wk.team

    WHERE yr.position = 'WR'
      AND yr.season IN ('2023', '2024')
      AND yr.team   IN ('BUF', 'CIN', 'DAL', 'MIA')

    GROUP BY
        yr.player_id,
        yr.player_name,
        yr.team,
        yr.season,
        yr.position,
        yr.receiving_yards,
        yr.receiving_touchdown,
        yr.season_type
)

SELECT *
FROM WR_Productivity
Where -- season = '2023'
season = '2024'
-- AND team = 'BUF'
-- AND team = 'CIN'
-- AND team = 'DAL'
AND team = 'MIA'
ORDER BY season_receiving_yards desc, season, team;

-- Based on the Data for WR, for the 2023 season we found:
    -- Stefon Diggs was the most productive WR for the BUF Bills:
    -- Diggs recorded 1,275 total yards in Post and Reg season and 8 total touchdowns. His best receicing yards in one game was 87 yards, along with 3 touchdowns in one of those games.

    -- Ja'Maar Chase was the most productive WR for the CIN Bengals:
    -- Chase recorded 1,244 total yards and 7 total touchdowns. His best receiving yards in one game was 81 yards, along with 3 touchdowns in one of those games.

    -- Brandin Cooks was the most productive WR for the DAL Cowboys:
    -- Cooks recorded 711 total yards and 8 total touchdowns. His best receiving yards in one game was 72 yards, along with 1 touchdown in one of those games. 

    -- Braxton Berrios was the most productive WR for the MIA Dolphins:
    -- Berrios recorded 238 total yards and 1 total touchdown. His best receiving yards in one game was 9 yards, along with 1 touchdown in one of those games. 
    -- Robbie Chosen had the best recieivng week out of all MIA WRs with 68 yards in a game. All receivers except for Chase Claypool had one touchdown max in one of their games.

-- Based on the Data for WR, for the 2024 season we found:
    -- Rookie WR Keon Coleman was the most productive WR for the BUF Bills (Diggs was traded this year):
    -- Coleman recorded 578 total yards and 4 total touchdowns. His best receiving yards in one game was 70 yards, along with 1 touchdown in one of those games.
    -- Amari Cooper had the best receiving week with 95 yards and a touchdown.

    -- Ja'Maar Chase was, again, the most productive WR for the CIN Bengals:
    -- Chase recorded 1708 total yards and 17 total touchdowns. His best receiving yards in one game was 97 yards, along with 3 touchdowns in one of those games.
    -- Chase exploded this year by recording more receiving yards and doubling more than his total touchdowns from the 2023 season.

    -- Brandin Cooks was, again, the most productive WR for the DAL Cowboys:
    -- Cooks recorded 259 total yards and 3 total touchdowns. His best receiving yards in one game was 52 yards, along with 1 touchdown in one of those games.
    -- Looks like Cooks had a down year and did not produce better numbers comapred to the 2023 season.

    -- River Cracraft was the most productive WR for the MIA Dolphins:
    -- Cracraft recorded 66 total yards and no touchdown. His best receiving yards in one game was 6 yards, and no touchdowns any of those weeks.
    -- Grant DuBose had the best receiving week with 13 yards and Odell Beckham Jr. (OBJ is his nickname, one of my favorite WRs), had the second best receiving season with 55 total yards
    -- Last year it was Berrios, but he did not record any stats which could most likely mean he had a season ending injury

-- Takeaways:
    -- For the 2023 season, Stefon Diggs, Ja'Maar Chase, and Brandin Cooks were the most productive WRs for their respective teams. Diggs and Chase had similar production in terms of yards and touchdowns, while Cooks had a lower yardage but a similar number of touchdowns. Braxton Berrios had a much lower production compared to the other three WRs.
    -- For the 2024 season, Ja'Maar Chase had an outstanding year with a significant increase in both yards and touchdowns compared to the previous year. Keon Coleman had a solid rookie season for the BUF Bills, while Brandin Cooks had a down year compared to his 2023 performance. River Cracraft had minimal production for the MIA Dolphins, and it seems like the team struggled to find a productive WR after Berrios' injury.
    -- Some teams also rush more than pass, so they may not have as much production from their WRs, but they could have more production from their RBs.

/* RB Production */

Select *
from NFLSportsProject.dbo.yearly_player_stats_offense

Select *
from NFLSportsProject.dbo.weekly_player_stats_offense

WITH RB_Productivity AS (
    SELECT
        yr.player_id,
        yr.player_name,
        yr.team,
        yr.season,
        yr.position,
        yr.season_type,

        -- Year-level productivity
        yr.rushing_yards      AS season_rushing_yards,
        yr.rush_touchdown     AS season_rushing_touchdowns,
        yr.receiving_yards      AS season_receiving_yards,
        yr.receiving_touchdown     AS season_receiving_touchdowns,

        -- Most productive WEEK
        MAX(wk.rushing_yards)        AS max_week_rushing_yards,
        MAX(wk.rush_touchdown)   AS max_week_rushing_td,
        MAX(wk.receiving_yards)        AS max_week_receiving_yards,
        MAX(wk.receiving_touchdown)   AS max_week_receiving_td

    FROM NFLSportsProject.dbo.yearly_player_stats_offense  yr
    JOIN NFLSportsProject.dbo.weekly_player_stats_offense wk
        ON yr.player_id = wk.player_id
       AND yr.season    = wk.season
       AND yr.team      = wk.team

    WHERE yr.position = 'RB'
      AND yr.season IN ('2023', '2024')
      AND yr.team   IN ('BUF', 'CIN', 'DAL', 'MIA')

    GROUP BY
        yr.player_id,
        yr.player_name,
        yr.team,
        yr.season,
        yr.position,
        yr.rushing_yards,
        yr.rush_touchdown,
        yr.season_type,
        yr.receiving_yards,
        yr.receiving_touchdown
)

SELECT *
FROM RB_Productivity
Where -- season = '2023'
season = '2024'
-- AND team = 'BUF'
-- AND team = 'CIN'
-- AND team = 'DAL'
AND team = 'MIA'
ORDER BY season_rushing_yards desc, season, team;


-- Based on the Data for RB, for the 2023 season we found:
    -- James Cook was the most productive RB for the BUF Bills:
    -- Cook recorded 1,412 total rushing yards and 474 receiving yards in Post and Reg season, along with 2 rushing touchdowns and 4 receiving touchdowns. 
    -- His best rushing yards in one game was 98 yards, along with 1 rushing touchdown in one of those games and his best receiving yards in one game was 83 yards, along with 1 receiving touchdown in one of those games.

    -- Chase Brown was the most productive RB for the CIN Bengals:
    -- Brown recorded 215 total rushing yards and 156 receiving yards in Post and Reg season, along with 1 rushing touchdown and 1 receiving touchdown. 
    -- His best rushing yards in one game was 61 yards, along with 1 rushing touchdown in one of those games and his best receiving yards in one game was 80 yards, along with 1 receiving touchdown in one of those games.
    -- It's also good to note that Brown had a better receiving season than rushing season, which shows he is more of a receiving back than a traditional running back. Also, CIN is more of a pass heavy team, so it makes sense that Brown had more receiving yards than rushing yards.

    -- Rico Dowdle was the most productive RB for the DAL Cowboys:
    -- Dowdle recorded 399 total rushing yards and 158 receiving yards in Post and Reg season, along with 5 rushing touchdowns and 2 receiving touchdowns. 
    -- His best rushing yards in one game was 9 yards, along with 4 rushing touchdowns in one of those games and his best receiving yards in one game was 8 yards, along with 1 receiving touchdown in one of those games.
    -- Dowdle had a low rushing yardage but a high number of rushing touchdowns, which shows that he is more of a goal line back who is used in short yardage situations to score touchdowns rather than to gain a lot of yards.
    -- DAL is more if a pass heavy team, so it makes sense if Dowdle had more receiving yards than rushing yards, but he still had a good number of rushing touchdowns which shows he is effective in the red zone.

    -- De'Von Achane was the most productive RB for the MIA Dolphins:
    -- Achane recorded 824 total rushing yards and 218 receiving yards in Post and Reg season, along with 8 rushing touchdowns and 3 receiving touchdowns. 
    -- His best rushing yards in one game was 9 yards, along with 2 rushing touchdowns in one of those games and his best receiving yards in one game was 7 yards, along with 2 receiving touchdowns in one of those games.
    -- The data for best rushing and receiving yards in one game for Achane seems to be incorrect because it shows he had 9 rushing yards and 7 receiving yards as his best games, but he had a good total yardage for the season, so it's likely that there was an error in recording the weekly stats for Achane.

-- Based on the Data for RB, for the 2024 season we found:
    -- James Cook was, again, the most productive RB for the BUF Bills:
    -- Cook recorded 1,300 total rushing yards and 326 receiving yards in Post and Reg season, along with 22 rushing touchdowns and 2 receiving touchdowns. 
    -- His best rushing yards in one game was 97 yards, along with 5 rushing touchdowns in one of those games and his best receiving yards in one game was 9 yards, along with 1 receiving touchdown in one of those games.
    -- Cook had a great season and was a key part of the BUF offense, especially in the red zone where he scored a lot of his touchdowns. He had a good balance of rushing and receiving yards, but he was more effective as a rusher than a receiver based on his yardage and touchdowns.

    -- Chase Brown was, again, the most productive RB for the CIN Bengals:
    -- Brown recorded 1,014 total rushing yards and 360 receiving yards in Post and Reg season, along with 7 rushing touchdowns and 4 receiving touchdowns. 
    -- His best rushing yards in one game was 91 yards, along with 2 rushing touchdowns in one of those games and his best receiving yards in one game was 9 yards, along with 1 receiving touchdown in one of those games.
    -- This was Brown's best season yet, despite CIN being a pass heavy team, Brown was able to have a good balance of rushing and receiving yards, but he was more effective as a rusher than a receiver based on his yardage and touchdowns. He had a great season and was a key part of the CIN offense, especially in the red zone where he scored a lot of his touchdowns.

    -- Rico Dowdle was, again, the most productive RB for the DAL Cowboys:
    -- Dowdle recorded 1,100 total rushing yards and 249 receiving yards in Post and Reg season, along with 2 rushing touchdowns and 3 receiving touchdowns. 
    -- His best rushing yards in one game was 84 yards, along with 1 rushing touchdown in one of those games and his best receiving yards in one game was 6 yards, along with 1 receiving touchdown in one of those games.
    -- This was Dowdle's best season yet where he had over 1,000 rushing yards and a decent amount of receiving yards, despite his touchdowns decreasing a little.

    -- De'Von Achane was, again, the most productive RB for the MIA Dolphins:
    -- Achane recorded 910 total rushing yards and 595 receiving yards in Post and Reg season, along with 6 rushing touchdowns and 6 receiving touchdowns. 
    -- His best rushing yards in one game was 99 yards, along with 1 rushing touchdown in one of those games and his best receiving yards in one game was 8 yards, along with 2 receiving touchdowns in one of those games.
    -- This was also one of Achane's best seasons where he had a good amount of rushing yards and a good amount of receiving yards, but he was more effective as a rusher than a receiver based on his yardage and touchdowns. He had a great season and was a key part of the MIA offense, especially in the red zone where he scored a lot of his touchdowns.
    -- He was the most balanced RB out of the 4 teams in terms of rushing and receiving yards, but he was still more effective as a rusher than a receiver based on his yardage and touchdowns. He had a great season and was a key part of the MIA offense, especially in the red zone where he scored a lot of his touchdowns.


-- Takeaways:
    -- Each RB for each team became better between the 2023 and 2024 seasons in terms of total yardage and touchdowns, except for Dowdle who had a decrease in touchdowns but an increase in yardage.
    -- James Cook was the most productive RB out of the 4 teams in both seasons.
    -- De'Von Achane was the most balanced RB out of the 4 teams in terms of rushing and receiving yards, but he was still more effective as a rusher than a receiver based on his yardage and touchdowns.

/* TE Production */

Select *
from NFLSportsProject.dbo.yearly_player_stats_offense

Select *
from NFLSportsProject.dbo.weekly_player_stats_offense

WITH TE_Productivity AS (
    SELECT
        yr.player_id,
        yr.player_name,
        yr.team,
        yr.season,
        yr.position,
        yr.season_type,

        -- Year-level productivity
        yr.receiving_yards      AS season_receiving_yards,
        yr.receiving_touchdown     AS season_touchdowns,

        -- Most productive WEEK
        MAX(wk.receiving_yards)        AS max_week_receiving_yards,
        MAX(wk.receiving_touchdown)   AS max_week_receiving_td

    FROM NFLSportsProject.dbo.yearly_player_stats_offense  yr
    JOIN NFLSportsProject.dbo.weekly_player_stats_offense wk
        ON yr.player_id = wk.player_id
       AND yr.season    = wk.season
       AND yr.team      = wk.team

    WHERE yr.position = 'TE'
      AND yr.season IN ('2024', '2025')
      AND yr.team   IN ('BUF', 'CIN', 'DAL', 'MIA')

    GROUP BY
        yr.player_id,
        yr.player_name,
        yr.team,
        yr.season,
        yr.position,
        yr.receiving_yards,
        yr.receiving_touchdown,
        yr.season_type
)

SELECT *
FROM TE_Productivity
Where -- season = '2024'
season = '2025'
-- AND team = 'BUF'
-- AND team = 'CIN'
-- AND team = 'DAL'
-- AND team = 'MIA'
ORDER BY season_receiving_yards desc, season, team;

-- There isn't much data on TEs in the 2023 season and their is none for DAL, so we will look at the 2024 and 2025 seasons for TE productivity.


-- Based on the Data for TE, for the 2024 season we found:
    -- Zach Davisdson was the most productive TE for the BUF Bills:
    -- Davidso recorded 5 total yards in Post and Reg season and no touchdowns. His best receicing yards in one game was 5 yards.
    -- Their probably is more data for TEs on the BUF Bills, but it is not showing up in the data set, so it's likely that there was an error in recording the stats for the TEs on the BUF Bills.

    -- Erick All was the most productive TE for the CIN Bengals:
    -- Davidso recorded 158 total yards in Post and Reg season and no touchdowns. His best receicing yards in one game was 32 yards.
    -- CIN has two star WRs in Jamarr Chase and Tee Higgins, so the TE is not a focal point of their offense, which is likely why All had a low yardage and no touchdowns.

    -- DAL Cowboys do not have any data recorded for their TE.

    -- Tanner Conner was the most productive TE for the MIA Dolphins:
    -- Conner recorded 16 total yards in Post and Reg season and no touchdowns. His best receicing yards in one game was 15 yards.
    -- Looks like Conner had a game with only one yard, which is rare based on the data.

-- Based on the Data for TE, for the 2025 season we found:

    -- The DAL Cowboys, BUF Bills, & CIN Bengals do not have any data recorded for their TEs.

    -- Greg Dulcich was the most productive TE for the MIA Dolphins:
    -- Dulcich recorded 345 total yards in Post and Reg season and 1 touchdown. His best receicing yards in one game was 58 yards and 1 touchdown in one of those games.
    -- Conner did have a slightly better season than last season, with 91 receiving yards, but Dulcich took the lead in every category.


-- Takeaways:
    -- We need more data for TEs, especially for these 4 teams.
    -- It is rare to have a good TE on your team, so it's not surprising that the yardage and touchdowns for TEs are low compared to WRs and RBs.
    -- Suprisingly, Dulcich was the most productive TE out of the 4 teams in 2025, even though he was not the most productive TE in 2024, which shows that TEs can have breakout seasons and become key players for their teams.