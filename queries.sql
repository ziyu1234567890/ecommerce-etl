-- ============================================================
-- ETL 项目分析 SQL（数据库：ecommerce_target）
-- ============================================================

-- ------------------------------------------------------------
-- 查询1：每个城市消费金额 TOP3 用户
-- 思路：先按城市+用户聚合消费总额，再用 ROW_NUMBER() 按城市排名取前3
-- ------------------------------------------------------------
WITH user_spend AS (
    -- 第一步：JOIN 两张表，按城市+用户聚合消费总额
    SELECT
        u.city,
        u.user_name,
        SUM(f.total_amount) AS total_spend
    FROM fact_orders f
    JOIN dim_users u ON f.user_id = u.user_id
    GROUP BY u.city, u.user_name
),
ranked AS (
    -- 第二步：按城市分组，按消费金额降序排名
    SELECT
        city,
        user_name,
        total_spend,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_spend DESC) AS rn
    FROM user_spend
)
-- 第三步：只取每个城市前3名
SELECT city, user_name, ROUND(total_spend, 2) AS total_spend
FROM ranked
WHERE rn <= 3
ORDER BY city, rn;


-- ------------------------------------------------------------
-- 查询2：每个商品类别销量排名
-- 思路：先按 category+product_name 聚合销量，再用 RANK() 排名
-- ------------------------------------------------------------
WITH product_sales AS (
    -- 第一步：按类别+商品聚合销量
    SELECT
        category,
        product_name,
        SUM(quantity) AS total_qty
    FROM fact_orders
    GROUP BY category, product_name
),
ranked AS (
    -- 第二步：按类别分组，按销量降序排名（RANK 允许并列）
    SELECT
        category,
        product_name,
        total_qty,
        RANK() OVER (PARTITION BY category ORDER BY total_qty DESC) AS sales_rank
    FROM product_sales
)
SELECT category, product_name, total_qty, sales_rank
FROM ranked
ORDER BY category, sales_rank;


-- ------------------------------------------------------------
-- 查询3：用户消费金额及占比
-- 思路：先算每个用户的总消费，再算全部订单总金额，最后求占比
-- ------------------------------------------------------------
WITH user_spend AS (
    -- 第一步：每个用户的总消费
    SELECT
        u.user_name,
        SUM(f.total_amount) AS total_spend
    FROM fact_orders f
    JOIN dim_users u ON f.user_id = u.user_id
    GROUP BY u.user_name
),
grand_total AS (
    -- 第二步：全部订单总金额
    SELECT SUM(total_amount) AS total_all FROM fact_orders
)
-- 第三步：计算占比
SELECT
    user_name,
    ROUND(total_spend, 2) AS total_spend,
    ROUND(total_spend / (SELECT total_all FROM grand_total) * 100, 2) AS pct_share
FROM user_spend
ORDER BY total_spend DESC;
