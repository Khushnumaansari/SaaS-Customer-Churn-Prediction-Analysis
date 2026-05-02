SELECT *
FROM customers


-- QUERY 1: EXECUTIVE CHURN SUMMARY
SELECT
    COUNT(*) AS total_customers,
    SUM(churned) AS churned_customers,
    CAST(ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS DECIMAL(10,2)) 
    AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churned = 1
          THEN monthly_charges_usd * 12 ELSE 0 END), 0)
          AS annual_revenue_at_risk,
    ROUND(AVG(CASE WHEN churned = 1
          THEN monthly_charges_usd END), 2)
          AS avg_monthly_rev_churned,
    ROUND(AVG(CASE WHEN churned = 0
          THEN monthly_charges_usd END), 2)
          AS avg_monthly_rev_active
FROM customers;


-- QUERY 2: CHURN RATE BY SUBSCRIPTION PLAN
SELECT
    subscription_plan,
    COUNT(*) AS total_customers,
    SUM(churned) AS churned,
    ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges_usd), 2) AS avg_monthly_charges,
    ROUND(SUM(CASE WHEN churned = 1
          THEN monthly_charges_usd * 12 ELSE 0 END), 0)
          AS revenue_at_risk
FROM customers
GROUP BY subscription_plan
ORDER BY churn_rate_pct DESC;


-- QUERY 3: CHURN BY CONTRACT TYPE & PLAN (CROSS ANALYSIS)
SELECT
    contract_type,
    subscription_plan,
    COUNT(*) AS customers,
    SUM(churned) AS churned,
    CAST(ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS DECIMAL(10, 2)) AS churn_rate_pct,
    ROUND(AVG(engagement_score), 1) AS avg_engagement
FROM customers
GROUP BY contract_type, subscription_plan
ORDER BY churn_rate_pct DESC;


-- QUERY 4: HIGH-RISK CUSTOMERS (The Money Query)
-- Customers likely to churn — for account manager action list
SELECT TOP 50
    customer_id,
    company_name,
    industry,
    subscription_plan,
    monthly_charges_usd,
    days_since_last_login,
    support_tickets_90d,
    nps_score,
    engagement_score,
    health_score,
    risk_sagment,
    ROUND(monthly_charges_usd * 12, 0) AS annual_value,
    CASE
        WHEN health_score < 30 THEN 'CRITICAL — Immediate Action'
        WHEN health_score < 50 THEN 'HIGH RISK — Outreach This Week'
        WHEN health_score < 70 THEN 'MEDIUM RISK — Monitor Weekly'
        ELSE 'LOW RISK — Standard Check-in'
    END AS action_priority
FROM customers
WHERE churned = 0
  AND health_score < 50
ORDER BY monthly_charges_usd DESC, health_score ASC;


-- QUERY 5: CHURN BY INDUSTRY WITH REVENUE IMPACT
SELECT
    industry,
    COUNT(*) AS total_customers,
    SUM(churned) AS churned,
    CAST(ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS DECIMAL(10,2)) AS churn_rate_pct,
    ROUND(SUM(monthly_charges_usd), 0) AS total_monthly_revenue,
    ROUND(SUM(CASE WHEN churned = 1
          THEN monthly_charges_usd * 12 ELSE 0 END), 0)
          AS annual_revenue_lost,
    ROUND(AVG(engagement_score), 1) AS avg_engagement,
    ROUND(AVG(nps_score), 1) AS avg_nps
FROM customers
GROUP BY industry
ORDER BY annual_revenue_lost DESC;



-- QUERY 6: THE 14-DAY LOGIN + SUPPORT TICKET ANALYSIS
-- (Your business suggestion validation)
SELECT
    CASE
        WHEN days_since_last_login > 14 AND support_tickets_90d >= 2
            THEN 'High Risk (14d+ no login & 2+ tickets)'
        WHEN days_since_last_login > 14
            THEN 'Inactive Only'
        WHEN support_tickets_90d >= 2
            THEN 'Support Issues Only'
        ELSE 'Normal'
    END AS risk_category,
    COUNT(*) AS customers,
    SUM(churned) AS churned,
    ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churned = 1
          THEN monthly_charges_usd * 12 ELSE 0 END), 0)
          AS revenue_at_risk
FROM customers
GROUP BY CASE
        WHEN days_since_last_login > 14 AND support_tickets_90d >= 2
            THEN 'High Risk (14d+ no login & 2+ tickets)'
        WHEN days_since_last_login > 14
            THEN 'Inactive Only'
        WHEN support_tickets_90d >= 2
            THEN 'Support Issues Only'
        ELSE 'Normal'
    END
