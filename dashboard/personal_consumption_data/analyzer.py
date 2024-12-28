# -*- coding: UTF-8 -*-
# author:      Liu Kun
# email:       liukunup@outlook.com
# timestamp:   2023/04/02 11:36:25
# description: 数据分析与标记

import os
import argparse
from sqlalchemy import create_engine, text


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

def count_field_values(engine=None):
    """
    统计数据库中各字段的值出现次数
    :param config_file: 配置文件
    :param engine: 数据库引擎
    :return:
    """
    # 待统计的字段
    fields = ['category', 'counterparty', 'account', 'goods', 'income_or_expenditure', 'channel', 'status', 'comments']
    with engine.begin() as connection:
        print('-' * 100)
        for field in fields:
            # 查询字段值出现次数
            print(f'统计字段: {field}')
            query = text(f'SELECT {field}, COUNT(*) AS counts FROM dashboard.transaction GROUP BY {field} ORDER BY counts DESC')
            results = connection.execute(query)
            # 将数据插入或更新到数据库的transaction_tag表中
            for row in results:
                stmt = text('''INSERT INTO transaction_tag (field, value, counts) VALUES (:field, :value, :counts)
                               ON DUPLICATE KEY UPDATE counts = :counts_need_update, update_time = NOW()''')
                value, counts = row[0], row[1]
                if not value:
                    continue
                connection.execute(stmt, {
                    'field': field,
                    'value': value,
                    'counts': counts,
                    'counts_need_update': counts
                })


def app():
    """
    主函数
    :return:
    """
    # 解析从命令行输入的参数
    args = args_parser()
    # 创建数据库引擎
    engine = create_engine(f'mysql+pymysql://{args.username}:{args.password}@{args.host}:{args.port}/{args.database}')
    # 统计字段值出现次数
    count_field_values(engine=engine)


if __name__ == '__main__':
    hd = 'HomeLab Dashboard'
    print(f'[{hd}] 执行 数据分析与标记 脚本')
    print(f'[{hd}] 当前运行路径: {os.getcwd()}')
    app()
    print('\nDone!')
