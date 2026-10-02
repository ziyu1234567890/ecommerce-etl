# -*- coding: utf-8 -*-
"""
ETL 清洗脚本：把 orders_raw 的脏数据清洗后写入 orders_clean
"""
import sys
import pandas as pd
from urllib.parse import quote_plus
from sqlalchemy import create_engine, text

# ============ 配置区 ============
DB_USER = "root"
DB_PASSWORD = "Root@123456"
DB_HOST = "localhost"
DB_PORT = 3306
SRC_DB = "ecommerce_source"
DST_DB = "ecommerce_target"
# ================================


def log(step, df, extra=""):
    print(f"  [{step}] 剩余 {len(df)} 行  {extra}")


def main():
    # 连接 MySQL
    pwd = quote_plus(DB_PASSWORD)
    url = (f"mysql+pymysql://{DB_USER}:{pwd}"
           f"@{DB_HOST}:{DB_PORT}?charset=utf8mb4")
    engine = create_engine(url)
    print("[连接] MySQL 8.0.29\n")

    # 1. 读取源表
    print("=== 读取源表 ===")
    df = pd.read_sql(f"SELECT * FROM {SRC_DB}.orders_raw", engine)
    log("原始", df)

    # 2. 去重：user_id + product_id + purchase_time 相同视为重复，保留第一条
    print("\n=== 1. 去重 ===")
    before = len(df)
    df = df.drop_duplicates(subset=["user_id", "product_id", "purchase_time"], keep="first")
    log("去重后", df, f"（删除 {before - len(df)} 行重复）")

    # 3. 金额字段：转数值，空值用同 category 均值填充，保留两位小数
    print("\n=== 2. 清洗金额（price / total_amount）===")
    for col in ["price", "total_amount"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")  # 无法转数值的变 NaN
        # 按 category 分组填均值
        df[col] = df.groupby("category")[col].transform(lambda s: s.fillna(s.mean()))
        # 兜底：如果整组都是空，用全局均值
        df[col] = df[col].fillna(df[col].mean())
        df[col] = df[col].round(2)
    log("金额清洗后", df)

    # 4. quantity：转数值，空值或 ≤0 的过滤掉
    print("\n=== 3. 清洗数量（quantity）===")
    before = len(df)
    df["quantity"] = pd.to_numeric(df["quantity"], errors="coerce")
    df = df[(df["quantity"].notna()) & (df["quantity"] > 0)]
    df["quantity"] = df["quantity"].astype(int)
    log("数量清洗后", df, f"（删除 {before - len(df)} 行）")

    # 5. purchase_time：统一为 YYYY-MM-DD HH:MM:SS，解析不了的丢弃
    print("\n=== 4. 清洗时间（purchase_time）===")
    before = len(df)
    df["purchase_time"] = pd.to_datetime(df["purchase_time"], errors="coerce")
    df = df[df["purchase_time"].notna()]
    df["purchase_time"] = df["purchase_time"].dt.strftime("%Y-%m-%d %H:%M:%S")
    log("时间清洗后", df, f"（删除 {before - len(df)} 行）")

    # 6. age：转数值，过滤 <0 或 >100
    print("\n=== 5. 清洗年龄（age）===")
    before = len(df)
    df["age"] = pd.to_numeric(df["age"], errors="coerce")
    df = df[(df["age"].notna()) & (df["age"] >= 0) & (df["age"] <= 100)]
    df["age"] = df["age"].astype(int)
    log("年龄清洗后", df, f"（删除 {before - len(df)} 行）")

    # 7. city：去前后空格，空值填"未知"
    print("\n=== 6. 清洗城市（city）===")
    df["city"] = df["city"].astype(str).str.strip()
    df.loc[df["city"].isin(["", "nan", "None"]), "city"] = "未知"
    log("城市清洗后", df)

    # 8. gender：统一为 男/女/未知
    print("\n=== 7. 清洗性别（gender）===")
    df["gender"] = df["gender"].astype(str).str.strip()
    df.loc[~df["gender"].isin(["男", "女"]), "gender"] = "未知"
    log("性别清洗后", df)

    # 9. 写入目标表
    print(f"\n=== 写入 {DST_DB}.orders_clean ===")
    df.to_sql(
        name="orders_clean",
        con=engine,
        schema=DST_DB,
        if_exists="replace",
        index=False,
        chunksize=1000,
    )

    # 验证
    with engine.connect() as conn:
        cnt = conn.execute(text(f"SELECT COUNT(*) FROM {DST_DB}.orders_clean")).scalar()
    print(f"\n{'='*40}")
    print(f"清洗前行数: 1000")
    print(f"清洗后行数: {cnt}")
    print(f"最终表: {DST_DB}.orders_clean")


if __name__ == "__main__":
    main()