ORDER BY churn_rate_pct DESC;



-- QUERY 7: ONBOARDING IMPACT ON CHURN
SELECT
    onboarding_completed,
    has_dedicated_csm,
    COUNT(*) AS customers,
    ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(engagement_score), 1) AS avg_engagement,
    ROUND(AVG(features_used_pct), 1) AS avg_features_used,
    ROUND(AVG(tenure_months), 0) AS avg_tenure
FROM customers
GROUP BY onboarding_completed, has_dedicated_csm
ORDER BY churn_rate_pct DESC;



-- QUERY 8: MONTHLY CHURN TREND
SELECT
    signup_year,
    signup_quater,
    COUNT(*) AS cohort_size,
    SUM(churned) AS churned,
    ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(tenure_months), 0) AS avg_tenure,
    ROUND(AVG(monthly_charges_usd), 2) AS avg_revenue
FROM customers
GROUP BY signup_year, signup_quater
ORDER BY signup_year, signup_quater;



-- QUERY 9: CHURN REASON DEEP DIVE WITH PROFILES
SELECT
    churn_reason,
    COUNT(*) AS count,
    ROUND(AVG(monthly_charges_usd), 2) AS avg_revenue,
    ROUND(AVG(tenure_months), 0) AS avg_tenure,
    ROUND(AVG(nps_score), 1) AS avg_nps,
    ROUND(AVG(support_tickets_90d), 1) AS avg_tickets,
    ROUND(AVG(engagement_score), 1) AS avg_engagement,
    ROUND(AVG(days_since_last_login), 0) AS avg_days_inactive
FROM customers
WHERE churned = 1
GROUP BY churn_reason
ORDER BY count DESC;



-- QUERY 10: CUSTOMER LIFETIME VALUE SEGMENTS
SELECT
    CASE
        WHEN total_revenue_lifetime_usd > 5000 THEN 'Platinum (>$5K)'
        WHEN total_revenue_lifetime_usd > 2000 THEN 'Gold ($2K-$5K)'
        WHEN total_revenue_lifetime_usd > 500 THEN 'Silver ($500-$2K)'
        ELSE 'Bronze (<$500)'
    END AS clv_segment,
    COUNT(*) AS customers,
    SUM(churned) AS churned,
    ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(total_revenue_lifetime_usd), 0) AS total_ltv,
    ROUND(AVG(engagement_score), 1) AS avg_engagement
FROM customers
GROUP BY CASE
        WHEN total_revenue_lifetime_usd > 5000 THEN 'Platinum (>$5K)'
        WHEN total_revenue_lifetime_usd > 2000 THEN 'Gold ($2K-$5K)'
        WHEN total_revenue_lifetime_usd > 500 THEN 'Silver ($500-$2K)'
        ELSE 'Bronze (<$500)'
    END
ORDER BY churn_rate_pct DESC;



-- QUERY 11: COUNTRY-LEVEL ANALYSIS
SELECT
    country,
    COUNT(*) AS customers,
    ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthly_charges_usd), 0) AS total_monthly_rev,
    ROUND(AVG(nps_score), 1) AS avg_nps,
    ROUND(AVG(support_tickets_90d), 1) AS avg_support_tickets
FROM customers
GROUP BY country
ORDER BY churn_rate_pct DESC;


-- QUERY 12: FEATURE ADOPTION VS CHURN
SELECT
    CASE
        WHEN features_used_pct < 20 THEN '1. Very Low (<20%)'
        WHEN features_used_pct < 40 THEN '2. Low (20-40%)'
        WHEN features_used_pct < 60 THEN '3. Medium (40-60%)'
        WHEN features_used_pct < 80 THEN '4. High (60-80%)'
        ELSE '5. Power User (80%+)'
    END AS feature_adoption_level,
    COUNT(*) AS customers,
    ROUND(AVG(CAST(churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(integrations_connected), 1) AS avg_integrations,
    ROUND(AVG(engagement_score), 1) AS avg_engagement
FROM customers
GROUP BY CASE
        WHEN features_used_pct < 20 THEN '1. Very Low (<20%)'
        WHEN features_used_pct < 40 THEN '2. Low (20-40%)'
        WHEN features_used_pct < 60 THEN '3. Medium (40-60%)'
        WHEN features_used_pct < 80 THEN '4. High (60-80%)'
        ELSE '5. Power User (80%+)'
    END
ORDER BY feature_adoption_level;