-- ============================================================
-- Customer Segmentation using RFM Analysis
-- Project: Customer Segmentation (RFM Analysis)
-- Platform: Google BigQuery
-- ============================================================

-- Step 1: Calculate customer-level RFM metrics
WITH rfm AS (

    SELECT
        customer_id,

        -- Recency: Number of days since the customer's last purchase
        DATE_DIFF(
            (
                SELECT MAX(order_date)
                FROM `growth-analytics-kamala.growth_analytics.orders`
            ),
            MAX(order_date),
            DAY
        ) AS recency,

        -- Frequency: Number of delivered orders
        COUNT(order_id) AS frequency,

        -- Monetary: Total value of delivered orders
        SUM(total_amount) AS monetary

    FROM `growth-analytics-kamala.growth_analytics.orders`

    WHERE order_status = 'Delivered'

    GROUP BY customer_id
),

-- Step 2: Assign RFM scores from 1 to 5
rfm_scores AS (

    SELECT
        *,

        -- Lower recency is better, therefore the ordering is descending
        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS recency_score,

        -- Higher frequency is better
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        -- Higher monetary value is better
        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM rfm
)

-- Step 3: Assign customers to business segments
SELECT
    *,

    CASE
        WHEN recency_score >= 4
         AND frequency_score >= 4
         AND monetary_score >= 4
            THEN 'Champions'

        WHEN frequency_score >= 4
            THEN 'Loyal Customers'

        WHEN recency_score <= 2
            THEN 'At Risk'

        ELSE 'Potential Loyalists'

    END AS customer_segment

FROM rfm_scores;
