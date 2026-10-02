# 电商数仓 ETL 项目
## 项目简介
独立完成一个完整的电商数仓 ETL 流程：从 MySQL 源库抽取脏数据，用 Python + Pandas 清洗后写入目标库，再用 SQL 建维度表/事实表，并完成多维度分析查询。
## 技术栈
- Python（Pandas、SQLAlchemy）
- MySQL
- SQL（JOIN、窗口函数、CTE）
## 项目流程
1. 在 MySQL 建源表 `orders_raw`，导入电商脏数据
2. 用 Python 读取源表，完成去重、空值填充、格式统一、异常值过滤
3. 清洗后数据写入 `ecommerce_target.orders_clean`
4. 基于清洗数据建 `dim_users`（维度表）和 `fact_orders`（事实表）
5. 用 SQL 完成 3 个业务分析查询
## 分析查询
- 每个城市消费金额 TOP3 用户（ROW_NUMBER）
- 每个商品类别销量排名（RANK）
- 用户消费金额及占比（CTE）
## 遇到的困难与解决
- 源数据日期格式不统一（`2024/1/1` 和 `2024-01-01`），用 `pd.to_datetime(errors='coerce')` 统一处理
- 金额字段有空值和带空格的情况，用 `pd.to_numeric(errors='coerce')` 转换后按类别均值填充
## 代码与文件
- `etl_clean.py`：数据清洗脚本
- `queries.sql`：分析查询
- `create_tables.sql`：建表语句
