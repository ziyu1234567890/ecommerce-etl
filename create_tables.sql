-- ============================================================
-- 电商数仓 ETL 项目：建表语句
-- ============================================================

-- ------------------------------------------------------------
-- 1. 源数据库 ecommerce_source
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ecommerce_source DEFAULT CHARSET utf8mb4;

USE ecommerce_source;

-- 源表：原始订单数据（全 VARCHAR，模拟脏数据）
DROP TABLE IF EXISTS orders_raw;
CREATE TABLE orders_raw (
    user_id        VARCHAR(100),
    user_name      VARCHAR(100),
    product_id     VARCHAR(100),
    product_name   VARCHAR(100),
    category       VARCHAR(100),
    price          VARCHAR(100),
    purchase_time  VARCHAR(100),
    quantity       VARCHAR(100),
    total_amount   VARCHAR(100),
    city           VARCHAR(100),
    gender         VARCHAR(100),
    age            VARCHAR(100)
);


-- ------------------------------------------------------------
-- 2. 目标数据库 ecommerce_target
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ecommerce_target DEFAULT CHARSET utf8mb4;

USE ecommerce_target;

-- 清洗后宽表（由 Python ETL 脚本写入）
-- 列：user_id, user_name, product_id, product_name, category,
--     price, purchase_time, quantity, total_amount, city, gender, age

-- 维度表：用户维度（从 orders_clean 拆出）
-- DROP TABLE IF EXISTS dim_users;
-- CREATE TABLE dim_users AS
-- SELECT DISTINCT user_id, user_name, city, gender, age FROM orders_clean;

-- 事实表：订单事实（从 orders_clean 拆出）
-- DROP TABLE IF EXISTS fact_orders;
-- CREATE TABLE fact_orders AS
-- SELECT purchase_time, user_id, product_id, product_name, category,
--        price, quantity, total_amount FROM orders_clean;
