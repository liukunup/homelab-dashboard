# -*- coding: UTF-8 -*-
# author:      Liu Kun
# email:       liukunup@outlook.com
# timestamp:   2024/2/7 00:28
# description: 个人薪资单同步到数据库

import re
import os
import typing
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
    当插入冲突时更新值(使用`dtm`+`company`交易订单号来确保记录唯一)
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
    stmt = stmt.on_duplicate_key_update(amount=stmt.inserted.amount, category=stmt.inserted.category,
                                        comments=stmt.inserted.comments)
    result = conn.execute(stmt)
    return result.rowcount


def salary_excel_parser(excel_file, engine=None):
    """
    薪资收入等 同步器
    :param excel_file: 薪资收入记录文件
    :param engine:     数据库引擎
    :return: 不涉及
    """
    # 文件读取
    df = pd.read_excel(excel_file, sheet_name="Sheet1")
    # 覆盖列名
    df.columns = ['dtm', 'company', 'amount', 'category', 'comments']
    # 同步数据
    print(f'当前同步文件: {excel_file}')
    with engine.begin() as connection:
        df.to_sql('salary', con=connection, if_exists='append', index=False, chunksize=100,
                  method=insert_on_conflict_update)


def app():
    """ 个人薪资单 """
    # 解析从命令行输入的参数
    args = args_parser()
    # 创建数据库引擎
    engine = create_engine(f'mysql+pymysql://{args.username}:{args.password}@{args.host}:{args.port}/{args.database}',
                           encoding='utf-8')
    # 过滤对账单文件
    salary_excel_parser(excel_file='薪资奖金记录.xlsx', engine=engine)


if __name__ == '__main__':
    hd = 'HomeLab Dashboard'
    print(f'[{hd}] 执行 个人薪资单 同步脚本')
    print(f'[{hd}] 当前运行路径: {os.getcwd()}')
    app()
    print('\nDone!')
