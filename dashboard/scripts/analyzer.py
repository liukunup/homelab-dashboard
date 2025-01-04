# -*- coding: UTF-8 -*-
# author:      Liu Kun
# email:       liukunup@outlook.com
# timestamp:   2025/01/01 17:49:00
# description: 数据分析器

import os
import json
import typing
import argparse
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
from dotenv import load_dotenv


class AbstractAnalyzer:
    """ 分析器的抽象类 """

    # 数据库
    __host = None
    __port = 3306
    __username = None
    __password = None
    __database = 'dashboard'

    def __init__(self, host, port, username, password, database: typing.Text = 'dashboard'):
        """ 初始化 """
        # 从`.env`文件中加载环境变量
        load_dotenv()
        # 获取数据库连接参数
        self.__host = host or os.environ.get('DB_HOST', 'localhost')
        self.__port = port or int(os.environ.get('DB_PORT', 3306))
        self.__username = username or os.environ.get('DB_USERNAME')
        self.__password = password or os.environ.get('DB_PASSWORD')
        self.__database = database or os.environ.get('DB_DATABASE', 'dashboard')
        # 创建数据库连接
        quoted_password = quote_plus(self.__password)
        self._engine = create_engine(f'mysql+pymysql://{self.__username}:{quoted_password}@{self.__host}:{self.__port}/{self.__database}?charset=utf8mb4',
                                     connect_args={'init_command': 'SET time_zone="+08:00"'})

    def analyze(self, **kwargs):
        """ 执行分析 """
        raise NotImplementedError('请在子类中实现该方法')


class FrequencyAnalyzer(AbstractAnalyzer):
    """ 频次分析器 """

    def analyze(self, **kwargs):
        """
        逐字段统计`transaction`表里字段值的出现次数,并将统计结果重新插入或更新到`transaction_tag`表中
        :return: None
        """
        # 打印`kwargs`参数
        print(f'辅助参数: {kwargs}')

        # 待统计字段
        fields = ['category', 'counterparty', 'account', 'goods', 'income_or_expenditure', 'channel', 'status', 'comments']

        # 创建数据库连接
        with self._engine.begin() as connection:

            print('-' * 100)
            for field in fields:

                # 统计字段值出现次数
                print(f'统计字段: {field}')
                query = text(f'SELECT {field}, COUNT(*) AS counts FROM dashboard.transaction GROUP BY {field} ORDER BY counts DESC')
                results = connection.execute(query)

                # 重新插入或更新到`transaction_tag`表中
                for row in results:
                    stmt = text('''INSERT INTO transaction_tag (field, value, counts) VALUES (:field, :value, :counts)
                                   ON DUPLICATE KEY UPDATE counts = :counts_need_update, update_time = NOW()''')
                    value, counts = row[0], row[1]
                    # 如果字段值为空,则跳过
                    if not value:
                        continue
                    connection.execute(stmt, {
                        'field': field,
                        'value': value,
                        'counts': counts,
                        'counts_need_update': counts
                    })

        # 打印分割线
        print('-' * 100)


class PreMarkAnalyzer(AbstractAnalyzer):
    """ 预标记分析器 """

    def analyze(self, **kwargs):
        # 打印`kwargs`参数
        print(f'辅助参数: {kwargs}')
        op = kwargs.get('op', 'import')
        if op == 'import':
            self.import_tags()
        elif op == 'export':
            self.export_tags()
        else:
            print(f'未知操作: {op}')

    def import_tags(self, **kwargs):
        """
        从json文件中导入标签数据到`transaction_tag`表中
        :return: None
        """
        # 读取json文件
        with open('transaction_tag.json', 'r', encoding='utf-8') as file:
            data = json.load(file)
            # 创建数据库连接
            with self._engine.begin() as connection:
                # 遍历json数据
                for field, tags in data.items():
                    for tag, values in tags.items():
                        if tag == '暂未标记':
                            continue
                        print(f'字段: {field}, 标签: {tag}, 值的数量: {len(values)}')
                        for value in values:
                            stmt = text('''INSERT INTO transaction_tag (field, value, counts, tag) VALUES (:field, :value, 0, :tag)
                                           ON DUPLICATE KEY UPDATE tag = :tag_need_update, update_time = NOW()''')
                            connection.execute(stmt, {
                                'field': field,
                                'value': value,
                                'tag': tag,
                                'tag_need_update': tag
                            })
        # 打印分割线
        print('<' * 100)

    def export_tags(self, **kwargs):
        """
        从`transaction_tag`表中导入标签数据到json文件中
        :return: None
        """
        white_list = ['category', 'counterparty', 'goods', 'income_or_expenditure', 'channel']
        black_list = ['account']
        # 创建数据库连接
        with self._engine.begin() as connection:
            # 查询标签数据
            query = text('SELECT `field`, `value`, `tag` FROM dashboard.transaction_tag')
            results = connection.execute(query)
            # 遍历结果集
            output = {}
            for row in results:
                field, value, tag = row[0], row[1], row[2]
                # 跳过黑名单字段
                if field in black_list:
                    continue
                # 只保留白名单字段
                if field not in white_list:
                    continue
                if field not in output:
                    output[field] = {tag: [value]}
                else:
                    if tag not in output[field]:
                        output[field][tag] = [value]
                    else:
                        output[field][tag].append(value)
            # 将标签数据写入json文件
            with open('transaction_tag.json', 'w', encoding='utf-8') as file:
                file.write(json.dumps(output, ensure_ascii=False, indent=4))
                print(f'标签数据已导出到文件: transaction_tag.json')
        # 打印分割线
        print('>' * 100)


def args_parser():
    """
    命令行参数解析
    :return: 从命令行输入的参数
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', type=str)
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--username', type=str)
    parser.add_argument('--password', type=str)
    parser.add_argument('--database', type=str, default='dashboard')
    parser.add_argument('--type', type=str, default='Frequency', choices=['Frequency', 'PreMark'])
    return parser.parse_args()


def app():
    """ 应用程序 """
    print('-' * 100)
    name = 'HomeLab Dashboard - Analyzer'
    print(f'[{name}] Usage: python analyzer.py '
           '--host localhost --port 3306 --username <username> --password <password> --database dashboard '
           '--type <name>')
    print(f'[{name}] 当前运行路径: {os.getcwd()}')
    print(f'[{name}] 开始执行脚本...')
    print('-' * 100)
    # 从命令行获取参数
    args = args_parser()
    # 按要求执行分析
    operator = {
        'Frequency': {
            'name': '频次分析器',
            'class': FrequencyAnalyzer,
        },
        'PreMark': {
            'name': '预标记分析器',
            'class': PreMarkAnalyzer,
            'kwargs': {
                'op': 'export',
            }
        }
    }[args.type]
    print(f'[{name}] 当前分析器: {operator["name"]}')
    print('-' * 100)
    analyzer = operator['class'](host=args.host, port=args.port, username=args.username, password=args.password, database=args.database)
    analyzer.analyze(**operator.get('kwargs', {}))
    print(f'[{name}] 执行完成!')


if __name__ == '__main__':
    # 应用程序入口
    app()
