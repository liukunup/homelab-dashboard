# -*- coding: UTF-8 -*-
# author:      Liu Kun
# email:       liukunup@outlook.com
# timestamp:   2024/12/30 00:15
# description: 已还款明细同步到数据库

import os
import argparse
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.dialects.mysql import insert


def args_parser():
    """
    命令行参数解析器
    :return: 从命令行输入的参数
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', type=str, default='localhost')
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--username', type=str, default='dashboard')
    parser.add_argument('--password', type=str)
    parser.add_argument('--database', type=str, default='dashboard')
    return parser.parse_args()


def insert_on_conflict_update(pd_table, conn, keys, data_iter):
    """
    当插入冲突时更新值
    :param pd_table: 数据表
    :param conn: 数据库连接
    :param keys: 键名列表
    :param data_iter: 数据迭代
    :return: 影响行数
    """
    data = [dict(zip(keys, row)) for row in data_iter]
    stmt = (
        insert(pd_table.table)
        .values(data)
    )
    stmt = stmt.on_duplicate_key_update(period=stmt.inserted.period, organization=stmt.inserted.organization,
                                        current_interest_rate=stmt.inserted.current_interest_rate, lpr_spread=stmt.inserted.lpr_spread,
                                        actual_principal_interest=stmt.inserted.actual_principal_interest,
                                        due_principal_interest=stmt.inserted.due_principal_interest,
                                        actual_principal=stmt.inserted.actual_principal, actual_interest=stmt.inserted.actual_interest,
                                        repayment_date=stmt.inserted.repayment_date, actual_interest_payment_date=stmt.inserted.actual_interest_payment_date,
                                        update_time=stmt.inserted.update_time)
    result = conn.execute(stmt)
    return result.rowcount


def loan_excel_parser(excel_file, engine=None):
    """
    已还款明细等 同步器
    :param excel_file: 已还款明细文件
    :param engine:     数据库引擎
    :return: 不涉及
    """
    # 文件读取
    df = pd.read_excel(excel_file, sheet_name="Sheet1")
    # 覆盖列名
    df.columns = ['period', 'organization', 'current_interest_rate', 'lpr_spread',
                  'actual_principal_interest', 'due_principal_interest', 'actual_principal', 'actual_interest',
                  'repayment_date', 'actual_interest_payment_date']
    # 添加更新时间
    df['update_time'] = pd.Timestamp.now()
    # 同步数据
    print(f'当前同步文件: {excel_file}')
    with engine.begin() as connection:
        df.to_sql('loan', con=connection, if_exists='append', index=False, chunksize=100,
                  method=insert_on_conflict_update)


def app():
    """ 已还款明细 """
    # 解析从命令行输入的参数
    args = args_parser()
    # 创建数据库引擎
    engine = create_engine(f'mysql+pymysql://{args.username}:{args.password}@{args.host}:{args.port}/{args.database}')
    # 过滤对账单文件
    loan_excel_parser(excel_file='已还款明细.xlsx', engine=engine)


if __name__ == '__main__':
    hd = 'HomeLab Dashboard'
    help = 'usage: python persist_to_db.py --host localhost --port 3306 --username <username> --password <password> --database dashboard'
    print(f'[{hd}] 执行 已还款明细 同步脚本')
    print(f'[{hd}] 当前运行路径: {os.getcwd()}')
    app()
    print('Done')
