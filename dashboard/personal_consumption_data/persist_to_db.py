# -*- coding: UTF-8 -*-
# author:      Liu Kun
# email:       liukunup@outlook.com
# timestamp:   2023/04/02 11:36:25
# description: 电子对账单同步到数据库

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
    parser.add_argument('--path', type=str, default='.')
    parser.add_argument('--host', type=str, default='localhost')
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--username', type=str, default='dashboard')
    parser.add_argument('--password', type=str)
    parser.add_argument('--database', type=str, default='dashboard')
    return parser.parse_args()


def csv_filter(path: typing.Text = '.'):
    """
    对账单文件过滤器
    目标是 找到存放目录中符合要求的对账单文件
    :param path: 存放对账单的目录
    :return: 搜索到的对账单文件列表
    """
    if not os.path.exists(path) or not os.access(path, os.R_OK):
        raise RuntimeError(f'The path {path} is invalid.')
    csv_files = list()
    for root, _, files in os.walk(path):
        if root != path: break
        for file in files:
            filename = os.path.join(root, file)
            if re.match(r'微信支付账单\(\d{8}-\d{8}\).csv', file):
                csv_files.append(['WeChat Pay', filename])
            if re.match(r'alipay_record_\d{8}_\d{6}.csv', file):
                csv_files.append(['Alipay', filename])
    return csv_files


def insert_on_conflict_update(pd_table, conn, keys, data_iter):
    """
    当插入冲突时更新值(使用`po_transaction`交易订单号来确保记录唯一)
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
    stmt = stmt.on_duplicate_key_update(timestamp=stmt.inserted.timestamp, category=stmt.inserted.category,
                                        counterparty=stmt.inserted.counterparty, account=stmt.inserted.account,
                                        goods=stmt.inserted.goods,
                                        income_or_expenditure=stmt.inserted.income_or_expenditure,
                                        amount=stmt.inserted.amount, channel=stmt.inserted.channel,
                                        status=stmt.inserted.status, po_seller=stmt.inserted.po_seller,
                                        comments=stmt.inserted.comments)
    result = conn.execute(stmt)
    return result.rowcount


def alipay_csv_synchronizer(csv_file, code=1, engine=None):
    """
    支付宝 电子对账单 同步器
    :param csv_file: 电子对账单文件
    :param code:     支付类型枚举值
    :param engine:   数据库引擎
    :return: 不涉及
    """
    # 文件读取(编码格式:GBK; 跳过行数:24)
    df = pd.read_csv(csv_file, sep=',', encoding="gbk", skiprows=lambda x: x < 24)
    # 覆盖列名
    df.columns = ['timestamp', 'category', 'counterparty', 'account', 'goods', 'income_or_expenditure', 'amount',
                  'channel', 'status', 'po_transaction', 'po_seller', 'comments', 'unknown']
    # 添加来源
    df.loc[:, 'source'] = code
    # 去除多余列
    df = df.drop(labels='unknown', axis=1)
    # 去除行首尾空格
    for k in ['timestamp', 'category', 'counterparty', 'account', 'goods', 'income_or_expenditure', 'channel', 'status',
              'po_transaction', 'po_seller', 'comments']:
        df[k] = df[k].apply(lambda s: s if not isinstance(s, str) else s.strip())
    # 去除多余制表符
    df['po_transaction'] = df['po_transaction'].apply(lambda s: s.replace('\t', ''))
    df['po_seller'] = df['po_seller'].apply(lambda s: s.replace('\t', ''))

    # 同步数据
    print(f'当前同步文件: {csv_file}')
    with engine.begin() as connection:
        df.to_sql('transaction', con=connection, if_exists='append', index=False, chunksize=100,
                  method=insert_on_conflict_update)


def wechatpay_csv_parser(csv_file, code=2, engine=None):
    """
    微信支付 电子对账单 同步器
    :param csv_file: 电子对账单文件
    :param code:     支付类型枚举值
    :param engine:   数据库引擎
    :return: 不涉及
    """
    # 文件读取(编码格式:UTF-8; 跳过行数:17)
    df = pd.read_csv(csv_file, sep=',', encoding='utf-8', skiprows=lambda x: x < 16)
    # 覆盖列名
    df.columns = ['timestamp', 'category', 'counterparty', 'goods', 'income_or_expenditure',
                  'amount', 'channel', 'status', 'po_transaction', 'po_seller', 'comments']
    # 添加来源
    df.loc[:, 'account'] = None
    df.loc[:, 'source'] = code
    # 处理¥符号以及转格式
    df['amount'] = df['amount'].apply(lambda s: float(s.replace('¥', '')))
    # 去除多余制表符
    df['po_transaction'] = df['po_transaction'].apply(lambda s: s.replace('\t', ''))
    df['po_seller'] = df['po_seller'].apply(lambda s: s.replace('\t', ''))

    # 同步数据
    print(f'当前同步文件: {csv_file}')
    with engine.begin() as connection:
        df.to_sql('transaction', con=connection, if_exists='append', index=False, chunksize=100,
                  method=insert_on_conflict_update)


def app():
    """
    对账单
    :return:
    """
    # 支付类型枚举 (枚举值, 同步器)
    pay_mapping = {
        'Alipay': (1, alipay_csv_synchronizer),
        'WeChat Pay': (2, wechatpay_csv_parser),
    }
    # 解析从命令行输入的参数
    args = args_parser()
    # 创建数据库引擎
    engine = create_engine(f'mysql+pymysql://{args.username}:{args.password}@{args.host}:{args.port}/{args.database}')
    # 过滤对账单文件
    csv_files = csv_filter(path=args.path)
    for csv_type, csv_file in csv_files:
        code, func = pay_mapping[csv_type]
        func(csv_file, code, engine)


if __name__ == '__main__':
    hd = 'HomeLab Dashboard'
    print(f'[{hd}] 执行 电子对账单数据 同步脚本')
    print(f'[{hd}] 当前运行路径: {os.getcwd()}')
    app()
    print('\nDone!')
